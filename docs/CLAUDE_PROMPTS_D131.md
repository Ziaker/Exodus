# Guia e Prompts Faseados de Implementação — D-131 (Claude / Agentes)

**Decisões:** D-131 · D-125 · D-137 · 2026-11-27  
**Status:** **CANÔNICO — DESIGN E VISUAIS (7/7) APROVADOS; PRONTO PARA IMPLEMENTAÇÃO EM 3 FASES**  
**Referências obrigatórias antes de codar:**
- Regras canônicas e mecânica fechada: [`docs/CANON_SKILLS_D131.md`](CANON_SKILLS_D131.md)
- Estilo visual oficial não-reza: [`docs/NON_PRAYER_VFX_STYLE.md`](NON_PRAYER_VFX_STYLE.md)
- HTML canônico aprovado (7/7, modo Inimigos + 3 Aliados Survival): [`docs/vfx_refs/d131/d131_skills_vfx_canon.html`](vfx_refs/d131/d131_skills_vfx_canon.html) e [`docs/vfx_refs/d131/README.md`](vfx_refs/d131/README.md)
- Histórico de validação e restrições do criador: [`docs/VALIDATION_LOG_D131.md`](VALIDATION_LOG_D131.md)
- Regras de agentes (auditoria, testes só no `HEAD` atual D-130, commit imediato D-120): [`AGENTS.md`](../AGENTS.md)

> [!IMPORTANT]
> **Pré-requisito já concluído no repositório:** `BattleUnit.is_vulnerable(defending)` (unificando `Vuln Pierce` com `Alvo Vulnerável` da D-131) já está implementada e testada desde o commit `3923446` (`tests/verify_d124_skills.gd`: 279 checks). **Não reimplementar do zero** — reutilizar `BattleUnit.is_vulnerable()` diretamente em `Energy Blow`!
>
> **Regra inviolável (D-119):** nunca introduzir campo `affinity` (`WEAK`/`RESIST`/`NULL`/`ABSORB`) em nenhuma skill.

---

## Fase 1 — Motor de Combate D-131 (`PHYS/MAGI/STAT`, `DMG`, `2T`, `Weaken`, `Mark of Sun`, EN steal, Drain cap)

```text
Leia AGENTS.md, docs/CANON_SKILLS_D131.md e docs/COMBAT_SPEC.md (§D-131).
Execute `git fetch origin --prune` e trabalhe apenas sobre a árvore principal atualizada (`main`, D-130).

Implemente a FASE 1 da D-131 (regras de motor de combate sem alterar ainda o catálogo do Survival nem os VFX):

1. Taxonomia oficial (`PHYS` / `MAGI` / `STAT`, dano `PHYS` / `MAGI` / `DMG`, alvos `1T` / `2T` / `3T`):
   - Em `scripts/core/skill_book.gd` / `scripts/core/skill_fx.gd`: adicione suporte aos campos opcionais `cat` (`"PHYS"`, `"MAGI"`, `"STAT"`), `dmg_type` (`"PHYS"`, `"MAGI"`, `"DMG"`), `targets` (`"1T"`, `"2T"`, `"3T"`), mantendo 100% de retrocompatibilidade com skills e testes existentes.
   - Em `scripts/core/battle_math.gd` e `scripts/battle/playable_controller.gd`: quando `dmg_type == "DMG"` (dano sem tipagem), ignore `DEF` e `MEF` completamente (`defense = 0`), mantendo barra de ritmo (50/80/100%), bloqueio/desvio, vantagem de SP e variação ±10%.

2. Estado de batalha em `scripts/core/battle_unit.gd` e `scripts/core/skill_fx.gd`:
   - **EN máx. temporário de batalha (`Energy Blow`):** adicione modificador temporário `battle_max_en_delta: int = 0` e helper `effective_max_en() -> int` (`maxi(1, stats.max_en + battle_max_en_delta)` quando `not prays`, ou `0` quando `prays`) sem mutar `stats.max_en` nem `sp_base()` nem o save. Ao roubar 50% do EN máximo de um alvo com EN, desconta `floor(target.effective_max_en() / 2.0)` de `target.battle_max_en_delta` (clampando `target.current_en`) e soma o mesmo valor ao `caster.battle_max_en_delta` (e `caster.current_en`) até o fim da batalha. Alvos sem EN (`prays == true` como Yoch) não sofrem roubo de EN.
   - **Debuff acumulável de `Weaken` / `Weakenen`:** adicione `weaken_mef_penalty: int = 0` e `weaken_mak_penalty: int = 0` em `BattleUnit`, aplicados em `effective_mef()` e `effective_mak()` com **teto máximo de redução de −50% do atributo base** (`floor(stats.mef * 0.5)` / `floor(stats.mak * 0.5)`) e **piso mínimo efetivo `1`**, sem mutar `stats` nem `sp_base()`. Registra status `&"weaken"` / `&"weakenen"` para que `SkillFx.cleanse_all(unit)` (`Tahorah` D-112) limpe integralmente ambos os acumuladores.
   - **`Mark of Sun`:** adicione `sun_mark_hits: int = 0` e `sun_mark_rounds: int = 0` em `BattleUnit` (status `&"mark_of_sun"`). Dura até o fim do próximo round (2 ticks de round, igual `BLIND`/`MAGEN`) **OU até o 3º golpe sofrido pelo alvo** (`sun_mark_hits` começa em `3` e decresce a cada golpe recebido que cause contato). Reaplicar renova `sun_mark_hits = 3` e `sun_mark_rounds = 2`. Removível por `SkillFx.cleanse_all()` (`Tahorah`).
   - **Gatilho de `Mark of Sun` em `playable_controller.gd`:** sempre que um alvo com `sun_mark_hits > 0` sofrer um golpe de ataque/skill que cause dano (inclusive cada acerto individual de multi-hit como `Lunge`, `Fang Spine`, `Ignoma Esh`), aplicar dano mágico extra `maxi(5, 20 - defender.effective_mef())` (piso mínimo `5`), decrementar `sun_mark_hits -= 1`, registrar no Battle Log e, ao chegar em `0`, limpar a marca (`sun_mark_rounds = 0`, `remove_status(&"mark_of_sun")`).

3. Seleção `2T` (2 alvos distintos) e `COND` de alvo em `playable_controller.gd`:
   - Suporte a `targets == "2T"`: quando houver 2 ou mais alvos vivos, permitir escolher/resolver 2 alvos distintos (herói seleciona 1º e 2º alvo distinto; IA escolhe 2 distintos; se só restar 1 vivo, aplica nesse 1).
   - Suporte a `fx.cond == "vuln_or_quarter_hp"` (`Energy Blow`): só permite usar/resolver em alvos que satisfaçam `target.is_vulnerable(defending) or target.current_hp * 4 <= target.stats.max_hp`.
   - Suporte a dreno percentual com cura `80%` e teto de chefe (`Drain Claw` / `Vital Claws`): parcela fixa `15`/`30` mitigada por `DEF` + barra de ritmo + parcela percentual `min(boss_cap, floor(target.stats.max_hp / 4.0))` (`boss_cap` = `40` ou `60` quando o alvo for chefe/Guardião/Anjo; sem teto em inimigos comuns); usuário recupera `floor(applied * 0.80)` HP via `caster.heal(...)` (respeitando `BLEED` canônico D-124) e, se `fx.steal_en > 0`, transfere até `15 EN` do alvo ao conjurador.

4. Testes e auditoria obrigatória:
   - Crie `tests/verify_d131_rules.gd` cobrindo 100% das regras acima (incluindo `DMG` ignorando DEF/MEF com ritmo/bloqueio/SP, `Energy Blow` COND + EN steal revertido fora da luta + Yoch sem EN, `Drain Claw`/`Vital Claws` 80% cura + `BLEED` + cap 40/60 em chefe/Guardião/Anjo, `Weaken`/`Weakenen` acúmulo + teto −50% + piso 1 + `Tahorah` dispell, `Mark of Sun` 3 golpes em multi-hit + piso 5 + expiração de round + `Tahorah` dispell, e `2T` com 1, 2 e 3 alvos).
   - Rode `verify_d131_rules.gd`, `verify_d124_rules.gd`, `verify_d124_skills.gd`, `verify_skill_fx.gd` e `verify_new_prayers.gd` no Godot headless sobre o `HEAD` atual (D-130).
   - Audite, corrija qualquer defeito e commite + push imediatamente (D-120).
```

---

## Fase 2 — Catálogo Canônico D-131 (`skill_book.gd`), Migração Survival (`survival_data.gd`) e UI de `4 ACT`

```text
Leia AGENTS.md, docs/CANON_SKILLS_D131.md, docs/CANON_BOUNDARY.md e confirme que a Fase 1 da D-131 está em `origin/main`.

Implemente a FASE 2 da D-131:

1. Substitua no catálogo canônico `scripts/core/skill_book.gd` as 5 skills antigas do Survival + adicione as 2 evoluções `ZAHAV` (todas com `"grotesque": true`, taxonomia oficial `cat`/`dmg_type`/`targets`, e ZERO campo `affinity` D-119):
   - `stone_crush` (substitui `heavy_crush`): `"STONE CRUSH"`, `4 ACT / 0 EN / PHYS / 1T`, `dmg_type: "PHYS"`, `power: 30` (+ATK).
   - `energy_blow` (substitui `crushing_blow`): `"ENERGY BLOW"`, `3 ACT / 0 EN / MAGI / 1T`, `dmg_type: "DMG"`, `power: 25` (+MAK), `fx: {"cond": "vuln_or_quarter_hp", "steal_max_en_ratio": 0.5}`.
   - `drain_claw` (substitui `life_drain`): `"DRAIN CLAW"`, `2 ACT / 15 EN / PHYS / 1T`, `dmg_type: "PHYS"`, `power: 15`, `fx: {"drain_max_hp_ratio": 0.25, "boss_cap": 40, "heal_ratio": 0.8}`, `zahav: &"vital_claws"`.
   - `vital_claws` (ZAHAV de `drain_claw`): `"VITAL CLAWS"`, `3 ACT / 25 EN / PHYS / 1T`, `dmg_type: "PHYS"`, `power: 30`, `fx: {"drain_max_hp_ratio": 0.25, "boss_cap": 60, "heal_ratio": 0.8, "steal_en": 15}`, `is_zahav: true`.
   - `weaken` (substitui `curse_ray`): `"WEAKEN"`, `1 ACT / 10 EN / STAT / 1T`, `fx: {"weaken_mef_base": 5, "weaken_mak_ratio": 0.5, "dispellable": true}`, `zahav: &"weakenen"`.
   - `weakenen` (ZAHAV de `weaken`): `"WEAKENEN"`, `2 ACT / 15 EN / STAT / 2T`, `fx: {"weaken_mef_base": 10, "weaken_mak_base": 10, "weaken_mak_ratio": 0.5, "dispellable": true}`, `is_zahav: true`.
   - `mark_of_sun` (substitui `spirit_bolt`): `"MARK OF SUN"`, `4 ACT / 20 EN / STAT / 1T`, `fx: {"mark_of_sun_hits": 3, "mark_of_sun_magi": 20, "mark_of_sun_min": 5, "dispellable": true}`.

2. Migração completa em `scripts/survival/survival_data.gd`, `scripts/battle/skill_letters.gd` e qualquer referência antiga (`git grep` por `heavy_crush`, `crushing_blow`, `life_drain`, `curse_ray`, `spirit_bolt` em `scripts/` e `tests/`):
   - Substitua os 5 IDs antigos pelos 5 canônicos (`stone_crush`, `energy_blow`, `drain_claw`, `weaken`, `mark_of_sun`) mantendo retrocompatibilidade em saves antigos do Survival se necessário.
   - Garanta que skills de `4 ACT` (`stone_crush`, `mark_of_sun`) exibem claramente `4 ACT` no menu/descrição e ficam habilitadas exatamente quando o combatente estocou 4 atos (`PASS`/`REST`), respeitando o teto D-005.
   - Garanta que `Energy Blow` sinaliza no menu/alvo quando nenhum alvo cumpre `COND` (vulnerável ou ≤ 1/4 HP).

3. Testes e auditoria obrigatória:
   - Crie `tests/verify_d131_skills.gd` validando todas as 7 entradas (custos, fichas, execução real de combate, migração do Survival, requisito `4 ACT`, `COND` de `Energy Blow`, `ZAHAV` metadata).
   - Rode toda a suíte relevante (`verify_d131_skills.gd`, `verify_d131_rules.gd`, `verify_survival_data.gd`, `verify_d124_skills.gd`, `verify_skill_fx.gd`) sobre o `HEAD` atual, corrija qualquer regressão e commite + push (D-120).
```

---

## Fase 3 — Coreografias VFX 1:1 em `SkillGrotesqueFX` (Inimigos + 3 Cartões Aliados Survival)

```text
Leia AGENTS.md, docs/NON_PRAYER_VFX_STYLE.md, docs/VALIDATION_LOG_D131.md e
docs/vfx_refs/d131/README.md + docs/vfx_refs/d131/d131_skills_vfx_canon.html.
Confirme que as Fases 1 e 2 da D-131 estão em `origin/main`.

Implemente a FASE 3 da D-131 em `scripts/battle/skill_grotesque_fx.gd` e `scripts/battle/playable_controller.gd`,
com fidelidade 1:1 absoluta ao HTML canônico aprovado (7/7):

1. Paletas canônicas novas em `SkillGrotesqueFX` (sem quebrar as da D-124):
   - `stone`: accent `#6d5e52`, hi `#d9cfc2`, deep `#16110e` (NORMAL — zero ouro)
   - `energy`: accent `#553675`, hi `#c9bde0`, deep `#0b0514` (NORMAL — zero ouro)
   - `blue_stat`: accent `#25568a`, hi `#9fc9ec`, deep `#061124` (NORMAL — zero ouro)
   - `zahav_blue`: accent `#2b669e`, hi `#ffd84a`, deep `#08162b` (ZAHAV — outline dourado)
   - `sun_normal`: accent `#c94c14`, hi `#f2d9b6`, deep `#240903` (NORMAL — zero ouro)
   - Reutilize `blood` (`Drain Claw`) e `zahav_blood` (`Vital Claws`).
   - **Guard obrigatório:** ZERO `#ffd84a` nas 5 skills normais; ZERO letras hebraicas em todas as 7 skills da D-131.

2. Primitivas novas reutilizáveis em `SkillGrotesqueFX`:
   - `_draw_single_impale_claw(tip, angle, length, f_idx, pal, alpha)` — fiel a `drawSingleImpaleClaw` (L395).
   - `_draw_sketch_orb(center, radius, f_idx, pal)` — fiel a `drawSketchOrb` (L408).
   - `_draw_solar_hit_flare(center, trig_prog, trig_env, f_idx, pal, min_y, ally_mode)` — fiel a `drawSolarHitFlare` (L554): anel solar rabiscado + estrela de 8 raios finos + núcleo breve `#f2d9b6` + pulso Moiré contido (**sem triângulos**, **sem cone trapezoide**).

3. As 7 coreografias + marca persistente `Mark of Sun` (todas funcionando tanto em **Inimigos** quanto nos **3 cartões de Aliados Survival**, D-137):
   - `play_stone_crush(caster, target)` — fiel a `renderStoneCrush` (L881–954; `2.55 s`, impacto `0.62 s`).
   - `play_energy_blow(caster, target)` — fiel a `renderEnergyBlow` (L955–1024; `2.65 s`, impacto `0.56 s`).
   - `play_drain_claw(caster, target)` — fiel a `renderDrainClaw` (L674–739; `2.25 s`, impacto `0.36 s`): **1 única garra afiada + Moiré contido + 6 gotas** (sem exagero!).
   - `play_vital_claws(caster, target)` — fiel a `renderVitalClaws` (L740–812; `2.40 s`, impactos `0.34 s` / `0.48 s`): **2 garras com outline `#ffd84a` + 6 gotas HP + 5 partículas EN** (sem boca/costela!).
   - `play_weaken(caster, target)` — fiel a `renderWeaken` (L1025–1071; `2.45 s`, impacto `0.58 s`): esfera azul + colapso Moiré + 7 setas (sem flash de inversão).
   - `play_weakenen(caster, victims)` — fiel a `renderWeakenen` (L813–880; `2.50 s`, impactos `0.78 s` / `0.90 s`): **1 esfera azul maior dourada disparando 2 esferas nos 2 alvos (`2T`)** + colapso limpo (sem raios elétricos nem grilhões!).
   - `play_mark_of_sun(caster, target)` + **marca persistente ativa enquanto `unit.sun_mark_hits > 0`** + `play_mark_of_sun_trigger(target)` ao disparar `+20 MAGI`:
     - **CRÍTICO (validação do criador):** no **inimigo**, o sol persistente fica acima da cabeça (abaixo do HUD superior); no **cartão do aliado (1–3 cartões)**, o sol persistente fica encaixado no **canto inferior-direito livre do cartão** com contador `×3`/`×2`/`×1` ao lado e `min_y` estritamente abaixo do Battle Log (**0 px de invasão no Battle Log**, sem cobrir nome/HP/PP/EN/ACT). **Zero triângulos caindo.**

4. Integração, testes e evidência visual para o criador:
   - Conecte todas as 7 coreografias em `playable_controller.gd` (`_gfx_start` / `_gfx_wait`) sincronizando a mecânica com o instante de impacto (`HIT_*`), e dispare `play_mark_of_sun_trigger(defender)` em cada gatilho de `+20 MAGI`.
   - Crie `tests/verify_d131_vfx.gd` testando todas as 7 coreografias em modo Inimigos e modo 3 Aliados Survival (duração, fim automático, sincronismo de impacto, guard de ouro exclusivo ZAHAV, guard de zero hebraico, e **guard geométrico provando que o sol persistente de `Mark of Sun` no cartão aliado nunca invade o `Rect2` do Battle Log**).
   - Estenda ou crie gravador `tools/record_d131_all.gd` para gerar vídeos/quadros reais no Godot (modo Inimigos e modo 3 Aliados) sobre o `HEAD` atual (D-130), inspecione os quadros, rode toda a suíte de testes, commite + push (D-120) e apresente ao criador para aprovação visual final (Regra 7).
```
