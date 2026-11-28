# Referência Canônica HTML — VFX Arte Egípcia 2D dos Animais (D-140 · 4/4 Aprovados)

**Decisão:** D-140 · 2026-11-27 (validação visual concluída pelo criador — **4/4 arquétipos aprovados** + obrigatoriedade visual dual **Cartão × Figuras**)  
**Arquivo canônico único:** [`animal_elements_vfx_canon.html`](animal_elements_vfx_canon.html)  
**Documento de estética & implementação:** [`docs/ANIMAL_EGYPTIAN_VFX_STYLE.md`](../../ANIMAL_EGYPTIAN_VFX_STYLE.md)  
**Regras relacionadas:** [`docs/NON_PRAYER_VFX_STYLE.md`](../../NON_PRAYER_VFX_STYLE.md) (D-125 / D-137) · [`docs/PRAYER_VFX_RULE.md`](../../PRAYER_VFX_RULE.md) (D-113) · [`docs/DECISIONS.md`](../../DECISIONS.md) (D-138 / D-140)

> [!IMPORTANT]
> Este diretório contém o arquivo HTML final aprovado pelo criador (`animal_elements_vfx_canon.html`), cobrindo os **4 arquétipos elementais dos Animais** (`AQUA`, `CRYO`, `VENO`/`TOXI`, `LEAF`) em ambos os modos obrigatórios pela **D-140**:
> 1. **Figuras / Sprites (`Inimigos (3)`):** mural/afresco 2D sobre a silhueta do inimigo (`216×148`).
> 2. **Cartões de Aliados (`Aliados — tamanho do cartão`):** composição panorâmica recortada **exatamente ao retângulo do cartão** (`256×52` nos 3 cartões Survival; `status_rect` no Godot), com **`0 px` sobre o Battle Log**.

---

## Tabela de Mapeamento 1:1 (Função HTML → Godot 4)

| # | Elemento | Arquétipo | Função em `animal_elements_vfx_canon.html` | Paleta (`BASE_PALS`) | Duração / Impacto | Adaptação Figuras vs. Cartão (`256×52`) |
|---|---|---|---|---|---|---|
| 1 | **`AQUA`** | **Nile Surge** | `renderAqua()` | `aqua` (`#2e6c8a` / `#143347` / `#c9d7cf` / `#a8693c`) | `2.80 s` · hit `0.85 s` | Figuras: 5 faixas `𓈖` + 2 ânforas (`1.0×`) + 2 peixes (`0.85×`). Cartão: 3 faixas `𓈖` de ponta a ponta + 2 ânforas (`0.56×`) nos cantos + 2 peixes (`0.56×`) cruzando os `256 px`. |
| 2 | **`CRYO`** | **Hail Fangs** | `renderCryo()` | `cryo` (`#5c9bc0` / `#1b3850` / `#eaf6fa` / `#92c4de`) | `2.85 s` · trava `0.82 s` · estilhaço `1.44 s` | Figuras: 7 lanças diagonais + 7 pares de dentes de gelo + 3 glifos 6-pontas + trinca horizontal + 18 cacos. Cartão: 8 lanças + 9 pares de dentes fechando teto/base dos `52 px` + 3 glifos (`11 px`) + trinca nos `256 px` + 16 cacos. |
| 3 | **`VENO` / `TOXI`** | **Uraeus Venom** | `renderVeno()` | `veno` (`#638029` / `#1d260b` / `#cfd696` / `#9c2d35`) | `2.85 s` · bote `0.76 s` | Figuras: 2 cobras Uraeus (`1.0×`) + escorpião (`1.30×`) + 5 colunas de veneno + 4 bolhas octogonais. Cartão: 2 cobras Uraeus (`0.52×`) saindo das bordas esq./dir. dando bote no centro + escorpião (`0.68×`) + 7 colunas + 4 bolhas nos `256×52`. |
| 4 | **`LEAF`** | **Thorn Lash** | `renderLeaf()` | `leaf` (`#265c3a` / `#0f2617` / `#d4c198` / `#8f2e2c`) | `2.80 s` · estalo `0.86 s` | Figuras: 4 chicotes espinhosos (`8.5 px`) em X + trava central + selo de sarça (`34 px`) + 12 folhas-lança horizontais. Cartão: 4 chicotes (`5.5 px`) em X pelas 4 quinas dos `256×52` + trava horizontal + selo (`20 px`) + 10 folhas-lança rasgando de ponta a ponta. |

---

## Invariantes Verificados em `animal_elements_vfx_canon.html`
- **100% 2D chapado:** zero efeitos 3D, zero gradientes radiais/lineares, zero sombra volumétrica, zero neon.
- **Cadência de mural:** animação quantizada em **10 FPS** (`qTime(t, 10)`, com estilhaços/projéteis rápidos em `12 FPS`).
- **Lei do Outline Dourado (D-125):** `#ffd84a` aparece **apenas** quando o toggle `✦ ZAHAV: ON` está ativo; zero dourado no modo normal.
- **Separação Hebraica (D-113):** **zero letras hebraicas** em todas as 4 magias.
- **Verificação headless (Node, 480 frames):** `SMOKE_V2_OK {"frames":480,"drawOps":707854,"nanDetected":0,"allyClips":240}` (100% dos 240 quadros de Aliados recortados exatamente a `280, 298, 256, 52`).
