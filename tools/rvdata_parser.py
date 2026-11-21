"""Minimal Ruby Marshal (4.8) reader for RPG Maker VX Ace .rvdata files.

Converts Ruby objects to plain Python dictionaries/lists so the Godot project
can consume them as JSON placeholder data. Supports the type subset used by
RGSS3 database files.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


class MarshalError(Exception):
    pass


class RubyObject:
    def __init__(self, class_name: str, ivars: dict[str, Any]):
        self.class_name = class_name
        self.ivars = ivars

    def to_dict(self) -> dict[str, Any]:
        result: dict[str, Any] = {"__class__": self.class_name}
        for key, value in self.ivars.items():
            result[key] = to_plain(value)
        return result


def to_plain(value: Any) -> Any:
    if isinstance(value, RubyObject):
        return value.to_dict()
    if isinstance(value, dict):
        return {str(k): to_plain(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [to_plain(v) for v in value]
    if isinstance(value, bytes):
        return value.decode("utf-8", errors="replace")
    return value


def to_hashable(value: Any) -> Any:
    if isinstance(value, list):
        return tuple(value)
    if isinstance(value, dict):
        return tuple(sorted(value.items(), key=lambda item: str(item[0])))
    return value


class MarshalReader:
    def __init__(self, data: bytes):
        self.data = data
        self.pos = 0
        self.symbols: list[str] = []
        self.objects: list[Any] = [None]  # object links are one-indexed

    def read_byte(self) -> int:
        if self.pos >= len(self.data):
            raise MarshalError("unexpected end of data")
        value = self.data[self.pos]
        self.pos += 1
        return value

    def read_bytes(self, count: int) -> bytes:
        if count < 0 or self.pos + count > len(self.data):
            raise MarshalError("invalid byte count")
        value = self.data[self.pos:self.pos + count]
        self.pos += count
        return value

    def read_int(self) -> int:
        first = self.read_byte()
        if first == 0:
            return 0
        if first == 1:
            return self.read_byte()
        if first == 0xFF:
            return -self.read_byte()
        if first == 2:
            return int.from_bytes(self.read_bytes(2), "little", signed=False)
        if first == 0xFE:
            return int.from_bytes(self.read_bytes(2), "little", signed=True)
        if first == 3:
            return int.from_bytes(self.read_bytes(3), "little", signed=False)
        if first == 0xFD:
            return int.from_bytes(self.read_bytes(3), "little", signed=True)
        if first == 4:
            return int.from_bytes(self.read_bytes(4), "little", signed=False)
        if first == 0xFC:
            return int.from_bytes(self.read_bytes(4), "little", signed=True)
        signed = first - 256 if first > 127 else first
        return signed - 5 if signed > 0 else signed + 5

    def read_long(self) -> int:
        return self.read_int()

    def read_byte_sequence(self) -> bytes:
        length = self.read_long()
        return self.read_bytes(length)

    def read_symbol(self) -> str:
        tag = self.read_byte()
        if chr(tag) == ';':
            index = self.read_long()
            if index >= len(self.symbols):
                raise MarshalError(f"bad symbol link {index}")
            return self.symbols[index]
        if chr(tag) != ':':
            raise MarshalError(f"expected symbol, got {tag!r}")
        name = self.read_byte_sequence().decode("utf-8", errors="replace")
        self.symbols.append(name)
        return name

    def read_value(self) -> Any:
        tag = self.read_byte()
        ch = chr(tag)
        if ch == '0':
            return None
        if ch == 'T':
            return True
        if ch == 'F':
            return False
        if ch == 'i':
            return self.read_int()
        if ch == 'f':
            text = self.read_byte_sequence().decode("ascii", errors="replace")
            try:
                return float(text)
            except ValueError:
                return text
        if ch == '"':
            return self.read_byte_sequence().decode("utf-8", errors="replace")
        if ch == ':':
            self.pos -= 1
            return self.read_symbol()
        if ch == ';':
            self.pos -= 1
            return self.read_symbol()
        if ch == '[':
            count = self.read_long()
            arr: list[Any] = []
            self.objects.append(arr)
            for _ in range(count):
                arr.append(self.read_value())
            return arr
        if ch == '{':
            count = self.read_long()
            table: dict[Any, Any] = {}
            self.objects.append(table)
            for _ in range(count):
                key = self.read_value()
                table[to_hashable(key)] = self.read_value()
            return table
        if ch == 'o':
            class_name = self.read_symbol()
            count = self.read_long()
            ivars: dict[str, Any] = {}
            obj = RubyObject(class_name, ivars)
            self.objects.append(obj)
            for _ in range(count):
                name = self.read_symbol()
                ivars[name] = self.read_value()
            return obj
        if ch == 'c':
            return self.read_symbol()
        if ch == 'u':
            class_name = self.read_symbol()
            payload = self.read_byte_sequence()
            obj = RubyObject(class_name, {"data": payload})
            self.objects.append(obj)
            return obj
        if ch == 'U':
            self.read_symbol()
            return self.read_value()
        if ch == 'C':
            self.read_symbol()
            return self.read_value()
        if ch == 'I':
            wrapped = self.read_value()
            count = self.read_long()
            for _ in range(count):
                name = self.read_symbol()
                value = self.read_value()
                if isinstance(wrapped, RubyObject):
                    wrapped.ivars[name] = value
            return wrapped
        if ch == '@':
            index = self.read_long()
            if index >= len(self.objects):
                raise MarshalError(f"bad object link {index}")
            return self.objects[index]
        if ch == 'S':
            self.read_symbol()
            count = self.read_long()
            for _ in range(count):
                self.read_symbol()
                self.read_value()
            return None
        if ch == 'e':
            self.read_value()
            self.read_symbol()
            return self.read_value()
        raise MarshalError(f"unsupported marshal tag {tag!r} ({ch!r}) at {self.pos - 1}")


def load_rvdata(path: Path) -> Any:
    data = path.read_bytes()
    if data[:2] != b'\x04\x08':
        raise MarshalError(f"{path.name}: unsupported marshal version")
    reader = MarshalReader(data[2:])
    return reader.read_value()


def main() -> int:
    if len(sys.argv) < 3:
        print("usage: rvdata_parser.py <source Data dir> <output json dir>")
        return 2
    source = Path(sys.argv[1])
    output = Path(sys.argv[2])
    output.mkdir(parents=True, exist_ok=True)
    wanted = ["Actors", "Skills", "Items", "Weapons", "Armors", "Enemies", "States", "Troops", "Classes"]
    for name in wanted:
        path = source / f"{name}.rvdata"
        if not path.exists():
            continue
        try:
            plain = to_plain(load_rvdata(path))
            text = json.dumps(plain, ensure_ascii=False, indent=1)
            (output / f"{name.lower()}.json").write_text(text, encoding="utf-8")
            print(f"{name}: ok ({len(text)} bytes)")
        except Exception as exc:  # noqa: BLE001 - report per-file failures
            print(f"{name}: FAILED - {exc}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
