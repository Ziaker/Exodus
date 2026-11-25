"""Generate the overworld's original textures (battle stage D palette).

Walls are craggy mountain rock, not masonry. The floor is continuous scorched
earth, not tiled slabs. Battle assets are untouched.
Run: python tools/generate_dungeon_art.py
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / "assets" / "generated" / "dungeon"
OUT.mkdir(parents=True, exist_ok=True)

WINE = (92, 28, 43)
DUSK = (67, 26, 38)
BRONZE = (97, 68, 46)
EMBER = (174, 86, 93)
RED = (187, 61, 72)
INK = (53, 25, 36)
BLACK = (8, 7, 10)
BONE = (214, 181, 159)
EARTH = (58, 34, 30)
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
RNG = random.Random(0x45584F44)


def rock_noise(x: float, y: float) -> float:
    return (
        math.sin(x * 0.031 + y * 0.017) * 0.42
        + math.sin(x * 0.093 - y * 0.061 + 1.7) * 0.27
        + math.sin((x + y) * 0.047 - 0.8) * 0.18
        + math.sin(x * 0.21 + math.sin(y * 0.025) * 2.4) * 0.13
    )


def wall() -> None:
    """Mountain cliff: striated crags and glowing faults, zero straight masonry."""
    img = Image.new("RGB", (256, 256), INK)
    px = img.load()
    for y in range(256):
        for x in range(256):
            n = rock_noise(x, y)
            shade = max(0.0, min(1.0, 0.5 + n * 0.9))
            base = tuple(
                int(BLACK[i] + (BRONZE[i] - BLACK[i]) * shade)
                for i in range(3)
            )
            # Cold wine shadows in the deep crevices.
            if n < -0.35:
                base = tuple(int(base[i] * 0.55 + WINE[i] * 0.45) for i in range(3))
            grain = (RNG.random() - 0.5) * 13
            px[x, y] = tuple(max(0, min(255, int(c + grain))) for c in base)
    d = ImageDraw.Draw(img, "RGBA")
    # Fault lines: jagged, mostly vertical, with a dim red halo.
    for _ in range(22):
        x = RNG.randrange(8, 248)
        y = RNG.randrange(0, 200)
        points = []
        for _k in range(6):
            points.append((x, y))
            x += RNG.randrange(-5, 6)
            y += RNG.randrange(10, 24)
        d.line(points, fill=(*RED, 55), width=4, joint="curve")
        d.line(points, fill=(*EMBER, 115), width=1, joint="curve")
    img.save(OUT / "wall.png")


def floor() -> None:
    """Continuous scorched ground: fine grain and cracks, no tile seams."""
    img = Image.new("RGB", (544, 233), EARTH)
    px = img.load()
    for y in range(233):
        for x in range(544):
            n = (
                math.sin(x * 0.021 + y * 0.013) * 0.45
                + math.sin(x * 0.067 - y * 0.041) * 0.3
                + math.sin((x - y) * 0.011) * 0.25
            )
            shade = max(0.0, min(1.0, 0.55 + n * 0.8))
            base = tuple(int(EARTH[i] + (DUSK[i] - EARTH[i]) * shade) for i in range(3))
            grain = (RNG.random() - 0.5) * 12
            px[x, y] = tuple(max(0, min(255, int(c + grain))) for c in base)
    d = ImageDraw.Draw(img, "RGBA")
    for _ in range(70):
        x, y = RNG.randrange(544), RNG.randrange(233)
        length = RNG.randrange(14, 70)
        pts = [(x, y)]
        for _k in range(4):
            x += RNG.randrange(-8, 9)
            y += RNG.randrange(2, 9)
            pts.append((x, y))
        d.line(pts, fill=(*RED, RNG.randrange(50, 120)), width=1, joint="curve")
    for _ in range(260):
        px[RNG.randrange(544), RNG.randrange(233)] = BONE
    img.save(OUT / "floor.png")


def backdrop() -> None:
    sky = Image.new("RGB", (544, 166))
    sp = sky.load()
    palette = [WINE, DUSK, BRONZE, EMBER, RED, INK]
    for y in range(166):
        for x in range(544):
            v = (
                math.sin(x * 0.07)
                + math.sin(y * 0.09 - 1.3)
                + math.sin((x + y) * 0.05 + 0.7)
                + math.sin(math.hypot(x - 268, y - 64) * 0.03)
            )
            level = (v + 4.0) / 8.0 * 6.0
            idx = int(level) + (1 if (level % 1.0) * 16.0 > BAYER[y % 4][x % 4] else 0)
            n = (RNG.random() - 0.5) * 8
            sp[x, y] = tuple(max(0, min(255, int(c * 0.62 + n))) for c in palette[idx % 6])
    sd = ImageDraw.Draw(sky, "RGBA")
    sd.ellipse((306, 14, 402, 110), fill=(*EMBER, 120), outline=(*RED, 170), width=2)
    # Two stacked ridges, like the approved battle skyline.
    for base_y, color in ((126, (*INK, 190)), (142, (*DUSK, 255))):
        ridge, points = base_y, [(0, 166)]
        for x in range(0, 552, 8):
            ridge = max(base_y - 26, min(base_y + 16, ridge + RNG.randrange(-10, 11)))
            points.append((x, ridge))
        points.append((544, 166))
        sd.polygon(points, fill=color)
    ground = Image.open(OUT / "floor.png").convert("RGB")
    gp = ground.load()
    for y in range(233):
        fade = max(0.08, 1.0 - y / 260.0)
        for x in range(544):
            gp[x, y] = tuple(int(c * fade) for c in gp[x, y])
    out = Image.new("RGB", (544, 416), BLACK)
    out.paste(sky, (0, 0))
    out.paste(Image.new("RGB", (544, 17), BLACK), (0, 166))
    out.paste(ground, (0, 183))
    out.save(OUT / "backdrop.png")


def floor_tile() -> None:
    """Tileable scorched slab with a faint square border, for the 3D floor mesh."""
    s = 64
    img = Image.new("RGB", (s, s), EARTH)
    px = img.load()
    for y in range(s):
        for x in range(s):
            n = (
                math.sin(x * 0.19 + y * 0.11) * 0.4
                + math.sin(x * 0.41 - y * 0.29) * 0.25
                + math.sin((x + y) * 0.07) * 0.35
            )
            shade = max(0.0, min(1.0, 0.5 + n * 0.8))
            base = tuple(int(EARTH[i] + (DUSK[i] - EARTH[i]) * shade) for i in range(3))
            grain = (RNG.random() - 0.5) * 10
            px[x, y] = tuple(max(0, min(255, int(c + grain))) for c in base)
    d = ImageDraw.Draw(img, "RGBA")
    # Square marking: dark groove plus a dim red inner edge.
    d.rectangle((1, 1, s - 2, s - 2), outline=(*BLACK, 210), width=2)
    d.rectangle((4, 4, s - 5, s - 5), outline=(*RED, 55), width=1)
    d.line((s // 2, 4, s // 2, s - 5), fill=(*BLACK, 45))
    d.line((4, s // 2, s - 5, s // 2), fill=(*BLACK, 45))
    img.save(OUT / "floor_tile.png")


def enemy_silhouettes() -> None:
    """Silhouettes extracted from the real SMT battlers (shape preserved, no art/border)."""
    from PIL import ImageFilter

    sources = [
        ("enemy_stalker.png", OUT.parents[1] / "graphics/battle_sprites/Avatar Anubis.png"),
        ("enemy_hound.png", OUT.parents[1] / "graphics/battle_sprites/Avatar Chimera.png"),
        ("enemy_wraith.png", OUT.parents[1] / "graphics/battlers/Avian Garuda.png"),
    ]
    for name, path in sources:
        src = Image.open(path).convert("RGBA")
        # Os PNG do VX vêm com moldura opaca: remove antes de extrair a máscara.
        a0 = src.getchannel("A")
        w, h = src.size
        left = 0
        while left < w and all(a0.getpixel((left, y)) > 0 for y in range(h)):
            left += 1
        right = w - 1
        while right > left and all(a0.getpixel((right, y)) > 0 for y in range(h)):
            right -= 1
        top = 0
        while top < h and all(a0.getpixel((x, top)) > 0 for x in range(w)):
            top += 1
        bottom = h - 1
        while bottom > top and all(a0.getpixel((x, bottom)) > 0 for x in range(w)):
            bottom -= 1
        src = src.crop((left, top, right + 1, bottom + 1))
        alpha = src.getchannel("A").point(lambda a: 255 if a > 40 else 0)
        box = alpha.getbbox()
        if box is None:
            continue
        pad = 4
        box = (max(0, box[0] - pad), max(0, box[1] - pad),
               min(src.width, box[2] + pad), min(src.height, box[3] + pad))
        alpha = alpha.crop(box)
        grown = alpha.filter(ImageFilter.MaxFilter(5))
        # Contorno = máscara dilatada menos a original.
        outline = Image.new("L", alpha.size, 0)
        outline.putdata([max(0, g - a) for g, a in zip(grown.getdata(), alpha.getdata())])
        out = Image.new("RGBA", alpha.size, (0, 0, 0, 0))
        body = Image.new("RGBA", alpha.size, (42, 12, 22, 255))
        rim = Image.new("RGBA", alpha.size, (220, 62, 76, 255))
        out.paste(body, (0, 0), alpha)
        out.paste(rim, (0, 0), outline)
        out.save(OUT / name)


if __name__ == "__main__":
    wall()
    floor()
    floor_tile()
    enemy_silhouettes()
    backdrop()
    for path in sorted(OUT.glob("*.png")):
        print("GENERATED", path.name, Image.open(path).size)
