import base64

names = [
    ("option_a.png", "OPCAO A - minima / cinematografica"),
    ("option_b.png", "OPCAO B - visor"),
    ("option_c.png", "OPCAO C - tatica"),
    ("option_d.png", "OPCAO D - console"),
    ("option_e.png", "OPCAO E - bloco"),
    ("option_f.png", "OPCAO F - foco"),
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
    "<title>Exodus - 6 opcoes visuais</title>"
    "<style>body{margin:0;background:#111;color:#eee;font:14px sans-serif}"
    "header{padding:12px 18px;border-bottom:1px solid #444}"
    ".grid{display:flex;gap:14px;padding:14px;flex-wrap:wrap}"
    "figure{margin:0;background:#1b1b1b;border:1px solid #555;padding:8px}"
    "img{display:block;width:544px;max-width:100%;image-rendering:pixelated}"
    "figcaption{padding:8px 2px 2px;font-weight:bold}</style></head><body>"
    "<header>EXODUS - tres interpretacoes (primeira pessoa | so oponente e fundo "
    "com arte | HUD em codigo)</header><div class='grid'>"
    + "".join(cards)
    + "</div></body></html>"
)

with open("captures/options_review.html", "w", encoding="utf-8") as fh:
    fh.write(html)

print("written")
