import base64

names = [
    ("option_v1.png", "V1 - anel de SP ao redor do oponente"),
    ("option_v2.png", "V2 - torres de SP nas laterais"),
    ("option_v3.png", "V3 - faixa superior espessa, oponente deslocado"),
]

cards = []
for filename, label in names:
    with open("captures/" + filename, "rb") as fh:
        data = base64.b64encode(fh.read()).decode()
    cards.append(
        "<figure><img src='data:image/png;base64," + data
        + "'><figcaption>" + label + "</figcaption></figure>"
    )

html = (
    "<!doctype html><html><head><meta charset='utf-8'>"
    "<title>Exodus - interpretacoes diferentes</title>"
    "<style>body{margin:0;background:#111;color:#eee;font:14px sans-serif}"
    "header{padding:12px 18px;border-bottom:1px solid #444}"
    ".grid{display:flex;gap:14px;padding:14px;flex-wrap:wrap}"
    "figure{margin:0;background:#1b1b1b;border:1px solid #555;padding:8px}"
    "img{display:block;width:544px;max-width:100%;image-rendering:pixelated}"
    "figcaption{padding:8px 2px 2px;font-weight:bold}</style></head><body>"
    "<header>EXODUS - tres interpretacoes diferentes (referencia usada so como inspiracao)</header>"
    "<div class='grid'>" + "".join(cards) + "</div></body></html>"
)

with open("captures/different_variations.html", "w", encoding="utf-8") as fh:
    fh.write(html)

print("written")
