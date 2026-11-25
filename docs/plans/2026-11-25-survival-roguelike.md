# Survival Mode → roguelike de verdade — plano (2026-11-25)

> Pedido do criador: "quero que faça grandes melhorias no modo survival pra ser um
> roguelike bom de verdade, principalmente quanto aos status, os inimigos, a progressão,
> itens e outras coisas, te dou completa liberdade criativa (SE PLANEJE ANTES, PEGUE
> REFERENCIAS)".
>
> Regras que continuam valendo: combate segue `docs/COMBAT_SPEC.md`; toda batalha usa o
> layout D com inimigos 15% menores (D-053); nada de commit/push sem autorização; a
> validação visual é só do criador. As decisões abaixo foram tomadas sob a **liberdade
> criativa dada pelo criador** e registradas como D-066 a D-076. Qualquer uma pode ser
> revertida isoladamente.

## 1. Diagnóstico do modo atual (antes desta rodada)

| Área | Como estava | Problema de roguelike |
|---|---|---|
| Estrutura | 1 labirinto fixo, 35 demônios embaralhados nele | Sem curva de ritmo: um tier 5 pode estar ao lado do início; não há "atos", chefe nem clímax |
| Cura | `HEAL` grátis e infinito no santuário | Zero atrito: HP nunca é recurso; risco/recompensa some |
| Inimigos | Status fixos; IA = sorteio igual entre ATAQUE e skills; alvo sempre o de mais SP | Todos se comportam igual; nada para ler nem planejar |
| Elites | +status e um afixo **só no nome** (BRUTAL/SWIFT… não faziam nada) | Promessa sem efeito; sem recompensa própria além de Macca ×2 |
| Status/progresso | Absorção dá +1..4 num atributo aleatório ou skill (30%); HP/EN nunca crescem; Yoch nunca cresce | Pouca decisão; o aliado não tem arco; sem raridade |
| Itens | 2 consumíveis (BEAD, CHAKRA) | Loja sem decisão |
| Relíquias | 12 relíquias só de atributo; 6 já possuídas no início; nunca se acha relíquia na run | Nenhum achado, nenhuma sinergia |
| Eventos | Nenhum | Exploração só serve para achar luta |
| Meta | Score → desbloqueia relíquias | Sem dificuldade crescente, sem compêndio |

## 2. Referências e lições (fontes no fim)

**Slay the Spire (Mega Crit).** *Intenções* dos inimigos visíveis antes do turno do
jogador — o jogo vira leitura e planejamento em vez de reação ao acaso. Mapa com
caminhos de risco diferente; **elite = relíquia garantida**; chefe no fim de cada ato
com relíquia de chefe escolhida entre 3. Relíquias pequenas que distorcem a identidade
da run. Ascensões: dificuldade empilhada desbloqueada por vitória.
→ *Lições usadas:* intenção do inimigo (D-069); elite dá relíquia, guardião dá escolha
de 3 (D-070); 5 estratos com guardião (D-066); OMEN como Ascensão (D-075).

**Hades (Supergiant).** Bênçãos com **raridade** (comum/rara/épica) e **bênçãos duplas**
que só aparecem quando você já tem as duas metades — sinergia como recompensa por
comprometer o build. Heat/Pact: o jogador escolhe a dificuldade em troca de recompensa.
→ *Lições:* raridade nas ofertas de absorção (D-071); **Pactos (covenants)**: pares de
relíquias no mesmo aliado liberam um terceiro efeito (D-073); OMEN com bônus de score
(D-075).

**Darkest Dungeon (Red Hook).** Atrito: o grupo se desgasta entre lutas e o recurso de
cura é escasso; luz baixa = mais perigo e mais saque. Curios: pontos do mapa com escolhas
de risco.
→ *Lições:* cura grátis só uma vez por estrato (D-068); eventos com troca HP↔recompensa
(D-074); absorver com pouco HP sobe a raridade (risco/recompensa, D-071).

**Shin Megami Tensei / Persona (Atlus).** Fusão com **herança de habilidades**: o que você
consome define o que você ganha; Press Turn recompensa explorar fraquezas e o inimigo usa
a mesma regra; compêndio de demônios.
→ *Lições:* a absorção oferece primeiro os atributos fortes do demônio (herança, D-071);
afinidade continua vindo do COMBAT_SPEC (sem mexer no Press Turn); compêndio (CODEX)
persistente (D-075).

**Inscryption (Daniel Mullins).** Sacrifício como recurso; altares que trocam algo seu
por poder (transferência de sigilos).
→ *Lições:* ALTAR DE SANGUE troca HP máximo atual por relíquia; ORÁCULO troca Macca por
skill ou aposta atributos (D-074).

**Balatro (LocalThunk).** Poucos slots (5 coringas) + efeitos que **se multiplicam**
entre si: a graça é montar o motor. Efeitos multiplicativos marcados de forma distinta.
→ *Lições:* slots limitados (2 relíquias por aliado, mantido) tornam cada relíquia uma
decisão; pactos dão o "estalo" de combo (D-073).

**Risk of Rain (Hopoo).** Dificuldade sobe com o tempo/estágio; itens empilham.
→ *Lições:* cada estrato traz demônios de tier maior e guardiões mais fortes (D-066);
itens de loja empilham na bolsa (D-072).

**FTL (Subset Games).** Setores com balizas desconhecidas: você só sabe o que é um evento
ao chegar; a frota rebelde empurra para frente; lojas com estoque variável por setor.
→ *Lições:* eventos aparecem como figuras no corredor e só revelam as opções ao falar
(D-074); loja com estoque rotativo por estrato e uma relíquia à venda (D-072);
descer o estrato fica disponível ao derrubar o guardião, mas ficar mais para lutar dá mais
absorções (pressão de escolha, D-066).

## 3. O que será feito (escopo)

### D-066 — Estratos e guardiões (ritmo)
- A run tem **5 estratos**. Os 35 demônios são ordenados por (tier, SP) e divididos em 5
  grupos de 7: o estrato 1 tem os 7 mais fracos, o 5 os 7 mais fortes.
- O mais forte de cada grupo é o **GUARDIÃO** (WARDEN): HP ×1,5, +2 ATK/MAK/DEF/MEF,
  luta sempre com até 2 escoltas do mesmo estrato ainda vivas.
- Derrotar o guardião abre `DESCEND` no santuário. Descer: novo labirinto, posição no
  início, mapa visitado zerado, inimigos do novo estrato. Os outros demônios do estrato
  são opcionais (mais absorções e Macca vs. mais desgaste).
- Derrotar o guardião do estrato 5 = **SURVIVAL CLEARED**.
- Reforços passam a vir do **mesmo estrato** (antes vinham de qualquer tier).

### D-067 — Labirintos por estrato
- Estrato 1 mantém o labirinto feito à mão (`SurvivalData.MAZE`).
- Estratos 2–5: labirinto 25×21 gerado pela semente (backtracker em células ímpares +
  ~35% de becos sem saída abertos em laço, para a perseguição não ficar trivial), com o
  mesmo santuário central e a mesma célula inicial. Teste BFS garante conexão.

### D-068 — Economia de cura
- `HEAL` no santuário é **grátis uma vez por estrato**; depois custa `15 × estrato` M.

### D-069 — Temperamentos e intenções dos inimigos
- Cada demônio tem um temperamento: BRUTE (prefere golpes físicos), CASTER (prefere
  magias), SUPPORT (cura/buff quando ferido ou sem buff), HUNTER (mira o herói com menor
  % de HP), TRICKSTER (sorteio uniforme, comportamento antigo).
- No início de cada rodada a primeira ação de cada inimigo é sorteada e **mostrada acima
  dele** (ex.: `ATTACK > FALLEN`, `HELLFIRE > ALL`, `MEND`), e é essa ação que ele executa
  (se ainda puder pagar). Mudança só no `survival_battle.gd`: as regras de reação,
  defesa, contra-ataque, atos e REST do COMBAT_SPEC não mudam.

### D-070 — Elites com afixo real e saque
- BRUTAL +4 ATK; SWIFT +5 AGI; STONE afinidade RESIST e +4 DEF; BURNING ganha
  EMBER TOUCH; VAMPIRIC ganha LIFE DRAIN. Elite dá **1 relíquia** ao ser derrotado;
  guardião dá **escolha de 1 entre 3** relíquias.

### D-071 — Status e absorção com raridade e herança
- Ofertas com raridade: COMUM (+1/+2), RARA (+3/+4), ÉPICA (+6, ou +3/+3 em dois).
  Peso da raridade sobe por estrato. Com HP < 35% a raridade sobe um nível.
- **Herança**: a primeira oferta de atributo é um dos 2 atributos mais fortes do demônio.
- HP máximo (+6/+10/+16) e EN máximo (+3/+5/+8) entram nas ofertas.
- **Yoch cresce**: 25% das ofertas podem ser `YOCH +n STAT` (ganhos próprios da run).
- 30% de skill nova continua; relíquias podem subir.

### D-072 — Itens e loja
- Novos consumíveis: MEDICINE (+50 HP), SOMA (HP e EN cheios em um aliado),
  BLAST STONE (18 de dano fixo num inimigo).
- A loja vira painel próprio (`SHOP`) com estoque do estrato: BEAD e CHAKRA sempre, mais
  2 itens rotativos e 1 relíquia à venda, preços sobem por estrato.

### D-073 — Relíquias com efeito, aquisição e pactos
- Começa com **1** relíquia inicial (sorteada pela semente), não 6. Outras vêm de elites,
  guardiões, eventos e da loja.
- 10 relíquias novas com efeito (Macca +50%, 4 opções na absorção, chance de skill
  +25%, cura pós-vitória, +1 estágio de ATK no início da luta, +2 PP da Yoch no início,
  itens curam +50%, imunidade a queimadura, skills chegam identificadas, loja −25%).
- **Pactos**: certos pares no mesmo aliado dão um bônus extra (ex.: SHARD OF URIM +
  EMBER TOOTH = WRATH +4 ATK).
- Continua o limite de 2 por aliado (escolha de build, como os slots do Balatro).

### D-074 — Eventos
- 3 eventos por estrato em células da semente, como figuras SMT no corredor (marca no
  automapa como NPC): ALTAR DE SANGUE, ESPÍRITO ERRANTE, ORÁCULO, MERCADOR
  (Jack Frost). Cada um tem 2–3 escolhas e some depois de usado.

### D-075 — Meta: OMEN, CODEX e score
- OMEN 0–5 (como Ascensão/Heat), escolhido no santuário antes da primeira luta;
  nível n+1 desbloqueia ao vencer no nível n. Efeitos cumulativos: (1) inimigos +15% HP,
  (2) HEAL nunca grátis, (3) elites 35%, (4) 2 continues, (5) guardiões +3 ATK/MAK.
  Score ×(1 + 0,2×OMEN).
- CODEX: demônios derrotados em qualquer run (compêndio), mostrado no fim.
- Score novo: derrotados×100 + estrato×300 + guardiões×250 + Macca/2 + continues×100.

### D-076 — Save da run v2
- Versão 2 com migração da v1 (campos novos entram com padrão; run v1 continua no
  estrato 1). Validação usa o labirinto do estrato salvo.

## 4. Fora de escopo (não mexer: sessões paralelas)
- `playable_hud.gd` (cartas de papel), regra base da absorção, ABSORB como ação de 2 ATOS,
  REST como passe. Toda mudança fica em `scripts/survival/`, cenas do survival e testes
  `verify_survival_*`. O override de `_perform_absorption` do survival só ganha o contexto
  novo (raridade/Yoch); merges futuros devem conferir esse override.

## 5. Verificação
- Testes novos: `verify_survival_strata.gd` (partição, guardiões, labirintos BFS ×200
  sementes, descida, clear), `verify_survival_enemies.gd` (temperamentos, intenção
  executada, afixos), `verify_survival_items_relics.gd` (loja, itens novos em batalha,
  relíquias com efeito, pactos, eventos), e os antigos `verify_survival_*` atualizados.
- GUT completo + todos os `verify_*`.
- Capturas: mundo (estrato 2 gerado, evento na frente, painel de loja, painel de evento,
  painel de relíquias com pacto, OMEN), batalha (intenções sobre 1/2/3 inimigos,
  guardião, elite, painel de raridade). Todas abertas e inspecionadas por mim; o
  julgamento é do criador.

## Fontes
- Slay the Spire — [Wikipedia](https://wikipedia.com/wiki/Slay_the_Spire); [Road to the IGF (Game Developer)](https://www.gamedeveloper.com/disciplines/road-to-the-igf-mega-crit-games-i-slay-the-spire-i-); [PC Gamer, Best Design 2019](https://pcgamer.com/best-design-2019-slay-the-spire)
- Hades — [Prima Games, duo boons](https://primagames.com/tips/hades-what-are-duo-boons-how-get-duo-boons); [Prima Games, legendary/heroic/duo](https://primagames.com/gaming/hades-guide-legendary-heroic-duo-boons); [Screen Rant, duo boons](https://screenrant.com/hades-duo-boons-guide/)
- Darkest Dungeon — [Game Developer, deep dive do sistema de Affliction](https://gamedeveloper.com/design/game-design-deep-dive-i-darkest-dungeon-s-i-affliction-system); [Gamepressure, luz](https://www.gamepressure.com/darkestdungeon/light-level-and-its-influence/z28424)
- Shin Megami Tensei — [Megaten Wiki, Skill Inheritance](https://megatenwiki.com/wiki/Skill_Inheritance); [Gematsu, Press Turn no SMT V](https://gematsu.com/2021/08/shin-megami-tensei-v-details-tao-yuzuru-ichiro-miyazu-hayao-press-turn-battles-magatsuhi-skills-and-skill-potentials); [Game Developer, análise de Nocturne](https://www.gamedeveloper.com/business/nightfalls-shin-megami-tensei-nocturne-analysis)
- Inscryption — [Game Developer, game jam "sacrifices"](https://www.gamedeveloper.com/design/how-game-jam-sacrifices-became-inscryption); [Wikipedia](https://en.wikipedia.org/wiki/Inscryption)
- Balatro — [Game Informer, entrevista](https://www.gameinformer.com/interview/2024/03/21/balatro-was-almost-called-joker-poker-and-other-details-from-its-creator); [PC Gamer, 150 coringas](https://www.pcgamer.com/games/card-games/balatro-was-only-supposed-to-have-120-jokers-but-instead-of-correcting-a-publisher-mistake-localthunk-just-made-30-more-of-them/)
- Risk of Rain — [Wikipedia ("difficulty = time")](https://en.wikipedia.org/wiki/Risk_of_Rain); [RoR2 wiki, Difficulty](https://riskofrain2.wiki.gg/wiki/Difficulty)
- FTL — [FTL wiki, Events](https://ftl.fandom.com/wiki/Events); [Wikipedia](https://wikipedia.com/wiki/Justin_Ma)

Observação honesta: boa parte das fontes acima é secundária (wikis, guias, imprensa);
nenhuma fala de desenvolvedor foi citada como prova de regra. As lições acima são leitura
de design minha a partir dessas fontes.

## Rodada 2 — decisões do criador (2026-11-25, ainda NÃO implementadas)

Respostas do criador nesta conversa (cada item é decisão dele):

1. O roguelike já implementado (D-066..D-076) fica **como base**.
2. Total de **88** no modo, **contando os anjos**.
3. Os demônios comuns novos são **sorteados aleatoriamente** entre os 534 battlers de
   `Shin Megami Tensei VX The Genesis/.../Graphics/Battlers`.
4. **Metatron sai** (só existia como imagem pintada, sem battler).
5. Chefes de dungeon = anjos SMT terminados em EL: **Aniel, Kazfiel, Michael, Ophaniel,
   Raphael, Tzaphkiel, Uriel, Zaphkiel** (8). Tzaphkiel e Zaphkiel entram os dois, mesmo com
   o mesmo sprite. O **Herald Gabriel do SMT sai**.
6. **Samael** (Vile Samael) é chefe **secreto**.
7. O **último chefe, o mais forte, é o Gabriel original do criador** (`art/gabriel og.png`,
   versão dourada), substituindo o Metatron.
8. O número de dungeons segue o número de anjos: **8 EL + Gabriel = 9 dungeons** (Samael à parte).
   Conta resultante (minha, a confirmar): 8 EL + Gabriel + Samael = 10 anjos → **78 demônios
   comuns** (35 atuais + 43 sorteados).
9. Todas as dungeons devem ser **visualmente diferentes em textura, mapa, interações e NPCs**.

10. **Tzaphkiel e Zaphkiel** (mesmo sprite) são **chefes em dupla** na mesma dungeon. Com isso
    a run tem **8 dungeons** (a contagem de 10 anjos e 78 comuns não muda).
11. **Ordem aprovada** (proposta pelo EXP de chefe no SMT VX, `data/extracted/enemies.json`):
    1 Kazfiel · 2 Zaphkiel + Tzaphkiel (dupla) · 3 Ophaniel · 4 Aniel · 5 Uriel · 6 Raphael ·
    7 Michael · 8 Gabriel original (o mais forte). Samael à parte, secreto.

12. Cada uma das 7 primeiras dungeons **representa um pecado capital**; a 8ª, do **Gabriel**,
    representa um **oitavo pecado: a Perfeição**. Visualmente, cada dungeon segue uma ideia
    estética do seu pecado.
13. **Samael fica de fora por ora** (não entra nesta rodada).

14. Sem o Samael: **9 anjos + 79 demônios comuns = 88** (os 35 atuais + 44 sorteados).

15. **Ligação anjo-pecado aprovada** (proposta minha, com motivo de lore):
    1 Kazfiel — Preguiça (Kafziel/Cassiel, anjo de Saturno, melancolia e lentidão) ·
    2 Zaphkiel + Tzaphkiel — Inveja (gêmeos idênticos; o sprite é um olho, o "olho gordo") ·
    3 Ophaniel — Avareza (os Ofanim são rodas; a roda da fortuna que acumula) ·
    4 Aniel — Gula (Haniel/Anael, anjo de Vênus e do prazer em excesso; ligação mais fraca) ·
    5 Uriel — Ira ("fogo de Deus", espada flamejante, julgamento) ·
    6 Raphael — Luxúria (prende Asmodeus, demônio da luxúria, no Livro de Tobias) ·
    7 Michael — Soberba ("quem é como Deus?", vence o orgulho de Lúcifer) ·
    8 Gabriel original — Perfeição.

Pendente (o criador decide): o que muda em cada dungeon (texturas, tipo de mapa,
interações, NPCs); força dos chefes anjos.
