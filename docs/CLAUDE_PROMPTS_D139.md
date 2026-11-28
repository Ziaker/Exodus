# Guia e Prompts Faseados de Implementação — D-139 (Claude / Agentes)

**Decisões:** D-139 · D-125 · D-137 · 2026-11-27  
**Status:** **CANÔNICO — DESIGN E VISUAIS (4/4) APROVADOS DE PRIMEIRA; PRONTO PARA IMPLEMENTAÇÃO EM 3 FASES**  
**Referências obrigatórias antes de codar:**
- Especificação mecânica fechada: [`docs/CANON_SKILLS_D139.md`](CANON_SKILLS_D139.md)
- Estilo visual oficial não-reza: [`docs/NON_PRAYER_VFX_STYLE.md`](NON_PRAYER_VFX_STYLE.md)
- HTML canônico aprovado (4/4, modo Inimigos + 3 Aliados Survival): [`docs/vfx_refs/d139/d139_skills_vfx_canon.html`](vfx_refs/d139/d139_skills_vfx_canon.html) e [`docs/vfx_refs/d139/README.md`](vfx_refs/d139/README.md)
- Dossiê de construção e validação: [`docs/VALIDATION_LOG_D139.md`](VALIDATION_LOG_D139.md)
- Regras de agentes (auditoria, testes só no `HEAD` atual D-130, commit imediato D-120): [`AGENTS.md`](../AGENTS.md)

> [!IMPORTANT]
> **Regras invioláveis antes de começar:**
> 1. **D-119 / D-138:** nunca introduzir campo `affinity` em nenhuma skill.
> 2. **D-130:** sempre executar `git fetch origin --prune` e rodar testes/capturas apenas sobre o `HEAD` atual de `main`.
> 3. **D-125:** `#ffd84a` (dourado) existe **exclusivamente** em `Stone Body [ZAHAV]`; **zero letras hebraicas** em todas as 4 skills da D-139.
> 4. **HUD adaptativo de status (`a73da1c`):** o repositório já possui gravuras monocromáticas adaptativas de status nos cartões/inimigos — incluir o ícone/gravura de **`STURDY`** sem regredir as 28 gravuras existentes.
> 5. **Pendências sinalizadas ao implementador:** (a) ao remover `frost_lance` de `PAZUZU` em `survival_data.gd`, confirmar/registrar se Pazuzu fica só com `ember_touch` ou recebe skill provisória do pool atual; (b) `Blade Dance` usa `15 PHYS (+ATK)` por golpe conforme o protótipo aprovado.

---

## Fase 1 — Motor de Combate D-139 (`STURDY`, `IMEDIATO` em Skills, `Blade Dance`: `ALL ACT → ACT+1`, Intercalado, `NO COUNTER`, Cooldown 2 Rounds)

```text
Leia AGENTS.md, docs/CANON_SKILLS_D139.md e docs/COMBAT_SPEC.md.
Execute `git fetch origin --prune` e trabalhe apenas sobre a árvore principal atualizada (`main`, D-130).

Implemente a FASE 1 da D-139 (regras de motor de combate sem alterar ainda os VFX):

1. Novo buff positivo `STURDY` em `scripts/core/battle_unit.gd` e `scripts/core/skill_fx.gd`:
   - Adicione estado de batalha em `BattleUnit`:
     - `sturdy_def_bonus: int = 0` (usado por `Stone Body [ZAHAV]`: `+15 DEF` enquanto `STURDY` permanecer).
     - Status `&"sturdy"` armazenado em `unit.statuses` com duração `1` rodada (expira no fim do round atual no `SkillFx.tick(unit)`).
     - Integre `sturdy_def_bonus` em `effective_def()` (somente enquanto `has_status(&"sturdy")`, sem mutar `stats.defense` nem `sp_base()`).
     - Ao remover `&"sturdy"` (por expiração no fim do round, consumo ao bloquear efeito debilitante, ou dispell inimigo), zere automaticamente `sturdy_def_bonus = 0` dentro de `BattleUnit.remove_status(id)` (ou helper `clear_sturdy()`).
   - **Bloqueio de efeito debilitante (consumindo `STURDY`):**
     - Crie helper em `SkillFx` (ex.: `try_block_debilitating(target: BattleUnit, kind: StringName) -> bool`): quando `target.has_status(&"sturdy")` e um efeito debilitante tentar ser aplicado (`SkillFx.NEGATIVE_STATUSES`, `burn`, `bleed`, `apply_weaken`, `mark_of_sun`, `paralyzed_acts`, `trapped_actions`), bloqueia a aplicação daquele efeito, remove `&"sturdy"` (zerando `sturdy_def_bonus`), retorna `true` e sinaliza no log/evento que `STURDY` bloqueou o efeito e se quebrou.
     - Conecte esse guard em `SkillFx.apply_status`, `SkillFx.apply_weaken`, aplicação de `bleed`/`burn`/`trapped`/`paralyzed`/`mark_of_sun` no `playable_controller.gd` (sem quebrar `aegis_iris` D-129 — se tiver ambos, respeite ordem determinística e documente).
   - **Dispell de buffs positivos:**
     - Adicione helper `SkillFx.dispel_positive(unit: BattleUnit) -> int` (ou conecte ao dispell inimigo existente, se houver) removendo `&"sturdy"` (e zerando `sturdy_def_bonus`). Garanta que `SkillFx.cleanse_all(unit)` (`Tahorah`, D-112) continua preservando `&"sturdy"` (pois `STURDY` é efeito positivo, não negativo).
   - **Escudo anti-interrupção no sistema de ponteiros (`playable_controller.gd`):**
     - Nos pontos de contra-ataque (`_execute_counter`, `_enemy_counter`, `_interrupt` e resolução de empate `_tie_report`): quando o atacante cujo turno está sendo contra-atacado possui `has_status(&"sturdy")`:
       - O dano do contra-ataque e efeitos não-debilitantes ainda ocorrem normalmente;
       - Efeitos debilitantes do contra-ataque são interceptados por `try_block_debilitating` (consumindo `STURDY`);
       - A ação do usuário com `STURDY` **NÃO é interrompida** (não cancela a ação atual, não limpa a fila restante nem concede `+1 ACT` por fila perdida ao oponente). Registre claramente no Battle Log (`"STURDY holds firm — %s is not interrupted!"`).

2. Palavra-chave `IMEDIATO` para habilidades do `SkillBook` (`playable_controller.gd`):
   - Estenda a execução de skills com `"immediate": true` (como `Rock Body` e `Stone Body [ZAHAV]`): ao escolher a skill no menu (ou quando a IA a anuncia), ela paga `1 ACT` e `EN` e **resolve imediatamente sem entrar em fila e sem janela de reação/contra-ataque** (seguindo D-118), devolvendo o controle ao mesmo combatente se ainda tiver `ACT` restantes no turno.
   - Reutilize/alinhe com o caminho existente de ações imediatas (`_immediate_command` / `D-104` / `D-118`).

3. Regras de `Blade Dance` em `scripts/core/battle_unit.gd`, `scripts/core/skill_book.gd` e `scripts/battle/playable_controller.gd`:
   - **Cooldown por skill em `BattleUnit`:** adicione `skill_cooldowns: Dictionary = {}` (`StringName -> int`, decrementado em 1 no fim de cada round). Uma skill com `cooldown_rounds: 2` usada no Round 1 grava cooldown `2` (ao virar para o Round 2 fica `1` → bloqueada; ao virar para o Round 3 fica `0` → liberada). Atualize `SkillBook.affordable()` (ou helper dedicado `can_use_skill(unit, skill)`) e o menu do jogador/IA para bloquear skills em cooldown mostrando motivo claro (`CD 1R`).
   - **`ALL ACT → ACT + 1` golpes (`"all_acts": true`, `"extra_hit": 1`):**
     - Ao selecionar `Blade Dance`, exige `acts_left >= 1` e `0 EN`, consome **todos** os `acts_left` restantes do turno (fechando a fila), e agenda exatamente `acts_spent + 1` golpes (ex.: `4 ACT → 5 golpes`, `2 ACT → 3 golpes`).
   - **Alvo Intercalado (`targets: "interleaved"`):**
     - Cada golpe alterna automaticamente entre os alvos vivos do lado oposto (ex.: `0 → 1 → 2 → 0 → 1` com 3 vivos; `0 → 1 → 0 → 1 → 0` com 2 vivos; repete o único vivo se só houver 1). Se um alvo cair no meio da sequência, continua intercalando apenas os vivos restantes; encerra se todos caírem.
   - **Sem reação ofensiva (`"no_counter": true`):**
     - Durante cada golpe de `Blade Dance`, o alvo (herói ou inimigo) **pode usar `DEFEND`** normalmente na barra de defesa, mas **`COUNTER` e reações ofensivas ficam bloqueados** (`_enemy_counter_roll` retorna `false` e menu de reação do herói desabilita/oculta `COUNTER`).

4. Testes e auditoria obrigatória:
   - Crie `tests/verify_d139_rules.gd` cobrindo 100% das regras acima:
     - `STURDY`: expira no fim do round (`1` tick), impede interrupção no `COUNTER` mantendo fila/ação e ainda recebendo dano, bloqueia efeito debilitante consumindo `STURDY`, `+15 DEF` de `Stone Body` ativo somente enquanto `STURDY` existir (cai ao expirar, ao quebrar em debuff e ao sofrer `dispel_positive`), e preservado por `Tahorah`.
     - `IMEDIATO`: `Rock Body` / `Stone Body` resolvem sem reação e permitem continuar gastando os `ACT` restantes no turno.
     - `Blade Dance`: consome `1..4 ACT` gerando `2..5` golpes a `0 EN`, intercala alvos vivos (1, 2 e 3 alvos, incluindo alvo morrendo no meio), bloqueia `COUNTER` permitindo `DEFEND`, e aplica cooldown exato (usou Round 1 → bloqueado Round 2 → liberado Round 3).
   - Rode `verify_d139_rules.gd`, `verify_d131_rules.gd`, `verify_d124_rules.gd`, `verify_skill_fx.gd` e `verify_new_prayers.gd` no Godot headless sobre o `HEAD` atual (D-130).
   - Audite, corrija qualquer defeito e commite + push imediatamente (D-120).
```

---

## Fase 2 — Catálogo Canônico D-139 (`skill_book.gd`), Remoção Global de `Frost Lance`, Migração `stone_grasp → rock_body` e Ícone `STURDY` no HUD

```text
Leia AGENTS.md, docs/CANON_SKILLS_D139.md, docs/CANON_BOUNDARY.md e confirme que a Fase 1 da D-139 está em `origin/main`.

Implemente a FASE 2 da D-139:

1. Atualize `scripts/core/skill_book.gd` (ZERO campo `affinity`, taxonomia oficial `cat`/`dmg_type`/`targets`, todas com `"grotesque": true`):
   - **Promover `twin_fang`:** `"TWIN FANG"`, `2 ACT / 5 EN / PHYS / 1T`, `dmg_type: "PHYS"`, `power: 5`, `marks: [0.35, 0.65]`, `fx: {"combo": 0.5}`, `"grotesque": true`.
   - **Rework `blade_dance`:** `"BLADE DANCE"`, `all_acts: true`, `extra_hit: 1`, `acts: 1` (mínimo), `en: 0`, `cat: "PHYS"`, `dmg_type: "PHYS"`, `targets: "interleaved"`, `power: 15`, `no_counter: true`, `cooldown_rounds: 2`, `"grotesque": true`.
   - **Substituir `stone_grasp` por `rock_body` + adicionar ZAHAV `stone_body`:**
     - `rock_body`: `"ROCK BODY"`, `1 ACT / 10 EN / STAT / SELF`, `kind: "buff"`, `immediate: true`, `grotesque: true`, `zahav_to: &"stone_body"`, `fx: {"sturdy": true, "sturdy_def": 0, "rounds": 1}`.
     - `stone_body`: `"STONE BODY"`, `1 ACT / 25 EN / STAT / SELF`, `kind: "buff"`, `immediate: true`, `grotesque: true`, `zahav: true`, `zahav_of: &"rock_body"`, `fx: {"sturdy": true, "sturdy_def": 15, "rounds": 1}`.
     - Registre `&"stone_grasp": &"rock_body"` em `SkillBook.LEGACY_IDS` para migrar automaticamente saves antigos do Survival/Progresso.
   - **Remover `frost_lance` no geral:**
     - Remova `&"frost_lance"` de `SkillBook.DEFS`, `SurvivalData.SURVIVAL_SKILLS`, `SurvivalData.HEBREW_SKILLS` e qualquer referência em `scripts/` e `tests/` (`git grep frost_lance`).
     - Em `SkillBook.migrate_ids(skills)`: descarte/filtre `&"frost_lance"` caso apareça em saves antigos (sem quebrar o carregamento de runs antigas).
     - Em `SurvivalData.DEMONS` (`PAZUZU`, `survival_data.gd`): remova `&"frost_lance"` da ficha de Pazuzu; verifique se algum teste exige ≥ 2 skills por demônio — se exigir, dê uma skill substituta canônica coerente (ex.: `&"twin_fang"`) e registre explicitamente na crítica para o autor confirmar.
     - Em `SurvivalData.DEMONS` (`BARONG`): atualize `&"stone_grasp"` para `&"rock_body"` (e `HEBREW_SKILLS` / `SURVIVAL_SKILLS` igualmente).

2. Integração ao HUD adaptativo de status (`scripts/battle/playable_hud.gd` e galeria de gravuras do commit `a73da1c`):
   - Adicione a entrada visual do status positivo **`&"sturdy"`** (gravura monocromática do escudo hexagonal de pedra com fissura, tag `STURDY` / `STURDY +15`, cor de buff positivo) ao sistema adaptativo `FULL → SHORT → ICON`, mantendo intocadas todas as 28 gravuras anteriores.
   - Garanta que `Blade Dance` em cooldown aparece desabilitada no menu com indicação clara (`CD 1R`).

3. Testes e auditoria obrigatória:
   - Crie `tests/verify_d139_skills.gd` validando todas as 4 entradas (`twin_fang`, `blade_dance`, `rock_body`, `stone_body`), migração `stone_grasp → rock_body`, ausência total de `frost_lance` em `SkillBook`/`SurvivalData` (com migração segura de save legado contendo `frost_lance`), `IMEDIATO`, `ZAHAV` metadata e renderização do ícone `STURDY` no HUD.
   - Rode toda a suíte relevante (`verify_d139_skills.gd`, `verify_d139_rules.gd`, `verify_survival_data.gd`, `verify_d131_skills.gd`, `verify_d124_skills.gd`, `verify_playable_feedback.gd`) sobre o `HEAD` atual, corrija qualquer regressão e commite + push (D-120).
```

---

## Fase 3 — Coreografias VFX 1:1 em `SkillGrotesqueFX` (Inimigos + 3 Cartões Aliados Survival)

```text
Leia AGENTS.md, docs/NON_PRAYER_VFX_STYLE.md (§4 e §5.3), docs/VALIDATION_LOG_D139.md e
docs/vfx_refs/d139/README.md + docs/vfx_refs/d139/d139_skills_vfx_canon.html.
Confirme que as Fases 1 e 2 da D-139 estão em `origin/main`.

Implemente a FASE 3 da D-139 em `scripts/battle/skill_grotesque_fx.gd` e `scripts/battle/playable_controller.gd`,
com fidelidade 1:1 absoluta ao HTML canônico aprovado (4/4):

1. Novas paletas canônicas em `SkillGrotesqueFX` (sem alterar as de D-124/D-131):
   - `PAL_BLADE`: `accent: Color("8c1d30")`, `hi: Color("dfe4ee")`, `deep: Color("17070c")` (NORMAL — zero ouro)
   - `PAL_ZAHAV_STONE`: `accent: Color("8c7252")`, `hi: Color("ffd84a")`, `deep: Color("1b140d")` (ZAHAV — outline e veios dourados)
   - Reutilize `PAL_BLOOD` (`Twin Fang`) e `PAL_STONE` (`Rock Body`).
   - **Guard obrigatório:** ZERO `#ffd84a` em `Twin Fang`, `Blade Dance` e `Rock Body`; ZERO letras hebraicas nas 4 skills da D-139.

2. Novas primitivas reutilizáveis em `SkillGrotesqueFX` (porte 1:1 de `d139_skills_vfx_canon.html`):
   - `_draw_twin_fang_pair(center, angle, scale, prog, f_idx, pal, alpha)` — fiel a `drawTwinFangPair` (L497–L525).
   - `_draw_parallel_gashes(center, angle, length, spread, grow, alpha, f_idx, pal, bold)` — fiel a `drawParallelGashes` (L527–L542).
   - `_draw_curved_blade_slash(center, angle, scale, prog, f_idx, pal, alpha)` — fiel a `drawCurvedBladeSlash` (L669–L702).
   - `_draw_rock_plate(center, rx, ry, rot, seed, f_idx, pal, is_zahav)` — fiel a `drawRockPlate` (L864–L882).
   - `_draw_sturdy_badge(center, r, f_idx, pal, is_zahav, pulse)` — fiel a `drawSturdyBadge` (L885–L901).

3. As 4 coreografias + estado persistente `STURDY` + evento de defesa/quebra (todas funcionando em **Inimigos** e nos **3 cartões de Aliados Survival**, D-137):
   - `play_twin_fang(caster, target, combo_active: bool)` — fiel a `renderTwinFang` (L544–L664; `2.35 s`, hits `0.28 s` e `0.86 s`; 2º golpe escala `1.32×` e anel de ligação quando `combo_active == true`, ou escala `1.0×` limpa se o 1º golpe errou).
   - `play_blade_dance(caster, hit_targets: Array[BattleUnit])` — fiel a `renderBladeDance` (L704–L859; duração `0.34 + n*0.33 + 0.95 s`, cadência `0.33 s`):
     - Fita/rastro rabiscado ligando `hit_targets[i-1] → hit_targets[i]` em arcos alternados (`-44` / `+34` em design px).
     - **Caso de 1 alvo vivo (`from == to`):** desenhar arco/laço lateral curvo saindo e retornando ao alvo único para preservar o ritmo visual de dança sem segmento degenerado.
     - Lâminas crescentes em ângulos alternados (`-0.62`, `+0.72`, `-0.45`, `+0.88`, `-0.32`), cicatrizes residuais tremendo até o fim da dança e 6 faíscas por impacto.
   - `play_rock_body(user)` — fiel a `renderStoneArmor(false)` (L903–L1095; lock `0.44 s`): 7 placas de pedra convergindo + anel seco + poeira + Moiré `stone`.
   - `play_stone_body(user)` — fiel a `renderStoneArmor(true)` (L903–L1095; lock `0.62 s`): 10 blocos pesados em 2 ondas com veios `#ffd84a` + 6 setas ascendentes douradas (`+15 DEF`) + Moiré `zahav_stone`.
   - **Estado persistente `STURDY` (enquanto `unit.has_status(&"sturdy")`) + pulso `play_sturdy_hold(unit)` / quebra `play_sturdy_break(unit)`:**
     - **CRÍTICO (D-137):** em inimigos, desenhar as duas ombreiras pétreas nos flancos + `_draw_sturdy_badge` acima-direita; em **cartões de aliados (1–3 cartões)**, desenhar as 4 cantoneiras pétreas nas quinas do cartão + `_draw_sturdy_badge` no **canto inferior-direito livre do cartão** com `min_y` estritamente abaixo do Battle Log (**0 px sobre o Battle Log**, sem cobrir nome/HP/EN/PP/ACT, e sem colidir com `Mark of Sun` caso ambos coexistam — deslocar horizontalmente se necessário).
     - `play_sturdy_hold(unit)`: dispara o arco/cúpula rabiscada + 6 estalos radiais (L1020–L1045) quando `STURDY` segura uma interrupção de `COUNTER`.
     - `play_sturdy_break(unit)`: variante curta de estilhaçamento das placas pétreas quando `STURDY` bloqueia um efeito debilitante e se consome no processo.

4. Integração, testes e evidência visual para o criador:
   - Conecte as 4 coreografias + `play_sturdy_hold` + `play_sturdy_break` em `playable_controller.gd` (`_gfx_start` / `_gfx_wait` / `_interrupt` / `try_block_debilitating`).
   - Crie `tests/verify_d139_vfx.gd` testando todas as 4 coreografias + `play_sturdy_hold` + `play_sturdy_break` em modo Inimigos e modo 3 Aliados Survival (duração, sincronismo de impacto, `Blade Dance` com 1, 2 e 3 alvos vivos, guard de ouro exclusivo em `Stone Body`, guard de zero hebraico, e **guard geométrico provando que o emblema/cantoneiras persistentes de `STURDY` no cartão aliado nunca invadem o `Rect2` do Battle Log**).
   - Crie o gravador `tools/record_d139_all.gd` para capturar vídeos/quadros reais no Godot (modo Inimigos e modo 3 Aliados) sobre o `HEAD` atual (D-130), inspecione os quadros, rode toda a suíte de testes, commite + push (D-120) e apresente ao criador para aprovação visual final (Regra 7).
```
