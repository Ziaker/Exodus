# Skills Canônicas Revisadas — Lote 2 + Taxonomia Oficial (`PHYS/MAGI/STAT`, `DMG`, `1T–3T`) e Alvo Vulnerável (D-131)

**Decisão:** D-131 · 2026-11-27 (decisão do criador)  
**Estado:** **CANÔNICO — DESIGN 100% FECHADO; NÃO IMPLEMENTADO (aguardando aprovação visual D-125 e implementação em código)**  
**Índice canônico:** [`docs/DECISIONS.md`](DECISIONS.md) · **GDD:** [`docs/GDD.md`](GDD.md) (Apêndice A) · **Combate:** [`docs/COMBAT_SPEC.md`](COMBAT_SPEC.md) · **Fronteira Canônica:** [`docs/CANON_BOUNDARY.md`](CANON_BOUNDARY.md) · **Lote 1 (D-124):** [`docs/CANON_SKILLS_D124.md`](CANON_SKILLS_D124.md) · **Estilo VFX Não-Reza (D-125):** [`docs/NON_PRAYER_VFX_STYLE.md`](NON_PRAYER_VFX_STYLE.md)

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
| 4 | **Weaken** | **Weakenen** | Rework de `CURSE RAY` (`curse_ray`) | `1ACT / 10EN / STAT / 1T` | Uma esfera de energia azul enfraquece as capacidades mágicas do alvo, reduzindo sua **`MEF` em `5 (+50% MAK do usuário)`** até o fim do combate. **Acumula** *(piso efetivo `1`)* e **pode sofrer dispell** *(ex.: `Tahorah`)*. |
| 4Z | **Weakenen** *(ZAHAV)* | Evolução de `Weaken` | — | `2ACT / 15EN / STAT / 2T` | Cria uma esfera de energia maior e dispara contra **2 alvos distintos** *(ou 1 se só restar 1 vivo)*, reduzindo suas capacidades mágicas (**`MAK` e `MEF`**) em **`10 (+50% MAK do usuário)`** até o fim do combate. **Acumula** *(piso efetivo `1`)* e **pode sofrer dispell** *(ex.: `Tahorah`)*. |
| 5 | **Mark of Sun** | — | Rework de `SPIRIT BRAND` (`spirit_bolt`) | `4ACT / 20EN / STAT / 1T` | Um sol surge acima do alvo, fazendo com que sofra **`20 MAGI` extra por golpe** *(mitigado por `MEF`)* de todo ataque que receber até o fim do próximo round — **a marca desaparece no 3º golpe que o alvo levar** *(o que vier primeiro; também dissipável via `Tahorah`)*. |

*(Todas as evoluções `ZAHAV` seguem a D-118: acionadas segurando `A`, nome em dourado, custo de 20 SP após a conclusão; outline dourado exclusivo de `ZAHAV` nos VFX não-reza conforme D-125.)*

---

## 4. Diretrizes de VFX (D-125)

Todas as 7 entradas acima (5 base + 2 `ZAHAV`) são ataques não-reza e deverão seguir estritamente [`docs/NON_PRAYER_VFX_STYLE.md`](NON_PRAYER_VFX_STYLE.md) (*Rabisco Anatômico Grotesco 12 FPS + Interferência Hipnótica Moiré* em paleta sombria, sem neon; **outline dourado exclusivo em `Vital Claws` e `Weakenen`**; sem letras hebraicas). Protótipos HTML interativos e validação visual do criador estão **PENDENTES**.

---

## 5. Decisões complementares fechadas (criador, 2026-11-27)

1. **`DMG` (dano sem tipagem):** ignora `DEF` e `MEF` completamente, mantendo barra de ritmo (50/80/100%), bloqueio/desvio, vantagem de SP e variação ±10%.
2. **`Energy Blow` — roubo de EN:** vale **até o fim da batalha atual** (não altera permanentemente o save nem fichas entre lutas). Reduz o EN máximo efetivo do alvo em 50% (ajustando o EN atual ao novo teto) e transfere esse ganho de EN máximo temporário para o usuário até o fim da luta. Contra alvos sem EN (como Yoch, que usa PP), causa apenas o dano `25 DMG + MAK`.
3. **`Drain Claw` / `Vital Claws` — cura e teto:**
   - **Cura:** o usuário recupera **80% do HP efetivamente drenado** (limitado ao HP máximo e sujeito ao `BLEED` canônico D-124); `Vital Claws` também transfere até `15 EN` do alvo para o usuário (limitado ao EN máximo).
   - **Mitigação e ritmo:** passa normalmente por barra de ritmo e bloqueio/desvio (`DEF` aplicada à parcela fixa `15`/`30`; piso de 1 de dano no contato).
   - **Teto em chefes/Guardiões/Anjos:** a parcela `1/4 da vida máxima` tem teto de **`40 HP`** em `Drain Claw` e **`60 HP`** em `Vital Claws` contra chefes, Guardiões e Anjos (evitando que 1 golpe arranque 25% de chefes com HP elevado).
4. **`Weaken` / `Weakenen` — acúmulo, piso, `2T` e dispell:**
   - Múltiplos usos **acumulam** até o fim do combate.
   - Piso mínimo de `MAK` e `MEF` efetivos = **`1`** (consistente com `BattleUnit.effective_mef()` / `effective_def()`, sem mutar `sp_base()`).
   - `Weakenen` (`2T`) seleciona **2 alvos distintos** quando houver 2 ou mais inimigos vivos (ou 1 alvo se só restar 1 vivo).
   - Ambas as versões sofrem dispell via **`Tahorah`** (D-112) e quaisquer futuros dispells.
5. **`Mark of Sun` — gatilho de 3 golpes, `MEF` e dispell:**
   - Os `20 MAGI` extras disparam **em cada golpe individual** (incluindo cada acerto de ataques multi-hit como `Lunge`, `Fang Spine`, `Ignoma Esh`), passando pela `MEF` do alvo.
   - **Consumo no 3º golpe:** a marca guarda **3 cargas** e **desaparece ao disparar no 3º golpe que o alvo levar** (ou ao fim do próximo round, o que acontecer primeiro). Reaplicar renova as 3 cargas e a duração; também pode sofrer dispell via `Tahorah`.
6. **Unificação com `Vuln Pierce` (D-124):** `Vuln Pierce` adota a definição unificada de **Alvo Vulnerável** da D-131 (ação não-ofensiva **ou** efeito que força `PASS`).
7. **Padronização documental e requisitos de 4 ACT:**
   - [`docs/CANON_SKILLS_D124.md`](CANON_SKILLS_D124.md) padronizado para a taxonomia `PHYS`/`MAGI`/`STAT`, `PHYS`/`MAGI`/`DMG` e `1T`/`2T`/`3T`.
   - Skills de `4 ACT` (`Stone Crush`, `Mark of Sun`) devem exibir claramente o requisito `4 ACT` no menu/descrição e respeitar o teto de 4 atos estocados (`PASS`/`REST`).
