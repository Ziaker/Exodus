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
- Duração da janela: `1s - 0,05s por ponto de AGI/SP a favor do atuante`, mínimo `0,2s`.
- Ao atacar: Ponto → dano integral; Trave → oponente bloqueia; Falha → sem dano.
- Ao defender: Trave → bloqueia; Ponto → desvia e ganha +1 SP; Falha → dano integral.
- Bloqueio extra: **+1 rolagem de bloqueio a cada 2 pontos de SP de vantagem**.

### D-021 (Rodada 5) — zonas especiais calibradas; não implementadas

- **4B:** cobertura total POINT inicial **10%**;
  ajustar **±1 ponto percentual por 10 pontos de
  diferença de AGI** em favor da AGI superior
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

## Escopo fora deste protótipo
Equipamentos, magia/elementos (AQUA/IGNI/AERO/ROCK/MANA/LUZI), oração de humanos,
progressão narrativa e absorção de longo prazo.
