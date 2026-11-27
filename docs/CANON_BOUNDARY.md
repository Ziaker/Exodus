# Fronteira Canônica — EXODUS (D-117)

**Decisão:** D-117 · 2026-11-26 (decisão do criador)  
**Índice canônico:** [`docs/DECISIONS.md`](DECISIONS.md) · **GDD:** [`docs/GDD.md`](GDD.md) (Apêndice A)

Este documento separa de forma explícita o que pertence ao **jogo principal (canônico)** daquilo que é **exclusivo do modo Survival**, **backlog de referência** ou **placeholder/legado**.

---

## 1. CANÔNICO — Vai para o jogo principal (autoria/aprovação do criador)

### 1.1 Sistema de combate e interface
* **Economia de combate e ritmo** (`D-005`–`D-049`, `D-104`, `D-105`, `D-108`, `D-109`): teto de 4 atos, `REST`, `PASS`, `ABSORB` imediato (2 ACT, disputa de SP no mash em 2 s / 10 apertos / sorteio único, ganhos persistentes), fila em bloco contínuo, contra-ataque em barra dupla (`D-049`), barra de ritmo (50/80/100%, desvio só defendendo no centro), dano com vantagem de SP + variação ±10%.
* **UI e feedback** (`D-053`, `D-055`–`D-060`, `D-100`, `D-102`): resolução base `816×624`, fundo D (plasma animado), Battle Log de 2 linhas (`D-056`), ordem de turno por AGI no topo, setas + cartões de papel persistentes (`ATTACK`/`TARGET`/`DEFEND`/`COUNTER`/`REACT`), nomes coloridos por papel no log, letras hebraicas flutuantes em toda mudança de SP (`D-100`).
* **Cena principal de combate:** `scenes/battle/BattlePlayable.tscn`.

### 1.2 Sistema de Reza e todas as rezas — 11 do D-115 + as do D-118 (`D-048`, `D-107`, `D-112`, `D-113`, `D-115`)
* **Mecânica de PP:** humanos rezam com PP no lugar da EN (teto 8, +2 SP por PP, persiste entre lutas); inimigos reagem apenas a `PRAY` e `Ra'am` (`reactable: true`).
* **Catálogo canônico (11 rezas do D-115; com o D-118 o `scripts/core/prayer_book.gd` tem 29 entradas, listadas abaixo):**
  * Iniciais do Yoch (`D-048`): **Refuah**, **Haganah**, **Ra'am**.
  * Criadas em `D-107` e confirmadas canônicas (`D-115`): **Sanverim**, **Nechamah**, **Cherev**.
  * Criadas em `D-112` e confirmadas canônicas (`D-115`): **Tahorah**, **Magen**, **Gevurah**, **Mishpat**, **Zohar**.
  * *(Forma e momento de desbloqueio das 8 rezas além das 3 iniciais na campanha: **PENDENTE**.)*
* **Expansão canônica em design (`D-118`, [`docs/ANGEL_PRAYERS_AND_ZAHAV.md`](ANGEL_PRAYERS_AND_ZAHAV.md) — 20/20 magias implementadas em 2026-11-27; ZAHAV e IA inimiga PENDENTES):**
  * **8 novas rezas (PP):** `Esh`, `Shalhevet`, `Lehavah`, `Nogah`, `Chaki`, `Lior`, `Meir`, `Shachar`.
  * **6 magias de Anjos** (EN para anjos; Yoch aprende em PP ao derrotar um anjo): `Ur Esh`, `Seraf`, `Nitzotz`, `Esh Ochelet`, `Esh Sinai`, `Gever`.
  * **6 skills de Gabriel:** `Angel Hug`, `God's Message`, `Hasneh Habo'er`, `Adin` → `Adina` → `Adinut`.
  * **Regra `IMEDIATO`** (resolve ao anunciar, sem reação) e **sistema `ZAHAV`** (metade do jogo; botão `A`; +2 estágios de dano e +20% chance de efeito por 20 SP após concluir; evolução com nome dourado; acessível a Anjos e elites).
* **VFX canônicos (`D-052`, `D-113`):** absorção em letras hebraicas (`absorb_vfx.gd`) e **regra obrigatória de VFX 100% letras hebraicas** para todas as rezas ([`docs/PRAYER_VFX_RULE.md`](PRAYER_VFX_RULE.md), `pray_fx.gd`).

### 1.3 Skills canônicas do Prólogo e Expansão Canônica (`D-050`, `D-117`, `D-124`)
* **4 skills do Prólogo** (`SkillBook.KIND_SKILLS`): **LUNGE**, **BLEEDBUFF**, **HEAT WAVE**, **ENERGEAT** *(renomeada de Energy Eat em D-117; id interno `energy_eat`)* + aprendizado permanente a cada 4 absorções.
* **6 skills canônicas revisadas + 2 evoluções `ZAHAV` (`D-124`, [`docs/CANON_SKILLS_D124.md`](CANON_SKILLS_D124.md) — DESIGN CONFIRMADO; IMPLEMENTADO (mecânica e VFX; aguardando validação visual final do criador no Godot; ativação ZAHAV, IA de escolha das novas skills e distribuição na campanha PENDENTES)):**
  * **Mazz Bite** *(rework de `SHADOW BITE`)*, **Fang Sting** *(rework de `FANG FLURRY`)* → ZAHAV **Fang Spine**, **Vuln Pierce** *(rework de `SOUL PIERCE`)*, **Dark Breath** *(rework de `FROST BREATH`)*, **Umbral Gaze** *(rework de `VOID GAZE`)*, **Ignoma** → ZAHAV **Ignoma Esh**.
  * **3 regras globais canônicas (`D-124`):** `HIGH SPEED` (ponteiro 20% mais rápido e vantagem no contra-ataque), `BLEED` canônico (−20% cura recebida até o fim do próximo turno, acumula 4×) e `Temporização de ação` (dura X ações após o efeito; aprisionamento age como `PASS` automático perdendo a fila atual).

### 1.4 Personagens, raças, lore e mundo
* **Personagens e raças (`D-048`, `D-050`, `D-126`, `D-128`):** **Fallen / Deviron / Samael** (Daema, primeiro devilman, perfeitamente simétrico), **Yoch** (humano), **Maziks** (inimigos de silhueta com simetria perfeita, criados pelos anjos mediante manipulação de corpos humanos), **Anjos** (todos Daemas; imunes a Ra'am). Daema e demônio são raças distintas.
* **Cosmologia (`D-126`):** Maesto é o universo e o criador; as religiões o chamam Shaddai sem saber se existe, e só Daemas o chamam THÉOS (D-128); Daemas são únicos e imortais e originam espécies com capacidades herdadas mais fracas; Deviron absorve e se funde com outros seres. Humanos, anjos e Deviron fazem parte dos experimentos descritos no [GDD §15](GDD.md#15-cosmologia-e-teologia--confirmado--pendente); animais ainda não estão presentes. O tom sombrio é restrito à época de EXODUS. **D-127:** THÉOS é Maesto, sua designação formal; Shaddai é a designação das religiões da época, confirmada pela D-128. Alguns Daemas de inspiração egípcia (equivalentes aos animais de tier 4) são uma possibilidade autorizada, sem grande impacto narrativo; indivíduos e capacidades não estão definidos. **D-128:** tiers animais medem antropomorfização, não poder; Maesto cria toda vida e o conceito de energia; religião é conjunto de seres de diferentes raças; Daemas regeneram de 8 em 8 dias e só a assimilação permanente dos devilmen pode obliterá-los. Anjos expulsaram Deviron por inveja e medo; Maesto não tem relação com ele além da criação. Rezas são ensinadas pelos anjos em seus templos; toda magia de fogo por Gabriel. Ver GDD §§9, 10, 14 e 15.
* **Locais e exploração (`D-050`, `D-054`, `D-062`, `D-063`):** Prólogo ([`docs/PROLOGUE_SCRIPT.md`](PROLOGUE_SCRIPT.md)), abertura na **cratera de areia branca** (`D-063`), **Cafarnaum** em vista superior com saída para mapa-múndi (`D-062`), overworld em dungeon crawler 1ª pessoa (`D-054`).

---

## 2. NÃO-CANÔNICO — Exclusivos do Survival Mode (`for fun` / sandbox, fora da lore)

* **Estrutura roguelike (`D-066`–`D-076`, `D-101`, `D-114`):** 5 estratos de 7 demônios, Guardiões (`SUCCUBUS`, `INCUBUS`, `LAKSHMI`, `PAZUZU`, `BEELZEBUB`), `DESCEND`, labirintos 25×21 procedurais (estratos 2–5), **Necrópole Saturnina** como 1ª dungeon do Survival (`D-114`, [`docs/NECROPOLE_SATURNINA.md`](NECROPOLE_SATURNINA.md)), `OMEN` 0–5, `CODEX`, `DAILY`, score, 3 continues, `follow_hero` (`D-101`).
* **Santuário, relíquias e eventos:** `HEAL` pago por estrato, `SHOP` com inflação, `HIRE`, `RESERVE`, **23 Relíquias + 7 Pactos (`Covenants`)** (`scripts/survival/survival_relics.gd`), 4 eventos de corredor (`BLOOD ALTAR`, `WANDERING SPIRIT`, `HOODED ORACLE`, `FROST MERCHANT`).
* **IA/combate exclusivo do Survival:** temperamentos/intenções (`BRUTE`, `CASTER`, `SUPPORT`, `HUNTER`, `TRICKSTER`), 5 afixos de elite (`BRUTAL`, `SWIFT`, `STONE`, `BURNING`, `VAMPIRIC`) e absorção roguelike com raridades `COMMON`/`RARE`/`EPIC`.
* **Sistema de aliados do Survival (`D-111`, `scripts/survival/survival_allies.gd`):** run começa só com Fallen; recrutamento de demônios/humanos, Yoch raro (15%/estrato), reserva até 8, crescimento a cada 2 lutas, `MANUAL`/`AUTO`, 3 painéis estreitos.
* **Inimigos exclusivos do Survival:** 35 demônios SMT (`PIXIE` até `IZANAMI`) e 5 grupos genéricos de humanos sem lore (`HUMAN A/B/C`).
* **22 skills exclusivas do Survival (das 27 do `D-106`, `SurvivalData.SURVIVAL_SKILLS`, valores ainda marcados como proposta; 5 promovidas/reworked para o cânone em `D-124`):**
  * *10 físicas:* ~~`SHADOW BITE`~~ *(→ `Mazz Bite`, D-124)*, ~~`FANG FLURRY`~~ *(→ `Fang Sting`/`Fang Spine`, D-124)*, `HEAVY CRUSH`, ~~`SOUL PIERCE`~~ *(→ `Vuln Pierce`, D-124)*, `TWIN FANG`, `FROST LANCE`, `LIFE DRAIN`, `FINISHING BLOW` (`crushing_blow`), `BLADE DANCE`, `STONE GRASP`.
  * *11 mágicas (all foes):* `PIXIE DUST`, ~~`FROST BREATH`~~ *(→ `Dark Breath`, D-124)*, `HELLFIRE`, `SPIRIT BRAND` (`spirit_bolt`), `CURSE RAY`, `VENOM CLOUD`, `MIND DRAIN` (`mind_blast`), `THUNDER CALL`, `SOUL LEECH` (`spirit_wave`), `EMBER BURST` (`ember_touch`), ~~`VOID GAZE`~~ *(→ `Umbral Gaze`, D-124)*.
  * *6 suportes/curas:* `HOWL`, `PRIMAL ROAR`, `WAR CRY`, `MEND`, `DARK BOON` (`dark_siphon`), `RENEW`.
* **5 itens de loja do Survival (`D-072`):** `BEAD`, `CHAKRA`, `MEDICINE`, `SOMA`, `BLAST STONE`.
* **Cenas e scripts:** `scenes/survival/SurvivalWorld.tscn`, `scenes/survival/SurvivalBattle.tscn`, `scripts/survival/*`, `prototypes/necropole-battle/`.

---

## 3. NÃO-CANÔNICO — Backlog, placeholders e legado

* **Banco de vocabulário mágico hebraico (`D-116`, [`docs/MAGIC_VOCABULARY_BACKLOG.md`](MAGIC_VOCABULARY_BACKLOG.md)):** candidatos de referência para uso eventual (nenhum implementado nem canônico ainda).
* **Assets temporários / placeholders (`D-003`, `D-018`):** sprites, retratos, battlers e texturas de `Shin Megami Tensei VX The Genesis` e RTP do RPG Maker VX — nunca publicar no jogo final.
* **Cenas legadas e protótipos:** `scenes/battle/Battle.tscn` (substituída por `BattlePlayable.tscn`), pasta `prototypes/` e capturas em `captures/`.
