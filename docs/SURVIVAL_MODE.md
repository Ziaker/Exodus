# Survival Mode — modo à parte, "for fun"

Não faz parte da lore nem da campanha. Sandbox de combate e exploração para
testar os **35 demônios**, 27 habilidades placeholder, itens e continues. A
entrada é o comando `Survival` do menu do título.

## Entrada, texto e tutorial (D-121 a D-123, criador 2026-11-27)

- **Cutscene de entrada (D-121):** run nova pelo título abre `scenes/survival/SurvivalIntro.tscn`
  (`scripts/survival/survival_intro_cutscene.gd`, sobre o protótipo `prototypes/survival-intro`,
  opção D). Letras hebraicas formam o Kazfiel amarelo de letras, o mostrador das 8 portas (א–ח)
  e a moldura da caixa; a fala "adormece"; as letras se espalham e o mapa real abre com a
  piscada de quem acorda (`scripts/survival/survival_wake_blink.gd`). Z mostra a fala inteira e
  depois pula. Run retomada vai direto ao mapa. Falas placeholder.
- **Texto (D-122):** todo texto do Survival em inglês; nome do anjo em hebraico (קפציאל). O
  estrato 1 é **SATURNINE NECROPOLIS** no HUD.
- **Tutorial do curandeiro (D-123):** a 1ª conversa com o SANCTUARY KEEPER (uma vez por perfil,
  `keeper_intro` no meta) mostra 8 páginas sobre o modo e depois abre a barra.
- Verificação: `tools/capture_survival_intro_flow.gd` (fluxo real título → cutscene → mapa) e
  `tests/verify_survival_extra.gd` (tutorial).

## Aliados (D-111, criador 2026-11-26)

Especificação: `docs/plans/2026-11-26-survival-aliados.md`. Regras puras em
`scripts/survival/survival_allies.gd`; estado em `SurvivalState` (save **v3**: saves antigos com o
Yoch fixo são descartados e a run recomeça).

- A run começa **só com o Fallen**. Grupo: Fallen + até **2 aliados**; reserva do santuário até **8**.
- Aliados **demônios e humanos** (nunca anjos). Entram por:
  - **oferta ao vencer** (25% das vitórias): painel com a arte do derrotado, `Z: ACCEPT  X: REFUSE`;
    entra com a ficha que tinha na luta e HP/EN/PP cheios;
  - **HIRE** no santuário: 2 demônios do estrato (sem guardião) por **SP × 2 M**;
  - **encontros no mapa** (0–3 por estrato: 15/35/35/15%; 75% demônio / 25% humano), figura de
    frente como os eventos: conversa (entra), pede um consumível, pede **SP × 1 M**, ou luta-teste
    (entra só se vencer; sem absorção; HP/EN/PP/continues voltam ao fim, itens gastos não).
- **Yoch**: 15% por estrato; aviso `YOCH IS SOMEWHERE IN THIS STRATUM`; figura = battler
  `Zealot Masakado.png` completamente amarelo; SP sempre igual ao do Fallen; entra ao falar com ele.
- **RESERVE** no santuário troca grupo ↔ reserva. Aliado caído não luta até o **HEAL** (que revive).
- **Relíquias**: 1 por unidade (Fallen incluído); humanos (Yoch incluído) 2. A reserva não ativa perks.
- **Crescimento**: absorção só melhora o Fallen (a oferta `YOCH +n` saiu). Aliado vivo no fim da luta
  conta a luta; a cada 2, +1 (65%) / +2 (20%) / +3 (15%) num atributo; aviso no canto do mapa.
- **MANUAL / AUTO** por aliado: tecla **C** no mapa (status, consumíveis, configuração) e comando
  **PARTY** do Fallen na batalha (não gasta ato). AUTO = IA dos inimigos, sem barra, nunca reage.
- Batalha com 3 heróis: as 3 janelas dividem a largura das 2 ("3 estreitos"); a janela estreita
  mantém os 4 marcadores de ato e esconde o texto `ACT n/4`.
- Debug (auditoria 2026-11-26): `tools/debug_survival_soak.gd -- [lutas] [semente] [mapas]` joga
  lutas e ações de mapa aleatórias com um bot, captura erros de script por `Logger` e checa os
  invariantes do save; `tools/debug_survival_roundtrip.gd` faz as idas e voltas reais de cena
  (mapa → luta → mapa, oferta, luta-teste vencida e perdida).
- Prova: `tests/verify_survival_allies.gd` (2140 checks). Capturas: `tools/capture_survival_allies.gd`
  → `captures/allies/`. **O julgamento visual é do criador.**

As seções abaixo sobre a Yoch fixa no grupo (ofertas `YOCH +n`, 2 relíquias por aliado, ficha
HP 17/SP 45) descrevem a base anterior; onde divergem, vale este bloco.

## Primeira dungeon · Necrópole Saturnina (D-114)

O primeiro estrato começa no Pórtico dos Que Desistiram, junto ao santuário.
A dungeon reúne cinco zonas de 11 salas cada. A Ruptura é obrigatória para
chegar ao Sepulcro do Sétimo Peso, onde espera o guardião do Survival.
O santuário oferece `DESCEND` após a vitória. Os estratos 2 a 5 usam os
labirintos gerados pela semente.

O cenário usa pedra azul de chumbo, luz pendular e céu vermelho animado.
A câmera e o filtro Cartucho ocre + Fita de horror são os da exploração do
jogo. A maquete editável, a planta e os vídeos ficam na
[pasta de arte da Necrópole](../assets/generated/ambiente-e-interacoes/saturnina/percurso/refinamento_55/LEIA-ME.md).
Ao retomar um save compatível da planta antiga do estrato 1, a partida abre
no Pórtico com a economia e os inimigos já derrotados preservados.

## Roguelike (2026-11-25, D-066 a D-076)

Plano e referências (Slay the Spire, Hades, Darkest Dungeon, SMT/Persona, Inscryption,
Balatro, Risk of Rain, FTL): `docs/plans/2026-11-25-survival-roguelike.md`.

- **5 estratos** (`survival_strata.gd`): os 35 demônios ordenados por tier/SP em grupos de 7.
  Estrato 1 = Necrópole Saturnina; 2–5 = labirinto gerado pela semente. O **GUARDIÃO**
  (o mais forte do grupo) espera na célula mais funda, não persegue, tem moldura dourada no
  automapa, HP ×1,5 e 2 escoltas. Derrotá-lo libera `DESCEND`; o 5º encerra a run.
  Guardiões: SUCCUBUS, INCUBUS, LAKSHMI, PAZUZU, BEELZEBUB.
- **Intenções**: cada inimigo rola o temperamento (BRUTE, CASTER, SUPPORT, HUNTER,
  TRICKSTER) e a 1ª ação da rodada, que é a ação executada. D-119: o cartão sob a arte e o texto
  do temperamento não são mais desenhados.
- **Elites** com afixo real (BRUTAL, SWIFT, STONE, BURNING, VAMPIRIC) e 1 relíquia de saque;
  guardião: Macca ×2 e escolha de 1 entre 3 relíquias.
- **Absorção** com raridade COMMON/RARE/EPIC (sobe por estrato e com HP < 35%), herança do
  atributo forte do demônio, HP/EN máximos e ofertas `YOCH +n` (a Yoch cresce na run).
- **Santuário**: `HEAL` grátis 1× por estrato (depois 15×estrato M), `SHOP` (BEAD, CHAKRA +
  2 de MEDICINE/SOMA/BLAST STONE + 1 relíquia; +15% por estrato), `RELICS`, `DESCEND`,
  `OMEN` (só antes da 1ª luta), `NEW RUN`, `DAILY`, `TITLE`, `LEAVE`.
- **Relíquias**: começa com 1; 23 no total (12 de atributo + 11 de efeito), 2 por aliado,
  7 pactos por pares no mesmo aliado.
- **Eventos**: 3 por estrato — BLOOD ALTAR, WANDERING SPIRIT, HOODED ORACLE, FROST MERCHANT.
- **Meta**: OMEN 0–5 desbloqueado por vitória, CODEX dos demônios derrotados, score novo.

Capturas desta rodada (`tools/capture_survival_roguelike.gd`, janela real):
`captures/survrl_01_*` a `survrl_23_*` e `captures/survrl_contact_sheet.png` — estrato 1
e 2, barra com OMEN/HEAL pago/DESCEND, loja, relíquias com pacto, os 4 eventos, guardião
no automapa, escolha de relíquia do guardião, fim de run, batalhas com intenções (guardião
+2 escoltas, elite, 2 inimigos), painel de absorção com raridade e 4 opções, CONTINUE e
SURVIVAL OVER. Inspecionadas pelo agente; **o julgamento visual é do criador**.

As seções abaixo descrevem a base anterior; onde divergem, vale o bloco acima.

## Como funciona

- **Overworld exclusivo** (`scenes/survival/SurvivalWorld.tscn`, script
  `scripts/survival/survival_world.gd`): labirinto 25×21 com santuário central
  (zona segura, x 10..14 / y 9..11) e quatro alas. Começo em (12,10) olhando
  para o norte, de frente para o atendente.
- **35 demônios SMT** (`scripts/survival/survival_data.gd`) espalhados pelo mapa.
  Cada um tem sprite real de `assets/graphics/battlers/`, 7 atributos próprios,
  2–3 habilidades placeholder distintas (`SkillBook.DEFS`, sem mexer no
  `KIND_SKILLS` da campanha), e recompensa em Macca (25–95M).
  No corredor aparece só a **silhueta escura com contorno vermelho**, extraída
  do battler por `tools/generate_survival_silhouettes.py`; a arte colorada fica
  só na batalha.
- **Combate com 1 a 3 demônios**: `SurvivalData.encounter_for(id)` escala o
  encontrado por tier — tier 1/2 luta individual, tier 3/4 traz 1 reforço,
  tier 5 traz 2. O demônio tocado no mapa sempre lidera; todos os derrotados
  saem do mapa e rendem Macca.
- **Perseguição**: demônios a até 6 tiles avançam um tile por passo do jogador
  (eixo maior primeiro) e nunca entram no santuário. Contato inicia a batalha.
- **Curandeiro + Vendedor** são o mesmo NPC (`SANCTUARY KEEPER`, sprite SMT
  `P99_メシア01.png`) com uma barra de opções única: `HEAL` restaura HP/EN de todo o grupo (grátis 1× por estrato, D-068); `BEAD +20HP (20M)` e `CHAKRA +10EN (20M)` compram
  itens; `NEW RUN` zera a run (pede um segundo Z para confirmar; X cancela);
  `TITLE` volta ao menu e salva a run; `LEAVE` fecha. Setas/Left-Right
  selecionam, Z confirma, X sai/cancela.
- **Navegação**: o painel `SURVIVAL` mostra `DEMONS n/35` e `NEXT: D n`, a
  direção (N/E/S/W) e a distância até o demônio vivo mais próximo.
- **Itens na batalha**: o comando `ITEM` abre o submenu com o que está na bolsa
  (some quando vazia). BEAD cura 20 HP; CHAKRA devolve 10 EN (ou 2 PP para
  Yoch). Item em alvo já cheio é **recusado sem gastar item nem ato**.
- **3 continues**: se o Fallen cai, aparece `CONTINUE? (n/3 LEFT)`. Z gasta 1
  continue, restaura HP/EN completo e **mantém todos os status** (nunca chama
  `ProgressStore.halve_gains()` nem `add_deaths()`); a mesma luta continua.
  X/Esc encerra a run e apaga o save. Com 0 restantes, `SURVIVAL OVER`.
- **Fim de run**: ao derrotar o guardião do estrato 5 aparece `SURVIVAL CLEARED`
  com Macca, continues, OMEN, score e CODEX; Z reinicia, X volta ao título (D-066).
- **ABSORB (D-104)**: o mesmo comando da batalha principal — ação imediata do turno do
  Fallen, **2 ACT**, não entra na fila e resolve na hora; nunca aparece como reação. Com
  menos de 2 atos livres a linha fica apagada e recusa.
- **Absorção roguelike** (`scripts/survival/survival_absorb.gd`): a cada absorção
  bem-sucedida aparecem **3 opções na barra de comandos**. **30%** das rolagens
  trazem uma **habilidade nova ainda não obtida** (do demônio ou do pool de 27),
  ocupando o lugar de uma das opções; as demais são atributos aleatórios de
  **+1 a +4 pontos**. A escolha é gravada na run na hora (gains/skills), nunca
  no `ProgressStore`. Cada run tem uma **semente** persistida, então a mesma
  semente reproduz as mesmas ofertas — base para seeds diários/determinismo.
- **Relíquias antigas** (`survival_relics.gd`): 12 relíquias com nomes hebraicos
  e efeitos de atributo, **no máximo 2 por aliado**. `RELICS` na barra do
  santuário abre o painel: ←/→ escolhe, Z equipa no Fallen, X equipa na Yoch,
  Esc fecha. A relíquia é única e muda de aliado. A run começa com 1 inicial
  (D-073); 6 de atributo desbloqueiam por score e 11 de efeito caem na run.
- **Identificação** (removida, D-120): toda habilidade aparece com o nome e a
  descrição reais desde que é aprendida; não é preciso usá-la antes.
- **Seed diário / posições**: `DAILY SEED` reinicia a run com a semente
  `AAAAMMDD`; as posições dos 35 demônios são embaralhadas pela semente
  (células válidas, conectadas, fora do santuário). O seed aparece no HUD.
- **Elites** (~20% determinístico por semente + id): demônio com nome
  `ELITE ... [AFIXO]`, status maiores e **Macca em dobro**.
- **Risco/recompensa**: absorver com menos de 35% de HP sobe a raridade das
  ofertas um nível (D-071; antes garantia +4).
- **Mash da absorção (D-103, criador 2026-11-25)**: igual à campanha — os apertos
  só contam; o resultado (2 SP por aperto, até 10 apertos, e **um único sorteio**
  com o RNG da run) é aplicado uma vez quando acabam os 2 s ou no 10º aperto, o
  que vier primeiro. Só depois de uma absorção bem-sucedida aparecem as 3 opções.
- **Meta-progresso** (`survival_meta.gd`): score = derrotados×100 + Macca +
  continues×50, salvo em `user://exodus_survival_meta.json`, separado da run;
  melhor score e relíquias desbloqueadas aparecem na tela de clear.
- **Persistência da run**: `SurvivalState` salva em `user://exodus_survival_run.json`
  (versão 1) a cada mudança. Entrar pelo título retoma a run salva; `NEW RUN`
  no santuário começa do zero.

## Isolamento

O estado da run (`Engine` meta `exodus_survival_state` + arquivo JSON) guarda
HP/EN/PP, ganhos e habilidades da run, Macca, bolsa, continues, derrotados,
posição e demônios restantes. O carregador valida tipos, intervalos, célula
válida no labirinto e IDs de demônios/habilidades; JSON corrompido é recusado e
a run começa do zero. `SurvivalBattle` usa `persist_progress = false`
e `apply_saved_gains = false`: absorções, rezas e mortes do survival **nunca**
escrevem no `ProgressStore` da campanha. Tests comparam gains/deaths antes e
depois de cada evento para garantir isso.

## Escala de dano

**D-101 (SP parecido).** O dano soma um sorteio de até a diferença de SP e o SP é a soma dos
sete atributos, então a ficha antiga (Fallen HP 140 / EN 32, SP 205, contra inimigos de SP 59 a
139) o tornava invencível. Agora o Fallen começa com a média do estrato 1 (HP 26, EN 12, ATK 7,
MAK 7, DEF 6, MEF 6, AGI 9; SP 73) e a Yoch com HP 17, ATK 8, DEF 6, AGI 8 (sem EN, SP 45). Ao
começar cada batalha, cada inimigo recebe (ou perde) a diferença entre o SP atual do Fallen e o SP
esperado no estrato (`SurvivalStrata.par_sp`), repartida pelos atributos (`SurvivalData.follow_hero`),
antes de guardião, elite e OMEN. Simulação de 5 estratos com absorções reais (poder básico 10):
antes da D-108, quem sempre pegava a maior oferta matava em 3 a 6 golpes e aguentava 3 a 8, com até
8% dos golpes inimigos dando 0 (e até 83% dos golpes do Fallen contra os inimigos de mais SP/DEF).

**D-108 (desvantagem de SP não tira dano; variação fixa ±10%, jogo todo).** O criador mandou tirar
o "nunca causar dano a inimigos com alta defesa". Agora só a vantagem de SP soma `1d(ΔSP)` e a
variação é sempre ±10%. Mesma simulação: quem pega a maior oferta mata em 2,5 / 3,9 / 5,4 / 6,0 /
8,1 golpes (estratos 1 a 5) e aguenta 2,2 / 3,2 / 4,7 / 5,5 / 6,2; quem escolhe ao acaso mata em
1,8 a 2,4 e aguenta 2,0 a 2,5. **0% de golpes de 0** nos dois sentidos, contra os 35 inimigos com
guardião, elite e OMEN 0 e 5 (`verify_survival_balance.gd`; medição por inimigo em
`tools/measure_zero_damage.gd`).
`BEAD`, `MEDICINE` e `CHAKRA` seguem nos valores antigos (pendente). O ataque básico usa
`basic_power = 10` neste modo (8 na campanha, D-057), na mesma ordem das habilidades placeholder (4–13).

## Habilidades (D-106)

As 27 habilidades do pool têm cada uma um efeito próprio; os estados duram rodadas, acabam com a
batalha e não entram no save. Tabela completa e valores em `docs/plans/2026-11-25-survival-skills-rework.md`
e em `SkillBook.DEFS` (campo `fx`); regras em `scripts/core/skill_fx.gd`. LUNGE, BLEEDBUFF,
HEAT WAVE, ENERGY EAT e as rezas da Yoch não mudaram. `tests/verify_skill_fx.gd` prova os 27 efeitos.

## Humanos (D-107)

Cada estrato tem 1 grupo só de humanos (3), que aparece no mapa e na batalha com a própria arte colorida e sem
sombra no chão (só mazikim são silhuetas), usando modelos de NPC humano do jogo (P15, P10 e P19), e luta sem demônios. Humanos rezam com PP (sem EN): PRAY (+1 PP), SANVERIM (2 PP, cegueira),
NECHAMAH (1 PP, 5 HP por round por 3 rounds) e CHEREV (3 PP, 10 + MAK − MEF em todos os heróis).
Não podem ser absorvidos e não entram no CODEX. Regras em `SkillBook.DEFS`, `SkillFx` e
`SurvivalData.human_defs`; prova em `tests/verify_human_groups.gd`.

## Floater Eyes (D-129, criador 2026-11-27)

Inimigos de suporte da dungeon que voam junto de humanos ou Maziks (35% dos encontros normais, determinístico pela semente; Guardiões ficam de fora) e entram como aliados deles na batalha:

- **Formação:** 1 ou 2 olhos (50/50) acompanhando **exatamente 1 único humano ou 1 único Mazik** — impede a formação de duplas ou trios de humanos e Maziks nessa situação.
- **Visual:** sprite 2D em silhueta completamente verde (`assets/generated/survival/floater_eye.png`, gerado por `tools/generate_floater_eye_sprite.py`), flutuando ao lado do aliado no corredor 3D e na batalha sobre o palco 3D real da Necrópole Saturnina no Estrato 1 (sem nomes inimigos sobre sprites, na faixa de turno ou no cabeçalho de SP, e sem intenções/temperamentos desenhados abaixo deles).
- **Atributos base (Estrato 1):** `HP 8`, `EN 24`, `ATK 2`, `MAK 4`, `DEF 3`, `MEF 3`, `AGI 10` (`SP 54`; escala leve por estrato `+1 HP / +4 EN` para manter baixa durabilidade e EN alta).
- **5 magias novas de buff (exclusivas no humano ou Mazik acompanhado, nunca em Floater Eyes, duração 1 rodada cheia):**
  - `VERDANT MIGHT` (`1 ACT / 8 EN`): `+1` estágio de `ATK` e `MAK` (`+25%` cada).
  - `VERDANT SHELL` (`1 ACT / 8 EN`): `+1` estágio de `DEF` e `MEF` (`+25%` cada).
  - `KEEN GAZE` (`1 ACT / 6 EN`): `+4 AGI` via `effective_agi()` (sem mutar `stats.agi`/`sp_base()`) e próximo ataque com `HIGH SPEED` (D-124).
  - `ETHER LINK` (`2 ACT / 10 EN`): `+6 SP` temporários.
  - `AEGIS IRIS` (`1 ACT / 8 EN`): escudo de imunidade a status por 1 rodada cheia (não-reza, sem glifos hebraicos).
- **Sem EN / órfão:** sem EN suficiente com aliado principal vivo, executa `REST` (D-038: `0 ACT`, `+2 EN` fixos, encerra participação na rodada). Se o humano ou Mazik principal morrer, os Floater Eyes órfãos **fogem automaticamente** (`FLEE`, sem conceder Macca). Nunca contra-atacam.
- **Absorção e economia:** absorvível pelo Fallen (herda `max_en` e pode ensinar os 5 buffs novos), rende `10M` quando derrotado (sem entrar em `defeated`/`CODEX`), e nunca aparece em oferta de recrutamento ou loja.
- **Verificação:** `tests/verify_floater_eyes.gd` (2631 checks) e capturas em `captures/floater_eyes/` (`tools/capture_floater_eyes.gd`). **Aprovação visual pertence ao autor.**

## Verificação

- `verify_survival_strata.gd` — 15827 checks (estratos, guardiões, 800 labirintos
  gerados com BFS, layout, temperamentos, afixos, raridade/herança/Yoch, relíquias e
  pactos, cura paga, descida, preços, OMEN, meta, migração v1→v2 e saves inválidos).
- `verify_survival_run.gd` — 107 checks com cenas reais (guardião e escoltas, intenção
  executada, temperamentos, relíquias de batalha, BLAST/SOMA/MEDICINE, saque de elite e
  guardião, estrato gerado, loja, 4 eventos, DESCEND, OMEN, escolha da relíquia, clear).
- `verify_survival_data.gd` — 629 checks (35 demônios/sprites/células, 15 novas
  skills, encounters 1/2/3, save JSON, isolamento).
- `verify_survival_world.gd` — 30 checks (mapa, 35 silhuetas, barra com 8
  opções, compras, cura, perseguição, zona segura, `NEXT` , tela de clear).
- `verify_survival_battle.gd` — 36 checks (1 oponente, itens, 3 continues,
  vitória/Macca, game over, isolamento).
- `verify_survival_roguelike.gd` — 819 checks (relíquias, hebraico, 5-seed
  shuffle com BFS, elites ~20%, risco/recompensa, score/unlocks e skill 4 marcas).
- `verify_survival_absorb.gd` — 7014 checks (1000 sementes, ~30% de skill,
  3 opções, +1..4, sem duplicata, aplicação pura e integração na batalha).
- `verify_survival_extra.gd` — 99 checks (2/3 oponentes, X encerra a run,
  CHAKRA em Yoch, item em alvo cheio, 35 silhuetas, save inválido recusado,
  confirmação de NEW RUN, TITLE).
- `verify_title_screen.gd` — 24 checks, incluindo a entrada `Survival`.
- `verify_survival_input.gd` — 17 checks com **teclas reais** injetadas por
  `Input.parse_input_event`: setas movem o cursor do painel, Z/X confirmam e
  liberam a batalha, clique é convertido em opção, mash continua respondendo.
  Regressão do travamento relatado no painel `ABSORPTION REWARD`: o HUD é filho
  do controller e chama `set_input_as_handled()`, então o `_input()` do
  `survival_battle.gd` nunca recebia as teclas no jogo aberto. A confirmação
  agora passa por `handle_confirm()`/`handle_back()`, que é o caminho usado
  pelo HUD; as setas e o mouse também são tratados nele.
- `verify_timing_log.gd` — 10 checks do teste de layout pedido: com
  `hud.timing_at_log = true`, as trilhas de ataque/defesa e os dois ponteiros
  da disputa ficam dentro de `BATTLE_LOG_RECT` (sem sobrepor o texto do log),
  e a trilha real usada pelo rhythm é a reposicionada. Desligada, o layout
  original do cartão continua idêntico.

Vídeo: `captures/survival_gameplay.mp4` (8,8 s). Stills auditados:
`captures/survival_01_*` a `survival_16_*`, e
`captures/survival_silhouettes_sheet.png` (5×7). Capturas do teste de disputa
no battlelog: `captures/timing_01_card_default.png`,
`timing_02_log_attack.png`, `timing_03_log_counter.png`. O julgamento final do
visual é do criador.

## Histórico

Fases 1–3 vieram da sessão concorrente Antigravity; fases 4–5 e a expansão
para 35 demônios / 15 skills / 7 melhorias foram feitas nesta sessão. Nada foi
commitado.
