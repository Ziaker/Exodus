# Prompts Faseados para Implementação no Claude — D-124 + D-125

Guia de execução em **5 fases atômicas** para implementar no Godot 4 o pacote completo **D-124** (6 ataques canônicos + 2 evoluções `ZAHAV` + 3 regras globais de combate) e **D-125** (estética oficial dos ataques não-reza, **100% fiel 1:1 aos HTMLs aprovados**).

- **Referências HTML canônicas salvas no repositório:** [`docs/vfx_refs/d124_d125/README.md`](vfx_refs/d124_d125/README.md)
- **Guia de estilo artístico dos ataques não-reza:** [`docs/NON_PRAYER_VFX_STYLE.md`](NON_PRAYER_VFX_STYLE.md)
- **Especificação mecânica canônica:** [`docs/CANON_SKILLS_D124.md`](CANON_SKILLS_D124.md)
- **Regras obrigatórias de entrega:** [`AGENTS.md`](../AGENTS.md) (auditoria contínua, crítica extrema, evidência real, Obrigação 8 fetch/rebase, Obrigação 11 D-120 commit+push imediato).

> [!TIP]
> Copie e cole **um bloco de fase por vez** no Claude Code. Cada fase termina auditada, com testes Godot headless passando e commit+push feitos antes de avançar para a próxima fase.

---

## FASE 1 — Regras Globais de Combate (D-124 Core: `HIGH SPEED`, `BLEED` Canônico e Temporização de Ação)

~~~text
Leia `AGENTS.md`, `docs/CANON_SKILLS_D124.md` (§2 e §3) e `docs/DECISIONS.md` (D-119, D-120, D-124).
Antes de editar, execute `git fetch origin --prune && git status --short` (Obrigação 8).

OBJETIVO DA FASE 1 — Implementar exclusivamente as 3 regras globais de combate da D-124 (sem alterar ainda o catálogo de skills nem criar VFX):

1. HIGH SPEED (D-124 §2.1):
   - Ataques marcados com `"high_speed": true` no `SkillBook` têm ponteiro 20% mais rápido (`velocidade ×1.20`, ou seja `duration = base_duration / 1.2`) tanto na barra de ataque/defesa (`scripts/battle/rhythm_bar.gd`, `scripts/battle/compact_rhythm_bar.gd`) quanto no trilho do atacante no contra-ataque (`scripts/battle/counter_rhythm_bar.gd` e `_counter_exchange` em `scripts/battle/playable_controller.gd`).
   - No contra-ataque (D-049), o ponteiro de um ataque `HIGH SPEED` deve ser mais rápido do que o ponteiro normal do oponente, aplicando o fator `/ 1.2` sobre a duração da barra do lado que executa o ataque `HIGH SPEED`.
   - Não quebrar D-034 (AGI/SP continuam controlando largura do `POINT`, não velocidade base).

2. BLEED Canônico Global (D-124 §2.2 e §3.5):
   - Substituir o `BLEED` legado do Survival (`2 de dano/round por 3 rounds`) em todo o jogo pela regra canônica oficial:
     * Reduz as curas recebidas pela unidade em **20% por acúmulo**, podendo acumular até **4 vezes** (`máximo -80%` de cura recebida).
     * Dura até o **fim do próximo turno** da unidade (ou próximo tick de virada de turno/round conforme `SkillFx.tick`).
   - Aplicar a redução diretamente em `BattleUnit.heal(amount)` em `scripts/core/battle_unit.gd` (e garantir helper claro como `BattleUnit.add_bleed(stacks := 1)` limitado a `SkillFx.BLEED_MAX_STACKS = 4`, arredondamento consistente `maxi(0, int(round(float(amount) * (1.0 - 0.20 * min(4, bleeds.size())))))`).
   - Remover o dano periódico `BLEED_DAMAGE` de `SkillFx.tick(unit)` em `scripts/core/skill_fx.gd`, mantendo apenas o decaimento de duração dos bleeds no `tick`.
   - Preservar integralmente `SkillFx.cleanse()` (`MEND`) e `SkillFx.cleanse_all()` (`Tahorah` D-112) limpando `unit.bleeds`.
   - Atualizar todos os testes que esperavam dano de bleed legado (`tests/verify_skill_fx.gd`, `tests/verify_new_prayers.gd`).

3. Temporização de Ação Global + Prisão / Auto-PASS (D-124 §2.3 e §3.4):
   - Adicionar suporte a aprisionamento por `X` ações globais em `BattleUnit` (`trapped_actions: int = 0` + status `&"trapped"` em `SkillFx.NEGATIVE_STATUSES` para que `Tahorah` possa purificar).
   - Sempre que QUALQUER ação global for concluída na batalha em `scripts/battle/playable_controller.gd` (no mesmo ponto de avanço de ação onde `prayer.tick_lior` é chamado), decrementar `trapped_actions` em 1 para todas as unidades presas vivas; ao chegar em 0, remover `&"trapped"` e registrar no log que a unidade foi liberta.
   - Enquanto uma unidade estiver com `trapped_actions > 0`:
     * Ao ser aprisionada, ela perde imediatamente os atos que já estavam **em fila** (fila de planejamento/ações pendentes daquela unidade é limpa).
     * Ao chegar sua vez de agir, a prisão funciona como um **PASS automático**: ela NÃO perde os atos/reações que ainda não utilizou (preserva seus `acts_available` / estoque conforme regra de PASS), apenas pula o turno com mensagem clara no log.

RESTRIÇÕES INVIOLÁVEIS:
- NUNCA reintroduzir `affinity` (WEAK/RESIST/NULL/ABSORB foi removido em D-119).
- Em GDScript, sempre tipar variáveis vindas de nós `Control` (`var x: int = ...`, `var f: float = ...`) para evitar erro de inferência de `Variant`.
- Não alterar arquivos de lore/docs de outras sessões sem necessidade.

VERIFICAÇÃO E ENTREGA (AGENTS.md + D-120):
- Criar `tests/verify_d124_rules.gd` cobrindo: HIGH SPEED em barra normal e contra-ataque; BLEED acumulando 1x..4x e bloqueando excesso acima de 4x, redução real de cura em `heal()`, expiração e limpeza por `Tahorah`/`MEND`; Temporização de Ação global contando ações de qualquer unidade, limpeza da fila ao aprisionar e auto-PASS preservando atos não usados.
- Rodar `tests/verify_d124_rules.gd`, `tests/verify_skill_fx.gd`, `tests/verify_new_prayers.gd`, `tests/verify_playable_counter.gd` e `tests/verify_playable_pass.gd` em Godot headless.
- Auditar contra bugs/esquecimentos, corrigir tudo, incluir crítica extrema com evidências reais, fazer `git fetch origin --prune`, commitar e dar `git push origin main` imediatamente (D-120).
~~~

---

## FASE 2 — Catálogo Canônico D-124 (6 Skills + 2 Evoluções `ZAHAV`) + Migração do Survival

~~~text
Leia `AGENTS.md`, `docs/CANON_SKILLS_D124.md` (inteiro) e `docs/DECISIONS.md` (D-118, D-119, D-120, D-124).
Antes de editar, execute `git fetch origin --prune && git status --short` (Obrigação 8).

OBJETIVO DA FASE 2 — Implementar todas as mecânicas dos 6 ataques canônicos + 2 evoluções ZAHAV da D-124 no código e migrar os 5 ataques antigos do Survival (sem implementar ainda os VFX D-125 — apenas lógica, custos, alvos, dano, status e testes):

1. Substituição em `scripts/core/skill_book.gd` e migração em `scripts/survival/survival_data.gd`:
   - Substituir diretamente os 5 antigos do Survival:
     * `shadow_bite` -> `mazz_bite`
     * `fang_flurry` -> `fang_sting` (com evolução ZAHAV `fang_spine`)
     * `soul_pierce` -> `vuln_pierce`
     * `frost_breath` -> `dark_breath`
     * `void_gaze` -> `umbral_gaze`
   - Adicionar a nova skill canônica:
     * `ignoma` (com evolução ZAHAV `ignoma_esh`)
   - Atualizar todas as referências em `scripts/survival/survival_data.gd` (pool de skills, mapa de nomes hebraicos se usado pelo Survival, loadouts dos demônios) e manter os outros 22 skills exclusivos do Survival intactos.

2. Especificação exata de cada uma das 8 entradas em `SkillBook.DEFS` e `playable_controller.gd`:
   - **Mazz Bite (`&"mazz_bite"`):**
     * Custo: `1 ACT / 30% do HP máximo` (`hp_pct: 0.30`). Atualizar `SkillBook.affordable()` e `_pay_skill()` / `_planned_hp()` para calcular `ceil/round(max_hp * 0.30)` e EXIGIR `current_hp > hp_cost` (impede suicídio automático).
     * Tipo: físico, 1 alvo, `"high_speed": true` (usa regra da Fase 1).
     * Dano: `10` de dano base + `30% do HP máximo` do conjurador de dano extra (passando pela fórmula/defesa normal do combate sem ignorar defesa).
   - **Fang Sting (`&"fang_sting"`):**
     * Custo: `2 ACT / 6 EN`, físico, 1 alvo.
     * Dano: `5 + ATK` (power `5` + ATK do conjurador).
     * Efeito: aplica `BLEED` (1 acúmulo canônico) **SOMENTE no `POINT`** — se acertar no `BEAM` (blast) ou `MISS`, **NÃO** aplica `BLEED`.
   - **Fang Spine [ZAHAV] (`&"fang_spine"`, evolução ZAHAV de `fang_sting`):**
     * Custo: `3 ACT / 10 EN`, físico, **alvo alternável (2 golpes consecutivos no mesmo alvo ou intercalados em 2 alvos diferentes na mesma ação)**, `"zahav": true`, `"zahav_of": &"fang_sting"`.
     * Dano: `15 + ATK` por golpe (2 golpes; se calibrar valor, documentar claramente na crítica; padrão canônico `15 + ATK`).
     * Efeito: aplica `BLEED` (1 acúmulo) ao contato (`BEAM` ou hit normal) e `BLEED ×2` (2 acúmulos) no `POINT`.
   - **Vuln Pierce (`&"vuln_pierce"`):**
     * Custo: `1 ACT / 8 EN`, físico, 1 alvo.
     * Dano: `15 + ATK`; causa **2× de dano** se o alvo estiver realizando uma **ação não-ofensiva** (buff, cura, reza não-ofensiva, defend/rest/pass/intenção não-ofensiva anunciada ou postura ativa).
   - **Dark Breath (`&"dark_breath"`):**
     * Custo: `3 ACT / 15 EN`, mágico, **todos os inimigos**.
     * Dano: **0 de dano** (explicitamente não causa dano de HP).
     * Efeito: em cada alvo que **não desviar** (não atingir esquiva perfeita `POINT` na defesa), reduz **PP em 3** (`target.change_pp(-3)` se `target.prays`; alvos sem PP sofrem apenas a cegueira) e aplica **`BLIND` até o fim do round** (`rounds = 1`).
   - **Umbral Gaze (`&"umbral_gaze"`):**
     * Custo: `3 ACT / 15 EN`, mágico, 1 alvo (atenção: diferente do antigo `void_gaze` que era AoE, `umbral_gaze` é **1 alvo**!).
     * Dano: `15 + MAK` (respeitando `MEF`).
     * Efeito: aprisiona o alvo por **2 ações globais** (`trapped_actions = 2` + status `&"trapped"`, limpa fila atual do alvo — usando motor da Fase 1).
   - **Ignoma (`&"ignoma"`):**
     * Custo: `2 ACT / 8 EN`, mágico, 1 alvo.
     * Dano: `10 + MAK` (respeitando `MEF`) com **35% de chance de `BURN`**.
   - **Ignoma Esh [ZAHAV] (`&"ignoma_esh"`, evolução ZAHAV de `ignoma`):**
     * Custo: `3 ACT / 12 EN`, mágico, **alvo alternável (2 bolas de fogo em 1 alvo ou em 2 alvos diferentes)**, `"zahav": true`, `"zahav_of": &"ignoma"`.
     * Dano: cada bola causa `10 + MAK` (respeitando `MEF`) com **35% de chance de `BURN`** (lembrando D-118: bônus ZAHAV quando acionado via sistema ZAHAV).

3. Suporte a Seleção de Alvo Alternável (2 golpes) em `playable_controller.gd`:
   - Permitir escolher 2 alvos (podendo repetir o mesmo alvo ou alternar entre 2 inimigos distintos) para `fang_spine` e `ignoma_esh`, além de suportar execução programática/testável (passando array de alvos) e IA inimiga.
   - Em `playable_controller.gd`, garantir que skills mágicas de 1 alvo (`umbral_gaze`, `ignoma`) não caiam no caminho antigo que assumia que todo `"kind": "magic"` é AoE (`"all_foes": true/false` ou `"target_mode": "single" | "all" | "dual_alt"`).

RESTRIÇÕES INVIOLÁVEIS:
- ZERO `affinity` (D-119).
- Não quebrar skills existentes do Prólogo (`lunge`, `bleedbuff`, `heat_wave`, `energy_eat`) nem nenhuma das 29 rezas do `PrayerBook`.

VERIFICAÇÃO E ENTREGA (AGENTS.md + D-120):
- Atualizar `tests/verify_skill_fx.gd`, `tests/verify_playable_skills.gd`, `tests/verify_survival_data.gd`, `tests/verify_survival_run.gd` e criar `tests/verify_d124_skills.gd` testando TODOS os 8 ataques (incluindo: Mazz Bite bloqueado com HP <= 30% max HP; Fang Sting sem BLEED no BEAM e com BLEED no POINT; Fang Spine em 1 alvo e em 2 alvos com BLEED×1/×2; Vuln Pierce 1× vs ofensivo e 2× vs não-ofensivo; Dark Breath 0 dano + -3 PP + BLIND e esquiva intacta; Umbral Gaze dano + prisão 2 ações globais; Ignoma e Ignoma Esh 1 e 2 alvos).
- Rodar toda a suíte de testes relevante em Godot headless até 100% PASS.
- Auditar, corrigir tudo, apresentar crítica extrema com evidências, fazer `git fetch origin --prune`, commitar e dar `git push origin main` imediatamente (D-120).
~~~

---

## FASE 3 — Motor Reutilizável de VFX Não-Reza D-125 (`SkillGrotesqueFX` + Shaders GPU)

~~~text
Leia `AGENTS.md`, `docs/NON_PRAYER_VFX_STYLE.md` (inteiro), `docs/vfx_refs/d124_d125/README.md` e inspecione os 3 HTMLs canônicos em `docs/vfx_refs/d124_d125/`.
Antes de editar, execute `git fetch origin --prune && git status --short` (Obrigação 8).

OBJETIVO DA FASE 3 — Construir a fundação visual 100% fiel à estética D-125 e aos HTMLs aprovados (sem implementar ainda as 8 coreografias específicas das Fases 4 e 5, ou apenas com harness de validação das primitivas):

1. Shader GPU de Interferência Hipnótica — `assets/shaders/hypnotic_moire.gdshader`:
   - Deve reproduzir **matematicamente 1:1** tanto `drawHypnoticField` (modo `0` = radial elíptico com suporte a `dark_bias`) quanto `drawBreathConeMoire` (modo `1` = cone exalado da garganta com suporte a `dir_x = +1.0` ou `-1.0` para espelhamento), avaliado na GPU em **grade pixel-crisp de 5×5 pixels** (`floor(local_px / 5.0) * 5.0`), mantendo **60 FPS** estáveis no Godot 4 (NUNCA usar loop GDScript por pixel!).
   - Uniforms exatos: `mode` (`0` radial / `1` breath_cone), `time_val`, `env`, `dark_bias`, `rect_size`, `mouth_pos`, `reach`, `dir_x`, `col_hi`, `col_accent`, `col_dark`.
   - Equações obrigatórias idênticas a `docs/NON_PRAYER_VFX_STYLE.md` §3.2 e `docs/vfx_refs/d124_d125/d124_skills_vfx_v3.html` / `v4.html`:
     * Radial: `v = sin(dist * 0.21 - t * 14.0 + sin(ang * 4.0 + t * 5.0) * 2.1) + cos((dx * 0.1 - dy * 0.08) + sin(py * 0.08 + t * 8.0) * 1.9)`
     * Cone: `half_h = 16.0 + dx * 0.21`, `v = sin(dx * 0.095 - t * 19.0 + sin(py * 0.1 + t * 9.0) * 2.3) + cos((py - mouth_y) * 0.13 + sin(dx * 0.055 - t * 11.0) * 2.2)`
   - Limiares de cor e alpha exatos (`0.30` / `0.26` / `0.22`, cristas `1.30` / `1.55`, médio `0.72` / `0.85` / `0.78`, base `#050208` ou `#030106`).

2. Shader GPU de Scanline Warp do Alvo — `assets/shaders/target_fever_warp.gdshader`:
   - Reproduzir `wx = sin(sy * 0.18 + t * 20.0) * warp_amp + cos(sy * 0.09 - t * 12.0) * warp_amp * 0.5` em faixas horizontais de ~3.5px + suporte a `invert_mix` (flash osso `#e8ddd0` / `#efe6d5` nos impact frames) preservando a silhueta/cor do sprite alvo (`scripts/battle/battle_effects.gd` / `playable_hud.gd`).

3. Nó Reutilizável `scripts/battle/skill_grotesque_fx.gd` (`class_name SkillGrotesqueFX` extends `Node2D` ou `Control` equivalente a `PrayFX`):
   - Registrar as **paletas canônicas exatas** de `docs/NON_PRAYER_VFX_STYLE.md` §4:
     * `PAL_BLOOD = {accent: "#a81c2e", hi: "#efe6d5", hi_soft: "#e8ddd0", deep: "#24050a"}`
     * `PAL_ZAHAV_BLOOD = {accent: "#a81c2e", hi: "#ffd84a", deep: "#26080d"}`
     * `PAL_ABYSS_DARK = {accent: "#361c52", hi: "#9b8ab0", hi_breath: "#a997bd", deep: "#09030f"}`
     * `PAL_FIRE_NORMAL = {accent: "#c94c14", hi: "#f2d9b6", deep: "#240903"}`
     * `PAL_ZAHAV_FIRE = {accent: "#d95b16", hi: "#ffd84a", deep: "#290d04"}`
     * `FIRE_HEBREW = ["#ff7a1f", "#ffd84a", "#ffffff"]`
   - Implementar as primitivas **1:1 dos HTMLs**:
     * `static func sketch_hash(n: float) -> float`: `var s := sin(n * 127.1 + 311.7) * 43758.5453; return s - floor(s)`
     * `func sketchy_pts(pts: PackedVector2Array, f_idx: int, jitter: float = 2.4) -> PackedVector2Array`
     * `func draw_sketch_shape(pts, f_idx, pal, jitter := 2.4, fill_col := Color("050208"), line_w := 2.0, alpha := 1.0)` (preenchimento + traço 1 `pal.hi` + traço 2 `f_idx + 77`, `jitter * 1.45`, `pal.accent`, `maxf(1.1, line_w * 0.65)`)
     * `func draw_sketch_eye(cx, cy, rx, ry, f_idx, pal, closed := false, dark_iris := false, alpha := 1.0)` (12 vértices, pupila móvel ou X de cegueira)
     * `func draw_sketch_flame(cx, cy, scale, f_idx, pal, fill_col, alpha := 1.0)` (exatamente os 11 vértices de `v3`/`v4` + língua interna `0.52`/`0.55` em `pal.accent`, SEM olho)
     * `func draw_hebrew_tri_word(word: String, center: Vector2, px: int, alpha: float)` — **APENAS** para híbridos hebraicos (`Ignoma Esh`), usando `font.get_string_size()` com kerning proporcional RTL seguro (como em `PrayFX._draw_palette_word`), sem nunca misturar ASCII na mesma chamada!
     * Gerenciador de instâncias de campo Moiré (camada atrás dos sprites/rabiscos) + véu de escurecimento do palco (`darken` recortado estritamente entre HUD superior `y=22` e Battle Log `BATTLE_LOG_RECT.position.y`) + `camera_shake` + `trigger_target_warp(unit, amp, duration, invert_duration)`.
   - **Regra Estrutural Obrigatória (D-125):** helper `palette_for(family: StringName, is_zahav: bool) -> Dictionary` que **NUNCA** retorna `#ffd84a` quando `is_zahav == false`.
   - Instanciar `SkillGrotesqueFX` no `playable_controller.gd` com `z_index` rigorosamente abaixo do `DamageLayer` (`z_index = 100`) e das janelas do HUD/Battle Log, e integrar `is_busy()` no fluxo de espera de VFX.

VERIFICAÇÃO E ENTREGA (AGENTS.md + D-120):
- Criar `tests/verify_grotesque_fx_core.gd` validando: parse dos 2 shaders (`.gdshader`), `sketch_hash` determinístico, `palette_for(..., false)` garantindo ZERO dourado em ataques normais, `palette_for(..., true)` retornando `#ffd84a`, execução limpa de todas as primitivas sem erros/leaks, e integração em `playable_controller.gd`.
- Rodar testes em Godot headless, auditar, corrigir tudo, incluir crítica extrema com evidências, fazer `git fetch origin --prune`, commitar e dar `git push origin main` imediatamente (D-120).
~~~

---

## FASE 4 — Coreografia 1:1 dos 4 Ataques Físicos (`Mazz Bite`, `Fang Sting`, `Fang Spine [ZAHAV]`, `Vuln Pierce`)

~~~text
Leia `AGENTS.md`, `docs/NON_PRAYER_VFX_STYLE.md` (§5) e `docs/vfx_refs/d124_d125/README.md`.
ABRA E LEIA LINHA POR LINHA as funções canônicas exatas nos HTMLs salvos no repositório:
- `docs/vfx_refs/d124_d125/d124_skills_vfx_v2.html`: `renderMazzBite()` (linhas 400–460) e `renderFangSting()` (linhas 462–508)
- `docs/vfx_refs/d124_d125/d124_skills_vfx_v3.html`: `renderFangSpine()` (linhas 410–493) e `renderVulnPierce()` (linhas 718–757)
⚠️ ATENÇÃO: NÃO use `renderFangSpine()` nem `renderVulnPierce()` do `v2.html`! As versões aprovadas deles estão no `v3.html`!
Antes de editar, execute `git fetch origin --prune && git status --short` (Obrigação 8).

OBJETIVO DA FASE 4 — Portar com fidelidade 1:1 quadro-a-quadro para `scripts/battle/skill_grotesque_fx.gd` e ligar ao `playable_controller.gd` os 4 ataques físicos da D-124:

1. `play_mazz_bite(caster, target)` — fiel 1:1 a `v2.html::renderMazzBite()`:
   - Paleta `PAL_BLOOD` (`#a81c2e` / `#efe6d5`, ZERO dourado). Duração `2.35s`, `hitT = 0.56s`, boil 12 FPS (`qt`, `f_idx`).
   - Moiré radial crescente (`48 + env * 74`, `42 + env * 62`) sob o alvo.
   - Mandíbula superior e inferior assimétrica de 11 dentes (`i = -5..5`, caninos `|i| == 2` com `×1.55`) fechando de `gap = 52` até `0` com curva `pow(..., 1.8)`.
   - No impacto (`0.56s`): shake `±8px` por `0.25s`, inversão osso `0.14s`, warp `env * 11`, e 3 olhos grotescos (`draw_sketch_eye`) surgindo ao redor do alvo por `0.65s`.
   - Nota: no jogo real, a mini barra decorativa do HTML NÃO duplica a barra real de ritmo — o `RhythmBar` real (com `HIGH SPEED +20%` da Fase 1) já cumpre esse papel!

2. `play_fang_sting(caster, target, landed_point: bool)` — fiel 1:1 a `v2.html::renderFangSting()`:
   - Paleta `PAL_BLOOD` (ZERO dourado). Duração `2.35s`, `hitT = 0.50s`.
   - Ferrão/dedo ósseo diagonal perfurando o alvo (`x0 = target.x - 155 * dir`, `y0 = target.y + 62` → `x1 = x0 + 285 * ext * dir`, `y1 = y0 - 115 * ext`), espelhando `dir = -1` quando inimigo ataca herói.
   - No impacto: fenda achatada de Moiré (`rx = 88 * env`, `ry = 26 * env`), inversão `0.14s`, warp `env * 8`, e 8 respingos triangulares de sangue com gravidade `85 * age * age` (intensificados quando `landed_point == true` e aplica `BLEED`).

3. `play_fang_spine(caster, targets: Array[BattleUnit])` — fiel 1:1 a `v3.html::renderFangSpine()`:
   - Paleta `PAL_ZAHAV_BLOOD` (`#a81c2e` / **`#ffd84a` outline dourado ZAHAV!**). Duração `2.70s`, `hits` em `0.44s` e `1.04s`.
   - Escurecimento do palco `0.16`.
   - Moiré radial em cada alvo no momento do respectivo hit (`76 * env + 18`, `60 * env + 14`).
   - Coluna vertebral articulada de **10 vértebras com apófise espinhosa** arqueando em parábola (`-sin(p * PI) * 72`) do 1º alvo até o 2º alvo entre `0.42s` e `1.38s` (quando ambos os hits forem no **mesmo alvo**, fazer o arco vertebral erguer-se sobre o alvo e mergulhar de volta nele, mantendo as 10 vértebras legíveis!).
   - Em cada alvo atingido: **4 pares de costelas curvadas** (`k = -1.5, -0.5, 0.5, 1.5`, ambos os lados) abrindo como gaiola perfurante + 8 gotas de sangue rabiscadas com gravidade `70 * age * age` + inversão `0.14s` + warp `env * 9`.

4. `play_vuln_pierce(caster, target, doubled: bool)` — fiel 1:1 a `v3.html::renderVulnPierce()`:
   - Paleta `PAL_BLOOD` (`#a81c2e` / `#e8ddd0`, **ESTRITAMENTE ZERO DOURADO!**). Duração `2.45s`, `hitT = 0.64s`.
   - Escurecimento `0.14`, Moiré radial (`44 + env * 86`, `36 + env * 66`).
   - Antes do impacto: olho aberto vulnerável (`rx = 26 * g, ry = 12 * g`) tremendo no centro do alvo (mais dramático quando `doubled == true`, indicando a abertura da ação não-ofensiva).
   - No impacto: agulha/garra grotesca horizontal atravessando de `-190` a `+195` + **10 estilhaços rabiscados** explodindo radialmente + inversão `0.16s` + warp `env * 12`.

5. Integração no `scripts/battle/playable_controller.gd`:
   - Disparar os 4 VFX no lugar de qualquer efeito genérico antigo tanto para ações do jogador quanto para inimigos (incluindo Survival).
   - Garantir que `mazz_bite`, `fang_sting`, `fang_spine` e `vuln_pierce` NUNCA disparem letras hebraicas.

VERIFICAÇÃO VISUAL E ENTREGA (AGENTS.md + D-120):
- Criar teste automatizado + script de captura headless que renderize quadros-chave (antes do hit, exato impact frame, pós-impacto) dos 4 ataques no palco real 816×624 do Godot e **inspecionar cada PNG capturado** procurando desalinhamentos, cortes no HUD/Battle Log, outline dourado indevido em ataque normal ou desvios dos HTMLs.
- Corrigir qualquer defeito encontrado, rodar os testes Godot headless, apresentar os quadros/evidências reais e a crítica extrema, fazer `git fetch origin --prune`, commitar e dar `git push origin main` imediatamente (D-120).
~~~

---

## FASE 5 — Coreografia 1:1 dos 4 Ataques Mágicos (`Dark Breath v2`, `Umbral Gaze`, `Ignoma`, `Ignoma Esh [ZAHAV]`) + Showcase Completo

~~~text
Leia `AGENTS.md`, `docs/NON_PRAYER_VFX_STYLE.md` (§5) e `docs/vfx_refs/d124_d125/README.md`.
ABRA E LEIA LINHA POR LINHA as funções canônicas exatas nos HTMLs salvos no repositório:
- `docs/vfx_refs/d124_d125/d124_skills_vfx_v4.html`: `renderDarkBreath()` (linhas 401–527) e `renderIgnomaEsh()` (linhas 528–596)
- `docs/vfx_refs/d124_d125/d124_skills_vfx_v3.html`: `renderUmbralGaze()` (linhas 670–716) e `renderIgnoma()` (linhas 553–599)
⚠️ ATENÇÃO: NÃO use `renderDarkBreath()` do `v2`/`v3`, NÃO use `renderUmbralGaze()`/`renderIgnoma()` do `v2`, e NÃO use `renderIgnomaEsh()` do `v2`/`v3` (o `v4` corrigiu o sincronismo de altura do Moiré com os arcos `52` e `82` e a ordem de camadas da boca no `Dark Breath v2`!).
Antes de editar, execute `git fetch origin --prune && git status --short` (Obrigação 8).

OBJETIVO DA FASE 5 — Portar com fidelidade 1:1 quadro-a-quadro para `scripts/battle/skill_grotesque_fx.gd` e ligar ao `playable_controller.gd` os 4 ataques mágicos da D-124 + entregar showcase final de todos os 8 ataques:

1. `play_dark_breath(caster, targets: Array[BattleUnit], dodged_ids: Array[StringName])` — fiel 1:1 a `v4.html::renderDarkBreath()`:
   - Paleta `PAL_ABYSS_DARK` (`#361c52` / `#a997bd`, ZERO dourado). Duração `2.95s`, `breathStart = 0.26s`, `darken = 0.48`.
   - **ORDEM EXATA DE CAMADAS (CRÍTICA!):**
     * **Camada 0 (atrás do sopro):** garganta negra funda (`#020005`) da boca de perfil (`mx = 104` se jogador conjura com `dir_x = +1`; espelhada à direita com `dir_x = -1` se inimigo conjura).
     * **Camada 1:** shader Moiré modo `1` (`breath_cone`) saindo de dentro da garganta (`mx - 6 * dir_x`, `reach` crescendo a `640 px/s`, `half_h = 16 + dx * 0.21`).
     * **Camada 2:** alvos atingidos sequencialmente conforme o sopro chega (`hitT = breathStart + abs(f.x - mx) / 640.0`). Alvos que **NÃO** estão em `dodged_ids` recebem warp `env * 11` (SEM flash de inversão, pois é 0 dano!) e olho riscado em X (`draw_sketch_eye(..., closed=true)`) acima da cabeça. Alvos que **desviaram** (`dodged_ids`) NÃO recebem olho riscado nem `-3 PP`/`BLIND`.
     * **Camada 3:** 28 correntes de vento rabiscadas ondulantes (`streams`, 9 pontos por fita) + 22 nuvens negras rabiscadas (`puffs`, polígonos de 9 vértices expandindo de `0.45×` a `1.90×`) originando-se **de dentro da garganta** (`mx - 4 * dir_x` e `mx + 2 * dir_x`).
     * **Camada 4 (na frente do sopro):** maxilar superior e inferior de perfil com presas/dentes tortos escancarando (`jaw = 44 * open + sin(t * 26) * 2.6`) enquadrando o ar que sai da boca!

2. `play_umbral_gaze(caster, target)` — fiel 1:1 a `v3.html::renderUmbralGaze()`:
   - Paleta `PAL_ABYSS_DARK` (`#361c52` / `#9b8ab0`, ZERO dourado). Duração `2.85s`, `hitT = 0.62s`.
   - Escurecimento forte do palco `0.56 * env` + Moiré radial com **`dark_bias = true`** (`96 * env`, `78 * env`).
   - Olho gigante rabiscado no chão sob os pés do alvo (`rx = 76 * g`, `ry = 17 * g`, **`dark_iris = true`** com esclera `#b8abc9` e pupila `#030106`).
   - No impacto (`0.62s`): inversão breve `0.12s`, warp `env * 8`, e **5 espinhos/dedos curvos** (`ox = -48, -24, 0, 24, 48`, altura `92` e `130px`, curvatura `bend = (i - 2) * -10`, preenchimento `#030106`) erguendo do olho ao redor do alvo.

3. `play_ignoma(caster, target)` — fiel 1:1 a `v3.html::renderIgnoma()`:
   - Paleta `PAL_FIRE_NORMAL` (`#c94c14` / `#f2d9b6` / `#240903`, **ZERO dourado ZAHAV, ZERO olho, ZERO hebraico!**). Duração `2.45s`, `hitT = 0.62s`.
   - Projétil em arco parabólico (`52px`) do conjurador ao alvo com Moiré térmico seguindo o projétil + rastro de chama menor (`scale = 0.55`, alpha `0.55`) + chama principal (`draw_sketch_flame`, `scale = 1.0`).
   - No impacto: inversão `0.14s`, warp `env * 10`, Moiré expandindo (`44 + (1 - env) * 96`) e **3 línguas de chama rabiscadas** (`1.45 + k * 0.7` central + 2 laterais `0.85` se afastando) erguendo sobre o alvo.

4. `play_ignoma_esh(caster, targets: Array[BattleUnit])` — fiel 1:1 a `v4.html::renderIgnomaEsh()`:
   - Paleta `PAL_ZAHAV_FIRE` (`#d95b16` / **`#ffd84a` outline dourado ZAHAV!** / `#290d04`) + `FIRE_HEBREW` (`#ff7a1f`, `#ffd84a`, `#ffffff`). **ÚNICO ataque da D-124 com letras hebraicas (`אש`).**
   - Duração `2.85s`, escurecimento `0.22`, 2 orbes (`startT = 0.08 / hitT = 0.62` com arco `52px`; `startT = 0.44 / hitT = 1.04` com arco `82px`) — suportando tanto **2 alvos diferentes** quanto **2 impactos no mesmo alvo** (com arcos `52px` e `82px` distinguindo visualmente as duas bolas!).
   - O Moiré térmico em voo DEVE usar **EXATAMENTE** o mesmo arco `(oi == 0 ? 52 : 82)` de cada chama (bug já corrigido no `v4.html`).
   - Em voo: `draw_sketch_flame(..., scale = 0.95)` + `draw_hebrew_tri_word("אש", ..., 18, 0.95)`.
   - No impacto de cada bola: chama expande sem preenchimento (`1.35 + age * 1.1` por `0.55s`) + **38 letras hebraicas tricolores** (1/3 alternando `א`/`ש`, 2/3 aleatórias do alfabeto hebraico, gravidade `85 * age * age`) + `draw_hebrew_tri_word("אש", ..., 32, 1 - age / 0.95)` subindo + inversão `0.14s` + warp `env * 9`.

5. Ligação Final, Documentação e Showcase Real no Godot:
   - Ligar os 4 ataques mágicos no `playable_controller.gd` (jogador e inimigos) e garantir que nenhum deles use o antigo `skill_letters.gd` (apenas `Ignoma Esh` exibe hebraico pelo próprio `SkillGrotesqueFX`).
   - Rodar **TODA** a suíte de testes Godot headless (`tests/verify_*.gd` e `tests/test_*.gd`) garantindo ZERO regressões.
   - Gerar um vídeo showcase real em 30 FPS (e/ou grade de keyframes PNG) rodando os **8 ataques D-124/D-125 no palco real 816×624 do Godot**, inspecionar visualmente todos os quadros-chave comparando com os HTMLs, e corrigir qualquer desvio antes de entregar.
   - Atualizar o cabeçalho de `docs/CANON_SKILLS_D124.md` e `docs/DECISIONS.md` (D-124/D-125) de "NÃO IMPLEMENTADO" para **"IMPLEMENTADO (aguardando validação visual final do criador no Godot)"**.
   - Fazer auditoria extrema completa com evidências reais, `git fetch origin --prune`, commitar e dar `git push origin main` imediatamente (D-120).
~~~

---

## Resumo Rápido da Ordem de Execução

| Fase | Foco | Arquivos Principais | Critério de Saída |
|---|---|---|---|
| **Fase 1** | Regras globais D-124 (`HIGH SPEED`, `BLEED`, Temporização de Ação) | `battle_unit.gd`, `skill_fx.gd`, `rhythm_bar.gd`, `compact_rhythm_bar.gd`, `counter_rhythm_bar.gd`, `playable_controller.gd` | `verify_d124_rules.gd` + testes de combate PASS + commit/push |
| **Fase 2** | 6 skills + 2 ZAHAV + migração Survival | `skill_book.gd`, `survival_data.gd`, `playable_controller.gd` | `verify_d124_skills.gd` + Survival tests PASS + commit/push |
| **Fase 3** | Motor D-125 (`SkillGrotesqueFX` + 2 shaders GPU) | `skill_grotesque_fx.gd`, `hypnotic_moire.gdshader`, `target_fever_warp.gdshader` | `verify_grotesque_fx_core.gd` PASS + ZERO ouro fora de ZAHAV + commit/push |
| **Fase 4** | 4 físicos 1:1 (`Mazz Bite`, `Fang Sting`, `Fang Spine`, `Vuln Pierce`) | `skill_grotesque_fx.gd`, `playable_controller.gd` | Keyframes Godot inspecionados vs `v2`/`v3` HTML + testes PASS + commit/push |
| **Fase 5** | 4 mágicos 1:1 (`Dark Breath v2`, `Umbral Gaze`, `Ignoma`, `Ignoma Esh`) + showcase | `skill_grotesque_fx.gd`, `playable_controller.gd`, `CANON_SKILLS_D124.md`, `DECISIONS.md` | Suíte inteira PASS + showcase 8/8 no Godot + commit/push |
