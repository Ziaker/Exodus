# Skills Canônicas Revisadas — Lote 2 + Taxonomia Oficial (`PHYS/MAGI/STAT`, `DMG`, `1T–3T`) e Alvo Vulnerável (D-131)

**Decisão:** D-131 · 2026-11-27 (decisão do criador)  
**Estado:** **CANÔNICO — DESIGN CONFIRMADO; NÃO IMPLEMENTADO (VFX D-125 e código aguardando aprovação/pendências)**  
**Índice canônico:** [`docs/DECISIONS.md`](DECISIONS.md) · **GDD:** [`docs/GDD.md`](GDD.md) (Apêndice A) · **Combate:** [`docs/COMBAT_SPEC.md`](COMBAT_SPEC.md) · **Fronteira Canônica:** [`docs/CANON_BOUNDARY.md`](CANON_BOUNDARY.md) · **Lote 1 (D-124):** [`docs/CANON_SKILLS_D124.md`](CANON_SKILLS_D124.md) · **Estilo VFX Não-Reza (D-125):** [`docs/NON_PRAYER_VFX_STYLE.md`](NON_PRAYER_VFX_STYLE.md)

> [!IMPORTANT]
> A partir da **D-131**, toda nova habilidade canônica passa a usar a taxonomia oficial de **categoria** (`PHYS`, `MAGI`, `STAT`), **tipo de dano** (`PHYS`, `MAGI`, `DMG`) e **quantidade de alvos** (`1T`, `2T`, `3T`). Além disso, **5 novas skills** (mais **2 evoluções `ZAHAV`**) promovidas do pool do Survival passam a ser **canônicas**, junto à definição oficial de **Alvo Vulnerável**.

---

## 1. Taxonomia Oficial de Habilidades e Dano (D-131)

| Eixo | Siglas oficiais | Significado |
|---|---|---|
| **Categoria da skill** | `PHYS` · `MAGI` · `STAT` | `PHYS` = habilidade física · `MAGI` = habilidade mágica · `STAT` = habilidade de status, marca ou enfraquecimento/buff. |
| **Tipo de dano** | `PHYS` · `MAGI` · `DMG` | `PHYS` = dano físico · `MAGI` = dano mágico · `DMG` = **dano sem tipagem** *(untyped)*. |
| **Número de alvos** | `1T` · `2T` · `3T` | `1T` = 1 alvo · `2T` = 2 alvos · `3T` = 3 alvos *(T = target)*. |

**Formato padrão de ficha:** `(<ACT>ACT/<EN>EN/<CATEGORIA>/<ALVOS>)`, por exemplo `(4ACT/0EN/PHYS/1T)`.

---

## 2. Regra Global — Definição Canônica de Alvo Vulnerável

> **Alvo vulnerável** é qualquer combatente que:
> 1. Esteja realizando uma **ação não-ofensiva**, **OU**
> 2. Esteja sob um **efeito que força o `PASS`**, como **paralisação** *(ex.: `Angel Hug`, D-118)* ou **aprisionamento** *(ex.: `Umbral Gaze`, D-124 §2.3, que atua como `PASS` automático)*.

---

## 3. Catálogo Canônico — Lote 2 (5 base + 2 evoluções `ZAHAV`)

| # | Nome Canônico | Evolução `ZAHAV` | Origem (Survival D-106) | Ficha (`ACT/EN/CAT/ALVO`) | Efeito Canônico |
|---|---|---|---|---|---|
| 1 | **Stone Crush** | — | Rework de `HEAVY CRUSH` (`heavy_crush`) | `4ACT / 0EN / PHYS / 1T` | O usuário arremessa uma grande rocha no alvo, causando **`30 PHYS (+ATK)`** de dano. |
| 2 | **Energy Blow** | — | Rework de `FINISHING BLOW` (`crushing_blow`) | `3ACT / 0EN / MAGI / 1T` | **`COND`:** só pode ser realizado em **alvos vulneráveis** ou com **≤ 1/4 da vida restante** *(25% do HP máx.)*. Causa **`25 DMG + MAK`** e **rouba metade do EN máximo do alvo permanentemente**. |
| 3 | **Drain Claw** | **Vital Claws** | Rework de `LIFE DRAIN` (`life_drain`) | `2ACT / 15EN / PHYS / 1T` | Finca uma garra no alvo e rouba sua vitalidade, tomando **`15 HP + 1/4 da vida máxima do alvo`**. |
| 3Z | **Vital Claws** *(ZAHAV)* | Evolução de `Drain Claw` | — | `3ACT / 25EN / PHYS / 1T` | Finca duas garras no alvo, roubando sua energia vital, tomando **`30 HP + 1/4 da vida máxima` e `15 EN`** do alvo. |
| 4 | **Weaken** | **Weakenen** | Rework de `CURSE RAY` (`curse_ray`) | `1ACT / 10EN / STAT / 1T` | Uma esfera de energia azul enfraquece as capacidades mágicas do alvo, reduzindo sua **`MEF` em `5 (+50% MAK do usuário)`** até o fim do combate. **Pode sofrer dispell.** |
| 4Z | **Weakenen** *(ZAHAV)* | Evolução de `Weaken` | — | `2ACT / 15EN / STAT / 2T` | Cria uma esfera de energia maior e dispara contra os alvos, reduzindo suas capacidades mágicas (**`MAK` e `MEF`**) em **`10 (+50% MAK do usuário)`** até o fim do combate. **Pode sofrer dispell.** |
| 5 | **Mark of Sun** | — | Rework de `SPIRIT BRAND` (`spirit_bolt`) | `4ACT / 20EN / STAT / 1T` | Um sol surge acima do alvo, fazendo com que sofra **`20 MAGI` extra** de todo ataque que receber até o fim do próximo round. |

*(Todas as evoluções `ZAHAV` seguem a D-118: acionadas segurando `A`, nome em dourado, custo de 20 SP após a conclusão; outline dourado exclusivo de `ZAHAV` nos VFX não-reza conforme D-125.)*

---

## 4. Diretrizes de VFX (D-125)

Todas as 7 entradas acima (5 base + 2 `ZAHAV`) são ataques não-reza e deverão seguir estritamente [`docs/NON_PRAYER_VFX_STYLE.md`](NON_PRAYER_VFX_STYLE.md) (*Rabisco Anatômico Grotesco 12 FPS + Interferência Hipnótica Moiré* em paleta sombria, sem neon; **outline dourado exclusivo em `Vital Claws` e `Weakenen`**; sem letras hebraicas). Protótipos HTML interativos e validação visual do criador estão **PENDENTES**.

---

## 5. Pendências abertas para fechamento antes da implementação

1. **`DMG` (dano sem tipagem):** `DMG` ignora `DEF` e `MEF` completamente, e ainda passa pela barra de ritmo / bloqueio / vantagem de SP, ou é dano direto sem mitigação de defesa?
2. **`Energy Blow` — escopo do "permanentemente":** o roubo de metade do EN máximo do alvo dura **até o fim do combate atual** (como `Weaken`/`Weakenen`), ou persiste fora do combate/save se atingir o jogador ou for usado pelo Fallen? E contra alvos sem EN (ex.: Yoch, que usa PP), causa apenas o dano `25 DMG + MAK`?
3. **`Drain Claw` / `Vital Claws` — fórmula do roubo:** `15 HP + 1/4 HP máx.` (e `30 HP + 1/4 HP máx. + 15 EN`) é dano direto sem `DEF`, ou sofre redução de `DEF`/barra de ritmo/bloqueio? O usuário cura **100% do HP efetivamente drenado** (limitado ao HP máximo) e recupera os `15 EN` (limitado ao EN máximo)? Há teto contra chefes/Guardiões/Anjos?
4. **`Weaken` / `Weakenen` — acúmulo, piso e seleção `2T`:** múltiplos usos no mesmo alvo acumulam ou prevalece apenas o maior valor? Qual é o piso mínimo de `MAK`/`MEF` (`0` ou `1`)? `Weakenen` (`2T`) exige 2 alvos distintos (se houver) ou pode acertar o mesmo alvo duas vezes? O dispell usa `Tahorah` (D-112) e/ou itens futuros?
5. **`Mark of Sun` — multi-hit, mitigação e dispell:** os `20 MAGI` extras aplicam-se **por golpe** (em ataques multi-hit como `Lunge`, `Fang Spine`, `Ignoma Esh`) ou **por ação**? Passam pela `MEF` do alvo? `Mark of Sun` também pode sofrer dispell via `Tahorah`?
6. **Unificação com `Vuln Pierce` (D-124):** `Vuln Pierce` passa a usar exatamente esta mesma definição de **Alvo Vulnerável** (incluindo alvos sob efeito que força `PASS`, como paralisação/aprisionamento)?
