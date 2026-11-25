"""Generate 35 dark-with-red-rim silhouettes for Survival Mode from local SMT battlers.

Handles both transparent PNGs and opaque RPG Maker VX battlers (baked 2px border +
solid chroma-key background around the demon).
Run: python tools/generate_survival_silhouettes.py
"""

from __future__ import annotations

from collections import deque
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
BATTLERS = ROOT / "assets" / "graphics" / "battlers"
OUT = ROOT / "assets" / "generated" / "survival"
CAPTURES = ROOT / "captures"

DEMONS = [
    ("pixie", "Fairy Pixie.png"),
    ("jack_frost", "Fairy Jack Frost.png"),
    ("pyro_jack", "Fairy Pyro Jack.png"),
    ("cerberus", "Beast Cerberus.png"),
    ("oni", "Brute Oni.png"),
    ("garuda", "Avian Garuda.png"),
    ("anubis", "Avatar Anubis.png"),
    ("chimera", "Avatar Chimera.png"),
    ("andras", "Fallen Andras.png"),
    ("succubus", "Night Succubus.png"),
    ("ganesha", "Yoma Ganesha.png"),
    ("vritra", "Dragon Vritra.png"),
    ("wyvern", "Drake Wyvern.png"),
    ("lich", "Haunt Lich.png"),
    ("matador", "Fiend Matador.png"),
    ("mara", "Tyrant Mara.png"),
    ("loki", "Vile Loki.png"),
    ("zouchouten", "Kishin Zouchouten.png"),
    ("lakshmi", "Megami Lakshmi.png"),
    ("hel", "Reaper Hel.png"),
    ("high_pixie", "Fairy High Pixie.png"),
    ("nekomata", "Beast Nekomata.png"),
    ("shuten_douji", "Brute Shuten-Douji.png"),
    ("phoenix", "Avian Phoenix.png"),
    ("barong", "Avatar Barong.png"),
    ("orobas", "Fallen Orobas.png"),
    ("incubus", "Night Incubus.png"),
    ("quetzalcoatl", "Dragon Quetzalcoatl.png"),
    ("leviathan", "Drake Leviathan.png"),
    ("vampire", "Haunt Vampire.png"),
    ("white_rider", "Fiend White Rider.png"),
    ("beelzebub", "Tyrant Beelzebub.png"),
    ("pazuzu", "Vile Pazuzu.png"),
    ("isis", "Megami Isis.png"),
    ("izanami", "Reaper Izanami.png"),
]


def extract_alpha(src: Image.Image) -> Image.Image:
    """Return a clean binary alpha mask for an SMT battler (transparent or opaque BG)."""
    rgba = src.convert("RGBA")
    w, h = rgba.size
    # Trim baked 2px VX window frame.
    if w > 8 and h > 8:
        rgba = rgba.crop((2, 2, w - 2, h - 2))
        w, h = rgba.size

    a_chan = rgba.getchannel("A")
    px = rgba.load()
    # Only trust raw alpha when the corners themselves are transparent.
    corners = (px[0, 0][3], px[w - 1, 0][3], px[0, h - 1][3], px[w - 1, h - 1][3])
    if sum(1 for c in corners if c < 40) >= 3:
        return a_chan.point(lambda a: 255 if a > 40 else 0)

    # Opaque battler: flood-fill from border pixels matching the corner background color.
    bg = px[0, 0][:3]
    tol = 14

    def is_bg(rgba_px: tuple[int, int, int, int]) -> bool:
        if rgba_px[3] < 40:
            return True
        return (
            abs(rgba_px[0] - bg[0]) <= tol
            and abs(rgba_px[1] - bg[1]) <= tol
            and abs(rgba_px[2] - bg[2]) <= tol
        )

    visited = bytearray(w * h)
    q: deque[tuple[int, int]] = deque()
    for x in range(w):
        for y in (0, h - 1):
            if is_bg(px[x, y]):
                idx = y * w + x
                if not visited[idx]:
                    visited[idx] = 1
                    q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if is_bg(px[x, y]):
                idx = y * w + x
                if not visited[idx]:
                    visited[idx] = 1
                    q.append((x, y))

    while q:
        cx, cy = q.popleft()
        for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
            if 0 <= nx < w and 0 <= ny < h:
                idx = ny * w + nx
                if not visited[idx] and is_bg(px[nx, ny]):
                    visited[idx] = 1
                    q.append((nx, ny))

    alpha = Image.new("L", (w, h), 255)
    alpha.putdata([0 if v else 255 for v in visited])
    return alpha


def build_silhouette(path: Path) -> Image.Image:
    alpha = extract_alpha(Image.open(path))
    box = alpha.getbbox()
    if box is None:
        raise RuntimeError(f"Empty silhouette mask for {path}")
    pad = 4
    w, h = alpha.size
    box = (
        max(0, box[0] - pad),
        max(0, box[1] - pad),
        min(w, box[2] + pad),
        min(h, box[3] + pad),
    )
    alpha = alpha.crop(box)
    grown = alpha.filter(ImageFilter.MaxFilter(5))
    outline = Image.new("L", alpha.size, 0)
    outline.putdata([max(0, g - a) for g, a in zip(grown.getdata(), alpha.getdata())])

    out = Image.new("RGBA", alpha.size, (0, 0, 0, 0))
    body = Image.new("RGBA", alpha.size, (42, 12, 22, 255))
    rim = Image.new("RGBA", alpha.size, (220, 62, 76, 255))
    out.paste(body, (0, 0), alpha)
    out.paste(rim, (0, 0), outline)
    return out


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    CAPTURES.mkdir(parents=True, exist_ok=True)
    generated: list[tuple[str, Image.Image]] = []
    for demon_id, filename in DEMONS:
        src = BATTLERS / filename
        if not src.is_file():
            raise FileNotFoundError(f"Missing SMT battler: {src}")
        img = build_silhouette(src)
        target = OUT / f"{demon_id}.png"
        img.save(target)
        generated.append((demon_id, img))
        print(f"GENERATED {target.name} {img.size}")

    # Contact sheet (5x7) for visual audit.
    cols, rows = 5, 7
    cell_w, cell_h = 180, 190
    sheet = Image.new("RGBA", (cols * cell_w, rows * cell_h), (18, 12, 16, 255))
    draw = ImageDraw.Draw(sheet)
    for idx, (demon_id, img) in enumerate(generated):
        cx = (idx % cols) * cell_w
        cy = (idx // cols) * cell_h
        draw.rectangle((cx + 2, cy + 2, cx + cell_w - 3, cy + cell_h - 3), outline=(90, 45, 55, 255))
        scale = min((cell_w - 16) / img.width, (cell_h - 30) / img.height, 1.0)
        nw, nh = max(1, int(img.width * scale)), max(1, int(img.height * scale))
        resized = img.resize((nw, nh), Image.NEAREST)
        sheet.paste(resized, (cx + (cell_w - nw) // 2, cy + cell_h - 22 - nh), resized)
        draw.text((cx + 8, cy + cell_h - 18), demon_id, fill=(240, 230, 225, 255))
    sheet_path = CAPTURES / "survival_silhouettes_sheet.png"
    sheet.save(sheet_path)
    print(f"CONTACT SHEET {sheet_path}")


if __name__ == "__main__":
    main()
