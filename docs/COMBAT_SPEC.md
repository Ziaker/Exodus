# Combat specification — Exodus (protótipo)

## Identidade
- Jogo: conceito original com conceitos visuais/gameplay de SMT 1 e 2.
- Protagonista: **Fallen** (nome real desconhecido), demônio caído.
- Inimigos do teste: 2 placeholders genéricos, sem dependência de nomes dos .rvdata.
- Aliado do teste: placeholder genérico.
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
- **Descanso**: abrir mão de **um** ato recupera **+20% do máximo de EN**.
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
- Contra poder básico 8 e ATK 8, DEF 8 produz dano-base 8 e **cinco acertos nominais** em HP 40. Diferença de SP resistente 88 contra atacante 80 causa `−1d8` antes dos demais modificadores; a meta 5–7 não está validada estatisticamente.

## Atos e reações
- Cada personagem possui **2 atos por rodada**; cada ato pode ser **Ação** ou **Reação**
  (2 ações, 2 reações ou 1 de cada).
- Ação = executada no próprio turno. Reação = qualquer ação fora do turno, declarada
  em resposta ao anúncio de uma ação inimiga (inclusive mirando outro aliado).
- Todos os comandos podem ser usados como Reação. Inimigos também possuem 2 atos e
  também podem declarar Reações.
- Atos não usados podem ser **armazenados até 4** para a próxima rodada
  (podem guardar todos de uma vez); inimigos também.
- **D-005 (2026-11-21): teto de 4 atos disponíveis no total por personagem**, somando
  atos novos da rodada, atos armazenados e bônus de SP/Press Turn. Vale igualmente
  para Fallen, aliados e inimigos. Substitui a interpretação de 4 armazenados
  **mais** 2 novos simultaneamente disponíveis. **IMPLEMENTADO:** o excedente é
  **adiado** ao estoque (`stored_acts`), limitado a 4, e pode reaparecer em rodada
  posterior. Atos novos e bônus entram primeiro; o que sobrar volta ao estoque.
- Ordem de turnos por `AGI`. Os atos são oferecidos em passagens intercaladas
  (`A, B, A, B`), e cada ato é consumido por uma ação ou reação.
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
- Acerto em fraqueza: **+1 ato** para quem acertou.
- Resistido / nulo / absorvido: **-1 ato** cada (independente do tipo).
- **Consequência de D-005:** o +1 por fraqueza também respeita o teto de 4 atos
  disponíveis; o excedente é adiado ao estoque. A penalidade de -1 não foi alterada
  e apenas reduz atos disponíveis.
- Afinidades consideradas: Weak, Normal, Resist, Null, Absorb.

## Dano (sem magia neste protótipo)
- Físico: `poder × ATK ÷ DEF`.
- **D-019 (Rodada 3, 3A):** a fórmula física acima é **preservada**;
  devem ser recalibrados os **valores de poder dos ataques/habilidades**.
  Novos valores específicos ainda não foram aprovados.
- Modificador de SP: rolar `1dN` onde `N = |SP_atuante - SP_alvo|`;
  soma se o atuante tem mais SP, subtrai se tem menos.
- **Implementação anterior da variação:** `±10% ± 2% por ponto de diferença de SP`
  (sinal conforme vantagem); ainda presente no código, mas **SUBSTITUÍDA
  como design** pela D-019.
- **D-019 (Rodada 3, 2C) — novo design, NÃO IMPLEMENTADO:** a
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
- Ganho de SP: **+1** por crítico, desvio perfeito, acerto em fraqueza e reação.
- **D-019 (Rodada 3, 4C):** manter essas fontes existentes e seus
  ganhos de **+1 SP**, sem introduzir limite extra por batalha nem
  ganhos decrescentes. O balanceamento da influência do SP deve
  ocorrer nas fórmulas; a mecânica de ganho continua igual.
- Crítico, Press Turn e ganhos de SP por fraqueza/crítico só são aplicados quando
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

### D-031 (Rodada 9, 3A) — ataque físico básico; DESIGN, NÃO IMPLEMENTADO

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

- **3B:** manter a rolagem SP `1d|ΔSP|` com sinal; ataques que **causam dano, fazem contato e possuem afinidade que permita dano** recebem **piso final de 1 dano**, mesmo se a diferença de SP anular o valor. Sem contato não há dano; afinidades **Null/Absorb** não recebem piso. Preservar D-015, fórmula crítica implementada D-021 e variação fixa ±10% aprovada D-019. **PENDENTE:** poder zero/Moves sem dano nominal, composição com efeitos futuros e estágio preciso em casos especiais. Código `BattleMath.physical_damage()` ainda permite zero.
- **6A:** 10.000 **casos controlados** com referência neutra contra cópia equivalente: **HP 32, ATK 8, DEF 8, poder básico 8, SP iguais, afinidade Normal, sem crítico/bloqueio, variação fixa ±10%**. Exigir **≥95% dos casos** com derrota em **3–5 ataques bem-sucedidos** (D-032). Diferença inicial de SP é zero e não produz `1dN`; não introduzir ganhos extras não definidos. **PENDENTES:** seeds, amostragem, resets e harness. Não houve execução de 10.000 casos; o motor ainda não implementa ±10% fixos para ΔSP diferente de zero.
- **8A:** testar **duelos** e **combates com múltiplos inimigos**, cobrindo teto e armazenamento de atos, reações e prioridade, fraquezas/Press Turn, dominância e ganhos SP, dano e duração dos perfis. Preservar D-024/D-025: propriedades, reprodutibilidade por seed, fronteiras, integração, equivalência mecânica em **30/60/120 FPS** com timestamps controlados. Matrizes, métricas, seeds e scripts de execução **PENDENTES**.

### D-036 (Rodada 12, 1D; 2A; 3D) — efeitos de dano e validação resistente; DESIGN, NÃO IMPLEMENTADO

- **1D:** cada **efeito que causa dano** declara explicitamente se participa do **piso mínimo 1** da D-033. Não presumir participação de todo Move, de todos os efeitos de status nem de todos os componentes de uma habilidade mista. Nome/tipo/valor-padrão do campo e definição de efeitos sem dano nominal ainda **PENDENTES**. O piso depende adicionalmente de contato e afinidade que permita dano.
- **2A:** para efeito participante, após **todos os modificadores e o arredondamento final**, se houve **contato** e a afinidade permite dano, aplicar **`max(dano_arredondado, 1)`**. Sem contato, ou com afinidade **Null/Absorb**, não aplicar piso e não criar dano artificial. Não alterar SP `1dN`, crítico D-021, variação ±10% D-019 e demais contratos. O código `BattleMath.physical_damage()` ainda usa `maxi(0, int(round(amount)))` e não possui metadados de participação por efeito.
- **3D:** separar a validação do **resistente de laboratório D-033** (HP 40, DEF 8, SP_base 88) em **duas baterias**: **SP igual** entre atacante de referência e alvo, para isolar HP/DEF; e **SP 80 do atacante contra SP 88 do alvo** para avaliar o impacto de `−1d8`. Manter ataque básico poder 8 e o objetivo resistente 5–7 acertos como referência, sem garantir que seja atingido. **PENDENTES:** valor de SP igual no primeiro cenário, controle do estado, quantidade de amostras, seeds, demais condições de ensaio e **taxa de aprovação de cada bateria**. O requisito de ≥95% em 10.000 casos da D-032/D-033 aplica-se ao **ensaio neutro**, não automaticamente a estas duas novas baterias. Não foram executados testes.

### D-037 (Rodada 13, 3C; 8C) — piso por pacote e validação resistente; DESIGN, NÃO IMPLEMENTADO

- **3C:** o piso final de 1 dano da D-033/D-036 incide **por pacote mecânico de dano identificado e associado aos efeitos de dano participantes**. Cada efeito conserva a declaração individual de participação no piso (D-036 1D), mas vários efeitos no **mesmo pacote** não produzem automaticamente vários pisos. Aplicar uma vez ao resultado final do pacote após modificadores e arredondamento, somente com contato e afinidade que permita dano; não criar dano para efeitos de status, sem contato ou em **Null/Absorb**. Pacotes independentes e casos com mistura de efeitos participantes/não participantes carecem de contrato de agrupamento, identificação e resolução; sem inventar multiplicação por quantidade de efeitos.
- **8C:** para o **resistente de laboratório D-033** (HP 40, DEF 8, SP_base 88), a bateria com **SP igual** exige **≥95% de casos** concluídos em **5–7 acertos físicos bem-sucedidos**. A bateria com **SP 80 versus SP 88**, já aprovada na D-036, é **somente diagnóstica**, sem limiar estatístico aprovado. Quantidade de casos por bateria, valor igual de SP, demais controles/seeds e critério de contagem permanecem **PENDENTES**; não copiar automaticamente os **10.000 casos** do teste neutro D-032/D-033. A diferença de SP pode alongar o combate; nenhum teste foi executado.

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
- Zonas: **Ponto = 10% central**, **Trave = 20% ao redor**, resto = falha.
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

## Itens e absorção
- Itens utilizáveis em batalha; itens de cura custam **+2 SP ao Fallen**.
- Absorção: restrita a **Fallen**; requer button mashing; **0 pressionamentos = falha,
  sem ganhos**. Um alvo absorvido é marcado e não pode render recompensas repetidas.
- **D-017 (2026-11-21): uma absorção bem-sucedida sempre elimina o alvo** (`current_hp =
  0`), que deixa de agir e pode encerrar o combate se for o último inimigo.
  **IMPLEMENTADO.**
- Ganho: 1-3 pontos do maior atributo do inimigo (exceto EN/SP/HP), mais SP base, HP e EN extras.
- **D-029:** limiar de mashing mantido em **4 apertos = +1, 8 = +2, 12 = +3**;
  nenhuma dificuldade escalonada foi inventada.
- **D-028 (2026-11-21): os ganhos persistem entre batalhas.** Os deltas de
  atributos são salvos em `user://exodus_progress.json` com versão e validação
  contra corrupção, e reaplicados ao Fallen ao criar a próxima batalha.
  **IMPLEMENTADO.**
- **PENDENTE:** novas tentativas após falha e limite de HP. Não foram inventadas.
- Sem equipamentos e sem magia neste protótipo.

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

## Escopo fora deste protótipo
Equipamentos, magia/elementos (AQUA/IGNI/AERO/ROCK/MANA/LUZI), oração de humanos,
progressão narrativa e absorção de longo prazo.
