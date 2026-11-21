#!/usr/bin/env python3
"""Populate assets/ from a locally available placeholder source.

The source is a checkout of the RPG Maker VX Ace fangame, or any directory with
the same layout. No files are downloaded and no third-party asset is committed.
Usage: python tools/setup_placeholder_assets.py [SOURCE_ROOT] [--force]
"""

import argparse
import json
import os
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "assets" / "ASSET_MANIFEST.json"


def load_manifest() -> dict:
    with MANIFEST.open(encoding="utf-8") as handle:
        return json.load(handle)


def choose_source(manifest: dict, cli_source: str | None) -> Path:
    candidate = cli_source or os.environ.get(manifest["source_env"])
    source = Path(candidate) if candidate else ROOT / manifest["default_source"]
    return source if source.is_absolute() else ROOT / source


def copy_tree(source: Path, destination: Path, force: bool) -> int:
    if not source.is_dir():
        print(f"  skip (missing): {source}")
        return 0
    copied = 0
    for item in sorted(source.iterdir()):
        if not item.is_file() or item.suffix == ".import":
            continue
        target = destination / item.name
        if target.exists() and not force:
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(item, target)
        copied += 1
    return copied


def copy_derived(source: Path, entry: dict, force: bool) -> bool:
    origin = source / entry["source"]
    target = ROOT / entry["dest"]
    if not origin.is_file():
        print(f"  derived source missing: {origin}")
        return False
    if target.exists() and not force:
        return True
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(origin, target)
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", nargs="?", help="source root directory")
    parser.add_argument("--force", action="store_true", help="overwrite existing files")
    args = parser.parse_args()

    manifest = load_manifest()
    source = choose_source(manifest, args.source)
    if not source.is_dir():
        print(f"ERROR: source root not found: {source}")
        return 1
    print(f"Source: {source}")

    total = 0
    for entry in manifest["mappings"]:
        total += copy_tree(source / entry["source"], ROOT / entry["dest"], args.force)
    for entry in manifest["derived"]:
        copy_derived(source, entry, args.force)
    print(f"Copied {total} placeholder file(s).")

    missing = [p for p in manifest["required"] if not (ROOT / p).is_file()]
    if missing:
        print("Missing required placeholder files:")
        for path in missing:
            print(f"  {path}")
        print("Provide them in the source root (derived sprites go in _prepared/battle_sprites/).")
        return 1
    print("All required placeholder files are present.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
