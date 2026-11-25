# Survival Mode — modo à parte, "for fun"

Não faz parte da lore nem da campanha. Sandbox de combate e exploração para
testar os **35 demônios**, 27 habilidades placeholder, itens e continues. A
entrada é o 4º comando do título (`Survival`).

## Roguelike (2026-11-25, D-066 a D-076)

Plano e referências (Slay the Spire, Hades, Darkest Dungeon, SMT/Persona, Inscryption,
Balatro, Risk of Rain, FTL): `docs/plans/2026-11-25-survival-roguelike.md`.

- **5 estratos** (`survival_strata.gd`): os 35 demônios ordenados por tier/SP em grupos de 7.
  Estrato 1 = labirinto feito à mão; 2–5 = labirinto gerado pela semente. O **GUARDIÃO**
  (o mais forte do grupo) espera na célula mais funda, não persegue, tem moldura dourada no
  automapa, HP ×1,5 e 2 escoltas. Derrotá-lo libera `DESCEND`; o 5º encerra a run.
  Guardiões: SUCCUBUS, INCUBUS, LAKSHMI, PAZUZU, BEELZEBUB.
- **Intenções**: cada inimigo mostra, acima da arte, seu temperamento (BRUTE, CASTER,
  SUPPORT, HUNTER, TRICKSTER) e a 1ª ação da rodada (`ATTACK ▸ YOCH`, `HELLFIRE ▸ ALL`,
  `MEND`), que é a ação executada.
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
  `KIND_SKILLS` da campanha), afinidade e recompensa em Macca (25–95M).
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
- **Identificação**: habilidade absorvida entra como **nome hebraico** no
  submenu FIGHT (`גל רוח`, `אש גיהנום`...); ao usá-la uma vez ela é identificada
  e passa a mostrar o nome/emfeite reais.
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
quem sempre pega a maior oferta mata o inimigo em 3 a 6 golpes (14 no estrato 5) e aguenta 3 a 8;
quem escolhe ao acaso, 2 a 3 golpes para matar e 2 a 5 para morrer; no máximo 8% dos golpes dão 0.
`BEAD`, `MEDICINE` e `CHAKRA` seguem nos valores antigos (pendente). O ataque básico usa
`basic_power = 10` neste modo (100 na campanha), na mesma ordem das habilidades placeholder (4–13).

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
