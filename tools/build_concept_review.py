import base64

with open("captures/concept_exodus.png", "rb") as fh:
    data = base64.b64encode(fh.read()).decode()

html = (
    "<!doctype html><html><head><meta charset='utf-8'>"
    "<title>Exodus - proposta unica</title>"
    "<style>body{margin:0;background:#111;color:#eee;font:14px sans-serif}"
    "header{padding:12px 18px;border-bottom:1px solid #444}"
    "figure{margin:14px;display:inline-block;background:#1b1b1b;border:1px solid #555;padding:8px}"
    "img{display:block;width:544px;max-width:100%;image-rendering:pixelated}"
    "figcaption{padding:8px 2px 2px;font-weight:bold}</style></head><body>"
    "<header>EXODUS - proposta unica: arte original, premissa canonica e HUD dos sistemas</header>"
    "<figure><img src='data:image/png;base64," + data
    + "'><figcaption>Conceito - Fallen vsGenetic Foe</figcaption></figure>"
    "</body></html>"
)

with open("captures/options_review.html", "w", encoding="utf-8") as fh:
    fh.write(html)

print("written")
