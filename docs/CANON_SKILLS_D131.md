# Skills Canônicas Revisadas — Lote 2 + Taxonomia Oficial (`PHYS/MAGI/STAT`, `DMG`, `1T–3T`) e Alvo Vulnerável (D-131)

**Decisão:** D-131 · 2026-11-27 (decisão do criador)  
**Estado:** **CANÔNICO — DESIGN E VISUAIS (7/7) APROVADOS; IMPLEMENTADO NAS 3 FASES (motor, catálogo e VFX no jogo; aguarda a validação visual do criador no Godot)**  
**Índice canônico:** [`docs/DECISIONS.md`](DECISIONS.md) · **GDD:** [`docs/GDD.md`](GDD.md) (Apêndice A) · **Combate:** [`docs/COMBAT_SPEC.md`](COMBAT_SPEC.md) · **Fronteira Canônica:** [`docs/CANON_BOUNDARY.md`](CANON_BOUNDARY.md) · **Lote 1 (D-124):** [`docs/CANON_SKILLS_D124.md`](CANON_SKILLS_D124.md) · **Estilo VFX Não-Reza (D-125):** [`docs/NON_PRAYER_VFX_STYLE.md`](NON_PRAYER_VFX_STYLE.md) · **HTML Canônico (7/7):** [`docs/vfx_refs/d131/README.md`](vfx_refs/d131/README.md) · **Validação do Criador:** [`docs/VALIDATION_LOG_D131.md`](VALIDATION_LOG_D131.md) · **Prompts Faseados:** [`docs/CLAUDE_PROMPTS_D131.md`](CLAUDE_PROMPTS_D131.md)

> [!IMPORTANT]
> A partir da **D-131**, toda habilidade canônica adota a taxonomia oficial de **categoria** (`PHYS`, `MAGI`, `STAT`), **tipo de dano** (`PHYS`, `MAGI`, `DMG`) e **quantidade de alvos** (`1T`, `2T`, `3T`). As **5 novas skills** (mais **2 evoluções `ZAHAV`**) promovidas do pool do Survival, a definição unificada de **Alvo Vulnerável** e todas as regras complementares abaixo estão **100% fechadas** pelo criador.

---

## 1. Taxonomia Oficial de Habilidades e Dano (D-131)

| Eixo | Siglas oficiais | Significado |
|---|---|---|
| **Categoria da skill** | `PHYS` · `MAGI` · `STAT` | `PHYS` = habilidade física · `MAGI` = habilidade mágica · `STAT` = habilidade de status, marca ou enfraquecimento/buff. |
| **Tipo de dano** | `PHYS` · `MAGI` · `DMG` | `PHYS` = dano físico (mitigado por `DEF`) · `MAGI` = dano mágico (mitigado por `MEF`) · `DMG` = **dano sem tipagem** *(ignora `DEF` e `MEF`, mantendo barra de ritmo, bloqueio/desvio, vantagem de SP e variação ±10%)*. |
| **Número de alvos** | `1T` · `2T` · `3T` | `1T` = 1 alvo · `2T` = 2 alvos · `3T` = 3 alvos *(T = target)*. |

**Formato padrão de ficha:** `(<ACT>ACT/<EN>EN/<CATEGORIA>/<ALVOS>)`, por exemplo `(4ACT/0EN/PHYS/1T)`.

---

## 2. Regra Global — Definição Canônica de Alvo Vulnerável

> **Alvo vulnerável** é qualquer combatente que:
> 1. Esteja realizando uma **ação não-ofensiva**, **OU**
> 2. Esteja sob um **efeito que força o `PASS`**, como **paralisação** *(ex.: `Angel Hug`, D-118)* ou **aprisionamento** *(ex.: `Umbral Gaze`, D-124 §2.3, que atua como `PASS` automático)*.

* **Unificação com `Vuln Pierce` (D-124):** confirmado pelo criador — **`Vuln Pierce`** passa a usar exatamente esta mesma definição de **Alvo Vulnerável** (dobra o dano contra ação não-ofensiva **ou** contra alvo sob efeito que força `PASS`).

---

## 3. Catálogo Canônico — Lote 2 (5 base + 2 evoluções `ZAHAV`)

| # | Nome Canônico | Evolução `ZAHAV` | Origem (Survival D-106) | Ficha (`ACT/EN/CAT/ALVO`) | Efeito Canônico |
|---|---|---|---|---|---|
| 1 | **Stone Crush** | — | Rework de `HEAVY CRUSH` (`heavy_crush`) | `4ACT / 0EN / PHYS / 1T` | O usuário arremessa uma grande rocha no alvo, causando **`30 PHYS (+ATK)`** de dano. |
| 2 | **Energy Blow** | — | Rework de `FINISHING BLOW` (`crushing_blow`) | `3ACT / 0EN / MAGI / 1T` | **`COND`:** só pode ser realizado em **alvos vulneráveis** ou com **≤ 1/4 da vida restante** *(25% do HP máx.)*. Causa **`25 DMG + MAK`** e **rouba metade do EN máximo do alvo até o fim da batalha** *(contra alvos sem EN, ex.: Yoch, causa apenas o dano)*. |
| 3 | **Drain Claw** | **Vital Claws** | Rework de `LIFE DRAIN` (`life_drain`) | `2ACT / 15EN / PHYS / 1T` | Finca uma garra no alvo e rouba sua vitalidade, tomando **`15 HP + 1/4 da vida máxima do alvo`** *(teto de 40 HP na parcela percentual contra chefes/Guardiões/Anjos; passa por barra de ritmo e `DEF` na parcela fixa)* e **curando o usuário em 80% do HP drenado** *(sujeito a `BLEED` canônico)*. |
| 3Z | **Vital Claws** *(ZAHAV)* | Evolução de `Drain Claw` | — | `3ACT / 25EN / PHYS / 1T` | Finca duas garras no alvo, roubando sua energia vital, tomando **`30 HP + 1/4 da vida máxima`** *(teto de 60 HP na parcela percentual contra chefes/Guardiões/Anjos)* e **`15 EN`** do alvo; **cura o usuário em 80% do HP drenado** e recupera o `EN` roubado *(até o máximo)*. |
| 4 | **Weaken** | **Weakenen** | Rework de `CURSE RAY` (`curse_ray`) | `1ACT / 10EN / STAT / 1T` | Uma esfera de energia azul enfraquece as capacidades mágicas do alvo, reduzindo sua **`MEF` em `5 (+50% MAK do usuário)`** até o fim do combate. **Acumula até o teto de −50% da `MEF` base** *(piso efetivo `1`)* e **pode sofrer dispell** *(ex.: `Tahorah`)*. |
| 4Z | **Weakenen** *(ZAHAV)* | Evolução de `Weaken` | — | `2ACT / 15EN / STAT / 2T` | Cria uma esfera de energia maior e dispara contra **2 alvos distintos** *(ou 1 se só restar 1 vivo)*, reduzindo suas capacidades mágicas (**`MAK` e `MEF`**) em **`10 (+50% MAK do usuário)`** até o fim do combate. **Acumula até o teto de −50% de `MAK`/`MEF` base** *(piso efetivo `1`)* e **pode sofrer dispell** *(ex.: `Tahorah`)*. |
| 5 | **Mark of Sun** | — | Rework de `SPIRIT BRAND` (`spirit_bolt`) | `4ACT / 20EN / STAT / 1T` | Um sol surge acima do alvo, fazendo com que sofra **`20 MAGI` extra por golpe** *(mitigado por `MEF`, piso mínimo de `5` de dano por disparo)* de todo ataque que receber até o fim do próximo round — **a marca desaparece no 3º golpe que o alvo levar** *(o que vier primeiro; também dissipável via `Tahorah`)*. |

*(Todas as evoluções `ZAHAV` seguem a D-118: acionadas segurando `A`, nome em dourado, custo de 20 SP após a conclusão; outline dourado exclusivo de `ZAHAV` nos VFX não-reza conforme D-125.)*

---

## 4. Diretrizes de VFX e Status de Aprovação (D-125 & D-137)

Todas as 7 entradas acima (5 base + 2 `ZAHAV`) são ataques não-reza canônicos e seguem estritamente [`docs/NON_PRAYER_VFX_STYLE.md`](NON_PRAYER_VFX_STYLE.md) (*Rabisco Anatômico Grotesco 12 FPS + Interferência Hipnótica Moiré* em paleta sombria, sem neon; **outline dourado exclusivo em `Vital Claws` e `Weakenen`**; zero letras hebraicas), validados nos modos **Inimigos** e **3 cartões de Aliados Survival** (**D-137**).

* **Status de aprovação visual (2026-11-27):** **TODOS APROVADOS (7/7)** — **`Stone Crush`**, **`Energy Blow`**, **`Drain Claw`** *(contido: 1 garra + 6 gotas)*, **`Vital Claws [ZAHAV]`** *(contido: 2 garras douradas + HP/EN)*, **`Weaken`**, **`Weakenen [ZAHAV]`** *(contido: esfera maior disparando 2 esferas)* e **`Mark of Sun`** *(sol no canto livre do cartão nos aliados sem invadir Battle Log, zero triângulos, clarão solar em estrela + anel)*.
* **Referência HTML canônica salva:** [`docs/vfx_refs/d131/d131_skills_vfx_canon.html`](vfx_refs/d131/d131_skills_vfx_canon.html) ([`README.md`](vfx_refs/d131/README.md)).
* **Processo completo de validação por ataque:** [`docs/VALIDATION_LOG_D131.md`](VALIDATION_LOG_D131.md).
* **Plano/prompts faseados de implementação:** [`docs/CLAUDE_PROMPTS_D131.md`](CLAUDE_PROMPTS_D131.md).

---

## 5. Decisões complementares fechadas (criador, 2026-11-27)

1. **`DMG` (dano sem tipagem):** ignora `DEF` e `MEF` completamente, mantendo barra de ritmo (50/80/100%), bloqueio/desvio, vantagem de SP e variação ±10%.
2. **`Energy Blow` — roubo de EN:** vale **até o fim da batalha atual** (não altera permanentemente o save nem fichas entre lutas). Reduz o EN máximo efetivo do alvo em 50% (ajustando o EN atual ao novo teto) e transfere esse ganho de EN máximo temporário para o usuário até o fim da luta. Contra alvos sem EN (como Yoch, que usa PP), causa apenas o dano `25 DMG + MAK`.
3. **`Drain Claw` / `Vital Claws` — cura e teto:**
   - **Cura:** o usuário recupera **80% do HP efetivamente drenado** (limitado ao HP máximo e sujeito ao `BLEED` canônico D-124); `Vital Claws` também transfere até `15 EN` do alvo para o usuário (limitado ao EN máximo).
   - **Mitigação e ritmo:** passa normalmente por barra de ritmo e bloqueio/desvio (`DEF` aplicada à parcela fixa `15`/`30`; piso de 1 de dano no contato).
   - **Teto em chefes/Guardiões/Anjos:** a parcela `1/4 da vida máxima` tem teto de **`40 HP`** em `Drain Claw` e **`60 HP`** em `Vital Claws` contra chefes, Guardiões e Anjos (evitando que 1 golpe arranque 25% de chefes com HP elevado).
4. **`Weaken` / `Weakenen` — acúmulo com teto, piso, `2T` e dispell:**
   - Múltiplos usos **acumulam** até o fim do combate, limitados ao **teto máximo de redução de −50% do valor base** de `MEF` (e de `MAK` em `Weakenen`), respeitando sempre o **piso mínimo efetivo `1`** (sem mutar `sp_base()`).
   - `Weakenen` (`2T`) seleciona **2 alvos distintos** quando houver 2 ou mais inimigos vivos (ou 1 alvo se só restar 1 vivo).
   - Ambas as versões sofrem dispell via **`Tahorah`** (D-112) e quaisquer futuros dispells.
5. **`Mark of Sun` — gatilho de 3 golpes, `MEF` com piso mínimo e dispell:**
   - Os `20 MAGI` extras disparam **em cada golpe individual** (incluindo cada acerto de ataques multi-hit como `Lunge`, `Fang Spine`, `Ignoma Esh`), passando pela `MEF` do alvo com **piso mínimo de `5` de dano por disparo** (garantindo retorno real pelo custo `4 ACT / 20 EN` mesmo contra `MEF` alta, e formando combo natural com `Weaken`).
   - **Consumo no 3º golpe:** a marca guarda **3 cargas** e **desaparece ao disparar no 3º golpe que o alvo levar** (ou ao fim do próximo round, o que acontecer primeiro). Reaplicar renova as 3 cargas e a duração; também pode sofrer dispell via `Tahorah`.
6. **Unificação com `Vuln Pierce` (D-124) — IMPLEMENTADO:** `BattleUnit.is_vulnerable(defending)` unifica a definição de **Alvo Vulnerável** (ação não-ofensiva, defesa, ou efeito que força `PASS`: `trapped_actions > 0`, `paralyzed_acts > 0`, `sleep`) e já está conectada ao dano e ao VFX de `Vuln Pierce` em `playable_controller.gd`, coberta em `tests/verify_d124_skills.gd`.
7. **Padronização documental e requisitos de 4 ACT:**
   - [`docs/CANON_SKILLS_D124.md`](CANON_SKILLS_D124.md) padronizado para a taxonomia `PHYS`/`MAGI`/`STAT`, `PHYS`/`MAGI`/`DMG` e `1T`/`2T`/`3T`.
   - Skills de `4 ACT` (`Stone Crush`, `Mark of Sun`) devem exibir claramente o requisito `4 ACT` no menu/descrição e respeitar o teto de 4 atos estocados (`PASS`/`REST`).

---

## 6. Notas de implementação (2026-11-27)

Código: `scripts/core/{battle_unit,skill_fx,skill_book}.gd`, `scripts/battle/{battle_controller,playable_controller,skill_grotesque_fx}.gd`; testes `tests/verify_d131_rules.gd` (motor), `tests/verify_d131_skills.gd` (catálogo, migração, fluxo real) e `tests/verify_d131_vfx.gd` (coreografias); gravador `tools/record_d131_all.gd`.

* **Status do motor.** `Weaken`/`Weakenen` registram os status `&"weaken_mef"` e `&"weaken_mak"` (o id `&"weaken"` já pertence ao `VENOM CLOUD`, que reduz 20% do dano causado). `Mark of Sun` usa `&"mark_of_sun"`. `Tahorah` (`SkillFx.cleanse_all`) limpa os três e os acumuladores.
* **`Energy Blow` e o roubo de EN.** Só ocorre quando o alvo e o usuário têm EN (quem reza, como Yoch, não rouba nem perde EN). O EN máximo temporário (`BattleUnit.battle_max_en_delta`, `effective_max_en()`) nunca toca `stats.max_en`, `sp_base()` nem o save.
* **`Drain Claw`/`Vital Claws`.** Chefe/Guardião/Anjo = `BattleUnit.is_boss_class()` (`boss_class` ou raça Anjo). A parcela de 1/4 do HP máx. é direta (sem DEF e sem barra); a parcela fixa passa por DEF e barra.
* **`2T`.** `targets: "2T"` pede dois alvos distintos (herói) e a IA sorteia dois distintos; com um só vivo o efeito cai uma vez.
* **`COND` de `Energy Blow`.** `SkillFx.cond_met`; o menu marca `NO VULNERABLE FOE` e a IA só escolhe a skill quando algum herói cumpre a condição.
* **Migração.** As 5 skills antigas viram as canônicas (`SkillBook.LEGACY_IDS`), também em saves do Survival (`SurvivalState.load_from_file`) e no aprendizado por absorção (`ProgressStore.load_skills`).
* **VFX.** Porte 1:1 do HTML canônico em `SkillGrotesqueFX` (`play_stone_crush`, `play_energy_blow`, `play_drain_claw`, `play_vital_claws`, `play_weaken`, `play_weakenen`, `play_mark_of_sun`, `play_mark_of_sun_trigger`). Em cartões de aliados o Moiré é "livre" (`free`, passa do palco) e a marca persistente de `Mark of Sun` fica no canto inferior-direito livre do cartão com `min_y` logo abaixo do Battle Log. A marca persiste enquanto `sun_mark_hits > 0` (`SkillGrotesqueFX._sun_step`/`_draw_suns`); o `+20 MAGI` chama `play_mark_of_sun_trigger` em cada gatilho.
* **Correção colateral.** O HUD do combate tinha tamanho 0 (o pai também) e SUMIA inteiro enquanto `camera_shake` mexia no canvas; agora recebe o tamanho da tela (`hud.size = hud.SCREEN`).
