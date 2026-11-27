# Combat specification — Exodus (protótipo)

## Identidade
- Jogo: conceito original com conceitos visuais/gameplay de SMT 1 e 2.
- Protagonista: **Fallen** (nome real desconhecido), demônio caído; raça **demônio** (D-048).
- Inimigos do teste: 2 placeholders genéricos, sem dependência de nomes dos .rvdata.
- Aliado: **Yoch** (D-048, 2026-11-22), raça **humano**; arte do teste ainda é placeholder
  genérico. No código o aliado se chama **Yoch** desde 2026-11-23 (`battle_controller.gd`).
- Idioma da UI: **inglês**.
- Visão frontal. Após revisão visual, o fundo plano `#333333` foi substituído por
  battleback e janelas no estilo RPG Maker VX Ace, usando assets temporários da fangame
  (`assets/graphics/parallaxes/BB01-001.png`, `Window.png`, battlers com fundo removido
  em `assets/graphics/battle_sprites/`). A referência visual buscada foi a screenshot
  oficial de batalha do VX Ace (Yanfly Channel, nov/2011).

## Atributos
`HP`, `EN` (Energy Points), `ATK`, `MAK`, `DEF`, `MEF`, `AGI`, `SP` (Superiority Points).

- `SP_base = HP + EN + ATK + MAK + DEF + MEF + AGI` (soma dos 7 atributos).
- SP ganho em batalha é **temporário**; volta ao base ao fim da luta.
- `EN`: habilidades custam EP definido nos dados; recupera **20% do máximo por rodada**.
- **D-048:** Yoch **não tem EN**; no lugar dele usa **PP** (Pray Points), ver §Reza.
  No SP de Yoch, cada **PP atual vale +2 SP** (0 PP = +0; 8 PP = +16), subindo ao
  rezar e caindo ao gastar. A regeneração de 20% de EN não se aplica a Yoch; o REST
  de Yoch **só guarda atos** (sem ganho de recurso).
- **REST / Descanso — D-038 (CONFIRMADO e IMPLEMENTADO):** não gasta
  nenhum ACT, recupera **2 EN fixos** (até o EN máximo; **sem porcentagem pelo
  REST**) e encerra a participação do combatente na rodada, guardando os atos
  ainda disponíveis para a próxima (estoque até 4; teto D-005). A recuperação
  automática de 20% de EN no **fim da rodada** (regra acima) é independente
  e não foi substituída. O REST antigo de 1 ato e +20% é histórico (D-006).
  **Implementado** em `BattleController._player_turn()` e
  `BattleUnit.recover_en_flat()`, com testes em `test_battle_combat.gd`.
  **D-105 (criador, 2026-11-25):** no turno o REST continua exatamente assim, mas ele
  **deixou de ser reação**.
- **PASS — D-105 (criador, 2026-11-25; IMPLEMENTADO):** passa a vez **sem gastar ato** e sem
  ganhar EN, SP ou PP. O herói **fica com os atos**, volta a agir nas vezes seguintes da mesma
  rodada (agindo ou reagindo) e o que sobrar no fim da rodada vai ao estoque (D-005). Ex.: com
  2 atos, ATTACK gasta 1; o outro pode ser usado mais tarde na rodada ou vira +1 ato na
  próxima. Fica **logo antes do REST** no menu do turno (Fallen: FIGHT, ITEM, PASS, REST,
  ABSORB; Yoch: FIGHT, PRAY, ITEM, PASS, REST), pode fechar uma fila (``ATTACK, PASS``) e
  **não é reação**. Se a vez voltar a quem passou sem que ninguém tenha agido desde então
  (todos que ainda têm vez passaram), **a rodada acaba**. PASS perdido numa interrupção
  (D-049) **não dá ato** ao inimigo. Implementado em `PlayableController._execute_pass()` e
  `_next_live_actor()`, com `tests/verify_playable_pass.gd`.
- Mapeamento dos `.rvdata`: `MaxHP→HP`, `MaxMP→EN`, `ATK→ATK`, `DEF→DEF`,
  `MAT→MAK`, `MDF→MEF`, `LUK→AGI`.

### D-025 (Rodada 8, 5E) — atributos iniciais (design aprovado; não implementado)

- **Todos os personagens e inimigos:** atributos básicos
  iniciais definidos em **8 ou múltiplos de 8**;
  a decisão não atribui a mesma ficha a cada espécie
  nem homologa os valores dos outros personagens.
- **Fallen no início do jogo:** `HP máximo = 32`,
  `EN máximo = 8`, `ATK = 8`, `MAK = 8`,
  `DEF = 8`, `MEF = 8`, `AGI = 8`.
- `SP_base = 32 + 8 + 8 + 8 + 8 + 8 + 8 = 80`,
  **calculado**, não uma estatística básica
  atribuída separadamente em 8.
- **PENDENTES:** valores específicos dos demais
  personagens e inimigos, progressão, limites
  superiores e ficha neutra de calibração
  da D-024 (7C), que continua sendo
  homologação separada.
- **DIVERGÊNCIA:** defaults de `UnitStats` e
  `BattleController._create_units()` não
  correspondem à regra; a escala altera SP
  base e demanda reavaliar poderes físicos
  segundo D-019/D-021. Nenhum código foi alterado.

### D-031 (Rodada 9, 1A e 2B) — fichas iniciais e referência neutra; DESIGN, NÃO IMPLEMENTADO

- **1A:** cada **espécie de personagem
  ou inimigo** recebe sua **própria ficha
  inicial**, seguindo a regra D-025 de
  **8 ou múltiplos de 8** nos
  atributos básicos. Não foram
  aprovados valores particulares
  para espécies adicionais.
- **2B:** a **referência neutra de
  testes** é **independente** dos dados
  de Fallen, mas tem os mesmos
  números iniciais: HP 32, EN 8,
  ATK/MAK/DEF/MEF/AGI 8 e
  `SP_base` derivado **80**.
  Deve ser **versionada
  separadamente**. Arquivo,
  esquema e número inicial
  de versão ficam pendentes;
  nenhum recurso ou arquivo
  de ficha foi criado.
- **D-028 preservada:** ganhos
  persistentes por absorção
  podem tornar os atributos
  efetivos posteriores diferentes
  de múltiplos de 8. A regra
  aplica-se às **fichas-base
  iniciais**, sem arredondar
  ganhos ou alterar saves.
  Referência neutra não
  recebe progresso de Fallen.
- **Estado:** os defaults de
  `UnitStats` e as fichas do
  protótipo no controlador
  ainda diferem destas
  regras. Nenhum código
  foi modificado nesta rodada.

### D-032 (Rodada 10, 2A e 3A) — composição de SP e fichas de teste; DESIGN APROVADO, NÃO IMPLEMENTADO

- **2A:** preservar
  `SP_base = HP + EN +
  ATK + MAK + DEF + MEF +
  AGI` com sete
  atributos inteiros;
  HP e EN entram
  integralmente. Sem
  novos pesos/tetos.
  D-007, D-021 e
  D-028 permanecem.
- **3A:** três **fichas
  exclusivamente de
  laboratório**, com
  atributos iniciais
  em múltiplos de 8:
  - **Ágil:** HP 24,
    EN 8, ATK 16,
    MAK 8, DEF 8,
    MEF 8, AGI 16;
    **SP_base=88**.
  - **Equilibrada:** HP 32,
    EN 8, ATK 8,
    MAK 8, DEF 8,
    MEF 8, AGI 8;
    **SP_base=80**.
  - **Resistente:** HP 48,
    EN 8, ATK 8,
    MAK 8, DEF 16,
    MEF 8, AGI 8;
    **SP_base=104**.
  Nenhum perfil
  altera a ficha
  canônica da espécie
  ou o save de Fallen.
  Referência neutra
  versionada da
  D-031 permanece
  independente.
- **Risco:** diferença
  de SP de +24 da
  ficha resistente
  contra a equilibrada
  também afeta dano,
  críticos, dominância
  e duração do ritmo.
  Não impor
  balanceamento
  sem validação
  matemática.

### D-033 (Rodada 11, 2C) — ficha resistente de laboratório revisada; DESIGN, NÃO IMPLEMENTADO

- **Somente a ficha resistente de laboratório** da D-032 muda: **HP 40, DEF 8**, conservando EN 8, ATK 8, MAK 8, MEF 8, AGI 8; **SP_base=88**, antes 104. Perfil antigo HP 48/DEF 16/SP 104 continua documentado como histórico da D-032, mas não é o valor vigente para novos testes.
- Perfis ágil/equilibrado, referência neutra independente, Fallen, dados de espécies e progresso D-028 intactos.
- Contra poder básico 8 e ATK 8, DEF 8 produz dano-base 8 e **cinco acertos nominais** em HP 40. Diferença de SP resistente 88 contra atacante 80 causava `−1d8` antes dos demais modificadores (desde a D-108 a desvantagem não desconta nada); a meta 5–7 não está validada estatisticamente.

## Tela da batalha na resolução D-055 (criador, 2026-11-24; IMPLEMENTADO)

- Com a tela 816x624 da D-055, a batalha e as cenas do anjo (morte e prólogo) ficaram no
  tamanho antigo e quebradas. O criador escolheu **tudo 1,5x**: elas continuam montadas em
  544x416 e a janela as mostra 1,5x (escala de conteúdo fracionária enquanto a cena está
  aberta, `scripts/core/layout_scale.gd`), com o texto desenhado no tamanho real. Título e
  dungeon seguem em 816x624.
- **HUD opção 13 "Janelas baixas" (criador, 2026-11-24; IMPLEMENTADO)**, escolhida entre
  os protótipos de `prototypes/combat-hud-html/index.html`:
  - Rodada, nomes com SP e a barra de SP numa **linha fina só no topo**; anúncios logo
    abaixo dela. O cenário vai até o fim da tela e os inimigos descem 36 px de tela.
  - **Log** de **2 linhas** (D-056, substituiu o antigo formato de 3 linhas) numa janela de borda fina clara e fundo
    escuro translúcido, com asteriscos no lugar dos quadrados; linhas antigas a 80%.
  - Cada herói na **sua janela**, em 2 linhas: seta ▸ antes do nome de quem está
    escolhendo, SP, ACT e os 4 pips em cima; barras de HP e EN (PP no Yoch) embaixo.
  - **Comandos** numa janela à direita, em 3 colunas (setas andam na grade); listas
    longas (habilidades, rezas) viram uma coluna e a janela cresce para cima.
  - **Números de dano nos aliados** aparecem **sobre a janela do herói**, 20 px, metade
    do tempo de antes.
- **D-100 (criador, 2026-11-25): letras hebraicas de SP flutuantes. IMPLEMENTADO.** Toda mudança
  de SP (ganho, perda, roubo) faz uma letra hebraica aleatória (nunca o valor), verde no ganho e
  vermelha na perda, subir de quem mudou até o rótulo de SP do seu lado; heróis e inimigos. Duração e tamanho aguardam o julgamento do criador.
- **D-102 (criador, 2026-11-25): cartões de papel visíveis enquanto o papel existe; revoga a
  D-061. IMPLEMENTADO.** Os cinco cartões ficam na tela enquanto o papel existe e somem quando os
  papéis são limpos (resultado confirmado); setas (D-059) e cores do log (D-060) não mudam.
- **D-060 (criador, 2026-11-25): nomes coloridos no Battle Log. IMPLEMENTADO.** Em cada frase,
  o nome de quem tem papel na ação ganha a cor do papel naquele momento (atacante vermelho, alvo
  amarelo, defesa azul, contra-ataque laranja, reação verde); o resto da frase não muda.
- **D-059 (criador, 2026-11-25): caixas de papel + setas animadas. IMPLEMENTADO.** As caixas
  da D-057 ficam; cada golpe desenha uma seta que corre do atacante ao alvo em 0,55 s e some
  perdendo opacidade rápido. No contra-ataque, uma seta sai de cada lado, elas se encontram no meio
  e uma faísca marca o choque. Sumiço, faísca e cores feitos pelo agente, aguardando o julgamento
  visual do criador.
- **D-058 (criador, 2026-11-25): fila de turnos no topo e reações no Battle Log.
  IMPLEMENTADO.** Sob a linha do topo, a ordem dos turnos da rodada (AGI) com quem está no turno
  destacado; quem caiu sai e quem não tem mais ato fica apagado. A barra de tempo da defesa e os
  dois trilhos do contra-ataque do herói rodam dentro da janela do Battle Log (o texto some
  enquanto correm); REACT/DENY continua no menu. Ataque do jogador e contra-ataque do inimigo
  seguem sobre o inimigo. Aparência feita pelo agente, aguardando o julgamento visual do criador.
- **D-057 (criador, 2026-11-25): Battle Log só com frases de evento. IMPLEMENTADO.** O log
  mostra uma linha por acontecimento, em inglês (``FALLEN attacks FOE A.``, ``FOE A
  counter-attacks!``, ``FALLEN blocks: 5 damage.``, ``FOE A is down.``, ``FALLEN gains 1 act.``,
  ``FALLEN loses 1 queued command.``), sem instruções de tecla nem números internos (ritmo, def,
  crit e SP roll ficam só em `log_history`, para diagnóstico). Explicações de menu e o
  contador da absorção continuam transitórios. **Delegado ao agente, aguardando o julgamento
  visual do criador:** linhas não lidas aparecem da mais antiga para a mais nova e cada Z mostra
  as próximas antes de a batalha seguir (também antes de qualquer outra entrada), então uma
  rajada de 3–4 frases (contra-ataque) nunca some das 2 linhas; e **rótulos de papel** ATTACK /
  TARGET / DEFEND / COUNTER / REACT sobre o nome do inimigo e na borda de cima da janela do
  herói, do anúncio até a confirmação do resultado (a defesa automática do inimigo também ganha
  DEFEND). Cobertura: `verify_playable_feedback.gd`, `verify_playable_layout.gd`,
  `verify_log_wrap.gd`.
- **Menu (criador, 2026-11-24):** **EXEC e UNDO** só aparecem com algo na fila. **REACT**
  saiu do menu do próprio turno: só é escolhido quando uma ação do oponente é anunciada
  (pergunta REACT / DENY). Com isso deixa de existir a reserva de atos pelo menu do turno
  (D-047); os testes ainda ligam essa reserva (`offer_reserve`) para chegar rápido a um
  anúncio.

## Atos e reações
- Cada personagem possui **2 atos por rodada**; cada ato pode ser **Ação** ou **Reação**
  (2 ações, 2 reações ou 1 de cada).
- Ação = executada no próprio turno. Reação = qualquer ação fora do turno, declarada
  em resposta ao anúncio de uma ação inimiga (inclusive mirando outro aliado).
- Todos os comandos podem ser usados como Reação pelo **personagem atacado**, que
  também pode bloquear (DEFEND), **exceto ABSORB (D-104)**, que só existe na ação do
  próprio turno. **D-045:** um aliado que **não é o alvo** do ataque
- Todos os comandos (menos REST e PASS, D-105) podem ser usados como Reação pelo **personagem atacado**, que
  também pode bloquear (DEFEND). **D-045:** um aliado que **não é o alvo** do ataque
  anunciado não pode bloquear; sua reação é **contra-ataque (ATTACK) ou item/magia
  (ITEM)**. Inimigos também possuem 2 atos e também podem declarar Reações.
- Atos não usados podem ser **armazenados até 4** para a próxima rodada
  (podem guardar todos de uma vez); inimigos também.
- **REST (D-038):** serve para guardar os atos remanescentes: escolher REST encerra
  as oportunidades do combatente na rodada **sem gastar um ACT**. Os atos que
  estavam disponíveis passam ao estoque (limite 4) para a próxima rodada,
  sujeitando-se às regras vigentes de início de rodada D-005. REST também
  recupera exatamente **2 EN** (até o máximo), **não** recupera EN por percentual
  e não pode ser repetido na mesma rodada pelo mesmo combatente após encerrar
  sua participação. **IMPLEMENTADO:** nenhum ato é gasto ao abrir o menu;
  ATTACK e ITEM consomem um ato quando escolhidos, e REST consome zero; ABSORB custa
  2 atos e resolve na hora (D-104).
  Os atos restantes vão ao estoque e `acts_available` zera. Não equiparar PASS
  a REST. A regeneração automática no fim de rodada permanece distinta.
  **D-105:** REST só no turno próprio (não é reação). Para passar a vez sem gastar atos e
  voltar a agir na mesma rodada existe o **PASS** (acima).
- **D-005 (2026-11-21): teto de 4 atos disponíveis no total por personagem**, somando
  atos novos da rodada, atos armazenados e bônus de SP/Press Turn. Vale igualmente
  para Fallen, aliados e inimigos. Substitui a interpretação de 4 armazenados
  **mais** 2 novos simultaneamente disponíveis. **IMPLEMENTADO:** o excedente é
  **adiado** ao estoque (`stored_acts`), limitado a 4, e pode reaparecer em rodada
  posterior. Atos novos e bônus entram primeiro; o que sobrar volta ao estoque.
- **D-057 (criador, 2026-11-25): o turno vai até zerar os atos.** Depois da fila, os atos
  que sobraram (não planejados ou devolvidos por recusa de novo alvo) são
  planejados de novo **no mesmo turno**; o turno só acaba com 0 atos, com REST ou com PASS (D-105). Isso substitui
  a frase ``se sobrar ato, ele planeja de novo quando o ciclo voltar`` abaixo; a ordem por AGI
  entre combatentes continua. **IMPLEMENTADO** em `PlayableController._player_turn()`.
- **Ordem de turnos (criador, 2026-11-23; substitui a D-044 `A, A, B, B`):** a vez é
  sempre dos **mais rápidos primeiro** e dos mais lentos por último, **uma vez por
  combatente**, e o ciclo se repete enquanto alguém tiver atos (ex.: `Fallen > inimigo >
  Yoch > inimigo > Fallen`). Na sua vez, o combatente executa **a fila inteira** que
  planejou (dois ataques na fila gastam os dois atos naquela vez só) e passa a vez; se
  sobrar ato, ele planeja de novo quando o ciclo voltar. A fila da D-046 continua.
  **D-105:** PASS passa a vez sem gastar ato e o ciclo continua; se a vez voltar a quem
  passou sem ninguém ter agido desde então, a rodada acaba (atos que sobraram vão ao estoque).
  - **Empate de AGI:** age antes quem tem **mais SP no início da rodada**. Empate de AGI
    **e** SP: **PENDENTE**.
  - Inimigo: a quantidade de ataques por vez fica como está (combo D-047 de até 2); o
    criador quer um **rework completo da IA** para ser forte e estratégica (**PENDENTE**).
  - Cada ato é consumido por uma ação ou reação. **IMPLEMENTADO** em
    `BattleState.next_actor()` / `_faster_first()`, com `tests/test_battle_state.gd` e a
    ordem real da batalha em `tests/verify_playable_reactions.gd`.
- **Correção do criador (D-051, 2026-11-22):** ele **nunca aprovou** que o inimigo gaste
  **sempre** dois atos em ataques independente do contexto. A escolha deve depender do
  contexto (IA **PENDENTE**); o código ainda ataca duas vezes.
- **D-047 (2026-11-22): combo inimigo.** O inimigo anuncia e resolve **dois
  ataques no mesmo bloco de turno**, cada um com reação própria e **um número
  de dano próprio na camada principal** (`DamageLayer`). Sem reação declarada,
  cada golpe usa o autoacerto D-022. A cadeia para se o atacante ou o alvo cair,
  ou se o combate terminar. **Corrigida pela D-051:** o criador nunca aprovou
  que o inimigo gaste **sempre** dois atos em ataques independente do contexto;
  a IA contextual está pendente. Um jogador que reservou atos com REACT não trava
  o agendamento (as vezes dele são puladas em `_next_live_actor()`). **IMPLEMENTADO** em
  `playable_controller.gd` (`_enemy_turn()`), com regressão em
  `tests/verify_playable_reactions.gd`.
- **D-007 (2026-11-21): limiar de superioridade por dominância em razão.** Ganha
  **+1 ato** quem possui `SP_próprio / (SP_próprio + SP_rival) > 0,7`. Substitui a
  interpretação literal `SP_próprio > 0,7 × SP_rival`, que premiava ambos os lados
  para qualquer par de SP positivo. **IMPLEMENTADO.**
- **D-019 (Rodada 3, 5B):** em confrontos contra múltiplos oponentes,
  cada combatente compara a própria dominância com o **adversário vivo de maior SP**.
  Este é o comportamento já implementado em `BattleState.strongest_opposite()`.
  Não confundir com a referência visual contextual de SP definida no GDD.
- **Consequência de D-005:** o bônus de SP respeita o teto de 4 atos disponíveis;
  não autoriza um quinto ato. O excedente é adiado ao estoque pela mesma regra.

### D-043 / D-046 — fila de comandos e ataques encadeados; IMPLEMENTADO no motor Godot

- O jogador pode **planejar em conjunto comandos para 1–4 atos disponíveis**
  (limite D-005) antes de iniciar a resolução. A interface marca **em verde**
  cada um dos ACT comprometidos no planejamento, distinguindo previsão,
  disponibilidade e ato efetivamente gasto.
- Quando mais de um dos comandos selecionados for ATTACK, o HUD deverá
  **reutilizar a mesma linha de ritmo no inimigo alvo**, resolvendo o timing
  de cada ataque e só então iniciando o próximo marcador. Cada ataque
  conserva seu julgamento mecânico independente (POINT/BEAM/MISS), dano,
  contato e efeitos; não há acertos automáticos nem soma implícita de danos.
- **D-044 (2026-11-21) resolve o conflito de ordem:** a sequência planejada
  é executada como **bloco contínuo** — o combatente resolve todos os atos
  comprometidos antes que qualquer outro combatente aja. A ordem entre
  combatentes continua por AGI, mas dentro do bloco não há intercalação.
  **Atualizada pelo criador em 2026-11-23:** a fila planejada continua em bloco, mas
  é uma vez só; os atos que não entraram na fila esperam a próxima vez do ciclo
  (ver §Atos e reações, ordem de turnos).
- **D-046 (2026-11-21): fila e linha persistente implementadas no Godot.**
  O Fallen planeja 1–4 comandos antes da resolução; cada ato comprometido
  acende um marcador **verde**, e **UNDO** (Backspace) remove o último.
  **EXEC** (X) inicia a resolução; ↑/↓ navega e Z/Enter confirma. Ataques
  consecutivos reutilizam a **mesma linha de ritmo**, reiniciando o marcador
  para cada julgamento. Implementado em `BattleController` e `RhythmBar`,
  com testes em `test_battle_combat.gd`. **Também implementado no caminho
  jogável** (`BattlePlayable.tscn`): os sete itens (cinco comandos + EXEC +
  UNDO) cabem na janela de comando, os ACT comprometidos acendem em verde no
  painel do personagem e REACT/REST/PASS (D-105) encerram o plano sem gastar ato extra.
  Regressão em `tests/verify_playable_reactions.gd`.
- **D-057 (criador, 2026-11-25): fila com alvo e sem confirmação. IMPLEMENTADO.** O alvo de
  cada ATTACK e golpe (Lunge) é escolhido **ao montar a fila** (ABSORB também era; desde a
  D-104 não entra na fila); EXEC roda os comandos
  um depois do outro sem perguntar nada e sem pausa de Z entre eles (a fila só espera o golpe e
  o número terminarem; a pausa do resultado vem depois do último comando ou de uma interrupção
  da D-049). Ataques seguidos no mesmo alvo dividem a mesma linha de ritmo; trocar de alvo fecha
  a linha. **Alvo que caiu:** o jogo pede outro alvo (faixa ``CHOOSE ANOTHER TARGET``); X recusa,
  o comando e os seguintes não rodam e **nenhum ato é gasto** (o herói planeja de novo). Os
  marcadores verdes mostram só os comandos que ainda vão rodar. A reza mantém a própria regra
  (alvo caído = PP de volta, D-048).
- **D-104 (criador, 2026-11-25): ABSORB imediato, 2 ACT, só na ação. IMPLEMENTADO.** No plano do
  próprio turno, ABSORB pede o alvo e resolve **na hora**, gastando **exatamente 2 atos** antes do
  minigame (`ABSORB_ACTS`, `_execute_absorb()`); nada entra na fila e os comandos já enfileirados,
  com alvos e marcadores, ficam iguais até o EXEC. Depois do resultado (Z) o plano continua com os
  atos que sobraram (0 atos encerra o turno). ABSORB não aparece no menu de REACT e
  `_execute_command(..., reacting=true)` o recusa. Com menos de 2 atos livres da fila (atos
  disponíveis, teto D-005, menos os já comprometidos) a linha fica **apagada e recusa**, a mesma
  regra das habilidades que o herói não pode pagar (`plan_row_disabled()`). Resolução da absorção
  (D-051) inalterada. Regressão: `tests/verify_playable_absorb.gd`.
- **PENDENTES:** reação entre os passos da cadeia. REST D-038 já encerra o
  planejamento ao ser escolhido. O HTML independente permanece como
- **PENDENTES:** reação entre os passos da cadeia. REST D-038 e PASS D-105 já encerram o
  planejamento ao serem escolhidos. O HTML independente permanece como
  protótipo visual, fora do repositório.

### Reações da Rodada 2 — D-014 (CONFIRMADO como design; não implementado)

- **3A:** sem atos disponíveis, o personagem **não pode bloquear nem desviar**.
- **4A:** o combate fica **pausado para a escolha da reação** quando elegível.
  A execução posterior da barra continua temporizada; a janela fixa
  de 0,8 s para escolher a reação deixa de ser o comportamento pretendido.
- **5C:** a ordem de resolução de **reações ofensivas** em relação à
  ação anunciada depende de **AGI**. Desempate, interrupção/cancelamento
  e detalhes de encadeamento permanecem **PENDENTES**. Nenhuma alteração
  implícita em custo ou comando foi autorizada.

### D-025 (Rodada 8, 6C e 7A) — prioridade ofensiva; design, não implementado

- **6C:** quando AGI empatar, desempatar
  ação anunciada versus reação ofensiva
  por **identificador estável do
  combatente**. O sentido da ordenação,
  empates residuais e requisitos de
  identidade são **PENDENTES**.
  Preservar prioridade por AGI (D-014).
- **7A:** reação ofensiva que resolve
  primeiro só **cancela** a ação
  anunciada se **eliminar o executor**
  ou provocar **interrupção por efeito
  explicitamente definido**.
  Dano sem morte/interrupção não cancela.
  **Substituído pela D-049 (2026-11-22):** o cancelamento agora segue o
  contra-ataque com duas barras (ver §Contra-ataque e interrupção).
  Não criar novos efeitos, custos ou
  recompensas por inferência. Ordem
  detalhada de gastos/eventos e
  efeitos interruptivos continuam
  **PENDENTES**.
- A exceção de autoacerto inimigo
  sem reação declarada da **D-022**
  não é modificada. Este contrato
  **não foi implementado**.

### D-031 (Rodada 9, 5A) — desempate lexicográfico; DESIGN, NÃO IMPLEMENTADO

- Quando **AGI empatar**
  entre uma ação anunciada
  e uma reação ofensiva,
  usar **ordem lexicográfica
  crescente dos IDs estáveis
  dos combatentes** para
  decidir qual resolve primeiro.
  Preserve o critério primário
  por AGI (D-014) e o
  cancelamento por eliminação
  ou interrupção explícita
  (D-025). Não escolher
  lado/posição da HUD como
  critério adicional.
- **PENDENTES:** normalização
  de IDs, colisões e comparação
  exata de valores não
  padronizados; IDs duplicados
  não recebem desempate
  silencioso. A regra não
  foi implementada.

## Press Turn
- **D-119 (criador, 2026-11-27): toda a afinidade foi removida.** Não existe mais fraqueza,
  resistência, nulo nem absorção: o dano não depende de afinidade, acertar não dá ato extra
  nem SP extra. `BattleMath.Affinity`, `affinity_multiplier()` e `press_turn_acts()` deixaram
  de existir. Supera D-057 ("só WEAK dá +1") e a parte "fraqueza" de D-109. Nenhuma regra
  de compensação foi criada.

## Dano (sem magia neste protótipo)
- Físico: `poder × ATK ÷ DEF`.
- **D-019 (Rodada 3, 3A):** a fórmula física acima é **preservada**;
  devem ser recalibrados os **valores de poder dos ataques/habilidades**.
  Novos valores específicos ainda não foram aprovados.
- Modificador de SP (**D-108, criador 2026-11-25; IMPLEMENTADO**): rolar `1dN` onde
  `N = SP_atuante - SP_alvo`, **somado só quando o atuante tem mais SP**. Com SP igual ou menor
  não há sorteio nem desconto (antes: subtraía, o que zerava golpes contra DEF/SP altos).
- **Implementação anterior da variação:** `±10% ± 2% por ponto de diferença de SP`;
  **removida do código pela D-108**.
- **D-019 (Rodada 3, 2C) — IMPLEMENTADO pela D-108 (2026-11-25):** a
  variação percentual aleatória do dano passa a ser **fixa em ±10%**,
  independente da diferença de SP, **preservando separadamente a
  rolagem `1dN` de superioridade**. Não alterou a ordem dos demais
  modificadores do dano.
- **Crítico — implementação vigente D-021:** multiplicador **×1.5**; chance =
  `min(50%, AGI% + min(20%, max(ΔSP, 0) × 2%))`. Desvantagem de SP não reduz
  a chance abaixo de AGI. **IMPLEMENTADO** em `BattleMath.crit_chance()`.
- **D-019 (Rodada 3, 1A) — direção de design, já quantificada por D-019/2026-11-21
  e implementada pela D-021:** a contribuição crítica por SP foi reduzida
  e o teto final passou a 50%. O histórico da D-019 é preservado; os
  números vigentes são os da D-021 acima.
- SP **não** multiplica o dano diretamente.
- Ganho de SP: **+1** por crítico, desvio perfeito e reação (D-119: não há mais ganho por fraqueza).
- **D-019 (Rodada 3, 4C):** manter essas fontes existentes e seus
  ganhos de **+1 SP**, sem introduzir limite extra por batalha nem
  ganhos decrescentes. O balanceamento da influência do SP deve
  ocorrer nas fórmulas; a mecânica de ganho continua igual.
- Crítico e ganhos de SP por crítico só são aplicados quando
  há **contato** (ritmo de ataque diferente de Falha e defesa diferente de Desvio).
  Ataques que falham não consomem rolagens de dano.
- **D-016 (2026-11-21, histórico):** limitou o bônus de SP a +30 p.p. e manteve
  teto 100%. **IMPLEMENTADO naquela rodada; SUBSTITUÍDO pela D-021** na
  implementação atual. O multiplicador ×1.5 permanece.

### D-021 (Rodada 5) — calibração crítica aprovada e IMPLEMENTADA

- **1B; 2B; 3B:** chance crítica futura:
  `min(50%, AGI% + min(20 p.p., max(ΔSP,0) × 2 p.p.))`.
  São **+2 pontos percentuais por SP de vantagem**,
  com bônus SP de até **+20 p.p.** e
  **teto crítico final de 50%**. Desvantagem de SP não
  reduz a chance base de AGI. Teto final vale mesmo
  para AGI superior a 50. Não alterar multiplicador
  ×1.5, condição de contato ou outras regras.
- A fórmula **D-016** foi **implementada na rodada original** e depois
  substituída pela D-021, que agora está no código. O histórico é preservado
  em `BattleMath.crit_chance()` e nos testes de `test_battle_math.gd`.
- **7A:** mantendo `poder × ATK ÷ DEF`, calibrar os
  poderes para que inimigo aproximadamente equivalente
  demande **3–5 ataques físicos bem-sucedidos**,
  sem bloqueios ou críticos no cenário de referência.
  Ainda não há valores aprovados para poderes nem
  HP/ATK/DEF de referência; não interpretar como número
  de rodadas.

### D-031 (Rodada 9, 3A) — ataque físico básico; IMPLEMENTADO pela D-057 (2026-11-25)

- **D-057:** o criador autorizou em 2026-11-25: o ataque básico do jogo principal usa
  **poder 8** (`BattleController.basic_power`), também no ataque inimigo contra a reza; o
  Survival segue com 10. A divergência ``poder 100`` abaixo está resolvida.

- O **ataque físico básico**
  possui **poder nominal 8**,
  mantendo a fórmula
  `poder × ATK ÷ DEF`
  aprovada na D-019.
  Poderes de outros ataques/
  habilidades continuam
  **PENDENTES**.
- Na ficha neutra
  D-031 (HP 32, ATK 8,
  DEF 8), o dano físico
  base é **8 por acerto**;
  **4 acertos nominais**
  alcançam 32 HP, dentro
  da meta D-021 de 3–5
  acertos. Isso **não**
  é um resultado de testes:
  variação fixa de ±10%
  aprovada mas não
  implementada (D-019),
  rolagem de SP `1dN`,
  crítico, afinidades,
  bloqueios e outros
  fatores modificam
  danos reais.
- **DIVERGÊNCIA com código:**
  o comando ATTACK do
  protótipo ainda utiliza
  poder 100. Não alterar
  a execução até a futura
  autorização de código.

### D-032 (Rodada 10, 4A e 8A) — metas de acertos e aceitação estatística; DESIGN, NÃO IMPLEMENTADO

- **4A:** metas iniciais
  de durabilidade em
  **ataques físicos
  bem-sucedidos**:
  frágeis **2–3**,
  equivalentes **3–5**
  (D-021), resistentes
  **5–7**. A meta
  não define duração
  em rodadas e não
  afirma que as
  fichas 3A já
  estão balanceadas.
- **CONFLITO registrado:**
  poder básico 8
  (D-031) e
  atacante ATK 8
  contra DEF 16
  da ficha resistente
  provocam dano-base
  `8 × 8 ÷ 16 = 4`.
  Com HP 48, são
  **12 acertos nominais**,
  enquanto o alvo
  aprovado é **5–7**.
  O SP resistente
  104 contra SP
  equilibrado 80
  pode introduzir
  `1d24` de
  penalidade no dano
  do atacante inferior
  em SP. Não alterar
  regras, estatísticas
  ou metas por
  suposição; é
  **pendência de
  balanceamento**.
- **8A:** exigir,
  em **10.000 casos
  controlados** contra
  a referência
  equivalente, que
  **≥95% (≥9.500)**
  terminem com
  **3–5 ataques
  físicos bem-sucedidos**
  para derrotar o alvo.
  Os testes deverão
  explicitar as
  condições de
  controle, incluindo
  ausência de bloqueio
  e crítico, SP
  inicial e afinidade,
  sorteios/seeds,
  arredondamentos e
  contagem de acertos,
  antes de serem
  considerados
  evidência. Nenhuma
  distribuição/seed
  foi homologada
  implicitamente.
- A variação aleatória
  fixa de ±10%
  (D-019) segue
  **aprovada em
  design, mas não
  implementada**;
  o código atual
  usa a amplitude
  variável anterior.
  **Nenhuma simulação
  foi executada** por
  esta decisão
  documental.

### D-033 (Rodada 11, 3B; 6A; 8A) — dano mínimo e critérios de teste; DESIGN, NÃO IMPLEMENTADO

- **3B:** manter a rolagem SP `1d|ΔSP|` com sinal; ataques que **causam dano, fazem contato e possuem afinidade que permita dano** recebem **piso final de 1 dano**, mesmo se a diferença de SP anular o valor. Sem contato não há dano; afinidades **Null/Absorb** não recebem piso. Preservar D-015, fórmula crítica implementada D-021 e variação fixa ±10% aprovada D-019. **PENDENTE:** poder zero/Moves sem dano nominal, composição com efeitos futuros e estágio preciso em casos especiais. Código `BattleMath.physical_damage()` ainda permite zero. **Sem efeito desde a D-108:** a desvantagem de SP não subtrai mais e a variação é ±10%, então só dá 0 com afinidade NULL/ABSORB ou quando `poder × ATK ÷ DEF` fica abaixo de ~0,55 (arredonda para 0); o piso de 1 não foi implementado.
- **6A:** 10.000 **casos controlados** com referência neutra contra cópia equivalente: **HP 32, ATK 8, DEF 8, poder básico 8, SP iguais, afinidade Normal, sem crítico/bloqueio, variação fixa ±10%**. Exigir **≥95% dos casos** com derrota em **3–5 ataques bem-sucedidos** (D-032). Diferença inicial de SP é zero e não produz `1dN`; não introduzir ganhos extras não definidos. **PENDENTES:** seeds, amostragem, resets e harness. Não houve execução de 10.000 casos; o motor ainda não implementa ±10% fixos para ΔSP diferente de zero.
- **8A:** testar **duelos** e **combates com múltiplos inimigos**, cobrindo teto e armazenamento de atos, reações e prioridade, fraquezas/Press Turn, dominância e ganhos SP, dano e duração dos perfis. Preservar D-024/D-025: propriedades, reprodutibilidade por seed, fronteiras, integração, equivalência mecânica em **30/60/120 FPS** com timestamps controlados. Matrizes, métricas, seeds e scripts de execução **PENDENTES**.

### D-036 (Rodada 12, 1D; 2A; 3D) — efeitos de dano e validação resistente; DESIGN, NÃO IMPLEMENTADO

- **1D:** cada **efeito que causa dano** declara explicitamente se participa do **piso mínimo 1** da D-033. Não presumir participação de todo Move, de todos os efeitos de status nem de todos os componentes de uma habilidade mista. Nome/tipo/valor-padrão do campo e definição de efeitos sem dano nominal ainda **PENDENTES**. O piso depende adicionalmente de contato e afinidade que permita dano.
- **2A:** para efeito participante, após **todos os modificadores e o arredondamento final**, se houve **contato** e a afinidade permite dano, aplicar **`max(dano_arredondado, 1)`**. Sem contato, ou com afinidade **Null/Absorb**, não aplicar piso e não criar dano artificial. Não alterar SP `1dN`, crítico D-021, variação ±10% D-019 e demais contratos. O código `BattleMath.physical_damage()` ainda usa `maxi(0, int(round(amount)))` e não possui metadados de participação por efeito.
- **3D:** separar a validação do **resistente de laboratório D-033** (HP 40, DEF 8, SP_base 88) em **duas baterias**: **SP igual** entre atacante de referência e alvo, para isolar HP/DEF; e **SP 80 do atacante contra SP 88 do alvo** para avaliar o impacto de `−1d8`. Manter ataque básico poder 8 e o objetivo resistente 5–7 acertos como referência, sem garantir que seja atingido. **PENDENTES:** valor de SP igual no primeiro cenário, controle do estado, quantidade de amostras, seeds, demais condições de ensaio e **taxa de aprovação de cada bateria**. O requisito de ≥95% em 10.000 casos da D-032/D-033 aplica-se ao **ensaio neutro**, não automaticamente a estas duas novas baterias. Não foram executados testes.

### D-037 (Rodada 13, 3C; 8C) — piso por pacote e validação resistente; DESIGN, NÃO IMPLEMENTADO

- **3C:** o piso final de 1 dano da D-033/D-036 incide **por pacote mecânico de dano identificado e associado aos efeitos de dano participantes**. Cada efeito conserva a declaração individual de participação no piso (D-036 1D), mas vários efeitos no **mesmo pacote** não produzem automaticamente vários pisos. Aplicar uma vez ao resultado final do pacote após modificadores e arredondamento, somente com contato e afinidade que permita dano; não criar dano para efeitos de status, sem contato ou em **Null/Absorb**. Pacotes independentes e casos com mistura de efeitos participantes/não participantes carecem de contrato de agrupamento, identificação e resolução; sem inventar multiplicação por quantidade de efeitos.
- **8C:** para o **resistente de laboratório D-033** (HP 40, DEF 8, SP_base 88), a bateria com **SP igual** exige **≥95% de casos** concluídos em **5–7 acertos físicos bem-sucedidos**. A bateria com **SP 80 versus SP 88**, já aprovada na D-036, é **somente diagnóstica**, sem limiar estatístico aprovado. Quantidade de casos por bateria, valor igual de SP, demais controles/seeds e critério de contagem permanecem **PENDENTES**; não copiar automaticamente os **10.000 casos** do teste neutro D-032/D-033. A diferença de SP pode alongar o combate; nenhum teste foi executado.

### D-039 (Rodada 14, 3A; 7A) — pacote tipado e bateria resistente; DESIGN, NÃO IMPLEMENTADO

- **3A:** futuros pacotes mecânicos de dano usarão **Resource tipado** com **ID estável** e associações explícitas aos efeitos, cada um com declaração de participação no piso da D-036. O piso aplica-se **uma vez por pacote**, após modificadores/arredondamento, somente com contato e afinidade que permita dano; nunca criar dano em Null/Absorb, sem contato ou por status puro. A estrutura real dos Moves deve ser auditada antes de estabelecer nomes de classes/arquivos/recursos; migração, associações e deduplicação ainda **PENDENTES**. Nenhum Resource foi criado.
- **7A:** na bateria **resistente com SP igual** da D-037, exigir **10.000 casos controlados**, com **≥95% (≥9.500 casos)** terminando em **5–7 ataques físicos bem-sucedidos**, usando a ficha resistente de laboratório D-033 (HP 40, DEF 8, SP_base 88). Valor igual de SP, controle de teste e seeds permanecem **PENDENTES**. A bateria SP 80 contra 88 **continua diagnóstica**, sem tamanho/limiar homologados. Nenhum teste foi executado.

## Sistema de ritmo (ataques físicos)
- Aplica-se a **todos os ataques físicos**, de ambas as partes.
- Entrada manual: atacante controlado pelo jogador usa a barra visível para o
  ataque; defensor controlado pelo jogador usa a barra visível apenas quando declarou
  reação e pagou 1 ato. Atacante e defensor controlados pela IA resolvem seu próprio
  ritmo sem entrada humana.
- Barra com marcador móvel; janela do oponente define as zonas.
- **D-015 (2026-11-21):** quando atacante e defensor acertam **POINT** simultaneamente,
  a **defesa prevalece**: não há contato, o dano é 0 e não há crítico, Press Turn nem
  ganho de SP. **IMPLEMENTADO** em `BattleMath.has_contact()`.
- Zonas: **Ponto = 10% central**, **Trave = 20% ao redor**, resto = trilha.
- **D-109 (criador 2026-11-25; IMPLEMENTADO): todo golpe com barra acerta.** Na barra de
  ataque, o marco **amarelo** (centro, verde na tela) dá **100%** do dano, o **cinza** (faixa
  lateral, bege na tela) dá **80%** e o **branco** (trilha das pontas) dá **50%**; a falha deixou
  de existir no ataque. Desvio de verdade só quando o alvo **DEFENDE** pagando **1 ACT** e para no
  centro da barra de defesa (0 de dano, D-015); defesa na faixa lateral = **50%**, qualquer que
  seja o marco do ataque; defesa nas pontas não reduz. Vale para ATTACK, habilidades físicas,
  magias, Ra'am e os golpes da troca de contra-ataque (empate na trilha branca: os dois acertam
  50%), do jogador e dos inimigos. O golpe na trilha branca conta como acerto para crítico e SP. O inimigo paga 1 ACT **sempre** que defende, dê certo ou não. As cores da barra
  não mudaram. `BattleMath.strike_multiplier()` / `scaled_damage()` (arredonda, golpe de 1 não vira
  0).
- Tecla: **Z / Enter**.
- **D-034 (2026-11-21): a barra tem velocidade própria e fixa de 1,0 segundo.**
  AGI e SP **não** alteram mais a duração. A diferença de AGI passa a alterar
  o **tamanho da zona POINT**: base 10% + **1 ponto percentual por ponto de
  AGI de vantagem**; o SP mantém os ajustes por faixa da D-021 (±1 p.p. por
  5 SP, até ±2 p.p.). Cobertura total limitada a 8%–16% (D-023).
  **IMPLEMENTADO** em `BattleMath.rhythm_duration()`, `point_half_width()` e
  `RhythmBar.configure()`. Substitui a regra anterior de duração variável.
- Ao atacar: Ponto → dano integral; Trave → oponente bloqueia; Falha → sem dano.
- Ao defender: Trave → bloqueia; Ponto → desvia e ganha +1 SP; Falha → dano integral.
- Bloqueio extra: **+1 rolagem de bloqueio a cada 2 pontos de SP de vantagem**.

### D-021 (Rodada 5) — zonas especiais calibradas; não implementadas

- **4B (histórico; ajuste de AGI substituído por D-034):** cobertura total
  POINT inicial **10%**; antes, ±1 p.p. por 10 de diferença de AGI.
  Agora a diferença de AGI vale **+1 p.p. por ponto**, conforme D-034;
  o ajuste por SP desta decisão permanece.
  do executante do timing.
- **5A:** ajustar **±1 ponto percentual por 5 pontos
  de diferença de SP**, limitado a **±2 p.p. de SP**,
  em favor do executante com mais SP.
  Cobertura final compartilhada entre zonas múltiplas
  e limitada a **8%–16%** conforme D-020.
  Exemplo: ΔAGI +10, ΔSP +5 → 12%;
  ΔAGI −20, ΔSP −10 → 8% após limite.
  Arredondamento para diferenças não múltiplas
  e leitura de atributos durante ação: **PENDENTES**.
- **6B:** cada região POINT requer **40 ms mínimos
  de passagem efetiva**; se o perfil, a duração
  total existente e a cobertura de 8%–16%
  não puderem coexistir, o **perfil é inválido**.
  Não prolongar duração, alargar zonas fora dos
  limites ou diminuir janela temporal silenciosamente.
  **PENDENTES:** geração/rejeição de perfis inválidos,
  limites de cadência, medição por tempo real,
  sincronização e testes sob FPS/latência diversos.
- O movimento uniforme atual pode oferecer
  apenas 16 ms de passagem por 8% do trajeto
  quando a barra completa dura 0,2 s;
  por isso **não atende automaticamente à D-021**.
  `RhythmBar` e `BattleMath.rhythm_zone()`
  continuam sob as regras do protótipo anterior.

### D-023 (Rodada 6) — contrato de perfis especiais, design aprovado; NÃO IMPLEMENTADO

- **1A:** interpolação contínua dos ajustes de
  largura POINT definidos na D-021:
  **0,1 p.p. por ΔAGI** e **0,2 p.p. por ΔSP**,
  com base de **10%**, parcela de SP limitada
  a **±2 p.p.** e cobertura total limitada
  a **8%–16% do percurso**. Sem arredondar
  diferenças AGI/SP a faixas completas.
  Exemplo: ΔAGI +7, ΔSP +3 → **11,3%**.
  Essa quantificação é a regra posterior
  aplicável à largura, apesar da formulação
  anterior por faixas da D-020.
- **2B:** máximo de **3 regiões POINT por perfil**,
  sem obrigação de usar todas.
- **3B:** o **perfil do inimigo declara**
  como dividir o orçamento total entre
  as regiões; não impor igualdade.
  A soma respeita 8%–16%, e cada região
  deve oferecer **≥40 ms de tempo efetivo**.
- **4D:** domínio do gerador restringido
  **desde a origem a configurações
  comprovadamente válidas**, sem depender
  de sorteio seguido de rejeição repetida.
  Verificar simultaneamente duração global,
  cobertura, número de regiões, cadência
  e mínimo temporal. Configuração sem
  solução: tratamento operacional **PENDENTE**,
  sem fallback inventado.
- **5A:** cadência com acelerações e
  desacelerações em **segmentos de
  transições suaves**, velocidade
  **contínua**, travessia normalizada
  à mesma duração global da D-020.
  Limites/funções de velocidade e
  aceleração são **PENDENTES**.
- **6B:** IA executa timing com
  **erro temporal triangular limitado**
  e concentrado junto ao alvo,
  dependente da habilidade. Valores
  e amplitude de erro **PENDENTES**.
  O autoacerto inimigo da **D-014/D-022**
  tem precedência quando o jogador
  **não declara reação**, seja porque
  não pode ou porque escolheu não fazê-lo.
  Não inferir crítico automático.
- **7A:** seed do encontro combinada
  com **IDs estáveis do inimigo e do
  perfil e índice de execução**;
  algoritmo de derivação, versão,
  formato/registro e isolamento
  de sequências RNG **PENDENTES**.
- **8A:** julgamento mecânico pelo
  **instante registrado da entrada**,
  não pela posição do último quadro
  renderizado; apresentação segue
  a posição do marcador correspondente
  ao mesmo referencial temporal.
  Relógio, precisão, tratamento de
  bordas e tolerâncias **PENDENTES**.
- **Viabilidade:** três regiões POINT
  em barra total de 0,2 s demandam
  **ao menos 120 ms de passagem
  somados nas regiões**. A regra
  de largura 8%–16% não garante
  esse tempo; o gerador e a curva
  precisam demonstrar validade,
  sem alterar os limites aprovados.
- **Estado atual:** `RhythmBar`
  avança uniformemente e avalia
  a posição do marcador em input,
  `BattleMath.rhythm_zone()` é fixo
  e `_ai_roll()` sorteia resultados.
  Os contratos da D-023 **não foram
  implementados nesta rodada**.

### D-024 (Rodada 7) — parâmetros e critérios de aceitação; DESIGN APROVADO, NÃO IMPLEMENTADO

- **1B:** a **velocidade instantânea máxima**
  do marcador é **4× a velocidade média**
  da travessia completa, relativa à duração
  global calculada. Manter transições
  suaves e continuidade da D-023; limites
  de aceleração, velocidade mínima e
  curvas específicas são **PENDENTES**.
- **2A:** perfis com **3 regiões POINT**
  exigem **duração global ≥300 ms**.
  Perfis de 1–2 zonas preservam a
  duração global preexistente, sempre
  sujeitos aos **40 ms mínimos por
  região** e à validação de viabilidade.
  Não prolongar a barra para forçar
  três zonas. Não criar fallback para
  configurações inválidas sem aprovação.
- **3A:** na distribuição triangular
  temporal limitada da IA (D-023),
  usar amplitudes iniciais por habilidade:
  **iniciante ±70 ms**, **comum ±40 ms**
  e **profissional ±20 ms**, em torno
  do instante alvo. Categoria de
  cada inimigo, moda exata e detalhes
  do modelo permanecem **PENDENTES**.
  A exceção de autoacerto das D-014/D-022
  prevalece quando **não há reação
  declarada**, sem crítico automático.
- **4B:** quando houver várias regiões
  POINT, a IA prioriza a que ofereça a
  **maior duração efetiva de passagem**
  do marcador. Critério de desempate
  e escolha do instante-alvo dentro
  da região ainda **PENDENTES**.
- **5B:** para replay e rastreabilidade,
  além de seed do encontro, IDs estáveis
  de inimigo e perfil e índice da execução
  da D-023, registrar **cópia completa
  dos parâmetros resolvidos do perfil**.
  Esquema, versionamento e algoritmo
  de derivação de seed são **PENDENTES**;
  não supor que o snapshot por si
  preserve compatibilidade entre
  versões diferentes do resolvedor.
- **6A:** julgar o input por relógio
  **monotônico, relativo ao início
  da barra**, registrando o instante
  **em que o evento é recebido**.
  O último frame renderizado nunca
  é fonte mecânica do resultado;
  verificar relógio e resolução
  reais disponíveis na API antes
  de implementar. Pausas, bordas,
  sincronização e tolerâncias
  permanecem **PENDENTES**. O instante
  de recebimento não deve ser
  confundido com o instante físico
  da tecla.
- **7C:** usar uma **ficha neutra de
  referência para calibrar poderes**,
  com **valores e estrutura a homologar
  separadamente**. A meta permanece
  **3–5 ataques físicos bem-sucedidos**
  contra equivalente sem bloqueios
  ou críticos; fórmula `poder×ATK÷DEF`
  preservada. Não foi criada ficha
  nem aprovado poder numérico.
- **8A:** antes de declarar a nova
  execução conforme, exigir **testes
  de propriedades matemáticas,
  replay determinístico por seed,
  testes de fronteira, integração e
  comparações entre taxas de FPS**.
  Abranger cobertura, duração, picos
  de velocidade, 40 ms mínimos por
  zona, relógio de input, IA,
  contato, crítico, SP e reações.
  Cenários, taxas específicas,
  limiares e tolerâncias dos
  critérios de aceitação **PENDENTES**.
  Nenhum desses testes foi executado
  nesta publicação documental.
- **Risco de viabilidade:** para
  três zonas em barra de 300 ms,
  é necessário tempo total de
  pelo menos **120 ms em POINT**,
  com até 180 ms restantes fora.
  O teto 4× não demonstra sozinho
  que perfis arbitrários com
  transições suaves sejam válidos;
  respeitar geração válida por
  construção de D-023.
- **Implementação corrente:** 
  `RhythmBar` usa progressão
  uniforme e posição visual para
  julgamento, `BattleMath.rhythm_zone()`
  usa zonas fixas e `_ai_roll()`
  sorteia resultados discretos.
  D-024 exige trabalho posterior
  em código, não autorizado nesta
  rodada. D-022 autoacerto sem
  reação já implementado permanece.

### D-025 (Rodada 8, 1B; 2B; 3A; 4A; 8A) — validação e tempo; design não implementado

- **1B:** se um perfil do encontro
  não possui configuração válida
  conforme D-020/D-021/D-023/D-024,
  **bloquear validação/carregamento do
  encontro** com diagnóstico explícito.
  Nenhum fallback automático foi
  aprovado. Quando AGI/SP mudarem
  em tempo de execução, a política
  de viabilidade continua **PENDENTE**.
- **2B:** `|dv/dt| ≤ 12 × v_média/T`,
  com `T` igual à duração total da
  travessia e `v_média` igual à
  distância total sobre `T`.
  Preservar teto de velocidade
  instantânea **4× v_média** e
  transições suaves D-023.
  Nenhuma curva específica foi
  aprovada. Exemplo: com barra
  de 300 ms, mudança de 1×
  v_média exige pelo menos 25 ms
  sob aceleração máxima.
- **3A:** a fronteira exata entre
  resultados pertence à zona
  mais favorável: **POINT > BEAM
  > MISS**. Sem tolerância temporal
  adicional, sem mudança na
  precedência POINT/POINT D-015.
- **4A:** para reação escolhida
  com combate pausado, iniciar
  **origem monotônica nova ao
  começar a barra após a escolha**,
  excluindo o tempo de menu
  da duração do reflexo.
  A implementação atual da
  escolha pausada ainda está
  pendente de acordo com D-014;
  a ativação e a primeira entrada
  elegível requerem definição.
- **8A:** exigir **resultado
  mecânico exatamente idêntico**
  sob **30, 60 e 120 FPS** com
  **timestamps controlados
  equivalentes**, mesma seed
  e parâmetros resolvidos.
  Testar inclusive fronteiras.
  Isso não exige igualdade
  visual quadro a quadro nem
  presume precisão física do
  hardware. Matriz e harness
  de teste ficam pendentes.
- **DIVERGÊNCIA atual:** `RhythmBar`
  usa a posição renderizada do
  marcador e `BattleMath.rhythm_zone()`
  aplica zonas fixas; o motor
  ainda não implementa esses
  contratos. Nenhum código,
  teste ou asset foi alterado.

### D-031 (Rodada 9, 4B; 6A; 7A; 8B) — variantes e instantes de ritmo; DESIGN, NÃO IMPLEMENTADO

- **4B:** permitir
  **variantes alternativas
  expressamente declaradas
  no perfil de inimigo**,
  **validadas antes de uso**
  e selecionadas **antes
  da execução** quando
  necessário para respeitar
  a duração/cobertura e
  demais contratos com
  AGI/SP dinâmicos.
  D-025 ainda bloqueia
  encontros com configurações
  sem solução válida no
  carregamento; variantes
  não autorizam fallback
  genérico, descarte
  de ações ou relaxamento
  de limites. **PENDENTES:**
  seleção entre variantes,
  ordem de validação,
  compatibilidade com
  estados alcançáveis,
  política caso nenhuma
  variante seja elegível
  em tempo de execução e
  se primário inválido
  pode coexistir com
  alternativa válida.
- **6A:** desprezar
  entradas registradas
  **antes do instante
  inicial da barra**;
  aceitar **novos eventos
  a partir de t=0**
  da barra. Não aceitar
  automaticamente
  a tecla anterior de
  confirmação de reação.
  A pausa de escolha
  da D-014 é externa
  ao intervalo da barra.
  Não inserir buffer
  antecipado, tolerância
  ou atraso obrigatório.
  **PENDENTES:** ordem
  de eventos em t=0,
  teclado/auto-repeat,
  precisão dos timestamps
  e tratamento de eventos
  simultâneos.
- **7A:** após selecionar
  a região POINT com
  **maior janela temporal
  efetiva** (D-024),
  a IA mira seu **centro
  temporal**, não o
  centro espacial.
  Aplicar erro triangular
  limitado da D-023/D-024
  em torno desse instante;
  critérios de desempate
  entre regiões e categoria
  da IA continuam pendentes.
  D-022 preserva acerto
  automático inimigo sem
  reação declarada.
- **8B:** capturar AGI e
  SP dos participantes
  **no instante de início
  de cada barra**, mantendo
  esses valores **fixos
  até seu término** para
  duração, geometria,
  variante, trajetória
  e julgamento temporal;
  registrar os atributos
  capturados no snapshot
  reproduzível D-024.
  Próxima barra realiza
  nova captura. **Não**
  alterar por inferência
  os instantes de consulta
  das estatísticas para
  cálculo de dano ou
  outros efeitos fora
  da execução da barra.
  **PENDENTES:** relação
  precisa entre captura
  e escolha da variante,
  eventos simultâneos
  de buffs/SP no início
  e integração com
  a pausa de reação.
- **Compatibilidade:**
  preservar D-020 a
  D-025 — cobertura
  8%–16%, 40 ms mínimos
  por região, máximo 3
  regiões (≥300 ms para
  usar 3), velocidades
  contínuas e limites
  de 4× velocidade média
  e 12×v_média/T de
  aceleração, avaliação
  por tempo de input e
  fronteiras POINT>BEAM>MISS.
  Perfis atuais da cena
  ainda não implementam
  D-031. Nenhuma alteração
  em scripts, testes ou
  recursos nesta rodada.

### D-032 (Rodada 10, 1C; 5A; 6A; 7A) — duração, variantes e replay; DESIGN, NÃO IMPLEMENTADO

- **1C:** recalibrar
  `BattleMath.rhythm_duration()`
  de **50 ms por
  ponto combinado**
  de ΔAGI+ΔSP para
  **50 ms por 8
  pontos combinados**.
  Preservar base
  **1 s**, limites
  **0,2–1 s**, sinais
  e duração fixa
  durante cada barra.
  Para diferenças
  múltiplas de oito:
  `T = clamp(1 -
  0.05 × ((ΔAGI+ΔSP)/8),
  0.2, 1)`.
  Exemplo: ΔAGI=0,
  ΔSP=+24 resulta
  em **0,85 s**,
  comparado com
  **0,2 s** no
  protótipo.
  **PENDENTE:**
  tratamento dos
  grupos incompletos
  (fração proporcional
  ou somente grupos
  inteiros) antes
  de implementar.
  Não modificar
  o teto 4× da
  velocidade, o
  limite de
  aceleração ou
  os 40 ms por
  região POINT.
- **5A:** a validação
  antecipada deve
  **comprovar** que
  existe **ao menos
  uma variante
  explicitamente
  declarada e
  válida para
  cada estado
  de atributos
  alcançável**
  no encontro.
  Conservar
  D-023/D-025/
  D-031 e bloquear
  carregamento de
  encontro que
  não satisfaça
  esse contrato.
  **PENDENTES:**
  domínio exato de
  estados alcançáveis,
  limites de
  progressão e
  modificadores
  existentes,
  método de prova
  de cobertura
  e desempenho
  do validador.
  Não inventar
  fallback, reduzir
  limites ou
  alterar saves
  D-028.
- **6A:** dentre
  variantes
  elegíveis,
  selecionar a
  **primeira na
  ordem de
  prioridade
  explicitamente
  declarada pelo
  perfil** antes
  da execução.
  Não usar sorteio
  nem maior número
  de regiões
  como regra
  implícita.
  Manter a captura
  AGI/SP da
  D-031 no início
  da barra;
  precedência
  exata entre
  captura e
  elegibilidade
  segue pendente.
- **7A:** registrar
  snapshots em
  **JSON versionado,
  independentes da
  apresentação
  visual**.
  Preservar o
  conteúdo do
  registro
  reproduzível
  D-023/D-024/
  D-031: seed,
  IDs, índice
  de execução,
  parâmetros
  resolvidos
  completos,
  AGI/SP capturados
  e marcos de
  timing/inputs.
  Esquema, versão
  inicial, precisão
  numérica e
  compatibilidade
  entre resolvedores
  permanecem
  **PENDENTES**.
  Não foi criado
  arquivo JSON.
- **Estado do motor:**
  a duração ainda
  usa 0,05 s por
  ponto combinado,
  as zonas são
  fixas e a
  avaliação depende
  da posição visual
  do marcador.
  D-032 não
  altera código.

### D-033 (Rodada 11, 1A; 4B; 5A; 7A) — duração contínua, prova e replay; DESIGN, NÃO IMPLEMENTADO

- **1A:** duração `T=clamp(1−0,00625×(ΔAGI+ΔSP),0,2,1)` segundos, **6,25 ms por ponto combinado**, interpolada continuamente, sem grupos inteiros; exemplo Δ combinado +5 → **0,96875 s**. Preservar orientação, limites 0,2–1 s e atributos congelados por barra. A implementação atual ainda usa 0,05 s/ponto.
- **4B:** validar variantes para **todos os estados de atributos alcançáveis** por **partição em intervalos e demonstração matemática de cobertura em cada intervalo**, incluindo extremos, cortes, limites temporais e velocidade. Amostragem não substitui prova; D-025 bloqueia encontro sem cobertura. **PENDENTES:** caracterização do domínio com D-028, representação de intervalos e método verificável de prova; sem inventar teto de atributos.
- **5A:** na ativação, **capturar AGI/SP**, **validar elegibilidade**, **selecionar a primeira variante válida por prioridade**, e **só então iniciar o relógio monotônico do input em t=0**. A transição é mecânica e atomicamente consistente; nenhum evento intermediário muda o estado capturado. Semântica de simultaneidade e ausência de variante válida **PENDENTES**.
- **7A:** snapshots **JSON** com **versão do esquema de dados** e **versão do resolvedor mecânico** distintas, conservando parâmetros completos, seed, IDs, índice, AGI/SP e instantes de input. Versão registrada não garante disponibilidade de resolvedores antigos. Esquema exato, precisão, compatibilidade e versões iniciais **PENDENTES**. Nenhum arquivo JSON criado.
- Preservar D-014/D-022 e D-020–D-025/D-031/D-032: cobertura 8%–16%, mínimo 40 ms por região, até três regiões se duração ≥300 ms, velocidade ≤4× e aceleração ≤12×média/T, resultado temporal por input.

### D-036 (Rodada 12, 4A; 5A; 6A; 7A; 8A) — domínio, input, replay e rastros; DESIGN, NÃO IMPLEMENTADO

- **4A:** demonstrar cobertura de variantes (D-032/D-033) sobre o **conjunto real de estados alcançáveis**, derivado dos **limites efetivos existentes no motor** e de **todas as transições permitidas de atributos**, incluindo persistência D-028, sem adicionar teto novo por design. A implementação `ProgressStore.MAX_GAIN=10000` limita ganhos serializados por atributo, mas não define automaticamente limite global de atributos/SP ou dos efeitos em combate. Domínio completo, prova intervalar e certificado de validade **PENDENTES**.
- **5A:** no instante de ativação, **resolver primeiro os eventos mecânicos já comprometidos até esse marco temporal**; só depois **capturar AGI/SP**, verificar elegibilidade de variantes, selecionar a primeira variante válida por prioridade e iniciar o relógio de input em **t=0**, de forma atomicamente consistente (D-033). A precedência entre eventos verdadeiramente simultâneos **não foi fixada** nesta rodada.
- **6A:** tempos mecânicos de snapshots JSON em **inteiros de microssegundos**. Conversão entre relógio de input, simulação e registro somente nas fronteiras necessárias, com política de arredondamento e resolução ainda **PENDENTES**. A unidade de armazenamento não implica precisão física de microssegundos na captura de input.
- **7A:** se a **versão do resolvedor mecânico** exigida pelo snapshot não estiver disponível, **recusar a reprodução mecânica exata**, identificar a incompatibilidade e **preservar os dados originais**. Não reexecutar com resolvedor recente alegando equivalência, migrar ou excluir automaticamente. Inspeção dos dados não comprova replay.
- **8A:** com **seed, parâmetros resolvidos e entradas temporais controladas iguais**, exigir **rastro de eventos mecânicos exatamente igual** a **30/60/120 FPS**, além dos estados finais. Incluir identidades, ordem, marcos de tempo, HP, SP, gastos/ganhos de atos, reações, fraquezas, efeitos e cancelamentos. Não exigir frames visuais idênticos. **PENDENTES:** esquema canônico, ordenação, rastreamento de RNG, cenários e testes executáveis.
- **Precedência:** a **D-034 implementada** substitui a **duração variável D-033** por barra **fixa de 1 s**; AGI afeta largura POINT, SP continua com faixas vigentes, e a **D-035 implementada** aplica mesma largura POINT na IA. Não restaurar fórmulas de duração antigas ou cadência variável sem nova aprovação. A IA atual ainda usa amostragem de posição, e `RhythmBar` classifica input pela posição do último quadro — **não** atendem ainda à exigência de rastro e relógio temporal. A D-036 não altera código, assets ou testes.
- **Consequência aritmética da D-034:** em travessia uniforme de 1 s, ≥40 ms por região implica largura espacial individual ≥4%. Para três regiões POINT, exige-se cobertura total ≥12%, mesmo que o intervalo global permita 8%–16%. Isso deve constar da prova de viabilidade, não ser assumido automaticamente como implementado.

### D-037 (Rodada 13, 1A; 2B; 4A; 5A; 6B; 7A) — velocidade, IA, certificados e rastros; DESIGN, NÃO IMPLEMENTADO

- **1A:** **todos os perfis** seguem velocidade **uniforme**, com duração de **1 s** da **D-034 implementada**, inclusive chefes e perfis especiais. A variedade dos especiais vem de **posição, largura e número das regiões POINT**, sem aceleração/desaceleração, preservando os limites temporais e espaciais ainda aplicáveis. Não restaurar D-020/D-023 de cadência variável ou duração variável D-032/D-033. Com 1 s uniforme, mínimo de 40 ms por região exige **≥4% de largura espacial por região**; três regiões exigem **≥12% no total**, dentro do intervalo de 8%–16%. Múltiplas regiões ainda não implementadas.
- **2B:** IA comum mantém **D-035 implementada**: amostragem uniforme de posição, classificação por largura POINT compartilhada com o jogador. Nos **perfis especiais**, IA mira o **centro temporal da região de maior janela efetiva** e aplica erro **temporal triangular limitado** de D-023/D-024, sem mudar a largura POINT aplicável ao combatente. Rolagens extras por SP e **autoacerto inimigo sem reação** (D-022) prevalecem. Classificação dos perfis, atribuição de habilidade e lógica do erro especial **PENDENTES**, sem alterar a IA comum.
- **4A:** a prova intervalar do domínio alcançável deve produzir **certificado por intervalo** com limites, condições verificadas, variantes que garantem cobertura e **contraexemplo em caso de falha**. Deve refletir regras vigentes D-034/D-035, não curvas/duração histórica. Formato e método matemático **PENDENTES**; amostragem não comprova universalidade.
- **5A:** ordenar eventos mecânicos com mesmo timestamp por **número de sequência estável atribuído ao serem comprometidos**. Preservar resolução dos eventos já comprometidos antes de capturar atributos e ativar barra (D-036). A atribuição de sequência deve ser determinística e independente da ordem acidental de callbacks; escopo/unicidade e eventos derivados **PENDENTES**. Esta ordem de eventos não substitui prioridade de AGI/ID entre combatentes.
- **6B:** snapshots JSON registram tempos mecânicos em **inteiros de microssegundos** (D-036), usando **arredondamento ao microssegundo mais próximo**; exemplo 0,1234567 s → **123457 µs**. A **regra para empates de metade de microssegundo** ainda **não foi escolhida**; resolução física e conversão do relógio continuam pendentes. Não inferir precisão física de captura.
- **7A:** cada evento do rastro mecânico canônico deve conter **identidade do evento, sequência, timestamp em µs, tipo, participantes, alterações de estado, decisões mecânicas, configuração/versão e dados de RNG necessários à reprodução**. Preservar o registro de seed, snapshots completos, versões de esquema/resolvedor e a exigência de **rastro exatamente igual em 30/60/120 FPS** sob inputs e seeds controlados (D-036). Campos, forma de dados de RNG, IDs e esquema de serialização **PENDENTES**. Nenhum JSON ou teste foi produzido.
- **Estado técnico:** `BattleMath.rhythm_duration()` e `RhythmBar` já refletem a duração fixa/uniforme D-034; `BattleController._ai_roll()` já utiliza amostragem comum D-035. A barra ainda julga input pela posição do último frame; IA especial triangular, múltiplas zonas, certificados e rastros completos **não estão implementados**. D-037 é apenas documental.

### D-039 (Rodada 14, 4A; 5B; 6A) — IDs de eventos, quantização e autoacerto; DESIGN, NÃO IMPLEMENTADO

- **4A:** sequência **inteira monotônica e única por encontro**, vinculada ao **ID estável do encontro**. Reinicia a cada novo combate, mantendo identidade do conjunto dos eventos. Cada número é atribuído quando um evento mecânico fica comprometido (D-037), com ordem de compromisso fundada nas regras mecânicas, não em callbacks visuais. Valor inicial, IDs de encontro e simultaneidade residual **PENDENTES**.
- **5B:** armazenar tempo em **microssegundos inteiros**, arredondando ao mais próximo; em empate exato, utilizar **inteiro par** (*round half to even*). Ex.: `123456,5 µs→123456`; `123457,5 µs→123458`. Exigir implementação explícita e testes, sem presumir o comportamento de `round()` do motor ou equivalência física de input.
- **6A:** **sem reação declarada pelo jogador**, resolver **primeiro** a exceção de autoacerto inimigo D-014/D-022; erro triangular da IA especial **não pode resultar em MISS**. Não conceder crítico automático, nem alterar sorteios SP/efeitos sem autorização; detalhes de consumo RNG ainda **PENDENTES**. Preservar D-034 (1 s uniforme), D-035 (IA comum uniforme), D-037 (timing triangular exclusivamente especial).

### D-040 (Rodada 15, 1A–7A) — input temporal e RNG da Fase 1; DESIGN, NÃO IMPLEMENTADO

- **1A:** capturar **relógio monotônico imediatamente na entrada do handler** e usar o instante de **recebimento relativo ao início da barra**, nunca último pixel desenhado/tick físico. API/resolução/latência do Godot não verificadas em execução.
- **2A:** após preparação atômica, ativar relógio e aceitar **novos inputs desde t=0**, mesmo antes do primeiro frame; não reaproveitar o evento anterior que confirmou a reação.
- **3A:** somente **primeiro pressionamento novo e elegível** decide a classificação; fechar imediatamente avaliação e impedir `echo`, eventos repetidos/atrasados e dupla emissão.
- **4A:** input com **t≤1.000.000 µs** vence o **timeout** e é classificado normalmente; t>1 s é inválido. Em t=1 s o percurso termina em **MISS**, mas distinguir input de timeout nos eventos. Fila/ordenação quando callback do timeout ocorre antes de input mecanicamente válido continua pendente; callbacks não podem decidir.
- **5A:** a **linha temporal mecânica** é a autoridade; UI visualiza o progresso, **sem determinar resultado**. Preservar duração/velocidade fixa D-034 e largura POINT D-034/D-035.
- **6A:** julgar por **instante monotônico capturado** e só então serializar em **µs inteiros** com arredondamento ao próximo e empate para o par D-039, sem mudar resultado. Registro só em µs pode colapsar instantes de lados opostos das fronteiras; **replay exato nesses casos ainda pendente**.
- **7A:** sem reação declarada (D-022), **não fazer rolagem triangular dispensada nem consumir seu RNG**; exigir **fluxos de RNG separados por finalidade**, preservando rolagens de dano/crítico e crítico não automático. Derivação de seeds/estados e IA especial ainda pendentes. Esta decisão **não implementa IA triangular**.

D-039 organiza Fase 1 temporal antes da Fase 2 especial, Fase 3 de dano e Fase 4 de replay. REST D-038 permanece **design não implementado**, separado e sem autorização de mudança nesta publicação.

### D-041 (Rodada 16, 1A–4A; 6C; 7B; 8A) — tempo, regiões especiais e RNG; DESIGN, NÃO IMPLEMENTADO

- **1A:** registrar origem da barra e instante de recebimento na entrada do handler com **`Time.get_ticks_usec()`** (mesma fonte monotônica), usando diferença relativa; verificar API e resolução real no Godot. Unidade de µs **não** implica latência física de input com precisão de µs.
- **2A:** arbitrar input e timeout por **tempo mecânico**, e em **t=1.000.000 µs** permitir que input novo elegível prevaleça, antes de atribuir ordem de sequência estável. Callback incidental do timeout não determina o resultado. Protocolo de fila, inclusive evento elegível recebido tardiamente, **PENDENTE**; não adicionar atraso por frame.
- **3A:** somente **nova transição de pressionamento após ativação**, sem reaproveitar o evento de confirmação ou `echo`; não exigir liberação global de todas as teclas. O primeiro input elegível encerra a execução uma única vez (D-040).
- **4A:** registrar, além de µs inteiro quantizado e resultado, **instante bruto capturado na precisão de origem efetiva**, **limites geométricos/temporais resolvidos** e **versão do resolvedor**, para auditoria de fronteira; não inventar precisão sub-µs se usar `get_ticks_usec()` nem mudar julgamento feito antes da quantização. Esquema exato e replay entre versões **PENDENTES**.
- **6C:** **BEAM do perfil especial é conjunto de intervalos explicitamente declarados e validados**, em conjunto com POINT, sem substituir a geometria BEAM central do **perfil comum** D-034/D-035. Fronteiras seguem **POINT > BEAM > MISS** (D-025). Orçamento total de BEAM, sobreposições, separação mínima e validade dos intervalos **PENDENTES**; não presumir adjacency automática ou BEAM ausente.
- **7B:** cada perfil especial declara **pesos relativos das regiões POINT**; distribuir o **orçamento total POINT calculado pela D-034 com AGI/SP (8%–16%)** proporcionalmente entre elas. Barra uniforme de 1 s ⇒ cada região POINT **≥4%** de largura para satisfazer **40 ms**. Uma variante que viole essa condição no estado atual é **inválida**; usar somente variantes explícitas validadas e priorizadas conforme D-025/D-031/D-032/D-033/D-036, sem ajustar pesos, excluir zonas, alterar tempo ou aceitar fallback oculto. Exemplo: 12% com pesos 1:1:1 ⇒ 4% cada, 8% ⇒ aproximadamente 2,67% cada, inválido. Domínio dos pesos, sobreposições, precisão de distribuição e viabilidade integral de estados ainda **PENDENTES**.
- **8A:** fluxos RNG separados por finalidade, derivados da **seed do encontro, IDs estáveis pertinentes, identidade do perfil, índice da execução e identificador da finalidade**. Preservar D-022/D-039/D-040: sem reação declarada, não sortear nem consumir erro triangular dispensado, sem deslocar dano/crítico. Algoritmo de derivação, codificação de IDs, estados internos, versionamento e integração com RNG atual ainda **PENDENTES**. O motor usa `BattleController.rng` compartilhado; nenhuma modificação nesta rodada.
- **Precedência:** D-034 fixa duração/velocidade uniforme de 1 s; D-035 conserva amostragem uniforme e largura POINT do perfil comum; D-037 prevê IA especial triangular. Não restaurar cadência/duração variable histórica, nem alterar REST D-038.

### D-042 (Rodada 17, 1A; 2A; 3A; 4A; 5A; 6A; 7D; 8A) — geometria especial e IA triangular; DESIGN, NÃO IMPLEMENTADO

- **1A:** perfis especiais possuem cobertura total **POINT+BEAM de 30%** do percurso uniforme de 1 s, somando a **união** de intervalos sem interior sobreposto. POINT mantém orçamento **dinâmico 8%–16%** calculado por AGI/SP na D-034; BEAM ocupa os **30% restantes**, isto é **22%–14%**, distribuído por intervalos explicitamente declarados (D-041). Perfil comum preserva seu BEAM central D-034/D-035. A forma autoral/dinâmica de ajustar múltiplos BEAM à cobertura variável ainda **PENDENTE**, sem assumir normalização ou redistribuição implícita.
- **2A:** proibir **sobreposição dos interiores** dos intervalos POINT/BEAM, inclusive em relação a intervalos da mesma categoria. Bordas comuns permitidas com prioridade **POINT > BEAM > MISS** (D-025), sem dupla contabilização de cobertura; sobreposição interna invalida a variante, sem reparo automático.
- **3A:** regiões POINT distintas requerem **lacuna estritamente positiva não-POINT** entre si, sem mínimo percentual extra. Regiões contíguas não contam como duas zonas; manter máximo de três e **≥40 ms/4% por região** em barra de 1 s.
- **4A:** os **pesos relativos de POINT** (D-041) são **finitos e >0**; normalizar a soma e distribuir proporcionalmente o orçamento total D-034; qualquer região resultante **<4%** invalida a variante no estado, sem zerar pesos nem eliminar regiões. Regras de arredondamento e precisão ainda **PENDENTES**.
- **5A:** cada região POINT declara **centro normalizado fixo**; varia largura **simetricamente** com AGI/SP. Variante é inválida se sair de [0,1], colidir com interiores de POINT/BEAM ou deixar de ter separação não-POINT positiva. Não reposicionar centros implicitamente.
- **6A:** perfis **ofensivo e defensivo especiais** são **independentes**, com dados, variantes e validação próprios; manter D-013 e precedência defensiva D-015. Não alterar perfil comum.
- **7D:** IA especial escolhe região POINT de **maior duração temporal efetiva** (D-024/D-031) e desempata pela **prioridade declarada entre regiões no próprio perfil**, independente da lista de prioridade entre variantes (D-032), sem RNG extra; mira o **centro temporal** da região selecionada.
- **8A:** erro temporal da IA especial obtido pela **média de dois sorteios uniformes independentes em [−L,+L]**, produzindo distribuição triangular simétrica limitada a **±70/±40/±20 ms** conforme habilidade D-024. **Exatamente duas amostras** na tentativa que necessita timing, sem rejeição/novo sorteio; se **não houver reação declarada**, D-022 garante autoacerto, **não consumir** o RNG triangular (D-039/D-040). Fluxo de timing separado por finalidade D-041. **PENDENTES:** clamp/regras para tempos finais fora da barra, validação de pesos/centros/BEAM, prioridade de regiões e contrato exato de RNG.
- **Viabilidade:** três regiões POINT exigem cobertura total **≥12%** e lacunas positivas; variante declarada com 8% distribuído entre três é inválida. Exigir prova intervalar de cobertura de todos os estados alcançáveis e alternativas expressamente validadas, sem fallback genérico. A D-034 de 1 s fixo e D-035 de IA comum uniforme permanecem vigentes; não restaurar velocidade/duração variável histórica.
- **Estado do projeto:** IA especial triangular e perfis POINT/BEAM múltiplos continuam **NÃO IMPLEMENTADOS**. A D-038 sobre REST foi **implementada** em commits posteriores; sua mecânica não é alterada nesta rodada.

### Acerto, bloqueio e exceção sem reação — D-014 (Rodada 2)

- **1E (ideia própria do diretor):** a **barra de ritmo** determina
  **acerto ou erro** do jogador e do inimigo durante os ataques.
  **Exceção:** o ataque inimigo **sempre acerta quando o jogador não
  pode reagir**. O acerto garantido não significa dano máximo,
  crítico automático ou alteração de modificadores de dano e afinidade.
  **D-022:** se o jogador *pode* reagir mas opta por não declarar reação,
  o ataque inimigo **também acerta automaticamente**. **IMPLEMENTADO.**
- **2A:** um **bloqueio na Trave reduz 50% do dano**. Percentual
  já praticado no código e agora confirmado como regra de design.
- **D-019 (Rodada 3, 6A):** quando a exceção de D-014 garantir acerto
  de ataque inimigo por **impossibilidade de reação**, o ataque ainda
  pode causar **crítico pela chance normal**. Não é crítico
  automático, nem recebe bônus adicional. Usa-se a fórmula crítica
  implementada até a calibração aprovada na D-019 (1A).
  A exceção de autoacerto foi **implementada** por D-014/D-022 em
  `BattleController._attack_timing()`.
- **3A e 4A:** sem atos não há bloqueio/desvio; com reação elegível,
  pausar a escolha e manter o tempo de execução da barra.
- A precedência POINT/POINT foi fixada por **D-015**: a defesa prevalece
  (0 dano, sem recompensas). O restante da resposta **1E** segue pendente
  conforme registrado no GDD §4.1.
- As zonas fixas descritas acima representam o **protótipo vigente**;
  os perfis variáveis de ritmo por inimigo e seus limites ainda
  estão em elaboração no GDD §8.1. D-014 não os cancela.
- **DIVERGÊNCIA RESTANTE:** a pausa para escolha de reação e a prioridade
  ofensiva por AGI ainda não foram implementadas. O autoacerto sem reação
  foi implementado por D-014/D-022.

### Perfis especiais de ritmo — D-013 e D-020 (Rodada 4; design aprovado, não implementado)

- **Escopo preservado de D-013:** determinados inimigos possuem
  perfis variáveis de **posição, número de zonas POINT e cadência**,
  com padrões distintos quando recebem ataques e quando os executam;
  padrão descoberto durante a execução. Nenhuma regra visual
  existente de HUD foi substituída.
- **D-020 (2026-11-21, 1B):** a **AGI define a largura-base POINT**,
  com ajustes por **faixas de superioridade SP**. Fórmulas, cortes,
  sinais e limites além do intervalo global abaixo ainda são
  **PENDENTES**; não derivar um coeficiente linear por suposição.
- **D-020 (2A e 3B):** quando existir mais de uma zona POINT, suas
  larguras **compartilham a mesma cobertura total**, cujo limite
  aprovado é **8% a 16% do percurso da linha** para perfis
  especiais. A distribuição entre zonas e largura mínima por
  região continuam **PENDENTES**; a cobertura não é
  automaticamente uma proporção equivalente de tempo.
- **D-020 (4A):** manter a **duração total** calculada pelas
  regras existentes e variar a cadência/velocidade do marcador
  dentro da travessia, **compensando** acelerações e desacelerações.
  Funções e extremos de velocidade permanecem **PENDENTES**.
- **D-020 (5A):** IA resolve perfis especiais simulando
  a **execução temporal** com erros de timing associados a
  sua habilidade; distribuição/escala desses erros ainda
  requerem aprovação. Respeitar a D-014 quando o jogador não
  puder reagir: o acerto inimigo garantido **prevalece**
  sobre uma falha simulada; crítico segue as regras da D-019.
- **D-020 (6B):** padrões variam por **seed de encontro**,
  preservando identidade e reprodutibilidade. A origem,
  persistência e derivação da seed e a variação entre ações
  do encontro ficam **PENDENTES**.
- **Limitação importante:** zona POINT de 8% em uma barra
  de duração total de 0,2 s equivale a **16 ms somente se
  a velocidade for constante**; aceleração local pode reduzir
  ainda mais a janela. Não há aprovação de duração mínima
  por zona ou de compensações automáticas para latência/FPS.
- **Compatibilidade:** POINT central fixo de 10%,
  `BattleMath.rhythm_zone()`, `RhythmBar` com movimento
  uniforme e sorteio discreto da IA continuam descrevendo
  **o código vigente**, não a execução dos perfis especiais
  D-013/D-020. Nenhuma implementação foi autorizada.

## Contra-ataque e interrupção — D-049; IMPLEMENTADO no motor Godot
- **Interrupção:** um personagem é interrompido na sua ação por um ataque que sofre, seja ataque normal ou magia. Quem é interrompido **perde o ato** da ação interrompida, e a ação não acontece.
- **Contra-ataque com duas barras:** ao reagir a um ataque com contra-ataque, aparecem **duas barras de ritmo** em vez de uma. Em cima fica a do oponente, com ponteiro **vermelho** da **direita para a esquerda**. Embaixo fica a do jogador, com ponteiro **branco** da **esquerda para a direita**.
- **Ritmo:** MISS, BEAM e POINT funcionam normalmente, como dois ataques consecutivos, um de cada lado.
- **Velocidade do ponteiro do oponente:** diferente da do jogador e definida pela **AGI**. Oponente com AGI maior que a do jogador tem ponteiro vermelho **mais rápido**; com AGI menor, mais lento.
- **Interrupção perfeita:** se o jogador ou o oponente aperta na hora certa quando os dois ponteiros estão na mesma posição, a tela pisca num **impact frame**, quem foi interrompido recebe **shake** e quem interrompeu **rouba 16 SP** do outro.
- **Interrupção comum:** quem tira o **resultado melhor** (POINT > BEAM > MISS) interrompe e rouba **4 SP**, não importa quem apertou primeiro (confirmado pelo criador em 2026-11-23; ver Resolução da troca).
- **Magias:** mantêm seus efeitos normais e também usam esse sistema para causar interrupção.
- **Fila:** quem interrompe ações em fila ganha **+1 ato por comando da fila perdido**, respeitando o teto de 4 atos disponíveis da D-005 (excedente vai ao estoque).
- **Decisões anteriores:** substitui **só o cancelamento** da D-025 (7A), que cancelava apenas por eliminação ou efeito explícito. A ordem por AGI (D-014, 5C) e o desempate lexicográfico por ID (D-031) continuam valendo. A interrupção da reza da D-048 segue a mesma ideia: o ataque de reação que acerta interrompe.
- **Empate:** resultados iguais: **os dois golpes resolvem** (ambos acertam ou ambos erram), cada lado perde **só os comandos seguintes da sua fila** e **ninguém perde SP** (confirmado pelo criador em 2026-11-23; substitui a redação antiga "ambos se interrompem, perdendo os atos").
- **SP roubado:** é SP de combate, portanto **temporário**: vale até o fim da batalha, como o +1 SP por evento (GDD §5). Só o SP de absorção e de atributos é permanente (D-028).
- **Dano:** o contra-ataque **causa dano** normalmente, além de interromper.
- **Magias:** a barra dupla funciona **exatamente como nos ataques**.
- **IA:** o momento em que o inimigo aperta na barra de cima é **aleatório**.
- **Impact frame:** o **cenário pisca em branco** por **3 quadros** (~0,05 s).
- **Janela da interrupção perfeita:** os dois ponteiros a até **~2% da barra** um do outro (praticamente o cruzamento).
- **Velocidade pela AGI:** velocidade do ponteiro vermelho = velocidade base × **AGI do oponente / AGI do jogador**.
- **SP zero:** o roubo pode deixar a vítima com **0 SP**, nunca negativo.
- **Só contra-ataque:** a barra dupla aparece só no contra-ataque (e em magias, como nos ataques). DEFEND/desvio e item usam a barra única de sempre.
- **D-015 no contra-ataque:** se os dois tiram POINT, vale o **empate da D-049** (os dois golpes resolvem e **cada golpe causa seu dano**; cada lado perde só os comandos seguintes da fila; sem perder SP); a D-015 continua valendo para defesa contra ataque.
- **D-022 mantida:** sem reação declarada, o inimigo acerta automaticamente, sem barra dupla nem interrupção.
- **Shake:** treme **só o sprite/cartão** de quem foi interrompido, por **0,4 s**, com amplitude de **4 px**.
- **Resolução da troca:** os resultados são comparados (POINT > BEAM > MISS). Quem tem resultado **melhor** interrompe: o seu golpe acerta, o do outro não acontece, e ele rouba 4 SP. Com resultados **iguais**, os dois golpes resolvem (ambos acertam ou ambos erram) e cada lado perde **só os comandos seguintes da sua fila**, sem ato extra e sem SP.
- **Golpe da perfeita:** conta como **POINT**, onde quer que o alinhamento aconteça.
- **Alvo do contra-ataque:** sempre o inimigo que anunciou o ataque. Se quem contra-ataca não é o alvo anunciado (D-045) e tira resultado pior, **ele leva o dano** no lugar do alvo e perde o SP equivalente.
- **Posição das barras:** sobre o inimigo quando é o inimigo quem contra-ataca; no painel de status do jogador quando é o jogador.
- **IA:** inimigo atacado que tem ato de reação contra-ataca com **33%** de chance; senão usa a defesa atual.
- **Perfeita só em movimento:** o alinhamento só conta enquanto os dois ponteiros andam; alinhar com um ponteiro já parado não é perfeita.
- **Movimento do shake:** horizontal, alternando esquerda/direita a cada ~2 quadros (30 Hz).
- **Implementação (2026-11-22):** IMPLEMENTADO no `BattlePlayable` (`counter_rhythm_bar.gd`, `playable_controller.gd`, `playable_hud.gd`, `BattleMath.resolve_counter`), coberto por `tests/verify_playable_counter.gd` e pelos testes GUT de `test_battle_math.gd`. A perfeita encerra a troca na hora do aperto (o ponteiro do outro congela), por isso o flash e o shake saem no instante do aperto. **PENDENTE de confirmação:** quando a vítima tem menos SP que o valor do roubo, o código rouba só o que ela tem (nunca negativo).

## Prólogo — primeiro combate (D-050); ROTEIRO, NÃO IMPLEMENTADO
- Fonte: `docs/PROLOGUE_SCRIPT.md` (texto do criador). Dois inimigos-sombra com nomes
  hebraicos na HUD:
  - **20 HP / 10 EN / 6 ATK / 3 MAK / 2 DEF / 8 MEF / 3 AGI** — Lunge (1 ACT, 4 EN: 5 de
    dano físico duas vezes em rápida sucessão de ritmo); Bleedbuff (2 ACT, 4 HP: +1
    estágio de ATK por 1 round).
  - **8 HP / 16 EN / 1 ATK / 8 MAK / 2 DEF / 2 MEF / 3 AGI** — Heat wave (2 ACT, 6 EN: 5
    de dano mágico IGNI em todos; 25% de burn, 3 de dano por round por 3 rounds);
    Energeat (1 ACT, 6 EN: recupera 5 HP + 1 por EN extra alocado).
- Resgate: diante de dano mortal ao protagonista, o humano entra (IA), cura tudo, corta
  o SP atual do protagonista pela metade e o combate reinicia. **D-051:** o humano é
  **Yoch** (0 PP no início da batalha) e reiniciar significa Fallen completamente
  recuperado, com HP cheio, e o SP atual continua **cortado pela metade** (confirmado
  pelo criador em 2026-11-23).
- Absorção tutorial: todas as opções viram ABSORB (D-119: sem fraqueza para indicar);
  +2 MEF do primeiro inimigo, depois +2 MAK com mash; permanentes.
- **PENDENTES** (lista completa no roteiro): "dano o bastante" e detalhes do resgate.
  Estágios de ATK, dano mágico, IGNI, burn e EN extra foram definidos pelo criador em
  2026-11-23 e estão implementados (seção "Habilidades do primeiro combate" abaixo). O conflito com a D-029 foi
  resolvido pela D-051 (D-029 revogada).

## Itens e absorção
- Itens utilizáveis em batalha; itens de cura custam **+2 SP ao Fallen**.
- Absorção: restrita a **Fallen**; requer button mashing; **0 pressionamentos = falha,
  sem ganhos**. Um alvo absorvido é marcado e não pode render recompensas repetidas.
- **D-017 (2026-11-21): uma absorção bem-sucedida sempre elimina o alvo** (`current_hp =
  0`), que deixa de agir e pode encerrar o combate se for o último inimigo.
  **IMPLEMENTADO.**
- **D-051 (2026-11-22) — absorção por disputa de SP; IMPLEMENTADO (`BattleMath.absorb_press`,
  `absorb_gain_options`, `BattleController._perform_absorption`, commit `dd0813e`).** Substitui
  a regra antiga (1–3 pontos do maior atributo mais SP base/HP/EN) e **revoga a D-029**
  (4/8/12 apertos), que o criador nunca aprovou:
- **Ganho:** baseado nos atributos do inimigo que são **múltiplos de 8** (o maior). Até **+2 em um atributo** ou **+1 e +1 em dois atributos diferentes** múltiplos de 8. Nem todo inimigo tem 8 em tudo: precisa ter **pelo menos 1 ou 2** atributos múltiplos de 8.
- **Mash como disputa de SP:** o inimigo resiste com o **SP restante dele** contra o SP do jogador. O mash rende **até 20 SP no total, em 10 apertos**. A absorção se completa quando o jogador **esgota por completo o SP do inimigo**.
- **SP baixo dos inimigos do prólogo é aceitável:** o combate começa com Fallen tendo **40 SP** (o criador confirmou que "40PP" era SP) mesmo com base 80; **só no prólogo**.
- **Fórmula da disputa (criador, 2026-11-22):** cada aperto vale **2 SP fixos** do inimigo, que **vão para o Fallen** (até 20 SP em 10 apertos, dentro de **2 s**). ~~A cada aperto há um sorteio; o primeiro sucesso completa a absorção.~~ **Corrigido pela D-103, abaixo.**
- **Chance:** base = **SP do Fallen − SP do inimigo**, em pontos percentuais, medida **uma vez no início** (diferença negativa = **0%**), mais **+1% por SP** tirado pelo mash. Se o SP do inimigo chega a **0**, a absorção é **garantida**.
- **D-103 (criador, 2026-11-25) — resultado único; IMPLEMENTADO (`BattleMath.absorb_result`,
  `BattleController._run_absorb_mash` / `_resolve_absorb_mash`).** Os apertos **só contam**:
  nada é tirado, dado ou sorteado a cada tecla. O resultado é resolvido e aplicado **uma vez**,
  quando os **2 s** acabam ou **assim que o 10º aperto é contado**, o que vier primeiro; depois
  disso nenhum aperto conta. No resultado: SP tirado = 2 × apertos (no máximo o SP que o
  inimigo tem), transferido ao Fallen; chance = base + 1% por SP tirado; **um único sorteio**;
  SP do inimigo zerado = absorção garantida. Com 0 apertos não há sorteio (falha). As letras
  verdes da D-052 continuam saindo **a cada aperto** (resposta do criador), mas a barra de SP
  só muda no resultado. Cobertura: `tests/verify_absorb_result.gd`, `tests/test_battle_math.gd`,
  `tests/test_battle_combat.gd`.
- **Falha:** se o mash acaba sem sucesso, a absorção falha, o ato é gasto e o **SP perdido pelo inimigo não volta**.
- **Atributos elegíveis:** ATK, MAK, DEF, MEF e AGI (sem HP e EN) cujo valor é múltiplo de 8. Com **dois ou mais**, **o jogador escolhe** entre +2 em um ou +1/+1 em dois; com **um**, +2 nele; com **nenhum**, o ganho vem do **maior** desses atributos.
- **HP/EN:** a absorção continua dando **+HP e +EN** do mesmo valor do ganho de atributo (como no código anterior).
- **VFX (D-052, criador 2026-11-22):** a arte do inimigo se reparte em **letras hebraicas
  soltas**, espaçadas **8 px** e **20% maiores** que a versão de 12 px (protótipo
  `prototypes/absorb-fragments`, opção `letters`). O golpe aprovado (`--hit=ringburst`) tem
  12 raios brancos chapados abrindo em anel com clarão central. A quebra acontece no instante do
  impacto e vem com tremor de tela aleatório e decrescente, borda preta, 0,35 s e 6 px.
  No **mash**, dentro da batalha, cada aperto solta do oponente, sem desmantelá-lo, **letras
  verdes** (verde do SP) que vão até a **barra de SP** (protótipo `--mash`, aprovado em
  2026-11-23: 3 letras por aperto, voo de 0,6 s, chegada na divisa verde/vermelho).
  **PENDENTE:** cor, tempos, trajetória e destino das letras da quebra, e visual da falha.
  **IMPLEMENTADO no jogo (2026-11-23):** `scripts/battle/absorb_vfx.gd`, chamado pelos ganchos
  `_on_absorb_press` e `_on_absorb_break` de `BattleController._perform_absorption`. Por enquanto,
  as letras da quebra vão até o card do Fallen, como na captura aprovada, e a falha não tem
  efeito próprio. A animação antiga `ABSORB` do SMT saiu. O flash `ABSORBED` no Fallen continua, por decisão do criador em 2026-11-23. O texto
  "ABSORBED" também continua, mas agora **em verde** (o verde do SP), com o **ganho escolhido**
  na linha de baixo (ex.: "+2 ATK"), **onde ficava o inimigo absorvido**, e não mais sobre a
  linha do log (criador, 2026-11-23).
  O tremor desloca o canvas da viewport. Cobertura em `tests/verify_playable_fx.gd`.
- **D-028 (2026-11-21): os ganhos persistem entre batalhas.** Os deltas de
  atributos são salvos em `user://exodus_progress.json` com versão e validação
  contra corrupção, e reaplicados ao Fallen ao criar a próxima batalha.
  **IMPLEMENTADO.**
- **Morte do Fallen (criador, 2026-11-23); IMPLEMENTADO** (`scripts/battle/death_cutscene.gd`,
  `tests/verify_death.gd`, captura `tools/capture_death.gd`):
  - A batalha acaba **assim que o Fallen cai**, mesmo com o aliado de pé (DEFEAT; os PP do
    Yoch zeram, D-048).
  - Ele perde **metade de cada ganho de status** das absorções; com valor ímpar perde a
    metade menor (+3 fica +2). Contadores de absorção e habilidades aprendidas ficam.
    Todos os inimigos atuais são normais, então todo ganho guardado entra na conta.
  - Isso **substitui** a regra de 2026-11-21 (Restart após DEFEAT nos atributos base): a
    próxima batalha aplica os ganhos que sobraram.
  - Sem pontos salvos no jogo ainda, o "último ponto salvo" é a **tela de título**.
  - **Contador de mortes:** cada morte soma 1 no save; a tela de título mostra o total em
    **algarismos romanos**, na fonte do título, **44 px**, **#a8182a**, centrado entre o
    título e o menu (nada antes da primeira morte).
  - Cutscene, **14 s** (3/2/5/3/1; antes 22 s): (1) 3 s de letras hebraicas vermelhas **#a8182a** escritas em linhas
    da direita para a esquerda (opção C do prólogo) enquanto o fundo escurece até o preto;
    (2) 2 s de voo formando o anjo e a caixa de diálogo do prólogo (mesma figura, tamanho
    e posição), em vermelho; (3) 5 s de fala, digitada no ritmo do prólogo: "Levanta-te,
    [hebraico], que a ti não é dada a bênção da morte. Do que te fortaleceu, parte
    perderás, como punição.", com "Do que te fortaleceu, parte perderás" em **#81e6a8**;
    (4) 3 s das perdas em texto ("-1 ATK"), em #a8182a, saindo dos **quatro cantos** até o
    anjo; (5) 1 s com anjo e caixa se desfazendo em letras.
  - **Música (criador, 2026-11-23):** "Law" do SMT VX (`assets/audio/bgm/DDS2_law.ogg`)
    começa **0,8 s depois da morte** (criador, 2026-11-24; antes 1 s) (início da cutscene), no volume do arquivo (100%), com **fade de 1 s** até
    o silêncio no fim. No prólogo do anjo (`prototypes/hebrew-transition`) ela toca **sem
    parar**, recomeçando quando a faixa acaba; o loop de 15,5 s da animação não a reinicia.
  - **Provisório, para o julgamento do criador:** cada rótulo de perda voa 1,5 s, as
    saídas se distribuem nos 3 s, ordem dos cantos (sup. esq., sup. dir., inf. dir.,
    inf. esq.), tamanho 14 px em negrito e o ponto de chegada (centro da figura).
- **PENDENTE:** limite de HP; pontos salvos (a morte volta ao título até existirem) e
  diferença entre inimigos normais e chefes na perda da morte.
- Sem equipamentos neste protótipo. A única magia implementada é o **Heat wave** (seção
  abaixo); a Reza (D-048) é tratada na sessão própria.

## Habilidades do primeiro combate e contador de absorção (criador, 2026-11-23); IMPLEMENTADO
Número de decisão ainda não atribuído no `DECISIONS.md`.
- **Contador de absorção:** abaixo de "ABSORBED" e do ganho, o texto verde mostra quantas
  vezes aquele **tipo** de inimigo foi absorvido, no formato **"3/4"**. O contador é **salvo
  entre batalhas** (`absorbs` em `user://exodus_progress.json`).
- **Aprendizado:** a cada **4 absorções** do mesmo tipo, Deviron (o Fallen) aprende **uma
  habilidade daquele inimigo, sorteada** entre as que ele ainda não tem, **para sempre**.
  O contador volta a 0. Habilidades que ele já tem (inclusive vindas de outro inimigo) são
  ignoradas, e as que usam PP nunca são aprendidas. Na 4ª absorção aparece mais uma linha
  verde, **"NEW SKILL: <nome>"**. Quando já não resta nada a aprender daquele tipo, o
  contador mostra **"MAX"**. As habilidades valem **sempre**, inclusive no reinício após
  derrota (os ganhos de atributo, não).
- **Inimigos:** GENETIC FOE A/B **mantêm os atributos atuais** e recebem as habilidades
  do roteiro: **FOE A = Lunge + Bleedbuff**, **FOE B = Heat wave + Energeat**.
- **Menu:** o comando ATTACK passou a se chamar **FIGHT**. Com habilidades aprendidas,
  FIGHT abre um submenu com **ATTACK** (ataque normal) e as habilidades, só pelo nome. A
  linha do battle log explica a linha destacada (atos, custo, efeito) e, quando falta
  recurso, diz o motivo ("NO ACT", "NO EN" ou "NO HP"). As habilidades sem ACT, EN ou HP
  suficientes ficam **escurecidas** e recusam a confirmação. Sem habilidades, FIGHT vai
  direto ao alvo. Uma habilidade de 2 ACT ocupa dois atos do plano. O submenu também
  aparece na **reação** (habilidades podem ser usadas como reação).
- **Lunge** (1 ACT, 4 EN): **poder 5** na fórmula poder×ATK÷DEF, **dois golpes** numa
  **duas barras normais, uma por golpe, uma após a outra** (correção do criador em
  2026-11-23: "nunca foi uma só, sempre foram 2"; a redação anterior, uma barra com marcas
  a 35% e 65%, estava errada). Um aperto por barra. A defesa do jogador contra o Lunge
  inimigo também usa duas barras seguidas, uma por golpe. Visual (criador 2026-11-23): um
  único efeito do ataque normal tocado normal e espelhado ao mesmo tempo (um X); os dois
  números de dano saem um após o outro, sem repetir o efeito.
- **Efeitos de letras hebraicas das habilidades (aprovados pelo criador em 2026-11-23,
  `scripts/battle/skill_letters.gd`), no jogador e no inimigo:** Heat wave = onda de letras
  laranja atravessando a fileira e chamas de letras em cada alvo atingido; cada queimadura
  solta brasas; Bleedbuff = letras vermelhas escorrendo e puxadas de volta, anel vermelho;
  Energeat = letras ciano em espiral para dentro, anel. No herói o efeito fica dentro do
  cartão. Magia mostra só o número (cues `MAGIC`/`MAGIC_BLOCK`, sem a garra). Ataques físicos
  (ATTACK, Lunge) **não** têm letras. O golpe normal não pisca mais o fundo; o clarão de
  fundo ficou só no Ra'am e em cura/REST/buff (criador 2026-11-23).
- **Bleedbuff** (2 ACT, 4 HP): **+1 estágio de ATK = +25% de ATK**, por **1 round inteiro**
  (até o mesmo ponto do round seguinte). Usado de novo, **acumula**. Com **4 HP ou menos**,
  não pode ser usado.
- **Heat wave** (2 ACT, 6 EN): dano mágico **5×MAK÷MEF** (mesma fórmula da física) em todos
  os oponentes. O **IGNI vale ×1 para todos** (D-119: sem afinidades). O atacante
  faz **uma barra**, e cada alvo defende por conta própria. Cada acerto tem **25% de burn**:
  3 de dano **no início de cada round**, por 3 rounds. Burns **acumulam**.
- **Energeat** *(antes Energy Eat; D-117)* (1 ACT, 6 EN): cura **5 HP + 1 por EN extra**. O jogador escolhe o extra
  numa linha **"EXTRA EN < n >"** (esquerda/direita, Z confirma, X volta). A IA sorteia o
  extra entre 0 e o EN que sobrar.
- **IA:** em cada escolha do bloco de dois atos, o inimigo **sorteia com chance igual**
  entre ATTACK e cada habilidade que ele pode pagar.
- **Reações e contra-ataques:**
  - Lunge e Heat wave inimigos são anunciados e respondidos **como o ATTACK**: sem reação,
    acertam direto; com DEFEND, a barra de defesa aparece. O Heat wave é anunciado a cada
    herói.
  - O jogador pode contra-atacar essas habilidades. Se o inimigo vence ou empata a troca,
    o **Lunge sai inteiro** sobre quem contra-atacou e o **Heat wave atinge todos os
    heróis**. Se o herói vence, a habilidade é interrompida.
  - O inimigo pode contra-atacar (33%) o Lunge e o Heat wave do Fallen. No Heat wave, cada
    inimigo atingido rola, e **o primeiro que passa** contra-ataca.
- **Escolhas de apresentação minhas, ainda não julgadas pelo criador:**
  - a barra do Heat wave aparece sobre o primeiro inimigo vivo;
  - o segundo golpe do Lunge espera o número do primeiro sumir;
  - o Bleedbuff usa o flash de cura com o texto "ATK UP";
  - o burn mostra só o número "-3", sem animação;
  - o texto das explicações do submenu.
- Código: `scripts/core/skill_book.gd` e `PlayableController` (seção skills).
  Cobertura em `tests/verify_playable_skills.gd`, captura `captures/skills/skills.mp4`.

## Reza (Pray Points) — D-048; IMPLEMENTADO no BattlePlayable (2026-11-23)
- **Quem:** personagens **humanos** conjuram **magias de luz** rezando, em vez de usar EN.
  Yoch é humano. Fallen (demônio) não usa Reza; como Fallen obtém magias é **PENDENTE**
  (envolve absorção e elementos).
- **PRAY:** comando que gasta **1 ato** e dá **+1 PP**. Pode ser **Ação ou Reação**.
- **PP:** ocupa o lugar da EN no painel de Yoch, cor `#f5f58c`. Teto **8 PP**. PP não
  gastos **persistem entre batalhas** até serem gastos. Cada PP atual dá **+2 SP** a
  Yoch. REST de Yoch só guarda atos.
- **Aba PRAY:** lista as magias com **custo base ≤ PP atuais**. A magia escolhida é
  usada como **Ação ou Reação** e gasta 1 ato.
- **Custo:** custo base de **1 a 4 PP** por magia. **PP extra:** selecionar uma magia
  **já em fila** aloca +1 PP nela, **sem gastar ato**; não há teto de 4 por magia (o
  limite são os PP disponíveis). Alocações no **mesmo alvo** saem **de uma vez só**.
- **Log:** nomes hebraicos; descrição simples em inglês; texto do log em `#f5f58c`.

| Magia | Hebraico | PT / EN | Custo base | Efeito |
|---|---|---|---|---|
| **Refuah** | רְפוּאָה | Cura / Healing | 2 PP | Cura um alvo: **20 HP + 10 por PP extra**, valor **fixo**. |
| **Haganah** | הֲגָנָה | Proteção / Protection | 2 PP | Escudo anti-condição de status em **um aliado** (inclusive Yoch) por **1 round inteiro** (do momento da conjuração até o mesmo ponto do round seguinte); desfaz-se quando o personagem receberia uma condição. |
| **Ra'am** | רַעַם | Trovão / Thunder | 3 PP | **10 + 10 por PP extra** de dano em um alvo, como **base da fórmula mágica**. **Sem efeito contra anjos.** |
| **Tahorah** *(D-112)* | טָהֳרָה | Pureza / Purity | 2 PP / 1 ACT | Limpa queimaduras, sangramentos e condições negativas de **um aliado**. |
| **Magen** *(D-112)* | מָגֵן | Escudo / Shield | 2 PP / 2 ACT | **+1 estágio de DEF física** (+25%) para **todos os aliados** até o fim do próximo round. |
| **Gevurah** *(D-112)* | גְּבוּרָה | Força / Might | 1 PP / 1 ACT | Próximo ataque do aliado escolhido causa **+15% + 5% por PP extra** de dano. |
| **Mishpat** *(D-112)* | מִשְׁפָּט | Julgamento / Judgment | 2 PP / 2 ACT | Causa dano a **um inimigo** igual ao **dano que ele causou em sua última ação + 15**. |
| **Zohar** *(D-112)* | זֹהַר | Esplendor / Radiance | 3 PP / 1 ACT | Alarga a zona **POINT** da barra de ritmo de **um aliado** até o fim do próximo round (`×1,5`, contraponto ao Sanverim). |
| **Sanverim** *(D-107 / D-115)* | סַנְוֵרִים | Ofuscamento / Blinding Light | 2 PP / 1 ACT | Cegueira de luz em **um inimigo** até o fim do próximo round (zona **POINT** reduzida à metade). |
| **Nechamah** *(D-107 / D-115)* | נֶחָמָה | Consolo / Comfort | 1 PP / 1 ACT | Cura **5 HP** no início de cada um dos próximos **3 rounds** em **um aliado**; acúmulos somam. |
| **Cherev** *(D-107 / D-115)* | חֶרֶב | Espada / Sword | 3 PP / 1 ACT | Corte de luz em **todos os inimigos**, dano **10 + MAK − MEF** em cada alvo (id interno `cherav`). |

- **Canonicidade (D-115):** todas as **11 rezas** da tabela acima (o D-118 acrescentou mais 18 entradas; ver `docs/CANON_BOUNDARY.md` §1.2) pertencem ao **jogo canônico** (unificadas em `PrayerBook`, todas com VFX hebraico obrigatório pela D-113). As 3 iniciais do Yoch na campanha continuam `Refuah`, `Haganah` e `Ra'am`; como e quando as demais são aprendidas ou distribuídas na campanha é **PENDENTE**.
- **Expansão canônica confirmada em design (D-118 — 20/20 magias implementadas em 2026-11-27; ZAHAV e IA inimiga PENDENTES):** **8 novas rezas** (`Esh`, `Shalhevet`, `Lehavah`, `Nogah`, `Chaki`, `Lior`, `Meir`, `Shachar`), **6 magias de anjos** aprendíveis por Yoch em PP ao derrotar anjos (`Ur Esh`, `Seraf`, `Nitzotz`, `Esh Ochelet`, `Esh Sinai`, `Gever`), **6 skills de Gabriel** (`Angel Hug`, `God's Message`, `Hasneh Habo'er`, `Adin`→`Adina`→`Adinut`), regra **IMEDIATO** e sistema **ZAHAV** — especificação completa em `docs/ANGEL_PRAYERS_AND_ZAHAV.md`.
- **Banco de ideias futuras (D-116):** candidatos de vocabulário mágico hebraico para uso eventual (exploração/`Hineni`, elementais, suporte/oração, maldições, metafísicas e qualificadores) estão catalogados em `docs/MAGIC_VOCABULARY_BACKLOG.md` (referência futura; sem regras mecânicas fechadas).

- Exemplos com os números do criador: Refuah 3 PP = 30 HP; Ra'am 4 PP = base 20.
- **Efeito visual das rezas (D-113):** todas as rezas usam obrigatoriamente VFX compostos 100% por letras hebraicas em `scripts/battle/pray_fx.gd` (ver `docs/PRAYER_VFX_RULE.md`).
- **Reação inimiga:** inimigos podem reagir **apenas** ao **PRAY** e ao **Ra'am** (`reactable: true` em `PrayerBook`), **não** às demais rezas (`Refuah`, `Haganah`, `Tahorah`, `Magen`, `Gevurah`, `Mishpat`, `Zohar`, `Sanverim`, `Nechamah` e `Cherev` permanecem `reactable: false`). **Todos** os inimigos com atos de reação disponíveis
  podem reagir (exceção à D-045 para o PRAY, que não mira ninguém). Se o ataque de
  reação **acertar**, a reza é **interrompida**:
  - **PRAY interrompido:** o ato se perde e Yoch **não recebe o PP**.
  - **Ra'am interrompido:** o ato se perde, a magia não tem efeito e os PP alocados
    nela (custo base **e** todos os PP extras alocados na fila) **voltam ao Yoch**.
  - **Mecânica de interrupção:** todos os comandos seguintes da fila de Yoch também
    se perdem, com seus atos; PP alocados em magias desses comandos **voltam ao Yoch**.
  - MISS ou bloqueio **não** interrompem: o PRAY ou o Ra'am resolve normalmente.
  - **PRAY** não é ataque, então não há contra-ataque: o inimigo **ataca** em reação, e o
    Yoch se defende com a barra única de sempre; vale a regra acima.
  - **Ra'am** é magia: um contra-ataque a ele usa a **barra dupla da D-049** (resultado
    melhor interrompe e rouba SP; iguais, os dois resolvem). Se o Ra'am for interrompido,
    vale a devolução de PP acima.
  - O inimigo que interrompe ganha **+1 ato por comando perdido** na fila de Yoch, como
    na D-049 (teto 4, D-005).
- **Itens abençoados:** consumíveis que dão efeitos e PP quando usados no aliado (Yoch).
- **PENDENTES:** lista, efeitos e PP dos itens abençoados (não implementados); sistema de
  condições de status bloqueadas pelo Haganah; efeitos mecânicos de raça (classificação de lore dos anjos definida pela D-126, GDD §15).
  A fórmula do Ra'am foi definida pelo criador em 2026-11-23 (abaixo).
- **Implementação (D-048 / D-112 / D-113 / D-115):** IMPLEMENTADO no `BattlePlayable` (só nele; a cena antiga
  `Battle.tscn` não conta, por decisão do criador). Regras em `scripts/core/prayer_book.gd`,
  fluxo em `scripts/battle/prayer_flow.gd` (ganchos em `playable_controller.gd`), PP em
  `BattleUnit` (`prays`, `current_pp`, `change_pp`) e no save (`ProgressStore.load_pp/save_pp`),
  HUD em `playable_hud.gd` (PP no lugar da EN em `#f5f58c`, submenu `pray`, log em `#f5f58c`).
  Cobertura: `tests/verify_playable_prayer.gd`. Respostas do criador de 2026-11-23 aplicadas:
  - Aliado exibido como **Yoch** (só a inicial maiúscula); ficha igual, **sem EN** (SP base 29,
    +2 por PP).
  - **PRAY** logo após FIGHT no menu; abre um **submenu**: `PRAY +1 PP` e as magias liberadas.
  - **Alvo** das magias escolhido no plano. Mesma magia no **mesmo alvo** = +1 PP (sem ato);
    em **outro alvo** = nova conjuração. Com todos os atos comprometidos o plano continua aberto
    enquanto houver PP para +1 em magia já na fila; UNDO desfaz primeiro o último +1 PP.
  - PP saem **ao enfileirar**; um PRAY enfileirado antes **conta** para liberar a magia depois
    (a parte não coberta fica devida e é paga quando esse PRAY resolve); PP reservados saem do
    disponível.
  - **Ra'am:** dano = **10 + MAK + 10 por PP extra − MEF do alvo**, com barra de ritmo como o
    ATTACK (D-109: marco 50/80/100%, desvio só com defesa no centro, defesa na lateral = metade), crítico, rolagem de SP, variação, e o mesmo
    tratamento de ato do ATTACK (sem afinidade, D-119). Anjo: sem efeito (a observação histórica de ausência de anjos no protótipo não implica ausência de anjos na lore; D-126, GDD §15).
  - **IA:** cada inimigo com ato de reação ataca o PRAY com **33%**; o inimigo atingido pelo
    Ra'am contra-ataca com **33%** (barra dupla da D-049). Vários inimigos: **todos atacam**;
    qualquer contato (POINT ou **BEAM**) interrompe; só o **primeiro** que acertou ganha os atos
    dos comandos perdidos. Contra o PRAY o Yoch **nunca tem barra** de defesa.
  - **Reação:** o Yoch pode usar PRAY e magias mesmo sem ser o alvo (amplia a D-045); inimigos
    reagem também a PRAY/Ra'am usados como reação. Magia em reação não tem PP extra (não há fila).
  - **Haganah:** marca de 1 round (até o mesmo ponto do round seguinte, como os estágios de ATK);
    sem efeito prático até existir sistema de condições; reconjurar **renova**.
  - **Refuah** só em aliados. **Derrota zera os PP**; vitória os mantém no save.
  - REST do Yoch: só guarda atos (log sem EN).
  - **Visual das rezas (D-048, atualizado pela D-112/D-113 em `scripts/battle/pray_fx.gd`):**
    todos os efeitos de reza são 100% compostos por letras hebraicas (sem bordas ou primitivas
    geométricas; ver `docs/PRAYER_VFX_RULE.md`). Ao conjurar PRAY, letras hebraicas em `#f5f58c`
    sobem do pé do cartão; **Refuah** projeta dupla hélice ascendente com `רפואה`; **Haganah**
    ativa mostra a letra **ה** ao lado do nome e uma **barreira composta inteiramente por letras
    hebraicas** ao redor do cartão do protegido (a antiga borda geométrica pulsando foi removida
    na D-112/D-113).
  - **Efeito do Ra'am APROVADO pelo criador (2026-11-23) e IMPLEMENTADO** (`pray_fx.gd`
    `play_raam`): versão 2 de letras do protótipo `prototypes/pray-vfx` — carga de 0,7 s
    (cenário escurece, letras em espiral formam a palavra רעם no céu), quadro branco, raio duplo
    de letras grandes até o chão com galhos, inimigo piscando em branco, tremor de tela, anel e
    chuva de letras no chão e letras residuais subindo. O dano cai no instante do raio; a camada
    de efeitos mostra só o número (cues `RAAM`/`RAAM_BLOCK` em `battle_effects.gd`, sem a
    garra do ATTACK). Um Ra'am que erra (MISS/desvio) não toca o trovão. **PENDENTE (decisão do criador):** magia cujo alvo cai antes de resolver
    (hoje: sem efeito, ato gasto, PP voltam).

## Raças — D-048; DESIGN, NÃO IMPLEMENTADO
- Em **Maesto**: humanos, animais, monstros e demônios (lista anterior D-048, não exaustiva); Daema é outra raça, distinta da raça demônio (D-128). Na época de EXODUS, animais ainda não estão presentes (D-126, GDD §15). No jogo, também a
  "raça" mecânica **Mazik** (inimigos mais genéricos).
- Fallen (Deviron/Samael): Daema, primeiro devilman. Todos os anjos são Daemas na lore (D-126/D-128), sem mudança de classificação mecânica. Yoch: humano. Efeitos de raça além da Reza: **PENDENTE**.
- **Lore (D-128; GDD §15.4):** corpos dos Daemas desaparecem em energia, regeneram de 8 em 8 dias; só os devilmen podem obliterar sua existência por assimilação permanente. Rezas são aprendidas nos templos através dos anjos; todas magias de fogo são ensinadas por Gabriel. Isso não muda as regras de absorção, alvos, aprendizado ou reza existentes.

## IA
- Inimigos: aleatório ponderado entre ataque e habilidades.
- Inimigos "profissionais" e inteligentes, mas com variações mais fracas previstas em dados.
- **D-035 (2026-11-21): a IA usa a mesma largura de POINT do jogador.**
  Ataque e defesa da IA rolam uma posição uniforme na barra e resolvem por
  `BattleMath.rhythm_zone(posicao, largura)`. A diferença de AGI altera essa
  largura (D-034); rolagens extras continuam dependendo apenas de SP, pela
  regra documentada de +1 rolagem a cada 2 pontos de vantagem.
  **IMPLEMENTADO** em `BattleController._zone_roll()`, `_ai_roll()` e
  `_defender_reaction()`.

### D-037 (Rodada 13, 2B) — fronteira entre IA comum e especial; DESIGN, NÃO IMPLEMENTADO

- O comportamento comum da D-035 permanece **implementado e vigente**: posição sorteada uniformemente sobre a mesma largura POINT disponível ao jogador.
- **Somente perfis especiais** utilizarão o contrato de timing temporal triangular D-023/D-024 com escolha da melhor janela temporal D-031, preservando geometria POINT, rolagens extras por SP e D-022. A regra não implica que o caminho especial esteja implementado; distinção de perfis e parâmetros concretos continuam pendentes.

### D-039 (Rodada 14, 1A; 2A; 8A) — plano de implementação por fases e liberação; DESIGN, NÃO EXECUTADO

- **1A:** quatro fases futuras: **(1) base de avaliação temporal e testes; (2) perfis POINT múltiplos/IA especial; (3) pacote tipado de dano; (4) replay JSON, certificados por intervalo e integração mecânica**. Testar cada fase conforme o próprio escopo, sem adiar a verificação fundamental à fase 4.
- **2A:** antes de alterar código, exigir auditoria do **HEAD vigente**, `AGENTS.md`, implementação existente, dados de Moves, dependências/scripts, decisões ainda vigentes versus substituídas e testes atuais; produzir mapa de contratos e plano de alterações restrito aos arquivos comprovadamente pertinentes.
- **8A:** liberar cada fase somente com **parse executado, testes unitários e de integração pertinentes, diff auditado, conformidade com design vigente e evidência real**. A fase concluída não implica aprovação de balanceamento/visual. Preservar D-038 (REST sem ACT, +2 EN fixos e guarda de atos) como decisão independente e **fora das fases D-039**; a implementação dessa regra não foi autorizada. Nada foi implementado/testado nesta rodada documental.

### D-040 (Rodada 15, 8A) — critérios executáveis de liberação da Fase 1; DESIGN, NÃO EXECUTADO

- **8A:** exigir **parse, testes unitários e integração pertinente, diff auditado e evidências verificáveis** de aderência a D-034/D-035/D-039 antes de liberar a Fase 1.
- Matriz mínima: **POINT/BEAM/MISS** com fronteiras, largura AGI/SP, **t=0**, **t=1 s com timeout**, inputs posteriores; primeiro input único, `echo`, reentrância; confirmação de reação anterior à barra; pausa/ativação; linha temporal visual subordinada; resultados mecânicos equivalentes a **30/60/120 FPS** sob timestamps controlados; regressões do combate (incluindo D-022, D-034, D-035) e isolamento de fluxos RNG quando erro triangular for dispensado.
- **Não alegar** cobertura de replay/rastro completo antes da Fase 4. **PENDENTES:** harness, API de tempo, política de simultaneidade de callbacks e dados adicionais de replay para instantes de fronteira. Nenhuma execução/alteração de código nesta rodada.

### D-041 (Rodada 16, 5A) — testes por injeção de tempo e integração FPS; CRITÉRIO, NÃO EXECUTADO

- Exigir **avaliador temporal mecânico testável com tempos injetados** para fronteiras, t=0, t=1 s, timeout e primeiro input, **mais testes de integração reais de `RhythmBar`/`BattleController`** com eventos e FPS controlados **30/60/120**. Mesmos timestamps, parâmetros e seeds exigem mesmas classificações e estados mecânicos; não exigir reprodução visual pixel a pixel.
- Verificar a infraestrutura Godot/testes do repositório antes de escolher harness ou arquivos. Fase 1 segue portões D-039/D-040: parse real, testes unitários/integração pertinentes, diff e evidência verificável; Fase 2 de múltiplas zonas e IA especial depende de liberação adequada da Fase 1. **Nenhum teste, código ou recurso foi executado/alterado nesta rodada documental.**

## Regras globais de ataques e status — D-124 (criador, 2026-11-27; DESIGN CONFIRMADO, NÃO IMPLEMENTADO)
Especificação completa das 6 skills canônicas (+ 2 evoluções `ZAHAV`: `Mazz Bite`, `Fang Sting`/`Fang Spine`, `Vuln Pierce`, `Dark Breath`, `Umbral Gaze`, `Ignoma`/`Ignoma Esh`) em `docs/CANON_SKILLS_D124.md`.

- **`HIGH SPEED` attacks:** ataques com "alta velocidade" no texto usam ponteiro **20% mais rápido** do que o normal (mais difíceis de bloquear) e também são **mais rápidos do que o ponteiro do oponente no contra-ataque** (D-049).
- **`BLEED` (canônico):** condição de status que **reduz em 20% as curas recebidas** até o fim do próximo turno, podendo **acumular até 4 vezes** (até −80%).
- **Temporização de ação:** efeitos que duram por **X ações/atos** encerram-se após **X ações realizadas depois da efetuação do efeito**. Para efeitos de prisão/imobilização, funciona como um **`PASS` automático**: o alvo **não perde** ações/reações ainda não utilizadas, **porém perde os atos que estavam em fila**.

## Escopo fora deste protótipo
Equipamentos, magia/elementos (AQUA/IGNI/AERO/ROCK/MANA/LUZI), itens abençoados da
Reza (D-048), progressão narrativa e absorção de longo prazo.
