# Skills Canônicas Revisadas — Lote 3 (Físicos Restantes) + Regra `STURDY` + Remoção de `Frost Lance` (D-139)

**Decisão:** D-139 · 2026-11-27 (decisão do criador)  
**Estado:** **CANÔNICO — DESIGN E VISUAIS (4/4) APROVADOS DE PRIMEIRA; PRONTO PARA IMPLEMENTAÇÃO NO GODOT**  
**Índice canônico:** [`docs/DECISIONS.md`](DECISIONS.md) · **GDD:** [`docs/GDD.md`](GDD.md) (Apêndice A) · **Combate:** [`docs/COMBAT_SPEC.md`](COMBAT_SPEC.md) · **Fronteira Canônica:** [`docs/CANON_BOUNDARY.md`](CANON_BOUNDARY.md) · **Lote 1 (D-124):** [`docs/CANON_SKILLS_D124.md`](CANON_SKILLS_D124.md) · **Lote 2 (D-131):** [`docs/CANON_SKILLS_D131.md`](CANON_SKILLS_D131.md) · **Estilo VFX Não-Reza (D-125):** [`docs/NON_PRAYER_VFX_STYLE.md`](NON_PRAYER_VFX_STYLE.md) · **HTML Canônico (4/4):** [`docs/vfx_refs/d139/README.md`](vfx_refs/d139/README.md) · **Dossiê de Construção & Validação:** [`docs/VALIDATION_LOG_D139.md`](VALIDATION_LOG_D139.md) · **Prompts Faseados:** [`docs/CLAUDE_PROMPTS_D139.md`](CLAUDE_PROMPTS_D139.md)

> [!IMPORTANT]
> Com a **D-139**, **todas as 10 habilidades físicas originais do Survival (D-106) foram encerradas**: 9 promovidas/reworked ao cânone (Lotes 1, 2 e 3) e 1 (`FROST LANCE`) **removida no geral** até que a estética visual das magias dos Animais seja definida. Restam apenas **13 habilidades não-canônicas** no Survival (7 mágicas + 6 suportes/curas).

---

## 1. Catálogo Canônico — Lote 3 (3 base + 1 evolução `ZAHAV`)

| # | Nome Canônico | Evolução `ZAHAV` | Origem (Survival D-106) | Ficha (`ACT/EN/CAT/ALVO`) | Efeito Canônico |
|---|---|---|---|---|---|
| 1 | **Twin Fang** | — | Promoção direta de `TWIN FANG` (`twin_fang`) | `2ACT / 5EN / PHYS / 1T` | 2 golpes físicos de **`5 PHYS (+ATK)`** no mesmo alvo. **COMBO:** se o 1º golpe acertar, o 2º golpe causa **`+50%` de dano**. |
| 2 | **Blade Dance** | — | Rework de `BLADE DANCE` (`blade_dance`) | `ALL ACT / 0EN / PHYS / Alvo Intercalado` | Gasta **todas as ações (`ACT`) restantes** do usuário para executar **`ACT + 1` golpes** *(ex.: 4 ACT → 5 golpes; 2 ACT → 3 golpes)* intercalando alvos, com cada golpe causando **`15 PHYS` extra** *(+ATK)*. **Não pode ser reagido ofensivamente** *(alvo só pode `DEFEND`, sem `COUNTER`)*. **Cooldown:** só pode ser usada **1× a cada 2 rounds** *(usou no Round 1 → bloqueada no Round 2 → liberada no Round 3)*. |
| 3 | **Rock Body** | **Stone Body** | Rework de `STONE GRASP` (`stone_grasp`) | `1ACT / 10EN / STAT / SELF` · **`IMEDIATO`** | O usuário tem seu corpo enrijecido como uma dura pedra, recebendo **`STURDY`** até o fim do round atual. *(Resolve ao anunciar, sem reação.)* |
| 3Z | **Stone Body** *(ZAHAV)* | Evolução de `Rock Body` | — | `1ACT / 25EN / STAT / SELF` · **`IMEDIATO`** | O usuário tem seu corpo enrijecido como duras rochas, recebendo **`STURDY`** e **`+15 DEF`** enquanto `STURDY` permanecer *(até o fim do round, ou até quebrar/ser dissipado)*. *(Resolve ao anunciar, sem reação.)* |

*(Evolução `ZAHAV` segue a D-118: acionada segurando `A`, nome em dourado, custo de `20 SP` após conclusão; outline dourado `#ffd84a` exclusivo de `ZAHAV` nos VFX não-reza conforme D-125. Zero campo `affinity`, conforme D-119/D-138.)*

---

## 2. Remoção Global de `FROST LANCE`

- **Decisão do criador (2026-11-27):** **`FROST LANCE` (`frost_lance`) é removida no geral** — sai tanto do caminho de canonização quanto do catálogo/pool do Survival (`SkillBook.DEFS`, `SurvivalData.SURVIVAL_SKILLS`, `HEBREW_SKILLS` e ficha de `PAZUZU`), até que seja definida a estética visual das magias dos **Animais** (`D-138`: `LEAF`, `VENO`/`TOXI`, `AQUA`).
- **Substituição fechada em `PAZUZU` (2026-11-28):** por ordem do criador (*"escolhe outras 3 aleatórias"*), ao remover `&"frost_lance"` de `PAZUZU` (`scripts/survival/survival_data.gd`), sua ficha recebe **3 outras skills** do pool atual (mantendo `ember_touch`): **`[&"ember_touch", &"ignoma", &"twin_fang", &"rock_body"]`** *(assinatura única entre os 35 demônios, cumpre `skills.size() >= 2` em `verify_survival_data.gd` e estreia `ignoma`, `twin_fang` e `rock_body` no Guardião do Estrato 4)*.

---

## 3. Regras Globais Canônicas Introduzidas na D-139

### 3.1 Novo Estado Positivo: **`STURDY`**
1. **Natureza:** efeito positivo (**buff**), aplicável via `Rock Body` / `Stone Body` (`IMEDIATO`, `SELF`).
2. **Duração:** dura **até o fim do round atual** *(1 tick de fim de rodada)*.
3. **Escudo no sistema de ponteiros (anti-interrupção D-049):**
   - Enquanto `STURDY` estiver ativo, o combatente **não pode ser interrompido durante uma ação** no duelo de contra-ataque (`COUNTER` / sistema de ponteiros).
   - A ação atual e a fila restante do combatente **não são canceladas** e ele não perde atos de fila por interrupção.
   - **Dano e efeitos do contra-ataque ainda ocorrem normalmente.**
4. **Bloqueio de efeitos debilitantes (consumo de `STURDY`):**
   - Se o combatente com `STURDY` for atingido por um **efeito debilitante** *(status negativos que enfraquecem/incapacitam/penalizam: `blind`, `chill`, `weaken`, `weaken_mef`, `weaken_mak`, `mark`, `mark_of_sun`, `snare`, `break`, `sleep`, `slow`, `chaki`, `paralyzed`, `trapped`, `bleed`, `burn` — isto é, a classe de condições negativas removíveis por `Tahorah`)*, **`STURDY` bloqueia esse efeito debilitante e é consumido/perdido no processo**.
   - Se o `STURDY` provinha de **`Stone Body [ZAHAV]`**, o bônus de **`+15 DEF`** está acoplado à permanência de `STURDY`: ao terminar o round, ao quebrar bloqueando um efeito debilitante ou ao sofrer dispell, o `+15 DEF` termina no mesmo instante.
5. **Dispell:** por ser um **efeito positivo**, qualquer **dispell inimigo** (que remova buffs positivos) afeta e remove `STURDY` (junto com o `+15 DEF` de `Stone Body`, se houver). `Tahorah` (D-112, limpa apenas status negativos em aliados) **não** remove `STURDY`.

### 3.2 Regras Especiais de `Blade Dance`
1. **Consumo total de atos (`ALL ACT` → `ACT + 1` golpes):**
   - Consome todos os `ACT` disponíveis do usuário no momento da declaração (`1` a `4 ACT`), executando exatamente `acts_spent + 1` golpes (`2` a `5` golpes).
   - Custo de **`0 EN`**.
   - Por gastar todas as ações restantes, encerra a montagem da fila desse turno (não aceita comandos adicionais após `Blade Dance`).
2. **Alvo Intercalado (`targets: "interleaved"`):**
   - Os golpes alternam entre alvos vivos disponíveis (ex.: `A → B → C → A → B` com 3 vivos; `A → B → A → B → A` com 2 vivos; repete o mesmo alvo com laço de retorno visual se só restar 1 vivo).
   - Caso um alvo caia no meio da sequência, os golpes restantes redirecionam automaticamente entre os alvos ainda vivos (ou encerram a sequência se não houver mais nenhum alvo vivo).
3. **Sem reação ofensiva (`no_counter: true`):**
   - Alvos de `Blade Dance` **podem usar `DEFEND`** normalmente na barra de defesa, mas **não podem declarar `COUNTER`** nem reagir ofensivamente.
4. **Cooldown de 2 rounds (`cooldown_rounds: 2`):**
   - Ao usar `Blade Dance` na rodada `R`, ela fica bloqueada na rodada `R + 1` e volta a ficar disponível na rodada `R + 2` *(ex.: usada no Round 1 → indisponível no Round 2 → disponível no Round 3)*.
5. **Poder por golpe confirmado (criador, 2026-11-28):**
   - **Confirmado: `15 PHYS (+ATK)` fixo em cada golpe individual** (sem escalada acumulativa; padrão idêntico a `Fang Spine` e `Stone Crush`).

### 3.3 `IMEDIATO` em Habilidades `SkillBook` (extensão da D-118)
- `Rock Body` e `Stone Body [ZAHAV]` reutilizam a palavra-chave canônica **`IMEDIATO`** (`D-118`): resolvem no momento em que são anunciadas (sem janela de reação/contra-ataque do oponente), descontando `1 ACT` e `10 EN` / `25 EN` na hora e permitindo que o usuário siga agindo no mesmo turno já protegido por `STURDY`.

---

## 4. Como os VFX Foram Construídos (Arquitetura D-125 + D-137)

Todos os 4 ataques da D-139 foram construídos integralmente sobre os **4 motores reutilizáveis** de [`docs/NON_PRAYER_VFX_STYLE.md`](NON_PRAYER_VFX_STYLE.md) (`boil` determinístico em **12 FPS** com silhueta `#050208` + duplo traço `hi`/`accent`, campo de **Interferência Hipnótica Moiré** em grade `5×5 px`, scanline warp + impact flash, e suporte integral a **Inimigos** e **3 cartões de Aliados Survival** da D-137):

1. **`Twin Fang` (`PALS.blood` — normal, zero ouro):**
   - Para diferenciá-lo visualmente de `Mazz Bite` (mandíbula inteira) e `Fang Sting` (ferrão único), foi criada a primitiva `drawTwinFangPair`: um par de presas curvas gêmeas com ranhura sangrenta interna.
   - A mecânica de **COMBO (+50%)** ganha leitura visual imediata: o Golpe 1 (`0.28 s`, diagonal `↗`) deixa 2 cicatrizes paralelas (`drawParallelGashes`) que permanecem acesas e geram um anel rabiscado de convergência até o Golpe 2 (`0.86 s`, diagonal `↘`), que desce em escala `1.32×` cruzando em **X** visceral + Moiré ampliado (`108×82`) + 12 respingos com gravidade.
2. **`Blade Dance` (`PALS.blade` — nova paleta aço sombrio `#dfe4ee` + carmesim `#8c1d30`, zero ouro):**
   - Escurece suavemente o palco (`0.28`) e liga cada alvo ao seguinte por uma **fita/rastro rabiscado em arco** (evidenciando o **Alvo Intercalado** tanto entre os 3 inimigos quanto entre os 3 cartões de aliados).
   - Em cada impacto (cadência de `0.33 s`), `drawCurvedBladeSlash` combina uma crescente negra de corte + sabre rabiscado em ângulos alternados (`-0.62`, `+0.72`, `-0.45`, `+0.88`, `-0.32`) que cresce de escala `0.92×` até `1.22×`, deixando cicatrizes residuais tremendo até o encerramento da dança + 6 faíscas por golpe.
3. **`Rock Body` (`PALS.stone` — normal, zero ouro):**
   - 7 placas angulosas irregulares (`drawRockPlate`) convergem com curva ease-out cúbica e travam no corpo/cartão em `0.44 s` com anel seco + poeira pétrea + Moiré `stone`.
   - **Estado persistente `STURDY`:** no inimigo, duas ombreiras pétreas nos flancos + escudo hexagonal `drawSturdyBadge` acima-direita; no cartão aliado, 4 cantoneiras pétreas nas quinas do cartão + `drawSturdyBadge` no **canto inferior-direito livre** (`y = 333`, estritamente abaixo do Battle Log).
   - **Demonstração de `STURDY` (`1.65 s`):** uma cúpula/arco de escudo rabiscado + 6 linhas radiais de estalo seco rebatem o choque de `COUNTER` mantendo postura firme (`UNINTERRUPTED!`).
4. **`Stone Body [ZAHAV]` (`PALS.zahavStone` — nova paleta `#8c7252` + ouro `#ffd84a` + `#1b140d`):**
   - Eleva o peso de "pedra" para "duras rochas": 10 blocos maiores em 2 ondas sucessivas com **veios internos e contornos dourados `#ffd84a`** exclusivos de `ZAHAV`, escurecimento `0.24`, tremor `±8.5 px` e 6 setas ascendentes douradas comunicando **`+15 DEF`**.
   - Mantém as mesmas regras de contenção no modo 3 Aliados (cantoneiras grossas + escudo dourado-pedra 100% abaixo do Battle Log).

---

## 5. Status de Aprovação e Próximos Passos

- **Validação visual do protótipo HTML (2026-11-27):** **4/4 APROVADOS DE PRIMEIRA** pelo criador (*"absolutamente perfeitos todos"*), sem necessidade de v2.
- **Implementação in-engine no Godot:** especificada em 3 fases prontas para execução em [`docs/CLAUDE_PROMPTS_D139.md`](CLAUDE_PROMPTS_D139.md); validação visual final no Godot pertence ao criador (`AGENTS.md` Regra 7).
