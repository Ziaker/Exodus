import base64

names = [
    ("option_a.png", "A - original (minima / cinematografica)"),
    ("option_a2.png", "A2 - minima, comandos na coluna direita"),
    ("option_a3.png", "A3 - minima, numeros grandes e acento vertical"),
    ("option_b.png", "B - original (visor)"),
    ("option_b2.png", "B2 - visor com SP segmentado horizontal"),
    ("option_b3.png", "B3 - visor com dois alvos"),
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
    "<title>Exodus - variacoes A e B</title>"
    "<style>body{margin:0;background:#111;color:#eee;font:14px sans-serif}"
    "header{padding:12px 18px;border-bottom:1px solid #444}"
    ".grid{display:flex;gap:14px;padding:14px;flex-wrap:wrap}"
    "figure{margin:0;background:#1b1b1b;border:1px solid #555;padding:8px}"
    "img{display:block;width:544px;max-width:100%;image-rendering:pixelated}"
    "figcaption{padding:8px 2px 2px;font-weight:bold}</style></head><body>"
    "<header>EXODUS - variacoes da primeira (A) e da segunda (B) opcao</header>"
    "<div class='grid'>" + "".join(cards) + "</div></body></html>"
)

with open("captures/variations_ab.html", "w", encoding="utf-8") as fh:
    fh.write(html)

print("written")
