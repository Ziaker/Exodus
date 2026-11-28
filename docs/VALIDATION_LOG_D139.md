# Dossiê de Construção e Validação do Criador — Skills Canônicas & VFX (D-139)

**Decisões associadas:** D-125 · D-137 · D-139 · **Data da conclusão:** 2026-11-27  
**Status final:** **4/4 APROVADOS DE PRIMEIRA** (*"absolutamente perfeitos todos"*) — design mecânico fechado + aprovação visual concluída em modo **Inimigos (3)** e **Aliados Survival (3 cartões)**; implementação no Godot pronta via [`docs/CLAUDE_PROMPTS_D139.md`](CLAUDE_PROMPTS_D139.md)  
**Referência HTML canônica:** [`docs/vfx_refs/d139/d139_skills_vfx_canon.html`](vfx_refs/d139/d139_skills_vfx_canon.html) · **Índice:** [`docs/vfx_refs/d139/README.md`](vfx_refs/d139/README.md) · **Spec mecânica:** [`docs/CANON_SKILLS_D139.md`](CANON_SKILLS_D139.md)

> [!NOTE]
> Este documento registra o **processo completo de definição, construção técnica, auto-auditoria e validação pelo criador** do Lote 3 de habilidades canônicas (fechamento das 4 físicas restantes do Survival).

---

## 1. Cronologia do Processo (Alinhamento → Construção → Auto-Auditoria → Aprovação)

### Etapa 1 — Levantamento das 4 Físicas Restantes do Survival (`D-106`)
Partindo de `docs/CANON_BOUNDARY.md` e `scripts/core/skill_book.gd`, foram listadas as 4 últimas físicas não-canônicas:
1. `TWIN FANG` (`NEKOMATA`) — 2 ACT / 5 EN, 2× poder 5, COMBO (+50% no 2º hit)
2. `FROST LANCE` (`PAZUZU`) — 1 ACT / 5 EN, poder 9, CHILL (−25% próximo ataque)
3. `BLADE DANCE` (`WHITE RIDER`) — 2 ACT / 6 EN, 4 hits escalando `3, 4, 5, 6`
4. `STONE GRASP` (`BARONG`) — 1 ACT / 4 EN, poder 6, SNARE (−4 AGI)

### Etapa 2 — Decisões Mecânicas do Criador (2 rodadas curtas de alinhamento)
O criador definiu e confirmou todos os pontos críticos antes de qualquer protótipo:
- **`Twin Fang`:** mecânica mantida como está (`2 ACT / 5 EN / PHYS / 1T`, 2× `5 PHYS`, COMBO `+50%`), precisando apenas de visual canônico.
- **`Frost Lance`:** **removida no geral** (fora do cânone e fora do Survival/Pazuzu por ora), pois a estética visual das magias dos Animais (`D-138`) ainda precisa ser definida.
- **`Blade Dance`:** rework completo para `ALL ACT / 0 EN / PHYS / Alvo Intercalado` — gasta todos os `ACT` restantes para dar **`ACT + 1` golpes** (`4 ACT → 5 golpes`), alternando entre alvos, com `15 PHYS` por golpe; **não pode ser reagida ofensivamente** (alvo só pode `DEFEND`, sem `COUNTER`); cooldown de **1× a cada 2 rounds** (Round 1 → Round 3).
- **`Rock Body` + `Stone Body [ZAHAV]`** *(rework de `STONE GRASP`)*:
  - `Rock Body` (`1 ACT / 10 EN / STAT / SELF`, **`IMEDIATO`**) → recebe **`STURDY`** até o fim do round.
  - `Stone Body [ZAHAV]` (`1 ACT / 25 EN / STAT / SELF`, **`IMEDIATO`**) → recebe **`STURDY`** + **`+15 DEF`** enquanto `STURDY` permanecer.
  - **`STURDY`:** escudo durante o sistema de ponteiros que impede interrupção durante uma ação; dano e efeitos do contra-ataque ainda ocorrem, mas **efeitos debilitantes são bloqueados consumindo `STURDY` no processo**; é um **buff positivo**, portanto **dispell inimigo afeta e remove**.

### Etapa 3 — Construção do Protótipo v1 (Aplicando Todos os Aprendizados da D-125 / D-131 / D-137)
Em vez de repetir erros já rejeitados na D-131 (excesso de camadas, marcas cobrindo o Battle Log, dourado fora de ZAHAV), o protótipo **v1** nasceu já respeitando todos os princípios permanentes:
1. **Contenção e clareza silhuética:** cada skill comunica sua mecânica principal em 1 leitura (X crescente de presas em `Twin Fang`; fita intercalada + sabres em `Blade Dance`; placas de pedra + escudo `STURDY` em `Rock Body`; blocos dourados + setas `+15 DEF` em `Stone Body`).
2. **Protótipo D-137 nativo:** harness `816×360` herdado diretamente de `d131_skills_vfx_canon.html`, com seletor **Inimigos (3) ↔ Aliados Survival (3 cartões)**, seletor `4 ACT → 5 hits` / `2 ACT → 3 hits` em `Blade Dance`, e `SELF` buffs de `EN` demonstrados sobre `FALLEN` (que possui `EN`, respeitando o fato de `YOCH` usar `PP`).
3. **Auto-auditoria técnica pré-apresentação (defeito capturado e corrigido antes da entrega):**
   - Durante a auditoria do próprio código da v1, detectou-se que o arco de defesa `shieldArc` de `renderStoneArmor` no modo Aliados estava ancorado em `tgt.ry + 1` (`299`) e clampado em `minY = 294`, o que achataria a metade superior do arco em uma linha reta horizontal.
   - **Correção aplicada antes de mostrar ao criador:** `shieldArc` foi centralizado em `tgt.y` (`324`) sem recorte artificial no pulso transitório (conforme D-137), preservando o recorte `y >= 298` estritamente para as cantoneiras e o emblema **persistente** de `STURDY` (0 px sobre o Battle Log).
   - **Verificação automatizada:** `node --check` retornou `0`, `HEBREW_CHARS: 0`, `ALLY_MODE_BTN: True` e `#ffd84a` auditado linha a linha como exclusivo de `isZahav` / `PALS.zahavStone`.

### Etapa 4 — Validação Visual do Criador
- **Resultado (2026-11-27):** **4/4 APROVADOS DE PRIMEIRA** — *"absolutamente perfeitos todos"*.
- Nenhuma iteração v2 foi necessária; o arquivo aprovado foi promovido integralmente (com `✓` nos botões) para [`docs/vfx_refs/d139/d139_skills_vfx_canon.html`](vfx_refs/d139/d139_skills_vfx_canon.html).

---

## 2. Ficha de Validação por Ataque (Lote 3 · 4/4)

### 2.1 `Twin Fang` (`2ACT / 5EN / PHYS / 1T`) — Promoção de `TWIN FANG`
- **Construção visual (`renderTwinFang`, L544–L664):**
  - Paleta `PALS.blood` (`accent #a81c2e`, `hi #efe6d5`, `deep #24050a`, corpo `#050208`) — zero ouro.
  - Golpe 1 (`0.28 s`): `drawTwinFangPair` em `-0.58 rad`, escala `0.96×`, 2 cicatrizes paralelas (`drawParallelGashes`), Moiré `68×54`, 7 respingos.
  - Ponte **COMBO (+50%)** (`0.46 s..0.90 s`): anel rabiscado contraindo de raio `56 → 21` sobre o alvo enquanto as 2 primeiras cicatrizes permanecem visíveis.
  - Golpe 2 (`0.86 s`): `drawTwinFangPair` em `+0.62 rad`, escala **`1.32×`**, 2 cicatrizes mais grossas cruzando em X, Moiré ampliado `108×82`, shake `±9.5 px`, 12 respingos.
- **Status:** **APROVADO DE 1ª** (Inimigos + 3 Aliados Survival).
- **Checklist no Godot:**
  - [ ] Custo `2 ACT / 5 EN`, 2 barras/golpes de poder `5 PHYS`, 2º golpe `+50%` quando o 1º acerta.
  - [ ] Coreografia 1:1 sem dourado e sem hebraico em Inimigos e 3 Aliados.

### 2.2 `Blade Dance` (`ALL ACT / 0EN / PHYS / Alvo Intercalado`) — Rework de `BLADE DANCE`
- **Construção visual (`renderBladeDance`, L704–L859):**
  - Nova paleta `PALS.blade` (`accent #8c1d30`, `hi #dfe4ee`, `deep #17070c`, corpo `#050208`) — aço sombrio + corte carmesim, zero ouro.
  - Escurecimento teatral `0.28` + fita/rastro rabiscado em arco alternado ligando cada alvo ao seguinte (`order = [0, 1, 2, 0, 1]` no protótipo).
  - Em cada impacto (cadência `0.33 s`): `drawCurvedBladeSlash` (crescente de corte + sabre rabiscado em ângulos alternados, escala crescendo `0.92× → 1.22×`) + Moiré `76×58` + cicatriz residual persistente até o fim da dança + 6 faíscas.
  - **Nota obrigatória para o porte Godot:** quando houver apenas **1 alvo vivo**, o rastro entre golpes consecutivos (`from == to`) deve desenhar um **laço/arco lateral de retorno** ao redor do alvo único em vez de um segmento de comprimento zero.
- **Status:** **APROVADO DE 1ª** (Inimigos + 3 Aliados Survival, testável em `4 ACT → 5 hits` e `2 ACT → 3 hits`).
- **Checklist no Godot:**
  - [ ] Consome todos os `ACT` restantes (`0 EN`), executa `ACT + 1` golpes intercalando alvos vivos.
  - [ ] Bloqueia `COUNTER` (permite apenas `DEFEND`); aplica cooldown de 2 rounds (Round 1 → libera Round 3).
  - [ ] Coreografia 1:1 funcional para 1, 2 e 3 alvos (Inimigos e 3 Aliados); zero dourado, zero hebraico.

### 2.3 `Rock Body` (`1ACT / 10EN / STAT / SELF`, `IMEDIATO`) — Rework de `STONE GRASP`
- **Construção visual (`renderStoneArmor(false)`, L903–L1095):**
  - Paleta `PALS.stone` (`accent #6d5e52`, `hi #d9cfc2`, `deep #16110e`, corpo `#050208`) — zero ouro.
  - 7 placas irregulares (`drawRockPlate`) convergem e travam em `0.44 s` + anel de travamento + 11 partículas de poeira + Moiré `78×58` + shake `±5.5 px`.
  - Estado persistente `STURDY`: ombreiras pétreas + escudo hexagonal (`drawSturdyBadge`) nos inimigos; **4 cantoneiras pétreas + escudo hexagonal no canto inferior-direito livre do cartão** nos aliados (`y >= 298`, **0 px sobre o Battle Log**).
  - Demonstração de resistência a `COUNTER` (`1.65 s`): arco de escudo + 6 linhas de estalo seco em tamanho cheio.
- **Status:** **APROVADO DE 1ª** (Inimigos + 3 Aliados Survival).
- **Checklist no Godot:**
  - [ ] Resolve `IMEDIATO` (sem reação), custa `1 ACT / 10 EN`, aplica `STURDY` até o fim do round.
  - [ ] Impede interrupção no contra-ataque (dano/efeitos normais ocorrem); bloqueia efeito debilitante perdendo `STURDY` (com estilhaçamento visual de quebra); removível por dispell inimigo.
  - [ ] Emblema/cantoneiras persistentes nunca invadem o Battle Log; ícone adaptativo de `STURDY` integrado ao HUD (`a73da1c`).

### 2.4 `Stone Body [ZAHAV]` (`1ACT / 25EN / STAT / SELF`, `IMEDIATO`) — Evolução ZAHAV de `Rock Body`
- **Construção visual (`renderStoneArmor(true)`, L903–L1095):**
  - Nova paleta `PALS.zahavStone` (`accent #8c7252`, `hi #ffd84a`, `deep #1b140d`, corpo `#050208`) — **outline e veios dourados exclusivos de ZAHAV**.
  - 10 blocos de rocha maiores em 2 ondas (`0.00 s` e `0.20 s`) travando em `0.62 s` + escurecimento `0.24` + Moiré `104×78` + shake `±8.5 px` + **6 setas finas ascendentes douradas (`+15 DEF`)**.
  - Estado persistente `STURDY +15 DEF`: blocos maiores nos flancos (inimigo) / cantoneiras grossas douradas + escudo dourado-pedra no canto livre do cartão (aliado, 0 px sobre o Battle Log).
- **Status:** **APROVADO DE 1ª** (Inimigos + 3 Aliados Survival).
- **Checklist no Godot:**
  - [ ] Evolução ZAHAV de `Rock Body` (`1 ACT / 25 EN`, `IMEDIATO`, nome dourado); concede `STURDY` + `+15 DEF` acoplado à vida de `STURDY`.
  - [ ] Ao terminar o round, quebrar contra efeito debilitante ou sofrer dispell inimigo, `+15 DEF` cai junto com `STURDY`.
  - [ ] Outline `#ffd84a` presente (ZAHAV); zero hebraico; emblema persistente fora do Battle Log.

---

## 3. Panorama Consolidado dos VFX Não-Reza Canônicos Aprovados (19/19)

| Lote | Decisão | Aprovados | Referência HTML Canônica | Status in-engine |
|---|---|---|---|---|
| **Lote 1** | D-124 / D-125 | **8/8** (`Mazz Bite`, `Fang Sting`, `Fang Spine [Z]`, `Vuln Pierce`, `Dark Breath v2`, `Umbral Gaze`, `Ignoma`, `Ignoma Esh [Z]`) | `docs/vfx_refs/d124_d125/` | Implementado (aguarda aceite visual no Godot) |
| **Lote 2** | D-131 / D-137 | **7/7** (`Stone Crush`, `Energy Blow`, `Drain Claw`, `Vital Claws [Z]`, `Weaken`, `Weakenen [Z]`, `Mark of Sun`) | `docs/vfx_refs/d131/` | Implementado nas 3 fases (aguarda aceite visual no Godot) |
| **Lote 3** | **D-139** | **4/4** (`Twin Fang`, `Blade Dance`, `Rock Body`, `Stone Body [Z]`) + `Frost Lance` removida | `docs/vfx_refs/d139/` | **Pronto para implementação** (`docs/CLAUDE_PROMPTS_D139.md`) |
