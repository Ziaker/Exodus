# Estilo Artístico, Catálogo & Implementação — Magias Egípcias 2D dos Animais (D-140 / D-141)

**Decisões:** D-140 · D-141 · 2026-11-27/28 (decisões e aprovação visual do criador — **4/4 visuais, nomenclatura egípcia e 4 mecânicas base aprovadas**)  
**Índice canônico:** [`docs/DECISIONS.md`](DECISIONS.md)  
**Estéticas irmãs da Tríade EXODUS:**
- **Rezas / Anjos (D-113):** [`docs/PRAYER_VFX_RULE.md`](PRAYER_VFX_RULE.md) — tipografia 100% hebraica.
- **Ataques Não-Reza Demoníacos / Físicos / Abissais (D-125 / D-131 / D-139):** [`docs/NON_PRAYER_VFX_STYLE.md`](NON_PRAYER_VFX_STYLE.md) — rabisco anatômico em boil 12 FPS + Moiré febril.
- **Magias dos Animais (D-140 — este documento):** **Arte Egípcia Animada 100% 2D** (`AQUA`, `CRYO`, `VENO`/`TOXI`, `LEAF`).

**Referência HTML canônica aprovada:** [`docs/vfx_refs/animal_egyptian/animal_elements_vfx_canon.html`](vfx_refs/animal_egyptian/animal_elements_vfx_canon.html) ([`README`](vfx_refs/animal_egyptian/README.md))  
**Delegação elemental (D-138):** [`docs/MAESTO_UNIVERSE_AUDIT.md`](MAESTO_UNIVERSE_AUDIT.md) (§4.5 e §7)  
**Lore egípcia / Daemas Tier 4 (D-127):** [`docs/ART_DIRECTION.md`](ART_DIRECTION.md) (§1)

---

## 1. Pilar Estético Unificado (Lei Canônica — D-140)

> **Todas as magias ligadas aos elementos dos Animais (`AQUA`, `CRYO`, `VENO`/`TOXI` e `LEAF`) utilizam uma estética completamente 2D inspirada em artes egípcias animadas: preenchimento mineral chapado (flat color), contorno firme em tinta negra (`#0a0608`), perfis ortográficos sem perspectiva 3D, frisos/registros horizontais opcionais e animação seca em 10 FPS de mural/papiro ganhando vida.**

### 1.1 Tríade Visual Canônica de EXODUS
| Linhagem | Decisão | Assinatura Visual Exclusiva | Uso no Jogo |
|---|---|---|---|
| **Rezas / Anjos** | `D-113` | Tipografia 100% hebraica (sem ilustrações figurativas) | `PrayerBook` / Yoch / Anjos |
| **Físicos, Demônios e Abissais** | `D-125`, `D-131`, `D-139` | Rabisco anatômico em boil 12 FPS + Campo Moiré `5×5 px` + warp febril | Demônios, ataques físicos, fogo/abismo/status arcanos (`SkillGrotesqueFX`) |
| **Magias dos Animais** | **`D-140`** | **Arte Egípcia Animada 100% 2D** (perfis chapados, pigmento mineral, 10 FPS, zero 3D/Moiré) | Animais (`AQUA`, `CRYO`, `VENO`/`TOXI`, `LEAF`) e magias correlatas (`AnimalEgyptianFX`) |

### 1.2 Regras Invioláveis da Estética Egípcia 2D
1. **100% 2D Absoluto (Zero 3D):**
   - **Proibido** qualquer efeito 3D, perspectiva forçada, gradiente radial/linear, brilho neon, bloom plástico, sombra volumétrica ou desfoque (blur).
   - Toda forma usa **preenchimento plano sólido** (`flat_poly`), dividido no máximo em 2 facetas planas de cor mineral (ex.: face clara e face escura em dentes/lanças de gelo) separadas por aresta seca.
   - A Lei da Frontalidade egípcia prevalece: animais e objetos em **perfil chapado** (peixes, ânforas, cobras Uraeus) com **olho frontal plano** (`draw_egyptian_eye`), ou **vista superior simétrica chapada** (escorpião de Serqet, selos geométricos).
2. **Contorno de Tinta e Cadência de Mural (10 FPS):**
   - Toda forma principal recebe contorno firme em tinta negra **`#0a0608`** (`1.5–2.2 px` reais em `816×624`, `antialiased = false`, `lineJoin = miter` / cantos vivos).
   - O tempo da animação é quantizado em **10 FPS** (`qt = floor(t * 10.0) / 10.0`), com estilhaços ou folhas-lança velozes em até **12 FPS**. Movimentos ocorrem em poses secas (snap poses de 2–3 quadros, ex.: bote das Uraeus, estalo da sarça, trinca do gelo), nunca interpolação mole estilo flash-tween.
3. **Lei do Outline Dourado (`ZAHAV` exclusivo — D-125):**
   - O dourado vivo **`#ffd84a`** é **exclusivo** de versões `ZAHAV`.
   - Magias normais **NUNCA** usam `#ffd84a`; tons claros de papiro/areia usam ocre/calcário fosco (`#d4c198`, `#c9d7cf`, `#cfd696`).
4. **Separação Hebraica (D-113):**
   - **ZERO letras hebraicas** nas magias dos Animais. Glifos permitidos são exclusivamente geométricos/egípcios (zigue-zague do Nilo `𓈖`, estrelas de 5/6 pontas, escorpião, olho kohl, bordas de blocos).
5. **Zero Afinidade Elemental (D-119 / D-138):**
   - Nenhuma skill desta família introduz campo `affinity`, multiplicador elemental ou Press Turn. O caráter de cada elemento nasce apenas da **estética visual** e da **mecânica tática** da skill.
6. **Nomenclatura Canônica em Egípcio Antigo (D-141):**
   - Todas as magias da raça dos Animais são nomeadas com raízes reais do **Egípcio Antigo** em transliteração limpa e pronunciável, fechando a tríade linguística de EXODUS (**Rezas = Hebraico `D-113`/`D-116` · Demônios = Inglês/Maesto · Animais = Egípcio Antigo `D-141`**).

---

## 2. Obrigação Canônica Dual — Funcionamento Visual em Cartão E Figuras (D-140)

> [!IMPORTANT]
> **OBRIGAÇÃO PERMANENTE PARA TODOS OS AGENTES (registrada em `AGENTS.md` obrigação 13 e `D-140`):**
> **Todo próximo VFX e todo protótipo HTML de ataque/magia DEVE funcionar visualmente em AMBOS os contextos — sobre figuras/sprites (inimigos) E sobre cartões de aliados (3 cartões do Survival e 1–2 cartões da campanha).**

### 2.1 Diferença de Enquadramento entre Famílias (D-137 vs. D-140)
| Família VFX | Alvo: Figuras / Sprites (Inimigos) | Alvo: Cartões de Aliados (`status_rect`) |
|---|---|---|
| **Grotesco / Rabisco (`D-125` / `D-137`)** | Sobre o sprite do inimigo em escala `k = sprite_h / 100`. | Diretamente sobre o cartão do aliado **no mesmo tamanho** usado em inimigos, **sem recorte ao cartão** (marcas persistentes fora do Battle Log). |
| **Arte Egípcia 2D (`D-140` — Animais)** | Mural/afresco 2D sobre o retângulo da figura inimiga (`~216×148` em escala de referência `816×624`, centrado no sprite). | **Exatamente no tamanho e recorte do cartão do aliado (`card_rect`, ex.: `256×52` nos 3 cartões do Survival)**, funcionando como um **friso horizontal egípcio** contido 100% dentro do cartão (**`0 px` sobre o Battle Log**). |

### 2.2 Regras Obrigatórias para o Modo Cartão (`is_ally == true`) na Estética Egípcia 2D
Qualquer nova magia egípcia 2D (no HTML de protótipo e no motor Godot 4) **não pode** simplesmente esmagar/esticar o efeito vertical de inimigo dentro do cartão. Ela **DEVE** cumprir os 5 critérios abaixo:
1. **Recorte estrito ao cartão (`card_rect`):** toda a renderização (cartucho, ondas, dentes de gelo, cobras, chicotes, cacos, folhas) respeita o retângulo `card_rect` do aliado atingido (acompanhando o shake horizontal do cartão). Apenas o número de dano padrão (`DamageLayer`, `z_index = 100`) flutua acima da borda do cartão.
2. **Composição panorâmica dedicada:** o layout aproveita a largura do cartão (`w > h`, seja nos 3 cartões estreitos do Survival ou nos 1–2 cartões largos da campanha):
   - Elementos que entram pelos flancos (`Uraeus`, `Ânforas`, `Chicotes`, `Peixes`, `Folhas-Lâmina`) ancoram-se nas bordas esquerda (`card.position.x`) e direita (`card.end.x`).
   - Elementos verticais (`Ondas do Nilo`, `Dentes de Gelo`, `Colunas de Veneno`) reduzem a altura e multiplicam repetições horizontais para preencher toda a largura `card.size.x` sem distorcer a proporção 1:1 das figuras.
3. **Cartucho / Friso de borda reduzido:** no cartão, a borda geométrica egípcia cai de `7 px` (inimigo) para `4 px` (cartão), com preenchimento `pal.stone` translúcido (`alpha = 0.68`) para que o nome, `HP` e `EN`/`PP` do herói continuem reconhecíveis sob a animação.
4. **Zero invasão do Battle Log:** como o efeito fica 100% dentro de `card_rect`, ele nunca cobre o Battle Log (`y = 450..538` em `816×624`).
5. **Seletor obrigatório no protótipo HTML:** todo protótipo HTML futuro da estética egípcia 2D DEVE expor seletor direto `Aliados (tamanho do cartão)` ↔ `Inimigos (3)` + toggle `☥ Cartucho: ON/OFF` + toggle `✦ ZAHAV: ON/OFF`.

---

## 3. Paletas Minerais Canônicas Exatas (D-140)

Constantes globais compartilhadas:
- `INK = Color("0a0608")` (contorno principal de tinta negra)
- `PAPYRUS = Color("d4c198")` (flash de inversão/impacto seco e texto/detalhe claro)
- `ZAHAV_GOLD = Color("ffd84a")` (**exclusivo** quando `is_zahav == true`, substituindo `stroke_hi` e adicionando filete dourado às bordas do cartucho e silhuetas principais)

| Família | `main` (pigmento central) | `dark` (sombra plana) | `light` (crista / destaque normal) | `accent` (detalhe secundário) | `stone` (fundo do cartucho) |
|---|---|---|---|---|---|
| **`aqua`** (`AQUA`) | `#2e6c8a` *(azul egípcio)* | `#143347` *(lápis-lazúli)* | `#c9d7cf` *(espuma calcária)* | `#a8693c` *(terracota ânfora)* | `#1b1512` |
| **`cryo`** (`CRYO`) | `#5c9bc0` *(gelo faience)* | `#1b3850` *(sombra glacial)* | `#eaf6fa` *(branco-gelo)* | `#92c4de` *(faceta gelo)* | `#101b24` |
| **`veno`** (`VENO`/`TOXI`) | `#638029` *(malaquita biliar)* | `#1d260b` *(piche de cobra)* | `#cfd696` *(papiro-peçonha)* | `#9c2d35` *(hematita rubra)* | `#1a180f` |
| **`leaf`** (`LEAF`) | `#265c3a` *(verde-sarça)* | `#0f2617` *(sombra espinheiro)* | `#d4c198` *(fibra papiro)* | `#8f2e2c` *(espinho rubro)* | `#151710` |

---

## 4. Arquitetura Técnica e Motor Reutilizável no Godot 4

### 4.1 Nó Dedicado: `AnimalEgyptianFX` (`scripts/battle/animal_egyptian_fx.gd`)
Para não inflar nem contaminar o motor de rabisco/Moiré (`SkillGrotesqueFX`), a estética egípcia 2D vive em um nó dedicado irmão:
- **Classe:** `class_name AnimalEgyptianFX extends Node2D`
- **Camada e coordenadas:** criado pelo `PlayableController` como `egyptian_fx`, em `z_index = 50` (mesma camada de `grotesque_fx` e abaixo de `DamageLayer` `z_index = 100`), desenhando em **espaço de design `816×624`** (lógico `544×416` × `1.5`, igual a `SkillGrotesqueFX`).
- **Sem shaders de Moiré nem warp:** **não** instancia `hypnotic_moire.gdshader` nem `target_fever_warp.gdshader` — a estética é 100% desenho vetorial 2D plano (`draw_colored_polygon` + `draw_polyline` + `draw_rect`) com shake horizontal discreto (passos secos, sem deformação elástica).

### 4.2 Solução de Recorte Estrito ao Cartão no Godot 4 (`card_rect` Clipping)
Como `Node2D._draw()` não possui `ctx.clip()` imperativo, o recorte exato ao cartão do aliado (`is_ally == true`) deve ser feito de forma limpa e sem alocação por frame:
- `AnimalEgyptianFX` mantém um nó filho reutilizável `_card_clip: Control` com `clip_contents = true` e `mouse_filter = Control.MOUSE_FILTER_IGNORE`, contendo um filho `_card_drawer: Control` que delega `_draw()` de volta para `AnimalEgyptianFX._draw_active_on_card(_card_drawer)`.
- Quando o alvo é **Inimigo (`is_ally == false`)**: o efeito desenha diretamente em `AnimalEgyptianFX._draw()` sobre `box = enemy_box(enemy_rect)` (com `_card_clip.visible = false`), permitindo que o sprite do inimigo fique entre `draw_back` (cartucho/escorpião/selo, `z_index` abaixo ou `back_layer`) e `draw_front` (ondas, dentes, cobras, chicotes).
  - *Nota de camadas sobre inimigo:* reproduzir exatamente a separação `drawBack` → `Inimigo` → `drawFront` do HTML usando dois filhos leves (`_back_layer` com `z_index` abaixo do sprite inimigo ou coordenado com o HUD, e `_front_layer` em `z_index = 50`).
- Quando o alvo é **Aliado (`is_ally == true`)**: `_card_clip.visible = true`, `_card_clip.position = card_rect.position + Vector2(shake_x, 0)`, `_card_clip.size = card_rect.size` (em coordenadas `816×624`, ou seja, `hud.status_rect(idx)` × `DESIGN_SCALE`), e `_card_drawer` desenha `draw_back` + `draw_front` em coordenadas locais `(0, 0, card_rect.size.x, card_rect.size.y)` — garantindo **recorte pixel-exato ao cartão**, `0 px` sobre o Battle Log e compatibilidade automática com 1, 2 ou 3 cartões!

### 4.3 Catálogo de Primitivas Reutilizáveis (Porte 1:1 do HTML)
Todas as primitivas operam com tempo quantizado `q_time(t, fps := 10.0) -> float` (`floor(t * fps) / fps`):

| Primitiva Godot | Equivalente HTML | Função |
|---|---|---|
| `_flat_poly(canvas, pts, fill, stroke, lw)` | `flatPoly()` | Polígono 2D plano + contorno fechado nítido (`antialiased = false`). |
| `_flat_line(canvas, pts, stroke, lw, close)` | `flatLine()` | Polilinha 2D seca com largura explícita. |
| `_draw_egyptian_border(canvas, rect, pal, is_zahav)` | `drawEgyptianBorder()` | Faixa de blocos minerais alternados (`main / light / accent / dark`) com moldura `#0a0608` (+ filete `#ffd84a` em ZAHAV). |
| `_draw_mural_cartouche(canvas, box, unfold, pal, is_ally, is_zahav)` | `drawMuralCartouche()` | Painel de papiro/pedra desenrolando do centro (`bh = 4 px` no cartão com `alpha = 0.68`; `bh = 7 px` no inimigo com `alpha = 0.96`). Controlado por flag `show_cartouche` (por skill ou tier). |
| `_draw_egyptian_eye(canvas, pos, r, pal, pupil_col)` | `drawEgyptianEye()` | Olho frontal com traço kohl alongado para criaturas de perfil. |
| `_draw_nile_band(canvas, x0, x1, y, amp, tooth, thick, phase, fill, top_col, clip_rect)` | `drawNileBand()` | Faixa serrilhada `𓈖` com período exato `fmod(phase, tooth)` (zero salto de loop). |
| `_draw_egyptian_jar(canvas, pos, dir, tilt, sc, pal, is_zahav)` | `drawEgyptianJar()` | Ânfora de barro de perfil com faixas pintadas. |
| `_draw_egyptian_fish(canvas, pos, sc, dir, pal)` | `drawEgyptianFish()` | Peixe egípcio de perfil com barbatanas terracota, escamas geométricas e olho frontal. |
| `_draw_ice_spear(canvas, pos, len, w, ang, pal, is_zahav)` | `drawIceSpear()` | Lança de gelo bipartida em 2 facetas planas (`light` / `main`). |
| `_draw_ice_fang(canvas, base, w, h, dir_y, pal, is_zahav)` | `drawIceFang()` | Estalactite/estalagmite de 2 facetas planas crescendo do teto ou do chão. |
| `_draw_frost_glyph(canvas, pos, r, pal)` | `drawFrostGlyph()` | Estrela geométrica de geada de 6 pontas com chevrons e losango central. |
| `_draw_uraeus_cobra(canvas, base, dir, sc, reach, strike, pal, is_zahav)` | `drawUraeusCobra()` | Cobra Naja Uraeus de perfil em S rígido, capelo listrado, olho frontal, presa e língua bifurcada rubra no bote. |
| `_draw_scorpion_glyph(canvas, pos, sc, pal)` | `drawScorpionGlyph()` | Escorpião de Serqet em vista superior simétrica com corpo segmentado, pinças e ferrão. |
| `_draw_thorn_whip(canvas, p0, p1, prog, snap, thick, pal, is_zahav)` | `drawThornWhip()` | Fita de sarça angular com espinhos-garra curvos que expandem `1.65×` no estalo (`snap = 1`). |
| `_draw_blade_leaf(canvas, pos, len, w, ang, pal)` | `drawBladeLeaf()` | Folha-lança cortante em formato ponta de flecha. |
| `_draw_briar_crest(canvas, pos, r, pal)` | `drawBriarCrest()` | Selo geométrico de 4 espinhos em cruz no centro do X. |

### 4.4 Calibração de Escala em `816×624` (Atenção ao Risco de Espessura)
- O palco HTML tem `816×360` com cartões Survival `256×52` (próximo aos `~255×66` reais dos 3 cartões Survival em `816×624` no Godot).
- Ao portar para Godot `816×624`, garantir **espessura mínima de linha de `1.5 px` reais** nos contornos `#0a0608` e detalhes internos (como o olho kohl da Uraeus ou chevrons de `draw_frost_glyph`) para manter leitura nítida sem aliasing quebrado.
- Para cartões de **1 ou 2 heróis** (mais largos que `256 px`), derivar `count` de repetições horizontais proporcionalmente a `box.size.x` (ex.: `dentes_gelo = maxi(7, int(round(box.size.x / 28.0)))`, `colunas_veneno` cobrindo `±35%` da largura), preservando a mesma densidade visual.

---

## 5. Catálogo Canônico 1:1 das 4 Magias Base (D-140 + D-141)

Todas as 4 magias genéricas base seguem o padrão enxuto de EXODUS (**1 efeito claro por magia**, escala `Ignoma`, `vfx_style: "egyptian_2d"`, zero campo `affinity`):

| # | Nome Egípcio (Raiz) | Elemento | Ficha Canônica (`D-141`) | Mecânica Aprovada (`D-141`) | Duração / Marcos | Coreografia Visual Aprovada (`D-140` — Figuras & Cartão) |
|---|---|---|---|---|---|---|
| 1 | **`Hapi`** (*ḥꜥpj* · cheia do Nilo) | **`AQUA`** | `2 ACT / 8 EN / MAGI / 1T` | **`10 MAGI (+MAK)`** e **remove 1 buff positivo** do alvo *(lavagem)* | `2.80 s` · hit `0.85 s` | Cartucho abre → 2 ânforas nos cantos superiores inclinam e despejam jatos em zigue-zague vertical → 5 faixas (3 no cartão) de zigue-zague `𓈖` sobem deslizando em sentidos opostos (período exato `toothW`) → 2 peixes de perfil cruzam em linha reta de ponta a ponta → impacto seco (`0.85 s`, flash papiro `0.12 s`, shake `±5 px`) → vazante e tag `DISPEL`. |
| 2 | **`Qebeh`** (*qbḥ* · frio/gelado) | **`CRYO`** | `2 ACT / 8 EN / MAGI / 1T` | **`12 MAGI (+MAK)`** e aplica **`CHILL`** (`−25%` dano causado por `2` rodadas) | `2.85 s` · trava `0.82 s` · estilhaço `1.44 s` | Cartucho abre → rajada diagonal de 7–8 lanças de gelo bipartidas → 7–9 pares de dentes de gelo (estalactites + estalagmites planas) crescem do teto e da base fechando em mandíbula (`0.82 s`) → **freeze-frame** (`0.82–1.44 s`): tint glacial no alvo, 3 glifos geométricos de geada piscam em 10 FPS e uma trinca horizontal rasga de ponta a ponta → **estilhaço (`1.44 s`)**: flash `0.13 s`, glifo central expandindo + 16–18 cacos triangulares giratórios e tag `CHILL`. |
| 3 | **`Metut`** (*mtwt* · veneno/peçonha) | **`VENO`/`TOXI`** | `2 ACT / 8 EN / MAGI / 1T` | **`8 MAGI (+MAK)`** e aplica **`VENO`** (`4 DMG` por `3` rodadas, dissipável) | `2.85 s` · bote `0.76 s` | Cartucho abre → 2 cobras Uraeus simétricas de perfil desenrolam das bordas esquerda/direita (`1.0×` figura; `0.52×` cartão) → **bote simultâneo em 2 quadros (`0.76 s`)** com presas + língua rubra → selo de escorpião (Serqet) surge no centro ao fundo → 5–7 colunas verticais de veneno escorrem de cima para baixo + 4 bolhas octogonais estouram em cruzes 2D → cobras recuam e tag `VENO`. |
| 4 | **`Seret`** (*srt* · espinho) | **`LEAF`** | `2 ACT / 8 EN / MAGI / 1T` | **`10 MAGI (+MAK)`** e aplica **`SNARE`** (`−4 AGI` por `2` rodadas) | `2.80 s` · estalo `0.86 s` | Cartucho abre → 4 chicotes de sarça espinhosa disparam sequencialmente das 4 quinas cruzando em **X** → **estalo seco (`0.86 s`)**: chicotes esticam, espinhos-garra crescem `1.65×`, barra horizontal de sarça trava o centro, selo de espinhos pulsa no meio + flash `0.11 s` → rajada horizontal de 10–12 folhas-lança cortantes rasga de ponta a ponta → chicotes recuam e tag `SNARE`. |

---

## 6. Plano de Implementação Faseado no Godot 4

### Fase 1 — Fundação `AnimalEgyptianFX` + Recorte de Cartão (`status_rect`)
1. Criar `scripts/battle/animal_egyptian_fx.gd` (`AnimalEgyptianFX`, `z_index = 50`) com:
   - Paletas `PAL_AQUA`, `PAL_CRYO`, `PAL_VENO`, `PAL_LEAF` + `palette_for(elem, is_zahav)` garantindo **zero `#ffd84a` quando `is_zahav == false`**.
   - Quantização temporal `q_time(t, fps)` e todas as primitivas da §4.3.
   - Infraestrutura dual de alvo: camada sobre figura inimiga (`enemy_sprite_rect`) e subárvore `_card_clip` (`Control` com `clip_contents = true`) posicionada exatamente sobre `hud.status_rect(idx)` em espaço `816×624`.
2. Teste headless `tests/verify_animal_egyptian_core.gd` verificando: paletas sem ouro em normal, ouro presente em ZAHAV, zero letras hebraicas, `q_time`, cálculo exato de `card_rect` (1, 2 e 3 heróis) com `min_y > BATTLE_LOG_RECT.end.y` (`0 px` sobre o Battle Log).

### Fase 2 — Coreografias 1:1 (`Hapi`, `Qebeh`, `Metut`, `Seret`) & Roteamento no `PlayableController`
1. Implementar `play_hapi`, `play_qebeh`, `play_metut` e `play_seret` em `AnimalEgyptianFX`, com parâmetros `(target_rect, is_ally, is_zahav, show_cartouche)` e tempos de impacto exatos (`0.85 s`, `1.44 s`, `0.76 s`, `0.86 s`).
2. Integrar `egyptian_fx` em `scripts/battle/playable_controller.gd` roteando qualquer skill com `"vfx_style": "egyptian_2d"` tanto para **jogador → inimigo** quanto **inimigo → herói (cartão)**.
3. Adicionar `tests/verify_animal_egyptian_vfx.gd` + ferramenta de captura `tools/capture_animal_egyptian_vfx.gd` gerando quadros-chave em **ambos os modos (Figuras e 3 Cartões Survival)** sobre o `HEAD` atual (`D-130`) para inspeção visual do criador.

### Fase 3 — Registro Mecânico (`SkillBook` + `SkillFx` + HUD `VENO`)
1. Registrar `&"hapi"`, `&"qebeh"`, `&"metut"` e `&"seret"` em `scripts/core/skill_book.gd` conforme §5 (`vfx_style: "egyptian_2d"`, zero `affinity`).
2. Conectar em `scripts/core/skill_fx.gd`:
   - `Hapi`: remover 1 buff positivo (`dispel_one_positive(target)` — compatível com `STURDY` da `D-139` e buffs de estágio/shield).
   - `Qebeh`: reutilizar `status: "chill", rounds: 2` já existente (`−25%` dano causado).
   - `Metut`: adicionar status negativo dissipável `&"veno"` (`4 DMG` por `3` rodadas no tick de fim/início de rodada, com gravura monocromática dedicada em `StatusIcons` / `playable_hud.gd` sem regredir as gravuras existentes).
   - `Seret`: reutilizar `status: "snare", rounds: 2` já existente (`−4 AGI`).
3. Distribuir entre os **Animais do Modo Survival** após confirmação do roster final (8 sprites livres vs. conflito de `Anubis` na `MAESTO_UNIVERSE_AUDIT.md`).

---

## 7. Critério de Aceitação para Toda Nova Magia Egípcia 2D
Uma nova magia da família dos Animais só é considerada entregue após cumprir:
1. Nome em **Egípcio Antigo** (`D-141`) e definição em `scripts/core/skill_book.gd` com `"vfx_style": "egyptian_2d"` e **zero campo `affinity`** (`D-119`/`D-138`).
2. **Protótipo HTML obrigatório com modo Dual (Figuras × Cartão `256×52`)** aprovado visualmente pelo criador (`D-140`).
3. Conformidade 100% 2D (zero 3D, zero gradientes, 10 FPS, zero hebraico, `#ffd84a` apenas em `ZAHAV`).
4. Implementação em `AnimalEgyptianFX` com recorte exato no cartão do aliado (`0 px` sobre Battle Log) e composição proporcional nas figuras inimigas.
5. Teste headless passando no `HEAD` atual (`D-130`) + capturas em **ambos** os modos (figuras e cartões) aprovadas visualmente pelo criador (`AGENTS.md` obrigação 7).

---

## 8. Banco de Vocabulário Egípcio de Referência *(Candidatos Não-Canônicos)*

> [!NOTE]
> Apenas os 4 nomes da §5 (`Hapi`, `Qebeh`, `Metut`, `Seret`) são canônicos pela **D-141**. As raízes abaixo ficam registradas apenas como banco de inspiração para magias futuras dos Animais (análogo ao `docs/MAGIC_VOCABULARY_BACKLOG.md` do Hebraico).

| Grupo | Candidato | Transliteração | Significado real | Uso sugerido |
|---|---|---|---|---|
| **`AQUA`** | **`Mu`** | *mw* | Água | Magia curta/básica ou suporte hídrico |
| **`AQUA`** | **`Nun`** | *nwn* | Águas primordiais / abismo | Magia de água superior / área |
| **`AQUA`** | **`Iteru`** | *jtrw* | Rio / Nilo | Correnteza / fluxo |
| **`CRYO`** | **`Qeb`** | *qb* | Frio (raiz curta) | Variante rápida de gelo |
| **`CRYO`** | **`Peret`** | *prt* | Inverno / estação fria | Geada em área |
| **`VENO`** | **`Iaret`** | *jꜥrt* | Cobra Uraeus | Variante ofensiva / `ZAHAV` de veneno |
| **`VENO`** | **`Hefau`** | *ḥfꜣw* | Serpente | Mordida/bote venenoso |
| **`VENO`** | **`Serqet`** | *srqt* | Escorpião / deusa escorpião | Veneno potente / maldição |
| **`LEAF`** | **`Wadj`** | *wꜣḏ* | Verde / papiro / vigor | Cura / regeneração / suporte `LEAF` |
| **`LEAF`** | **`Shent`** | *šndt* | Acácia espinhosa | Barreira de espinhos / defesa `LEAF` |
| **`LEAF`** | **`Khet`** | *ḫt* | Madeira / árvore | Construto / defesa `WOOD`/`LEAF` |
| **Qualificadores *(futuro)*** | **`Wer`** / **`Aa`** | *wr* / *ꜥꜣ* | Grande / poderoso / maior | Possível sufixo para versões evoluídas / `ZAHAV` |
