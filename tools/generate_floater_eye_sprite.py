"""Generate the 2D solid-green silhouette sprite for Floater Eyes (D-129).

Produces a crisp RGBA PNG (`assets/generated/survival/floater_eye.png`) whose
outer silhouette unmistakably reads as a floating demonic eye (orbital upper and
lower eyelid arcs + central iris orb + radiating lashes + trailing optic-nerve
tendrils) filled in solid green, with all transparent gaps open to the exterior
so PlayableHud.make_silhouette() preserves every cutout cleanly.

Run: python tools/generate_floater_eye_sprite.py
"""

from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "generated" / "survival" / "floater_eye.png"

# Crisp vibrant dungeon-support green matching EXODUS HUD SP/emerald register.
GREEN = (54, 206, 114, 255)


def _thick_curve(draw: ImageDraw.ImageDraw, pts: list[tuple[float, float]], widths: list[float]) -> None:
    for i in range(len(pts) - 1):
        x0, y0 = pts[i]
        x1, y1 = pts[i + 1]
        w0 = widths[i]
        w1 = widths[i + 1]
        steps = max(4, int(math.hypot(x1 - x0, y1 - y0) * 1.5))
        for s in range(steps + 1):
            t = s / steps
            x = x0 + (x1 - x0) * t
            y = y0 + (y1 - y0) * t
            r = (w0 + (w1 - w0) * t) * 0.5
            draw.ellipse((x - r, y - r, x + r, y + r), fill=GREEN)


def build_floater_eye(size: int = 128) -> Image.Image:
    # Draw at 2x and downsample with NEAREST/BOX threshold for crisp silhouette edges.
    s = size * 2
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    cx = s * 0.5
    cy = s * 0.39

    # 1. Central floating iris / pupil orb (detached from outer eyelid arcs so the
    #    open eye silhouette stays transparent even after flood-fill make_silhouette).
    orb_rx = 26.0
    orb_ry = 28.0
    d.ellipse((cx - orb_rx, cy - orb_ry, cx + orb_rx, cy + orb_ry), fill=GREEN)

    # 2. Upper eyelid arc (stylized almond arch, open at left & right tips).
    upper_pts: list[tuple[float, float]] = []
    upper_w: list[float] = []
    n = 32
    for i in range(n + 1):
        u = -1.0 + 2.0 * (i / n)  # -1..1
        x = cx + u * 86.0
        arch = math.cos(u * math.pi * 0.5)
        y = cy - 10.0 - arch * 44.0 + (u * u) * 6.0
        w = 4.5 + arch * 13.0
        upper_pts.append((x, y))
        upper_w.append(w)
    _thick_curve(d, upper_pts, upper_w)

    # 3. Lower eyelid arc (slightly softer arch, leaves clear gaps at both corners).
    lower_pts: list[tuple[float, float]] = []
    lower_w: list[float] = []
    for i in range(n + 1):
        u = -1.0 + 2.0 * (i / n)
        x = cx + u * 78.0
        arch = math.cos(u * math.pi * 0.5)
        y = cy + 12.0 + arch * 38.0 - (u * u) * 4.0
        w = 4.0 + arch * 11.0
        lower_pts.append((x, y))
        lower_w.append(w)
    _thick_curve(d, lower_pts, lower_w)

    # 4. Upper lashes / ocular spines radiating upward from the upper eyelid.
    lash_specs = [
        (-0.72, -18.0, -20.0, 7.0),
        (-0.42, -10.0, -28.0, 8.5),
        (-0.14, -3.0, -32.0, 9.0),
        (0.14, 3.0, -32.0, 9.0),
        (0.42, 10.0, -28.0, 8.5),
        (0.72, 18.0, -20.0, 7.0),
    ]
    for u, dx, dy, base_w in lash_specs:
        arch = math.cos(u * math.pi * 0.5)
        bx = cx + u * 86.0
        by = cy - 12.0 - arch * 44.0 + (u * u) * 6.0
        mx = bx + dx * 0.55
        my = by + dy * 0.6
        tx = bx + dx
        ty = by + dy
        _thick_curve(d, [(bx, by), (mx, my), (tx, ty)], [base_w, base_w * 0.5, 2.0])

    # 5. Small wing-like side fins / ciliary wisps near the eye corners (floating feel).
    for sign in (-1.0, 1.0):
        bx = cx + sign * 84.0
        by = cy - 2.0
        _thick_curve(
            d,
            [(bx, by), (bx + sign * 14.0, by - 8.0), (bx + sign * 24.0, by - 14.0)],
            [7.5, 5.0, 2.0],
        )
        _thick_curve(
            d,
            [(bx - sign * 4.0, by + 9.0), (bx + sign * 10.0, by + 13.0), (bx + sign * 18.0, by + 18.0)],
            [6.0, 4.0, 1.8],
        )

    # 6. Trailing optic-nerve tendrils dangling from the lower eyelid (floating silhouette).
    tendrils = [
        # Central main optic stalk (sinuous S-curve)
        (
            [
                (cx, cy + 50.0),
                (cx - 5.0, cy + 78.0),
                (cx + 8.0, cy + 106.0),
                (cx - 4.0, cy + 132.0),
                (cx + 2.0, cy + 146.0),
            ],
            [13.0, 9.5, 7.0, 4.5, 2.2],
        ),
        # Left tendril
        (
            [
                (cx - 26.0, cy + 45.0),
                (cx - 34.0, cy + 72.0),
                (cx - 24.0, cy + 98.0),
                (cx - 34.0, cy + 122.0),
            ],
            [9.0, 6.5, 4.5, 2.0],
        ),
        # Right tendril
        (
            [
                (cx + 26.0, cy + 45.0),
                (cx + 35.0, cy + 70.0),
                (cx + 25.0, cy + 96.0),
                (cx + 33.0, cy + 120.0),
            ],
            [9.0, 6.5, 4.5, 2.0],
        ),
        # Outer short filaments
        (
            [
                (cx - 50.0, cy + 34.0),
                (cx - 58.0, cy + 56.0),
                (cx - 52.0, cy + 78.0),
            ],
            [6.5, 4.2, 1.8],
        ),
        (
            [
                (cx + 50.0, cy + 34.0),
                (cx + 58.0, cy + 56.0),
                (cx + 52.0, cy + 78.0),
            ],
            [6.5, 4.2, 1.8],
        ),
    ]
    for pts, widths in tendrils:
        _thick_curve(d, pts, widths)

    # Downsample to target size and threshold alpha to binary solid green (zero artifacts).
    small = img.resize((size, size), Image.BILINEAR)
    px = small.load()
    for y in range(size):
        for x in range(size):
            if px[x, y][3] >= 110:
                px[x, y] = GREEN
            else:
                px[x, y] = (0, 0, 0, 0)

    box = small.getbbox()
    if box is None:
        raise RuntimeError("Generated Floater Eye image is empty")
    pad = 4
    box = (
        max(0, box[0] - pad),
        max(0, box[1] - pad),
        min(size, box[2] + pad),
        min(size, box[3] + pad),
    )
    return small.crop(box)


def main() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img = build_floater_eye(128)
    img.save(OUT)
    print(f"GENERATED {OUT} size={img.size}")


if __name__ == "__main__":
    main()
