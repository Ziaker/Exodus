# Estilo Artístico Oficial — VFX de Ataques Não-Reza (D-125)

**Decisão:** D-125 · 2026-11-27 (decisão do criador; **8/8 ataques D-124 aprovados visualmente**)  
**Índice canônico:** [`docs/DECISIONS.md`](DECISIONS.md)  
**Contraponto sagrado (Rezas):** [`docs/PRAYER_VFX_RULE.md`](PRAYER_VFX_RULE.md) (D-113)  
**Catálogo mecânico base:** [`docs/CANON_SKILLS_D124.md`](CANON_SKILLS_D124.md) (D-124)  
**Referências HTML canônicas:** [`docs/vfx_refs/d124_d125/README.md`](vfx_refs/d124_d125/README.md)

---

## 1. Pilar Estético Unificado (Lei Canônica)

> **Todos os ataques não-reza de EXODUS (físicos, mágicos demoníacos/abissais e habilidades absorvidas) compartilham uma estética visual própria e reutilizável: Anatômico Grotesco de Rabisco (boil em 12 FPS, silhueta negra + contorno orgânico duplo) combinado com Interferência Hipnótica (Moiré / ondas febris) em paleta sombria sem neon.**

Assim como as **rezas** possuem uma identidade visual unificada e inconfundível (tipografia 100% hebraica da **D-113**), os **ataques não-reza** possuem esta assinatura visual única que os distingue imediatamente no campo de batalha — evocando o grotesco anatômico, o febril e o desconforto metafísico de *EXODUS* sobre o palco 816×624.

---

## 2. Regras Invioláveis de Contraste e Exclusividade

1. **Lei do Outline Dourado (`ZAHAV` exclusivo):**
   - O **outline dourado (`#ffd84a`) só existe quando o ataque é executado através de `ZAHAV`**.
   - Ataques normais **NUNCA** usam outline ou destaque dourado — sempre usam suas cores naturais/sombrias (osso `#e8ddd0`/`#efe6d5`, sangue `#a81c2e`, abismo `#361c52`/`#9b8ab0`, fogo natural `#c94c14`/`#f2d9b6`).
   - *Exemplo canônico:* `Vuln Pierce` (normal) usa `PALS.blood` (zero dourado); `Fang Spine` e `Ignoma Esh` (`ZAHAV`) usam `PALS.zahavBlood` e `PALS.zahavFire` (outline `#ffd84a`).
2. **Separação Hebraica (D-113 vs. D-125):**
   - Ataques não-reza **NÃO usam letras hebraicas**.
   - **Única exceção:** ataques híbridos que carregam explicitamente uma palavra hebraica no nome/natureza (como **`Ignoma Esh`**, que contém **`Esh` / `אש`** e rompe seu rabisco de fogo ZAHAV em letras hebraicas tricolores `#ff7a1f` / `#ffd84a` / `#ffffff`).
3. **Sem Neon e Sem Gradientes Plásticos:**
   - Todo corpo anatômico/rabiscado tem preenchimento interno **negro abissal** (`#050208`, `#030106`, `#020005`) ou brasa escura (`#240903`, `#290d04`).
   - Nada de círculos lisos com `radial-gradient` genérico de RPG, brilho neon/rave ou cores saturadas desconectadas da paleta do palco.
4. **Estética Reservada (Não Misturar):**
   - **Geometria / wireframe** está reservada para **alguns outros Anjos** futuros — não deve ser utilizada em ataques comuns não-reza.
5. **Hierarquia de Leitura em Tela (816×624):**
   - Nenhum VFX não-reza pode obscurecer o **HUD superior**, o **Battle Log**, os **cartões de status** ou os **números de dano (`DamageLayer`, `z_index = 100`)**.
   - O campo Moiré e os rabiscos devem respeitar recorte acima do Battle Log e `z_index` rigorosamente abaixo da camada de números e janelas do HUD.

---

## 3. Motores Reutilizáveis da Linguagem (Porte 1:1 para Godot 4)

A estética é composta por **4 blocos modulares** reutilizáveis por qualquer ataque não-reza atual ou futuro (`scripts/battle/skill_grotesque_fx.gd` + shaders):

### 3.1 Motor 1 — Rabisco Anatômico em Boil de 12 FPS
- **Quantização temporal:** todo vértice rabiscado é avaliado em passos discretos de **12 FPS**:
  - `f_idx = int(floor(t * 12.0))`
  - `qt = float(f_idx) / 12.0`
- **Jitter determinístico (sem `randf()` caótico por frame de 60 FPS):**
  - `hash(n) = fract(sin(n * 127.1 + 311.7) * 43758.5453)`
  - Para cada vértice `i`:
    - `jx = (hash(f_idx * 31 + i * 7) - 0.5) * jitter * 2.0`
    - `jy = (hash(f_idx * 47 + i * 13) - 0.5) * jitter * 2.0`
- **Duplo traço orgânico (`draw_sketch_shape`):**
  1. Preenchimento sólido escuro (`fill_col`, padrão `#050208` ou `#030106`) com o polígono `f_idx`.
  2. Contorno principal em **`pal.hi`** (`line_w` padrão `2.0px`, `antialiased = false`).
  3. Segundo contorno deslocado usando **`f_idx + 77`** e **`jitter * 1.45`** em **`pal.accent`** (`max(1.1, line_w * 0.65)`).
- **Primitivas anatômicas reutilizáveis:**
  - `draw_sketch_eye(cx, cy, rx, ry, f_idx, pal, closed, dark_iris)`: olho de 12 segmentos com pupila móvel trêmula (`closed = false`) ou fenda fechada com risco em **X** (`closed = true`, cegueira).
  - `draw_sketch_flame(cx, cy, scale, f_idx, pal, fill_col)`: polígono de 11 vértices com línguas irregulares assimétricas + língua interna preenchida com `pal.accent` (**sem olho no centro**).

### 3.2 Motor 2 — Campo de Interferência Hipnótica (Moiré / Ondas Febris)
Nos HTMLs de referência, o campo Moiré é desenhado em grade pixel-crisp de **`step = 5px`** para garantir estética retro/suja. **No Godot 4, isso NÃO deve ser um loop GDScript por pixel** — deve ser um **`CanvasItem` shader leve** (`assets/shaders/hypnotic_moire.gdshader`) avaliando exatamente as mesmas equações por célula quantizada de `5×5 px`:

- **Modo 0 — Elipse Radial (`radial`):**
  ```glsl
  // Em coordenadas locais (dx, dy) centradas na elipse de raios (rx, ry):
  float norm_sq = (dx * dx) / (rx * rx + 1.0) + (dy * dy) / (ry * ry + 1.0);
  if (norm_sq > 1.0) discard;
  float fall = 1.0 - sqrt(norm_sq);
  float dist = length(vec2(dx, dy));
  float ang = atan(dy, dx);
  float v = sin(dist * 0.21 - u_time * 14.0 + sin(ang * 4.0 + u_time * 5.0) * 2.1)
          + cos((dx * 0.1 - dy * 0.08) + sin(y * 0.08 + u_time * 8.0) * 1.9);
  ```
  - Limiar normal (`dark_bias = false`): `v * fall * env > 0.30`; cores `v > 1.30 → pal.hi`, `v > 0.72 → pal.accent`, senão `#050208`. Alpha `min(0.92, env * fall * 1.45)`.
  - Limiar escuro (`dark_bias = true`, usado em `Umbral Gaze`): `v * fall * env > 0.26`; cores `v > 1.55 → pal.hi`, `v > 0.85 → pal.accent`, senão `#030106`. Alpha `min(0.95, env * fall * 1.50)`.

- **Modo 1 — Cone Exalado da Boca (`breath_cone`, usado em `Dark Breath v2`):**
  ```glsl
  // Origem na garganta (mouth_x, mouth_y), direção dir_x (+1 direita / -1 esquerda):
  float dx = (px - mouth_x) * dir_x;
  if (dx < 0.0 || dx > reach) discard;
  float frac = dx / max(1.0, reach);
  float half_h = 16.0 + dx * 0.21;
  float dy = abs(py - mouth_y);
  if (dy > half_h) discard;
  float edge_x = frac < 0.08 ? frac / 0.08 : (frac > 0.78 ? max(0.0, 1.0 - (frac - 0.78) / 0.22) : 1.0);
  float edge_y = max(0.0, 1.0 - dy / half_h);
  float fall = edge_x * edge_y;
  float v = sin(dx * 0.095 - u_time * 19.0 + sin(py * 0.1 + u_time * 9.0) * 2.3)
          + cos((py - mouth_y) * 0.13 + sin(dx * 0.055 - u_time * 11.0) * 2.2);
  // Limiar: v * fall * env > 0.22
  // Cores: v > 1.55 -> pal.hi | v > 0.78 -> pal.accent | else #030106
  // Alpha: min(0.95, env * fall * 1.55)
  ```

### 3.3 Motor 3 — Distorção Febril do Alvo e Feedback de Impacto
- **Scanline Warp horizontal no sprite/cartão do alvo (`warp_amp`):**
  - `wx = sin(sy * 0.18 + t * 20.0) * warp_amp + cos(sy * 0.09 - t * 12.0) * warp_amp * 0.5`
  - No Godot 4, aplicar como shader temporário leve no sprite do inimigo atingido (ou offset/warp no cartão quando o alvo for herói), decaindo com o envelope `env` do impacto.
- **Inversão breve no impact frame:** flash osso claro (`#e8ddd0` / `#efe6d5`) por `0.12–0.16 s` apenas nos ataques que causam dano (em `Dark Breath`, que dá **0 dano**, **não há flash de inversão**, apenas warp + olho riscado em X).
- **Escurecimento do palco (`darken`):** véu `rgba(4, 1, 8, darken)` cobrindo apenas a faixa do palco (entre HUD superior e Battle Log) durante ataques abissais/pesados (`Umbral Gaze`: até `0.56`, `Dark Breath`: até `0.48`, `Fang Spine`: `0.16`, `Ignoma Esh`: `0.22`).

### 3.4 Motor 4 — Espelhamento e Direção (Jogador ↔ Inimigo)
- **Jogador → Inimigo:** projéteis partem do centro superior do cartão do conjurador (`hud.status_rect(i)`) até o centro do sprite inimigo (`hud.enemy_sprite_rect(j)`); em `Dark Breath`, a boca grotesca de perfil surge à **esquerda** do palco exalando para a direita (`dir_x = +1`).
- **Inimigo → Herói:** projéteis partem do sprite inimigo até o cartão do herói; formas horizontais (`Fang Sting`, `Vuln Pierce`) invertem o eixo X; em `Dark Breath`, a boca de perfil surge espelhada à **direita** exalando para a esquerda (`dir_x = -1`) sobre a faixa dos cartões/palco sem esconder o Battle Log.

---

## 4. Paletas Canônicas Exatas

| Família | `accent` (2º traço / onda média) | `hi` (1º traço / crista) | `deep` (preenchimento interno) | Uso permitido |
|---|---|---|---|---|
| `blood` (Normal) | `#a81c2e` | `#efe6d5` / `#e8ddd0` | `#24050a` (corpo `#050208`) | `Mazz Bite`, `Fang Sting`, `Vuln Pierce`, ataques físicos sangrentos normais |
| `zahavBlood` (**ZAHAV**) | `#a81c2e` | **`#ffd84a`** *(dourado)* | `#26080d` (corpo `#050208`) | `Fang Spine [ZAHAV]`, físicos sangrentos via ZAHAV |
| `abyssDark` (Normal) | `#361c52` | `#9b8ab0` / `#a997bd` | `#09030f` (corpo `#030106`) | `Umbral Gaze`, `Dark Breath`, ataques abissais/sombrios normais |
| `fireNormal` (Normal) | `#c94c14` | `#f2d9b6` | `#240903` | `Ignoma`, ataques de fogo não-reza normais |
| `zahavFire` (**ZAHAV**) | `#d95b16` | **`#ffd84a`** *(dourado)* | `#290d04` | `Ignoma Esh [ZAHAV]`, ataques de fogo não-reza via ZAHAV |
| `FIRE_HEBREW` (Exceção `Esh`) | `#ff7a1f` | `#ffd84a` | `#ffffff` *(3ª cor)* | **EXCLUSIVO** de letras hebraicas em `Ignoma Esh` (`אש`) |

---

## 5. Catálogo Aprovado — Coreografia 1:1 dos 8 Ataques (D-124)

| Ataque | Ref. HTML + Função | Duração / Hit | Paleta | Coreografia Canônica Aprovada |
|---|---|---|---|---|
| **Mazz Bite** | `v2` · `renderMazzBite()` | `2.35s` · hit `0.56s` | `blood` | Moiré radial crescente → mandíbula superior+inferior assimétrica de 11 dentes rabiscados fechando de `gap=52` a `0` sobre o alvo → shake `±8px` + inversão `0.14s` + 3 olhos grotescos piscando em volta |
| **Fang Sting** | `v2` · `renderFangSting()` | `2.35s` · hit `0.50s` | `blood` | Ferrão/dedo ósseo perfurando em diagonal (`-155,+62` → `+130,-53`) → fenda horizontal de Moiré (`rx=88, ry=26`) + 8 respingos triangulares de sangue rabiscados (com `BLEED` só no `POINT`) |
| **Fang Spine [ZAHAV]** | `v3` · `renderFangSpine()` | `2.70s` · hits `0.44s`, `1.04s` | `zahavBlood` | Escurece palco `0.16` → 10 vértebras com apófise espinhosa arqueando do 1º ao 2º alvo (ou em laço se mesmo alvo) → em cada alvo, 4 pares de costelas curvadas se abrindo como gaiola perfurante + 8 gotas de sangue + **outline `#ffd84a`** |
| **Vuln Pierce** | `v3` · `renderVulnPierce()` | `2.45s` · hit `0.64s` | `blood` *(zero dourado!)* | Escurece `0.14` → olho vulnerável aberto tremendo no alvo (quando em ação não-ofensiva) → agulha/garra horizontal atravessando de `-190` a `+195` + 10 estilhaços rabiscados do olho despedaçado |
| **Dark Breath v2** | `v4` · `renderDarkBreath()` | `2.95s` · sopro `0.26s` | `abyssDark` | Escurece `0.48` → **camada 0:** garganta negra funda de perfil à esquerda; **camada 1:** cone de Moiré saindo de dentro da garganta (`reach` cresce a `640px/s`); **camada 2:** alvos recebem warp `11` + olho riscado em X (somente se não desviaram!); **camada 3:** 28 correntes de vento ondulantes + 22 nuvens negras rabiscadas saindo de dentro da boca; **camada 4:** maxilar superior e inferior com dentes tortos **por cima**, pulsando na exalação |
| **Umbral Gaze** | `v3` · `renderUmbralGaze()` | `2.85s` · hit `0.62s` | `abyssDark` *(darkBias)* | Escurece `0.56 * env` → Moiré radial escuro (`darkBias=true`) + olho abissal gigante (`rx=76, ry=17`, `darkIris=true`) abrindo sob os pés do alvo → 5 espinhos/dedos curvos erguendo do olho (`92–130px`) e aprisionando o alvo |
| **Ignoma** | `v3` · `renderIgnoma()` | `2.45s` · hit `0.62s` | `fireNormal` | Arco parabólico (`52px`) com rastro de chama rabiscada menor (`scale=0.55`) + chama principal (`scale=1.0`, **sem olho**) + Moiré térmico → explosão de 3 línguas de chama rabiscadas subindo sobre o alvo |
| **Ignoma Esh [ZAHAV]** | `v4` · `renderIgnomaEsh()` | `2.85s` · hits `0.62s`, `1.04s` | `zahavFire` + `FIRE_HEBREW` | Escurece `0.22` → 2 projéteis `drawSketchFlame` com **outline dourado `#ffd84a`** e palavra `אש` dentro, em arcos parabólicos (`52px` e `82px`) com Moiré sincronizado exatamente ao mesmo arco → no impacto, chama expande sem preenchimento e rompe em **38 letras hebraicas tricolores** com gravidade + `אש` (`32px`) subindo |

---

## 6. Critério de Aceitação para Novos Ataques Não-Reza

Qualquer novo ataque não-reza adicionado ao jogo só é considerado entregue após cumprir:
1. Definição registrada em `scripts/core/skill_book.gd` (sem qualquer campo de afinidade — **D-119**).
2. Efeito visual implementado em `scripts/battle/skill_grotesque_fx.gd` seguindo os 4 motores desta especificação.
3. Conformidade verificada com a **Lei do Outline Dourado** (`ZAHAV` exclusivo) e a **Separação Hebraica** (sem letras hebraicas, salvo exceção nominal).
4. Cobertura de teste automatizado headless (`tests/`).
5. Captura visual (quadros/vídeo reais no Godot) inspecionada pelo agente e **aprovada visualmente pelo criador** (`AGENTS.md`).

---

## 7. Fase 3 implementada (2026-11-27) — fundação visual

`scripts/battle/skill_grotesque_fx.gd` (`SkillGrotesqueFX`, `z_index` 50, criado pelo `PlayableController` como `grotesque_fx`), `assets/shaders/hypnotic_moire.gdshader` e `assets/shaders/target_fever_warp.gdshader`; teste `tests/verify_grotesque_fx_core.gd` (111 checks) e captura `tools/capture_grotesque_core.gd`. Ainda **sem as 8 coreografias** (Fases 4 e 5): o motor só oferece as primitivas e os campos. A validação visual é do criador.

- **Espaço de design:** o nó desenha em 816×624 (lógico × 1,5), então a célula de Moiré de 5 px é 5 px reais na janela.
- **Moiré:** modo 0 (radial, `dark_bias`) e modo 1 (cone da garganta, `dir_x` ±1) na GPU. Cada ataque usa o perfil de limiar do HTML canônico dele: `v2` (0,30 / cristas 1,28), `v3` (0,26 / 1,30) e `v4` (0,30 / 1,30).
- **Warp do alvo:** inimigo ganha um sprite sobreposto com o shader (o HUD esconde a silhueta preta enquanto isso); o cartão do herói ondula pela mesma equação.
- **Paletas:** `palette_for(família, is_zahav)`; o ouro `#ffd84a` só sai com `is_zahav == true`. Leitura adotada, a confirmar: `abyss` + ZAHAV (sem paleta definida no guia) troca só a crista para ouro.
- **Limite conhecido:** o motor não desenha as formas dos ataques (mandíbula, ferrão, vértebras, olhos de cada skill); isso entra nas Fases 4 e 5.
