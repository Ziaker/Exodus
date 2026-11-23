"""Extract local RGSS animation frames/timings, without editing source images.

The fangame Sprite_Base uses four 60 Hz updates per animation frame (15 fps).
RTP-only sheets are reported; the heal profile retains original flash timings only.
"""
import json
import shutil
import struct
from pathlib import Path

from rvdata_parser import load_rvdata

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Shin Megami Tensei VX The Genesis/Shin Megami Tensei The Genesis"
SELECTED = {"claw": 120, "bite": 121, "absorb": 68, "target": 70, "heal_flash": 61}
SOUNDS = ["se_attack", "se_hit01", "se_karn", "se_cursor_ng", "se_cursor_ok", "se_warning", "se_comp", "se_dead01", "105-Heal01", "079-Monster01"]


def extract():
    database = load_rvdata(SOURCE / "Data/Animations.rvdata")
    result = {"fps": 15, "cell_size": 192, "animation_count": len(database) - 1, "profiles": {}, "missing_sheets": [], "restored_sounds": []}
    for name, index in SELECTED.items():
        data = database[index].ivars
        sheets = [data["@animation1_name"], data["@animation2_name"]]
        for sheet in sheets:
            if sheet and not (ROOT / "assets/graphics/animations" / (sheet + ".png")).exists():
                result["missing_sheets"].append(sheet)
        frames = []
        for raw_frame in data["@frames"]:
            raw = raw_frame.ivars["@cell_data"].ivars["data"]
            _, width, height, depth, count = struct.unpack("<5I", raw[:20])
            assert height == 8 and depth == 1 and count == width * height
            values = struct.unpack("<" + "h" * count, raw[20:])
            cells = []
            for cell in range(width):
                fields = [values[field * width + cell] for field in range(8)]
                if fields[0] >= 0 and name != "heal_flash":
                    cells.append(fields)
            frames.append(cells)
        timings = []
        for raw_timing in data["@timings"]:
            t = raw_timing.ivars
            se = t["@se"].ivars
            timings.append({"frame": t["@frame"], "scope": t["@flash_scope"], "duration": t["@flash_duration"], "color": list(struct.unpack("<4d", t["@flash_color"].ivars["data"])), "sound": se["@name"], "volume": se["@volume"], "pitch": se["@pitch"]})
        result["profiles"][name] = {"source_id": index, "sheets": ["", ""] if name == "heal_flash" else sheets, "position": data["@position"], "frames": frames, "timings": timings}
    for sound in SOUNDS:
        source = SOURCE / "Audio/SE" / (sound + ".ogg")
        destination = ROOT / "assets/audio/se" / source.name
        assert source.read_bytes()[:4] == b"OggS", source
        if not destination.exists() or destination.stat().st_size <= 1:
            shutil.copyfile(source, destination)
        assert destination.read_bytes()[:4] == b"OggS", destination
        result["restored_sounds"].append(sound)
    output = ROOT / "assets/data/smt_combat_fx.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"SMT_FX_EXTRACTED: {result['animation_count']} definitions; {len(SELECTED)} profiles; {len(SOUNDS)} valid sounds; missing sheets: {result['missing_sheets']}")


if __name__ == "__main__":
    extract()
