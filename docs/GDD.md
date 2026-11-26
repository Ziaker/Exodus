# EXODUS — Game Design Document

Documento vivo. Criado em 2026-11-21 a partir da auditoria documental e estrutural do
repositório `Ziaker/Exodus`.

## 0. Como ler este documento

### 0.1 Hierarquia de autoridade

1. Instruções explícitas e decisões do diretor criativo.
2. Documentação oficial vigente (`docs/GDD.md`, `docs/COMBAT_SPEC.md`).
3. Código e dados efetivamente implementados.
4. Histórico de decisões (Apêndice A).
5. Propostas em discussão.
6. Recomendações do editor.

Conflito entre fontes deve ser identificado e decidido pelo diretor antes de qualquer
alteração de regra. Uma regra implementada não é, por si, intenção final de design.

### 0.2 Estados da informação

| Estado | Significado |
|---|---|
| **CONFIRMADO** | Decisão explicitamente aprovada pelo diretor ou regra com autoridade documental estabelecida. |
| **PROPOSTO** | Ideia apresentada para avaliação; não aprovada. |
| **PENDENTE** | Questão que exige decisão. |
| **PROVISÓRIO** | Solução temporária aceita, sujeita a revisão. |
| **IMPLEMENTADO** | Comportamento presente no código. |
| **VALIDADO** | Comportamento submetido a verificação com evidência. |
| **SUBSTITUÍDO** | Regra anterior formalmente modificada. |

Estado de design e estado de implementação são independentes. "VALIDADO" aqui significa
verificação técnica (parse, teste, execução); **nunca** aprovação visual. A validação
visual pertence exclusivamente ao diretor criativo.

### 0.3 Relação com outros documentos

- `docs/COMBAT_SPEC.md` — fonte técnica autoritativa de combate. Fórmulas, limiares e
  valores não são duplicados neste GDD; são linkados.
- `assets/SOURCE_ASSETS.md` — proveniência dos assets temporários.
- Apêndice A deste arquivo — registro cronológico de decisões (substitui um arquivo
  separado por decisão do diretor).
- `AGENTS.md` (raiz) — **cópia canônica da regra principal** para todos os agentes que
  mexerem no projeto: auditar sempre, caçar erros e esquecimentos, corrigir até ficar
  entregável, deixar crítica extrema com dimensões mínimas e recomendações para o autor
  decidir, anexar evidência verificável, buscar `origin` antes de commit e nunca afirmar
  nada não verificado. A validação visual pertence exclusivamente ao diretor.
- `CLAUDE.md` (raiz) — ponteiro curto para `AGENTS.md`; não duplica a regra.
- `docs/DECISIONS.md` (raiz de `docs/`) — **índice canônico de IDs**; o texto
  completo permanece neste Apêndice A. Nova decisão reserva ID no índice.

### 0.4 Protocolo de continuidade das rodadas — **CONFIRMADO**

Quando uma resposta de game design, systems design, worldbuilding ou auditoria
editorial encerrar uma etapa com decisões ainda abertas, **apresentar imediatamente
a próxima rodada completa de perguntas na mesma resposta**. O diretor não deve
precisar pedir para "continuar" a cada rodada.

Cada pergunta deve oferecer alternativas concretas e diferenciadas, explicação
das consequências, recomendação justificada do editor e a alternativa explícita
**"Ideia própria"**, permitindo que o diretor escreva livremente sua solução,
combine opções ou altere suas premissas. Não induzir aprovação automática.

Priorizar questões que dependem de decisões ainda não tomadas. Consultar antes
o estado vigente dos documentos e do repositório; não repetir perguntas resolvidas
por decisões ou implementações posteriores. Perguntas da nova rodada são
**PROPOSTAS/PENDÊNCIAS**, não novas regras aprovadas. Registrar no GDD apenas
as respostas aprovadas pelo diretor.

Em entregas exclusivamente técnicas ou respostas sem decisões abertas pertinentes,
não inventar questionários artificiais. Essa exceção não permite encerrar uma
rodada de design pendente sem apresentar a continuação.

---

## 1. Visão geral

### 1.1 Premissa — **CONFIRMADO**

EXODUS é um RPG autoral de fantasia sombria com referências visuais e conceituais a
Shin Megami Tensei I e II. As referências não devem ser reproduzidas integralmente;
a identidade do projeto depende de seus próprios sistemas, narrativa, atmosfera e conflitos.

O protagonista, **Fallen**, é um demônio cujo nome verdadeiro ainda não foi revelado.
Ele cai do céu e afunda em um mar de areia branca, sob um céu vermelho-escuro, em um
mundo fantasioso e desolado. Sua existência é marcada por uma vontade insaciável de se
tornar superior. Fallen promete a **THÉOS** que absorverá todos os anjos e retornará ao céu.

A narrativa utiliza releituras fantasiosas, caóticas e autorais dos três reis magos,
de Herodes e de uma figura equivalente a Jesus. Definições definitivas dessas entidades
**não** foram aprovadas.

### 1.2 Identidade mecânica — **CONFIRMADO**

Turnos em bloco contínuo por combatente (D-044), ações e reações, reflexos,
atos armazenáveis e Superiority Points.
Atributos: HP, EN, ATK, MAK, DEF, MEF, AGI e SP. SP representa a superioridade dos
combatentes e influencia diferentes aspectos do desempenho. Fallen absorve adversários
e desenvolve atributos sem níveis tradicionais. Magia, oração humana, economia de EN,
custos de SP e armazenamento de atos fazem parte do sistema.

### 1.3 Pilares de design — **PROPOSTO**

Os itens abaixo são derivados das decisões confirmadas e ainda não foram ratificados
como pilares formais:

1. Superioridade é um recurso legível, disputado e persistente dentro da batalha.
2. Toda ação física é um duelo de reflexos, não apenas um cálculo de dano.
3. Sem níveis: o crescimento vem da absorção e da soma de atributos.
4. A narrativa e o combate tratam da mesma ambição: tornar-se superior.

---

## 2. Experiência pretendida e perfil de jogador — **PENDENTE**

Não há decisão aprovada sobre público-alvo, duração de sessão, dificuldade-alvo global,
tom de dificuldade fora do combate ou acessibilidade. O diretor descreveu o ideal de
que o jogo seja difícil e que inimigos básicos sejam "profissionais e inteligentes",
com variações mais fracas previstas em dados — isso está registrado como intenção, sem
valores numéricos oficiais.

---

## 3. Core gameplay loop — **PENDENTE**

O loop de combate existe (`start_round` → ações/reações → `end_round` → vitória/derrota;
ver `COMBAT_SPEC.md`). O loop completo de jogo — exploração, encontros, progressão,
narrativa — ainda não foi definido.

---

## 4. Sistema de combate

- Regras oficiais: `docs/COMBAT_SPEC.md`.
- Formato: turnos em **bloco contínuo por combatente** (D-044) com Ação e
  Reação; ordem **entre** combatentes por AGI; até 4 inimigos; protagonista
  + 1 aliado (**Yoch**, D-048) no protótipo. **CONFIRMADO**.
- Protótipo atual: cena `res://scenes/battle/Battle.tscn`, dois inimigos genéricos e
  o aliado Yoch com arte placeholder. **IMPLEMENTADO**; interface em inglês.
  **CONFIRMADO**. Desde 2026-11-23 o código usa o nome **Yoch** (D-048).
- Fundo plano `#333333` — **SUBSTITUÍDO** localmente por battleback e janelas inspiradas
  em RPG Maker VX Ace. Essa substituição ainda **não foi publicada**. A validação visual
  pertence ao diretor.

### 4.1 Divergências da auditoria — estado atual

| ID | Gravidade | Achado | Estado |
|---|---|---|---|
| A-01 | CRÍTICO | `next_actor()` oferecia cada unidade uma única vez por rodada. | **CORRIGIDO:** atos consumidos por ações e reações; ordem final em bloco contínuo por combatente conforme D-044; testes de estado. |
| A-02 | ALTO | Limiar literal `SP_atual > 0,7 × SP_rival` premiava ambos os lados. | **CORRIGIDO:** D-007 substitui por dominância em razão. |
| A-03 | MÉDIO | Reação do jogador não era utilizável para defesa; ataques inimigos exigiam entrada manual. | **CORRIGIDO:** entrada manual apenas para personagens do jogador; IA resolve seus próprios tempos; defesa manual exige reação declarada e 1 ato. |
| A-04 | MÉDIO | IA não tinha resolução própria de ritmo. | **IMPLEMENTADO como execução provisória:** mesmas zonas POINT/BEAM/MISS com tentativas extras por vantagem; sem nova regra de design. |
| A-05 | MÉDIO | Trave = 50% de dano, sem registro documental. | **HOMOLOGADO pela D-014 (2A):** bloqueio Trave reduz 50% do dano, comportamento já presente no código. |
| A-06 | MÉDIO | Descanso consumia 2 atos. | **CORRIGIDO:** D-038 implementada — REST não gasta ato, guarda os atos restantes e recupera 2 EN fixos; testes de regressão. |
| A-07 | BAIXO | "SP base extra" da absorção ambíguo. | **PENDENTE:** implementação recalcula SP pela soma dos atributos. |
| A-08 | BAIXO | Item de cura fixo, sem inventário. | **PENDENTE:** fora do escopo da correção. |
| A-09 | ALTO | Crítico e Press Turn concediam recompensas sem contato. | **CORRIGIDO:** recompensas e rolagens apenas em ataque com contato. |
| A-10 | ALTO | Absorção rendia com 0 pressionamentos e não impedia repetição. | **CORRIGIDO:** restrita a Fallen, falha sem entrada, alvo marcado; dificuldade exata permanece pendente. |
| A-11 | ALTO | D-005 (teto de 4 atos no total) não implementado. | **CORRIGIDO:** teto aplicado; excedente adiado ao estoque. |

---

### 4.2 D-033 (Rodada 11, 3B) — piso de dano em ataques com contato — **CONFIRMADO como design; NÃO IMPLEMENTADO**

**3B:** preservar o modificador de SP `1dN` (`N=|SP_atacante−SP_alvo|`) e sua contribuição com sinal conforme vantagem. Um **ataque que cause dano**, faça **contato** e tenha **afinidade que permita dano** deve causar **pelo menos 1 de dano final**, mesmo quando a desvantagem de SP zeraria ou tornaria negativo o total. Não alterar a amplitude do dado, não conceder contato quando houver MISS/desvio POINT e não aplicar esse piso a **Null/Absorb**. Preservar crítico D-021, variação fixa ±10% aprovada em D-019 (ainda não implementada) e demais contratos.

**PENDENTES:** interação com Moves sem dano nominal ou de poder zero e estágios de processamento dos efeitos futuros. O motor atual `BattleMath.physical_damage()` usa `maxi(0, int(round(amount)))` e pode produzir dano zero. **Código não alterado**.

### 4.3 D-036 (Rodada 12, 1D e 2A) — participação explícita e piso final de dano — **CONFIRMADO como design; NÃO IMPLEMENTADO**

- **1D:** **cada efeito de dano declara explicitamente** se participa do piso mínimo de dano da D-033 (3B). Essa participação **não é inferida** apenas por contato, afinidade, nome do Move ou presença de um efeito de status. Em Moves com múltiplos efeitos, a decisão pertence a cada efeito de dano, não ao Move inteiro. **PENDENTES:** nome/tipo do campo declarativo, valor-padrão, migração dos ataques existentes e comportamento de efeitos puramente de status ou com poder nominal zero; nenhum Resource ou ficha foi alterado.
- **2A:** quando o efeito declaradamente participa do piso e o ataque **faz contato** com **afinidade que permite dano**, aplicar o **mínimo final de 1 somente depois de todos os modificadores e do arredondamento final**. Sem contato, por MISS ou desvio POINT, não há piso; afinidades **Null/Absorb** não recebem dano artificial. O modificador SP `1dN`, a chance crítica D-021 e a variação percentual fixa ±10% da D-019 continuam sujeitos aos contratos existentes. Não criar dano para efeitos apenas de status.
- **Divergência técnica:** `BattleMath.physical_damage()` atualmente calcula `maxi(0, int(round(amount)))`, sem declaração por efeito e sem piso final. **D-036 não modifica esse código**.

### 4.4 D-037 (Rodada 13, 3C) — unidade do piso por pacote mecânico de dano — **CONFIRMADO como design; NÃO IMPLEMENTADO**

**3C:** aplicar o piso de 1 dano da D-033/D-036 **por pacote mecânico de dano**, não automaticamente por Move inteiro, impacto visual ou cada efeito isolado. Cada pacote precisa ser **identificado mecanicamente** e **associado aos efeitos de dano que o compõem**; cada efeito continua declarando explicitamente se participa do piso (**D-036, 1D**). Um pacote com efeitos participantes deve receber a regra de piso **uma vez**, depois de seus modificadores e do arredondamento final (**D-036, 2A**), quando houver **contato** e **afinidade que permita dano**. Não criar dano quando não houver contato, quando a afinidade for **Null/Absorb**, ou em efeitos puramente de status.

**Risco de múltiplos impactos:** quatro efeitos de dano dentro do **mesmo pacote** não significam automaticamente quatro aplicações do piso. Pacotes mecânicos realmente distintos podem ter resoluções distintas, conforme configuração a definir. **PENDENTES:** estrutura e identidade estável dos pacotes, associação/ordem dos efeitos, limites do agrupamento, distribuição de afinidades por pacote, comportamento de pacotes sem efeitos participantes e tratamento de entregas duplicadas em replays. Nenhuma ficha, Resource, script ou teste foi alterado.

### 4.5 D-039 (Rodada 14, 3A) — Resource mecânico tipado para pacotes de dano — **CONFIRMADO como design; NÃO IMPLEMENTADO**

**3A:** cada pacote mecânico de dano (D-037, 3C) deverá ser representado por **Resource mecânico tipado**, com **identificador estável**, referência/associação aos **efeitos participantes** e a **declaração individual de participação de cada efeito no piso mínimo de 1** da D-036. O piso continua incidindo **uma vez por pacote**, após todos os modificadores e arredondamento final, somente com contato e afinidade que permita dano; não inventar dano para Null/Absorb, status puro ou ataque sem contato.

**Pré-condição técnica:** inspecionar a estrutura existente dos dados de Moves antes de escolher classes, nomes de Resources, arquivos, migrações ou integrações. Esta aprovação **não implica** que um Resource tipado já exista nem autoriza criar um segundo pipeline paralelo incompatível com o motor. **PENDENTES:** esquema/tipos e valor-padrão da declaração por efeito, identidade de instâncias, associações entre impactos/pacotes, deduplicação de entrega e regras para pacotes mistos. Nenhum Resource/código foi criado nesta rodada.

## 5. Superiority Points — **CONFIRMADO**

`SP_base` = soma de HP, EN, ATK, MAK, DEF, MEF e AGI. SP ganho em batalha é temporário.
Fórmulas de dado, variação, crítico e limiar: `docs/COMBAT_SPEC.md`.

SP define superioridade, sorteio de dano extra, rolagens de bloqueio e vantagem geral.
**D-007:** ganha +1 ato quem tem `SP_próprio / (SP_próprio + SP_rival) > 0,7`.
Isso substitui a leitura literal de 70% do SP alheio e impede que ambos os lados
recebam o bônus na mesma rodada. **IMPLEMENTADO.**

### 5.1 Rodada 3 — efeitos do SP no dano e crítico (D-019) — **CONFIRMADO como design**

- **1A:** reduzir a influência de **cada ponto de vantagem de SP** sobre
  a chance crítica e instituir **teto final inferior a 100%**. A taxa por
  ponto e o teto percentual exato **não foram aprovados** e dependem de
  calibração. Essa direção **substitui parcialmente D-016**, que limitava
  o bônus total a +30 p.p., mas mantinha +10 p.p. por ponto de SP e
  admitia 100% de chance final. **O código ainda usa D-016**.
- **2C:** manter somente **±10% de variação percentual aleatória fixa**
  no dano, **independente da diferença de SP**. Preservar em separado
  a rolagem de superioridade `1dN` já definida na especificação. A
  amplitude variável anterior (`±10% + 2% × |ΔSP|`) fica
  **SUBSTITUÍDA como design**, mas permanece no código até futura
  implementação autorizada.
- **3A:** manter a fórmula de dano físico `poder × ATK ÷ DEF`
  e **recalibrar os poderes das habilidades/ataques**. Não há
  valores, tabelas, alvos de TTK ou escalas aprovados nesta rodada.
- **4C:** preservar os ganhos existentes de **+1 SP** pelas fontes
  já documentadas; controlar a sensibilidade por meio das fórmulas
  em vez de criar um teto extra ou ganhos decrescentes de SP.
- **5B:** para bônus de dominância em confrontos múltiplos,
  comparar com o **adversário vivo de maior SP** (por combatente).
  Essa regra **já corresponde** a `BattleState.strongest_opposite()`.
  A decisão não altera a barra contextual de SP da HUD, definida
  em §§17.1–17.2.
- **6A:** ataque inimigo que acerte automaticamente por
  **impossibilidade de reação do jogador** continua **elegível a
  crítico pela chance normal**. Não há crítico automático, bônus
  especial de crítico ou mudança de afinidades.

**Estado da implementação:** 3A, 4C e 5B preservam regras ou
direções existentes; 1A e 2C exigem alterações futuras de fórmulas;
6A é consequência aprovada da exceção de acerto da D-014, cuja
implementação ainda está pendente. Os valores numéricos de 1A e
3A devem ser aprovados em rodada posterior antes de mudar código.

---

### 5.2 D-021 — calibração crítica aprovada na Rodada 5 — **IMPLEMENTADA**

**1B; 2B; 3B:** para os novos críticos, a diferença de SP positiva concede
**+2 pontos percentuais por ponto**, com **bônus máximo de +20 p.p.** e
**chance crítica final limitada a 50%**. Desvantagem de SP não diminui a
base de AGI, mantendo esse aspecto anterior da D-016. O novo teto final
também restringe AGI elevada.

Expressão de design:
`chance_crit(%) = min(50, AGI + min(20, max(SP_atacante−SP_alvo,0) × 2))`.

Exemplos aritméticos, não resultados de testes: AGI 6 e ΔSP +5 → **16%**;
AGI 6 e ΔSP +10 → **26%**; AGI 40 e ΔSP +10 → **50%**.
O multiplicador ×1.5, a exigência de contato e os demais contratos
de crítico não foram alterados.

**Rastreabilidade:** D-021 quantifica a direção da D-019 e substituiu
os parâmetros da D-016. A fórmula acima está **implementada** em
`BattleMath.crit_chance()` e coberta por `test_battle_math.gd`.
A D-016 permanece no histórico como implementação anterior, sem ser
reclassificada como não executada. A variação de dano da D-019 em
±10% permanece pendente — não foi alterada aqui.

---

### 5.3 Rodada 10 — D-032 (2A), preservação da composição do SP — **CONFIRMADO como design**

**2A:** preservar **integralmente** a regra vigente
`SP_base = HP + EN + ATK + MAK + DEF + MEF + AGI`;
HP e EN contam com o **valor integral** na soma
dos sete atributos. Não reduzir seus pesos, não
excluir nenhum termo e não estabelecer teto de
SP por inferência. A D-007 (dominância por razão),
os ganhos de +1 SP, a fórmula crítica D-021
**já implementada** e a persistência de atributos
D-028 permanecem inalterados.

**Risco conhecido:** HP maior também aumenta o
SP base, podendo favorecer durabilidade, rolagem
de dano por diferença de SP, chance crítica,
cadência do ritmo e economia de atos. A resposta
2A preserva essa relação, mas **não comprova**
seu equilíbrio nas novas fichas. A fórmula de
duração é objeto da escolha separada 1C e não
altera o cálculo de SP base.

---

## 6. Atributos e recursos — **CONFIRMADO**

HP, EN (Energy Points), ATK, MAK (magic attack), DEF, MEF (magic defense), AGI e SP.
EN é usado para conjuração e se recupera automaticamente no fim da rodada: 20% do
máximo (regra distinta, não modificada aqui). **REST (D-038)** não consome ato:
recupera **2 EN fixos**, limitado ao máximo de EN, e guarda os atos ainda disponíveis
para a próxima rodada conforme D-005. Mapeamento dos `.rvdata`: `LUK → AGI`,
`MAT → MAK`, `MDF → MEF`. Detalhes em `docs/COMBAT_SPEC.md`.

---

### 6.1 Rodada 8 — D-025 (5E), escala inicial dos atributos — **CONFIRMADO como design; NÃO IMPLEMENTADO**

**Ideia própria do diretor, 5E:** todos os **personagens e inimigos** devem iniciar
com valores dos atributos básicos em **8 ou múltiplos de 8**. Para **Fallen**
no início do jogo, foram expressamente definidos:

| Atributo básico | Valor inicial de Fallen |
|---|---:|
| HP máximo | **32** |
| EN máximo | **8** |
| ATK | **8** |
| MAK | **8** |
| DEF | **8** |
| MEF | **8** |
| AGI | **8** |

**SP não é um atributo inicial independente:** pela regra anterior,
`SP_base = HP + EN + ATK + MAK + DEF + MEF + AGI`; portanto, para Fallen,
`SP_base = 32 + 8 + 8 + 8 + 8 + 8 + 8 = 80`.
O SP temporário de batalha continua seguindo os contratos anteriores.

**Não definidos nesta decisão:** fichas específicas de aliados/inimigos,
limite máximo dos atributos, progressão, regra exata de escolha dos múltiplos
para espécies diferentes, eventuais exceções futuras e valores de poder
das habilidades. Não inferir que todos os personagens tenham a mesma ficha
de Fallen ou que SP deva começar em 8. A escolha 5E responde à proposta
de ficha de referência da Rodada 8 com uma **regra global de atributos
iniciais**; ela não aprova uma ficha neutra de testes nem substitui
silenciosamente a intenção de referência separada da D-024 (7C).

**Divergência verificada com o código:** `UnitStats` tem valores
padrão 10/5, e `BattleController._create_units()` ainda inicializa
Fallen com HP 14, EN 8, ATK 7, MAK 3, DEF 5, MEF 3, AGI 6; aliados e
inimigos também usam valores fora da nova escala. **Design aprovado,
não implementado**. A mudança de escala exige recalibrar poderes
físicos conforme D-019/D-021, sem alterar a fórmula autorizada.

---

### 6.2 Rodada 9 — D-031 (1A e 2B), fichas por espécie e referência neutra — **CONFIRMADO como design; NÃO IMPLEMENTADO**

- **1A — identidade por espécie:** cada espécie de
  personagem ou inimigo possui **sua própria ficha
  inicial de atributos**, respeitando a D-025:
  **8 ou múltiplos de 8** nos atributos básicos
  iniciais. Não unificar todas as fichas na de
  Fallen. Valores específicos de aliados,
  inimigos e outras espécies continuam
  **PENDENTES**; não foram criados dados de
  espécies nem critérios de progressão.
- **2B — referência neutra independente:**
  para calibração, aprovar uma **ficha de
  laboratório separada de Fallen**, com
  os **mesmos valores iniciais**, porém
  **versionada separadamente**. Seus atributos
  são HP 32, EN 8, ATK 8, MAK 8, DEF 8,
  MEF 8 e AGI 8; seu `SP_base` derivado é
  **80**. Igualdade dos números não autoriza
  compartilhar o estado, o save ou a
  progressão de Fallen com a ficha neutra.
  Permanecem **PENDENTES** o esquema, versão
  inicial, local de armazenamento e a futura
  materialização da ficha de testes; esta
  publicação é **somente documental**.
- **Compatibilidade com D-028:** a persistência
  de ganhos por absorção **permanece**. Os
  múltiplos de 8 dizem respeito às
  **fichas-base iniciais**; estatísticas
  efetivas após progresso persistente
  podem deixar de ser múltiplos de 8.
  Não apagar, arredondar nem alterar os
  ganhos salvos para forçar essa regra.
  A ficha neutra não herda tais ganhos.
- **Implementação atual:** `UnitStats` e a
  criação de unidades em
  `BattleController._create_units()` ainda
  usam valores anteriores; o código e os
  recursos de unidades **não foram alterados**.

---

### 6.3 Rodada 10 — D-032 (3A), três fichas de laboratório — **CONFIRMADO como design; NÃO IMPLEMENTADO**

**3A:** estabelecer três **perfis de teste** para
avaliação da escala, **sem criar espécies
canônicas ou alterar combatentes do jogo**.
Fichas iniciais seguem a D-025/D-031, em
múltiplos de 8:

| Perfil de teste | HP | EN | ATK | MAK | DEF | MEF | AGI | SP_base derivado |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Ágil | 24 | 8 | 16 | 8 | 8 | 8 | 16 | **88** |
| Equilibrado | 32 | 8 | 8 | 8 | 8 | 8 | 8 | **80** |
| Resistente | 48 | 8 | 8 | 8 | 16 | 8 | 8 | **104** |

A referência neutra **independente e versionada**
da D-031 (HP 32, EN 8, demais atributos 8)
permanece; a coincidência com a linha equilibrada
não autoriza acoplar seus arquivos ou estados.
A D-028 preserva os ganhos de absorção; fichas
de laboratório não herdam progresso persistente
de Fallen.

**PENDENTES:** representação e versionamento das
três fichas, identidade e categoria de
habilidade dos inimigos reais, amostras de
teste e compatibilidade efetiva com as metas
de durabilidade da escolha 4A. Estes valores
são **referências de laboratório**, não novas
fichas de inimigos já publicadas no jogo.

---

### 6.4 D-033 (Rodada 11, 2C) — revisão somente da ficha resistente de laboratório — **CONFIRMADO como design; NÃO IMPLEMENTADO**

**2C:** substituir somente a ficha **resistente de laboratório** da D-032, alterando HP de **48 para 40** e DEF de **16 para 8**; EN/ATK/MAK/MEF/AGI permanecem **8**. Assim, `SP_base = 40+8+8+8+8+8+8 = 88`, em vez de 104.

| Ficha de laboratório revisada | HP | EN | ATK | MAK | DEF | MEF | AGI | SP_base |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Resistente — **D-033 vigente** | **40** | 8 | 8 | 8 | **8** | 8 | 8 | **88** |

**Rastreabilidade:** a D-032 (3A) continua documentando o perfil anterior (HP 48, DEF 16, SP 104), mas está **substituída para novos testes**. Perfis ágil/equilibrado, referência neutra separada, Fallen, espécies reais e progresso persistente da D-028 **não foram alterados**.

Com poder básico 8 e ATK/DEF 8, o dano-base nominal é 8 e **cinco acertos nominais** vencem 40 HP: agora atende nominalmente à meta resistente 5–7. Porém, atacante SP 80 contra resistente SP 88 sofre **−1d8** de dano antes dos demais modificadores. O piso de 1 (D-033 3B) **não garante** que a derrota ocorra em 5–7 acertos efetivos. **Balanceamento ainda não homologado**.

## 7. Ações, reações e armazenamento — **CONFIRMADO**

Dois atos por personagem por rodada: 2 ações, 2 reações ou 1 de cada. Reação é
qualquer ação fora do turno, declarada em resposta ao anúncio de uma ação inimiga,
inclusive mirando outro aliado. Todos os comandos (menos REST e PASS, D-105) podem ser Reação; inimigos também
reagem. Atos não usados podem ser armazenados até 4 para a próxima rodada.

**D-005:** teto de **4 atos disponíveis no total** por personagem, somando atos novos,
armazenados e bônus de SP/Press Turn; aplica-se a Fallen, aliados e inimigos.
**IMPLEMENTADO:** excedente é **adiado** ao estoque (máximo 4) e pode voltar em rodada
posterior. Substitui a soma de até 4 armazenados com 2 novos simultaneamente.

**REST — D-038 (CONFIRMADO e IMPLEMENTADO):** é o comando usado para
**guardar as ações restantes**. Ao escolhê-lo, o personagem **encerra sua
participação na rodada sem gastar nenhum ACT**, conserva os atos ainda disponíveis
no estoque para a próxima rodada (máximo de 4, respeitando D-005) e recupera
**exatamente 2 EN**, sem porcentagem e sem ultrapassar o EN máximo. REST não
realiza ataque, não consome um ato por si só e não concede uma nova ação imediata.
O encerramento da participação evita múltiplas recuperações de REST na mesma
rodada pelo mesmo personagem. O REST **substitui apenas** a regra anterior de
custo de 1 ato e recuperação de 20% pela escolha de descanso (histórico D-006);
**não altera** a regeneração automática no fim da rodada, as regras gerais
de armazenamento ou outros comandos. **Implementação no motor Godot:** o menu
não gasta ato; ATTACK e ITEM consomem um ato cada ao serem escolhidos (ABSORB custa
2 atos e resolve na hora, D-104),
enquanto REST consome zero, envia os atos restantes ao estoque e usa
`recover_en_flat()` para conceder 2 EN; coberto por `test_battle_combat.gd`.
O HTML jogável anterior pode permanecer com o comportamento antigo — fora
do escopo desta implementação. **D-105 (criador, 2026-11-25):** no turno o REST
continua exatamente assim, mas **deixou de ser reação**.

**PASS — D-105 (criador, 2026-11-25; IMPLEMENTADO):** passa a vez **sem gastar
ato** e sem ganhar EN, SP ou PP; o herói fica com os atos, volta a agir nas vezes
seguintes da mesma rodada e o que sobrar no fim da rodada vai ao estoque (D-005). Fica
logo antes do REST no menu do turno, pode fechar uma fila e não é reação. Se a vez
voltar a quem passou sem ninguém ter agido desde então, a rodada acaba. Detalhes em
`docs/COMBAT_SPEC.md`.

### 7.1 Reações — decisões da Rodada 2 (D-014) — **CONFIRMADO como design**

- **3A:** sem atos disponíveis, o personagem **não pode bloquear nem desviar**.
- **4A:** quando a reação for elegível, **pausar o combate durante a escolha**.
  O reflexo executado depois continua exigindo precisão temporal; o prazo
  fixo de 0,8 s observado no código não corresponde à escolha aprovada.
- **5C:** a prioridade entre uma ação anunciada e uma **reação ofensiva**
  é determinada por **AGI**. **PENDENTE:** regra para AGI igual, definição
  de interrupção/cancelamento da ação posterior e demais casos de simultaneidade.

Essas decisões não modificam custos de atos, nem autorizam alteração do código
nesta rodada. **Estado:** somente design; implementação incompleta.

Implementação parcial: ver A-01, A-03, A-04 e D-005.

---

### 7.2 D-025 (Rodada 8) — desempate e cancelamento de reação ofensiva — **CONFIRMADO como design; NÃO IMPLEMENTADO**

- **6C:** quando a ação anunciada e a reação ofensiva tiverem
  **AGI igual**, determinar a prioridade por **identificador
  estável do combatente**. A comparação exata dos IDs (qual
  ID precede), requisitos de unicidade e eventual igualdade
  de IDs permanecem **PENDENTES**; não decidir por ordem
  alfabética ou lado por suposição.
- **7A:** se a reação ofensiva resolver primeiro por AGI
  (ou pelo desempate acima), só **cancela** a ação anunciada
  quando **eliminar o executor da ação posterior** ou
  aplicar um **efeito de interrupção explicitamente definido**.
  Dano comum sem morte nem interrupção explícita não cancela.
  Esta decisão **não cria** novos efeitos de interrupção
  nem define seus tipos (**a D-049 substitui este cancelamento**, §7.5); continuam pendentes a semântica
  exata de efeitos existentes, o momento dos gastos/recompensas,
  a resolução de simultaneidade e testes de encadeamento.
- Preservar a D-014 (prioridade por AGI), D-015 (defesa
  POINT prevalece), D-022 (autoacerto sem reação declarada)
  e os tetos de atos. **Código atual não implementa
  essas prioridades ofensivas.**

---

### 7.3 Rodada 9 — D-031 (5A), desempate por ID — **CONFIRMADO como design; NÃO IMPLEMENTADO**

A D-025 (6C) determinou desempatar AGI
igual por identificador estável; a D-031
(5A) fixa **ordem lexicográfica crescente
dos IDs estáveis dos combatentes** para
resolver a prioridade entre ação anunciada
e reação ofensiva. Essa ordem não depende
do lado, de quem anunciou, da ordem
visual da HUD ou do valor de SP.
**PENDENTES:** padronização de maiúsculas,
caracteres e codificação dos IDs e
tratamento de identidades duplicadas
ou inválidas. Não inventar resolução
para colisões de IDs.
Preservar a D-014 (prioridade primária
por AGI), a D-025 (cancelamento só
por eliminação/interrupção expressa)
e a D-022 (autoacerto sem reação
declarada). Nenhum código foi alterado.

---

### 7.4 D-043 / D-046 - planejamento conjunto de ações e ritmo encadeado - **IMPLEMENTADO no motor Godot**

Decisão explícita do diretor para o HUD e o fluxo de combate (2026-11-21):

- O jogador **não precisa escolher e executar um único comando por vez**.
  Pode **montar antecipadamente uma sequência de comandos** que comprometa
  1, 2, 3 ou 4 atos disponíveis, observando o teto D-005. Escolher
  vários comandos antes da resolução não concede atos adicionais.
- Cada ACT correspondente a uma ação **planejada** fica **aceso/brilhando em
  verde**, em posição própria entre os quatro marcadores ACT do personagem,
  indicando claramente quantos atos da sequência foram comprometidos.
  Distinguir atos disponíveis, planejados e efetivamente gastos; não
  subtrair mecanicamente o ato apenas por editar uma prévia.
- Se a sequência incluir **múltiplos ATTACKs**, os timings ofensivos devem
  formar uma **cadeia de jogo de ritmo na mesma linha sobre o inimigo alvo**:
  um reflexo é resolvido e **só então** inicia o próximo marcador/timing.
  Cada ataque mantém avaliação mecânica própria e sua aplicação de efeitos;
  «simultaneamente» descreve o **planejamento combinado**, não acertos no
  mesmo instante. A barra nunca exige janela central sobre os personagens.
- Preservar as regras vigentes de custo por ato, uso de REACT como parte do
  mesmo estoque, REST D-038 (sem custo, +2 EN e armazenamento) e o limite de
  quatro; não inventar alterações em fórmulas de dano, SP ou Press Turn.

**D-044 (2026-11-21) resolve o conflito:** o diretor escolheu a execução
em **bloco contínuo** — os 2–4 ataques planejados resolvem antes de qualquer
outro combatente agir. `BattleState.next_actor()` agora devolve o mesmo
combatente enquanto ele tiver atos (`A, A, B, B`); a ordem entre combatentes
continua por AGI. **IMPLEMENTADO** com testes de estado. A fila visual com
ACT verdes e a linha de ritmo persistente foram implementadas no motor Godot
pela **D-046** (abaixo), preservando o HTML como protótipo externo.

**Protótipo HTML de teste:** `exodus_batalha_jogavel.html` (artefato
independente, fora do repositório) apresenta fila, ACT verde, desfazer,
botão de execução e sequência contínua de ataques; a execução em bloco
é uma **hipótese de demonstração**, não prova de comportamento homologado
no Godot. Outros pontos pendentes: consumo e destino de ações cuja seleção
se torna inválida antes da resolução, reações/cancelamentos dentro da
cadeia, variação de alvo entre ataques e regras de fila quando REST
aparece entre comandos. Nenhuma dessas hipóteses passa a valer no motor
sem decisão específica.

### 7.5 D-049 — contra-ataque com duas barras e interrupção — **IMPLEMENTADO no motor Godot**

Decisão do criador (2026-11-22):

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

## 8. Ritmo, bloqueio e desvio — **CONFIRMADO**

Aplica-se a todos os ataques físicos, de ambas as partes. Barra com marcador e janela
do oponente: ponto 10% central, trave 20% ao redor, resto falha. Tecla Z/Enter.
Duração `1s − 0,05s por ponto de vantagem de AGI/SP` (mínimo 0,2 s). Bloqueio extra:
+1 rolagem a cada 2 SP de vantagem. Ponto ao defender = desvio e +1 SP.

Implementado na cena; disputed details em A-04 e A-05.

### 8.1 Perfis de ritmo por inimigo — **CONFIRMADO como design; NÃO IMPLEMENTADO**

Decisões do diretor sobre perfis especiais de ritmo (respostas **1C; 2B; 3C; 4C**,
2026-11-21):

- **1C:** determinados inimigos podem variar a **posição** das regiões POINT, a
  **velocidade/cadência** do marcador ao longo da linha e o **número de regiões POINT**.
- **2B:** cada inimigo pode possuir **dois padrões distintos**, um associado aos
  ataques recebidos (ritmo ofensivo do jogador contra esse inimigo) e outro aos ataques
  que executa (ritmo de defesa/reação do jogador contra ele).
- **3C:** a **largura das regiões de acerto** deve variar de acordo com **SP e AGI**.
  Ainda não foram aprovadas fórmula, direção da influência, limites nem distribuição
  da largura entre múltiplas regiões POINT.
- **4C:** o padrão especial é **descoberto durante a execução**; não há prévia
  obrigatória que revele o padrão completo antes do reflexo começar.

Essas decisões alteram o **design mecânico pretendido**, não somente a aparência
da barra. **Conflito de especificação explicitado:** a regra vigente de POINT
central fixo (10%) e BEAM adjacente (20%), em `docs/COMBAT_SPEC.md`, e a função
`BattleMath.rhythm_zone()` representam o comportamento **implementado atualmente**,
mas não descrevem os novos perfis. Continuam válidos para o protótipo existente
até a definição formal da nova regra e implementação autorizada. Não se estabelecem
aqui números, curvas de aceleração, aleatoriedade, duração adicional ou alterações
na resolução de dano, crítico, bloqueio e Press Turn.

**PENDENTES de especificação mecânica:** formato dos perfis por inimigo, limites e
sobreposição das múltiplas zonas, função de SP/AGI sobre as larguras, precedência
entre a duração já calculada por SP/AGI e a cadência variável, comportamento da IA
com perfis especiais e testes de sincronização entre cursor visual e resultado real.

### 8.1.1 Rodada 4 — contrato dos perfis especiais (D-020) — **CONFIRMADO como design; NÃO IMPLEMENTADO**

Decisões do diretor em 2026-11-21 (**1B; 2A; 3B; 4A; 5A; 6B**),
que complementam a D-013 sem alterar seus padrões distintos de ataque/defesa:

1. **1B — AGI/SP e largura:** **AGI define a largura-base** da zona
   POINT, e **SP aplica ajustes por faixas de superioridade**.
   Fórmula, grandeza relativa utilizada, limites das faixas e efeitos
   exatos de cada uma permanecem **PENDENTES**. Não inferir automaticamente
   crescimento linear nem direção/sinal de todos os ajustes.
2. **2A — múltiplas zonas:** quando um perfil apresenta várias regiões
   POINT, elas **dividem um orçamento único de cobertura total**.
   Multiplicar o número de zonas não multiplica a cobertura conjunta.
   Divisão igual ou desigual, larguras mínimas e prevenção de
   sobreposição permanecem **PENDENTES**.
3. **3B — cobertura POINT:** a **soma** das regiões POINT ocupa
   **8% a 16% do percurso da linha** para os perfis dinâmicos.
   A zona central de 10% do protótipo cabe dentro desse intervalo,
   mas **não** substitui a obrigação futura de implementar perfis
   variáveis. Trata-se de extensão **espacial**, não garantia de
   8% a 16% da duração temporal total.
4. **4A — cadência/duração:** conservar a **duração total calculada**
   pelas regras já existentes e introduzir acelerações/desacelerações
   compensadas dentro dela, mantendo a travessia completa no mesmo
   tempo. Não definir arbitrariamente picos de velocidade,
   curvas de aceleração nem efeitos adicionais de AGI/SP.
5. **5A — execução da IA:** simular a execução **temporal** do
   marcador e aplicar erros de timing coerentes com a habilidade
   do inimigo, em vez de resolver o perfil especial apenas
   escolhendo POINT/BEAM/MISS sem relação com a linha.
   Distribuição, escala, limites e habilidade por perfil são
   **PENDENTES**. Preservar a exceção de acerto garantido da
   D-014 quando o jogador **não pode reagir**: essa regra tem
   precedência sobre um erro simulado da IA.
6. **6B — variação reproduzível:** o perfil pode variar por
   **seed de encontro**, preservando a identidade do inimigo
   e permitindo reprodução controlada dos padrões. Ficam
   **PENDENTES** derivação e armazenamento da seed, limites
   da variação entre ações do mesmo encontro e política
   para não tornar a dificuldade arbitrária.

**Risco crítico de calibragem:** com duração global mínima
de 0,2 s (protótipo), percorrer uma zona correspondente a
8% do trajeto sob velocidade constante equivale a apenas
16 ms de janela temporal. Uma aceleração local pode reduzir
ainda mais o tempo útil. A cobertura espacial de 8%–16%
**não homologa nenhuma janela mínima em milissegundos**,
nem autoriza ajustes ocultos. É necessária decisão e teste
específicos para justiça, taxa de quadros, latência de entrada,
legibilidade, integração ao HUD (D-012) e sincronização da
janela visual com a avaliação do timing.

**Conflito documentado com a implementação atual:** 
`BattleMath.rhythm_zone()` usa POINT central fixo de 10% e
`RhythmBar` percorre o eixo em velocidade uniforme; a IA
atual sorteia resultados discretos. Esses comportamentos
permanecem **IMPLEMENTADOS NO PROTÓTIPO, não conformes ao novo
design D-020**. Nenhum código, teste ou recurso visual foi
alterado nesta rodada.

---

### 8.1.2 D-021 — largura e tempo POINT — **PARCIALMENTE IMPLEMENTADA**

**D-034 substitui o ajuste de AGI abaixo:** a diferença de AGI agora vale
**+1 p.p. por ponto de vantagem** e a barra tem duração fixa de 1,0 s.
O ajuste de SP (5A) permanece e está implementado.

**4B (histórico):** largura-base da **cobertura total POINT = 10% da linha**;
antes, ±1 p.p. a cada 10 pontos de diferença de AGI.

**5A:** ajustar **±1 ponto percentual a cada 5 pontos de diferença
de SP**, no máximo **±2 p.p. por SP**, a favor do executante com maior SP.
Aplicar o intervalo total aprovado na D-020 de **8% a 16%** após
os ajustes, preservando o compartilhamento entre múltiplas zonas.
Exemplos para diferenças múltiplas: ΔAGI +10 e ΔSP +5 → 12%;
ΔAGI −20 e ΔSP −10 → 6% bruto, limitado a 8%.
**PENDENTES:** política de frações/restos de AGI/SP, leitura temporal
dos atributos e divisão entre zonas individuais; não definir
arredondamento por suposição.

**6B:** cada região POINT **individual** deve representar pelo
menos **40 ms de tempo real de passagem do marcador**, independentemente
da largura espacial. Perfil incompatível com essa condição e
com a duração global e a cobertura da D-020 é **inválido**.
Não elevar automaticamente a duração da barra, não exceder a
cobertura de 8%–16% e não reduzir os 40 ms.
**PENDENTES:** geração e rejeição de perfis inválidos, limites
de velocidade e critérios de avaliação com latência e FPS.

Risco concreto: uma região de 8% do percurso sob velocidade
uniforme em barra de 0,2 s oferece **16 ms**, violando o mínimo.
Duas zonas devem oferecer pelo menos **80 ms no total**,
sendo 40 ms para cada uma; velocidades compensadas podem
alterar o tempo local sem alterar o tempo global.
Não confundir porcentagem de espaço com porcentagem de tempo.

**Estado do código:** `BattleMath.rhythm_zone()` ainda usa
POINT central fixo e `RhythmBar` tem progressão uniforme;
a D-021 não foi implementada nesta entrega.

---

### 8.1.3 Rodada 6 — D-023: geração e avaliação temporal dos perfis — **CONFIRMADO como design; NÃO IMPLEMENTADO**

O diretor aprovou **1A; 2B; 3B; 4D; 5A; 6B; 7A; 8A**.
Estas decisões detalham D-013, D-020 e D-021, sem reabrir os
limites anteriores de cobertura, duração ou a direção visual da HUD.

1. **1A — interpolação contínua:** a cobertura total POINT
   parte de **10% do percurso** e recebe **0,1 ponto
   percentual por ponto de diferença de AGI**, mais
   **0,2 ponto percentual por ponto de diferença de SP**.
   O sinal da diferença favorece o combatente que executa
   o timing. A parcela SP permanece limitada a **±2 p.p.**
   e o resultado total a **8%–16%**. Não arredondar
   diferenças a faixas completas de 10 AGI ou 5 SP.
   Exemplo: ΔAGI +7 e ΔSP +3 → 10%+0,7%+0,6%
   = **11,3% de cobertura POINT**.
   Para o cálculo da largura, esta regra quantitativa
   da D-021/D-023 **especifica e prevalece** sobre a
   descrição anterior por faixas da D-020, sem
   remover o registro histórico.
2. **2B — quantidade máxima:** perfis especiais podem ter
   **até 3 regiões POINT**. Não exige exatamente três
   zonas em todos os casos.
3. **3B — distribuição por perfil:** as regiões POINT
   dividem o mesmo orçamento espacial total e a
   **divisão entre elas é declarada pelo perfil
   do inimigo**. Não pressupor divisões iguais;
   proporções específicas continuam dados pendentes
   para cada perfil. Cada região deve satisfazer
   seus **40 ms mínimos** da D-021.
4. **4D — geração válida por construção:** o domínio
   do gerador deve admitir **somente configurações
   comprovadamente válidas** quanto à cobertura,
   número de zonas, cadência, duração total e
   **tempo mínimo efetivo por zona**, sem sorteio
   irrestrito seguido de múltiplas tentativas de
   rejeição. O procedimento para configurações de
   autoria sem solução e as provas de viabilidade
   permanecem **PENDENTES**. Não introduzir
   fallback, extensão de duração ou relaxamento
   de limites não aprovados.
5. **5A — cadência:** acelerações e desacelerações
   organizadas em **segmentos de transição suave**
   com **velocidade contínua**, mantendo a
   duração total aprovada pela D-020 por
   normalização da travessia. Curvas específicas,
   limites de velocidade/aceleração e distribuição
   de segmentos continuam **PENDENTES**.
6. **6B — erro de IA:** simular instante temporal
   de atuação com **erro triangular limitado**,
   concentrado em torno do alvo, ajustado à
   habilidade do inimigo. Não estabelecer
   silenciosamente a amplitude nem a escala
   de habilidade. A exceção de autoacerto
   das **D-014/D-022** prevalece quando o
   jogador **não declara reação**, seja por
   impossibilidade ou por escolha voluntária.
   Essa exceção não concede crítico automático.
7. **7A — seed de padrão:** combinar a **seed do
   encontro**, **IDs estáveis do inimigo e do
   perfil** e o **índice da execução**.
   O algoritmo de combinação, a versão do
   perfil, o formato/registro dos IDs, a
   independência de sequências de RNG e
   os dados necessários ao replay continuam
   **PENDENTES**.
8. **8A — resultado pelo tempo de input:** julgar
   POINT/BEAM/MISS usando o **instante temporal
   registrado da entrada**, calculando a posição
   mecânica correspondente; o último frame
   apresentado não determina o resultado.
   O relógio, a precisão disponível na API
   de input, a política de bordas e eventuais
   tolerâncias requerem verificação/decisão.
   Nenhuma tolerância adicional é aprovada.

**Interdependência crítica:** três zonas POINT em
barra de 0,2 s necessitam de **pelo menos 120 ms
somados dentro das zonas**, embora juntas
ocupem somente 8%–16% do percurso. O gerador
válido por construção e as curvas suaves
precisam comprovar a viabilidade sob os
futuros limites de velocidade. O mínimo
de 40 ms por zona não pode ser desrespeitado.

**Divergência técnica verificada em leitura de código:**
`RhythmBar._process(delta)` desloca o marcador
por progressão uniforme, e `_unhandled_input()`
julga a posição visual mais recente;
`BattleMath.rhythm_zone()` usa zonas fixas,
e `BattleController._ai_roll()` usa sorteios
discretos. Os perfis D-023 **não estão
implementados**. O autoacerto D-022, já presente
no código remoto, deve ser preservado.

---

### 8.1.4 Rodada 7 — D-024: limites, IA, reprodução e validação — **CONFIRMADO como design; NÃO IMPLEMENTADO**

O diretor aprovou **1B; 2A; 3A; 4B; 5B; 6A; 7C; 8A**,
detalhando D-020, D-021 e D-023. As decisões preservam os
40 ms mínimos por região POINT, o orçamento espacial de
8%–16%, a duração total calculada por AGI/SP, a
geração válida por construção, os perfis distintos
de ataque/defesa e as exceções D-014/D-022.

1. **1B — pico de velocidade:** limitar a velocidade
   instantânea do marcador a **4 vezes a velocidade
   média da travessia completa** do perfil, medida
   para a duração total vigente. Manter velocidade
   contínua e transições suaves de D-023.
   **PENDENTES:** velocidade mínima, aceleração
   máxima, função/segmentação concreta e prova
   de viabilidade do gerador sob esses limites.
2. **2A — três regiões:** perfis especiais com
   **3 regiões POINT** só são elegíveis se a
   **duração total da barra for ≥300 ms**.
   Com 1 ou 2 regiões, permanece a duração
   global já calculada e seu mínimo vigente
   no protótipo (0,2 s), condicionada
   à validade temporal de cada região.
   Não estender automaticamente uma barra
   de menor duração para autorizar 3 regiões;
   configurações impossíveis são inválidas
   conforme D-021/D-023. **PENDENTE:** política
   operacional para perfis sem configuração válida.
3. **3A — habilidade da IA:** para o **erro
   temporal triangular limitado** de D-023,
   amplitudes iniciais **iniciante ±70 ms;
   comum ±40 ms; profissional ±20 ms**,
   concentradas no alvo temporal escolhido.
   **PENDENTES:** quais inimigos pertencem
   a cada categoria, modo da distribuição,
   especificação do gerador triangular e
   regras de eventual modificação por
   outros atributos. Quando não há reação
   declarada pelo jogador, prevalece
   o acerto automático das D-014/D-022:
   não permitir falha produzida pelo erro
   temporal nesses casos.
4. **4B — região pretendida pela IA:** quando
   houver várias zonas POINT, priorizar
   aquela de **maior duração temporal
   efetiva**, não necessariamente a mais
   larga espacialmente. **PENDENTES:**
   desempate e cálculo do alvo temporal
   dentro dessa região.
5. **5B — reprodução de padrões:** conservar
   a derivação por **seed do encontro,
   IDs estáveis do inimigo e do perfil
   e índice da execução** da D-023,
   e **registrar também cópia completa
   dos parâmetros resolvidos do perfil**
   para permitir análise/reprodução
   mesmo quando os dados originais mudarem.
   **PENDENTES:** formato, versionamento
   da configuração/motor, algoritmo de
   derivação e dados adicionais de estado
   exigidos para replay fiel.
6. **6A — relógio de input:** usar
   **relógio monotônico relativo ao início
   da barra** e **registrar o instante em
   que o evento de input for recebido**
   como base do julgamento temporal.
   Não usar a posição do último quadro.
   Não afirmar que o instante de recebimento
   corresponde ao momento físico da tecla.
   **PENDENTES:** API e precisão disponíveis,
   associação entre recebimento e início,
   tratamento de pausa/reinício, empates
   de fronteira e eventuais tolerâncias;
   nenhum bônus de latência foi aprovado.
7. **7C — ficha neutra de calibração:** criar
   uma **referência estatística neutra
   específica para testes**, a ser
   **homologada separadamente pelo diretor**.
   A decisão não aprova os valores de HP,
   ATK, DEF ou poder nem a estrutura de
   arquivo de uma ficha; não cria arquivo
   ou autoriza alterar dados do jogo.
   Manter a meta D-021 de 3–5 ataques
   físicos bem-sucedidos contra equivalente,
   **sem bloqueios nem críticos**.
8. **8A — critérios de validação:** exigir
   **testes de propriedades matemáticas,
   reprodução por seed, testes de fronteira,
   testes de integração e comparação entre
   diferentes FPS** antes de declarar o
   novo sistema conforme. Verificar os
   limites de velocidade e cobertura,
   duração total, tempo mínimo por zona,
   classificação pelo instante temporal,
   distribuição/erro da IA e conservação
   das regras de contato, crítico, SP e
   reações. **PENDENTES:** matriz de
   cenários, taxas de FPS, amostragem,
   metas/tolerâncias mensuráveis e comandos
   executáveis. Esta decisão é um
   **critério de aceitação**, não
   evidência de testes já executados.

**Viabilidade condicionada:** a restrição de 3 zonas
em ≥300 ms oferece pelo menos 120 ms somados
dentro das zonas (D-021) e até 180 ms restantes
para os outros trechos, mas isso **não prova**
que qualquer distribuição, curva ou limite
de velocidade produza perfil válido. Com
teto de 4× a velocidade média, a geração
válida por construção deve demonstrar
factibilidade considerando a continuidade
e os limites de aceleração ainda pendentes.

**Estado da implementação:** `RhythmBar`,
`BattleMath.rhythm_zone()` e
`BattleController._ai_roll()` ainda não
implementam perfis dinâmicos e avaliação
temporal. D-024 não altera código, testes
ou assets nesta rodada; a exceção D-022
implementada deve ser preservada.

---

### 8.1.5 Rodada 8 — D-025: validação, aceleração, fronteiras e tempo — **CONFIRMADO como design; NÃO IMPLEMENTADO**

Decisões aprovadas nesta área: **1B; 2B; 3A; 4A; 8A**.
As escolhas mantêm D-020/D-021/D-023/D-024: perfis
válidos por construção, 8%–16% de cobertura POINT,
ao menos 40 ms por região, duração global preservada,
máximo de três zonas e velocidade instantânea
até 4× a média.

1. **1B — configuração sem solução:** impedir a
   **validação/carregamento do encontro** com
   diagnóstico explícito quando um perfil de
   inimigo não admitir configurações válidas.
   Não resolver arbitrariamente com fallback,
   descarte de habilidade, duração extra ou
   violação do mínimo temporal. **PENDENTE:**
   como verificar essa condição quando atributos
   variáveis durante o combate alterarem
   duração, cobertura ou disponibilidade
   das regiões; a validação antecipada deve
   ser coerente com todos os estados elegíveis.
2. **2B — aceleração:** impor
   `|dv/dt| ≤ 12 × velocidade_média / T`,
   onde `T` é a duração global da barra
   e velocidade_média é a velocidade de
   travessia total dividida por `T`.
   O teto anterior de velocidade
   instantânea **4× a média** permanece;
   velocidade contínua e transições
   suaves também. A fórmula não escolhe
   a curva específica nem o limite
   mínimo de velocidade.
   Exemplo: quando `T=300 ms`, variar
   a velocidade em 1× a média demanda
   pelo menos **25 ms** sob aceleração
   máxima constante.
3. **3A — fronteiras:** exatamente na
   fronteira entre zonas de resultados
   diferentes, classificar com a
   **categoria mais favorável**:
   **POINT > BEAM > MISS**. Não acrescenta
   tolerância temporal nem alarga zonas.
   Mantém a precedência independente
   da D-015 para POINT ofensivo
   versus POINT defensivo.
4. **4A — início do relógio:** quando
   uma reação elegível exigir escolha,
   **pausar a decisão** (D-014) e
   iniciar **nova origem temporal ao
   começar a barra**, após a escolha.
   O tempo gasto no menu não integra
   a duração do reflexo. O relógio
   monotônico e o instante de
   recebimento do evento permanecem
   os aprovados em D-024. **PENDENTE:**
   ponto exato de ativação da barra
   e primeiro input elegível.
5. **8A — independência de FPS:** em
   cenários com **timestamps
   controlados equivalentes** e
   mesma seed/parâmetros resolvidos,
   exigir **classificação mecânica
   exatamente igual a 30, 60 e
   120 FPS**, inclusive nas
   fronteiras POINT/BEAM/MISS.
   Não reivindicar igualdade de
   frames visuais, latência física
   do teclado ou resultados de
   testes que não foram executados.
   Matrizes de entradas, geração
   de timestamps e integração
   Godot permanecem **PENDENTES**.

**Risco de incompatibilidade:** uma
configuração válida no carregamento
pode deixar de ser viável em execução
quando AGI/SP alterar a duração ou
a cobertura. A política correspondente
não foi aprovada e não pode ser
resolvida por prolongamento silencioso
da barra, violação de limites ou
cancelamento implícito de ações.
A implementação ainda usa zonas
fixas, `_process(delta)` e
posição visual para classificar input;
nenhuma mudança de código foi
autorizada nesta rodada.

---

### 8.1.6 Rodada 9 — D-031: variantes, input, IA e captura de atributos — **CONFIRMADO como design; NÃO IMPLEMENTADO**

- **4B — variantes alternativas explícitas:**
  um perfil de ritmo pode declarar
  **variantes alternativas próprias**,
  que devem ser **expressamente
  configuradas e previamente validadas**
  antes de serem elegíveis; selecionar a
  variante aplicável **antes da execução**.
  Isto trata incompatibilidades
  **dinâmicas** produzidas por mudanças
  de AGI/SP sem permitir fallback
  genérico, sorteios/rejeições normais
  ou extensão silenciosa de duração.
  **Preservar D-025 (1B):** encontro
  com configuração sem solução válida
  continua bloqueado no
  carregamento/validação. A política
  para estados alcançáveis sem nenhuma
  variante válida, critérios de seleção
  e a situação de perfil primário
  inválido mas alternativo válido
  **permanecem PENDENTES**, sem
  cancelamento implícito de ações.
- **6A — primeira entrada temporal:**
  descartar eventos de input cujo
  instante registrado anteceda o
  **início da barra**; aceitar
  **novos eventos desde o instante
  zero** da barra. A tecla usada
  para confirmar a reação pausada
  não pode ser reaproveitada como
  entrada anterior à ativação.
  Isto não cria tempo de espera,
  buffer retrospectivo, tolerância
  extra nem altera as regras de
  fronteira da D-025 (3A).
  **PENDENTES:** semântica de
  eventos simultâneos, key repeat,
  ativação do relógio e verificação
  da API de input no Godot.
- **7A — alvo temporal da IA:**
  após escolher a região POINT
  de **maior duração temporal
  efetiva** (D-024), a IA visa o
  **centro temporal dessa
  região**. Sua distribuição de
  erro continua **triangular
  limitada** (D-023/D-024:
  ±70, ±40 ou ±20 ms conforme
  habilidade), concentrada no
  alvo; não usar centro espacial
  quando a cadência for variável.
  Desempate entre regiões e
  classificação de habilidade
  de cada inimigo seguem
  **PENDENTES**. Sem reação
  declarada do jogador, prevalece
  o acerto automático D-022.
- **8B — congelamento por barra:**
  capturar **AGI e SP dos
  participantes quando a barra
  efetivamente começar** e
  manter **esses valores
  constantes durante aquela
  travessia**, para calcular
  duração, cobertura POINT,
  variante/cadência e avaliação
  mecânica do timing com o
  mesmo estado. Barras
  subsequentes podem obter
  nova captura. Registrar os
  valores efetivos junto ao
  snapshot do perfil (D-024).
  **Não** define, por si,
  quando estatísticas devem
  ser consultadas para o
  **cálculo de dano, crítico,
  recompensas ou outras fases**
  fora da barra; esses contratos
  devem ser preservados ou
  discutidos separadamente.
  **PENDENTES:** ordem de
  seleção/validação de variante
  e captura de atributos no
  início da barra, eventos
  simultâneos nesse marco
  temporal e integração com
  a pausa de reação D-014.

**Compatibilidade:** todos os
perfis conservam limites de
8%–16% de cobertura total,
40 ms mínimos por região,
até 3 regiões com duração
≥300 ms, velocidade máxima
4× a média, aceleração
máxima 12×v_média/T e
validação do input por
instante de recebimento.
As escolhas da D-031
não implementam perfis
dinâmicos no código atual.

---

### 8.1.7 Rodada 10 — D-032 (1C; 5A; 6A; 7A), duração e perfis reproduzíveis — **CONFIRMADO como design; NÃO IMPLEMENTADO**

1. **1C — recalibração da duração global:** substituir
   a taxa anterior de **50 ms por ponto** de vantagem
   combinada (`ΔAGI + ΔSP`) por **50 ms para cada
   8 pontos de vantagem combinada**.
   Manter o tempo-base de **1 s**, os limites
   de **0,2–1 s**, o sinal da vantagem e a
   referência atacante/defensor já adotada.
   Para diferenças múltiplas de 8, o
   contrato é inequívoco:
   `T = clamp(1 − 0,05 × ((ΔAGI + ΔSP)/8), 0,2, 1)`
   em segundos, interpretando o quociente
   exatamente nos casos múltiplos.
   Exemplo com ΔAGI=0, ΔSP=+24:
   **T = 0,85 s**, contra **0,2 s** da
   implementação anterior.
   **PENDENTE:** se valores combinados
   que **não** forem múltiplos de 8
   usam contribuição proporcional
   fracionária ou apenas grupos
   completos, inclusive sinais
   negativos; não homologar
   arredondamento por suposição.
   A decisão **substitui explicitamente**
   a taxa da função atual
   `BattleMath.rhythm_duration()`,
   mas **não foi implementada**.
   Preservar a D-020: o tempo calculado
   permanece constante durante a barra,
   mesmo com cadência variável.
2. **5A — cobertura total de variantes:**
   o validador de um encontro deve
   **comprovar antecipadamente** que
   existe **pelo menos uma variante
   expressamente declarada e válida**
   para **cada estado de atributos
   permitido e alcançável naquele
   encontro**, antes de disponibilizá-lo.
   Preservar D-023 (válido por construção),
   D-025 (bloquear carregamento de
   encontro impossível), D-031
   (alternativas explícitas), os
   limites de cadência e as
   condições de três zonas.
   **PENDENTES:** o conjunto exato de
   estados alcançáveis, limites/
   representação de modificadores
   de AGI/SP e método verificável
   de demonstração de cobertura.
   A absorção persistente da
   D-028 pode ampliar substancialmente
   esse espaço; não inventar
   um limite de progressão para
   facilitar a prova. Não autorizar
   fallback genérico ou descarte
   silencioso de ação.
3. **6A — escolha entre variantes
   elegíveis:** cada perfil declara
   uma **lista ordenada de prioridade**
   das variantes. Se mais de uma
   variante já validada for elegível,
   selecionar a **primeira nessa
   ordem** antes da execução.
   Não priorizar automaticamente
   maior número de regiões, sorteio
   por seed ou proximidade geométrica.
   Manter o snapshot dos
   parâmetros resolvidos D-024
   e a captura AGI/SP D-031;
   a ordem entre captura, avaliação
   de elegibilidade, escolha e
   início da barra exige contrato
   operacional próprio, ainda
   **PENDENTE**.
4. **7A — formato de replay:** registrar
   snapshots em **JSON versionado,
   independente da apresentação
   visual**, preservando como dados
   necessários os parâmetros
   resolvidos completos do perfil
   (D-024), identidade/seed/índice
   (D-023), AGI/SP capturados (D-031)
   e instantes relevantes de input
   e classificação mecânica.
   Não declarar esquema, nomes de
   campos, versão inicial, algoritmo
   de serialização, precisão dos
   números ou compatibilidade
   entre versões como aprovados;
   esses detalhes permanecem
   **PENDENTES**. Não foi criado
   arquivo JSON nesta rodada.

**Risco de integração:** a nova
taxa de duração melhora o
intervalo útil contra diferenças
de SP elevadas, mas estados
persistentes de D-028 ainda podem
saturar os limites de duração.
A cobertura formal exigida em
5A precisa considerar essa
realidade sem modificar
silenciosamente a progressão
nem enfraquecer as garantias
de temporização de D-021/D-025.
Nenhum script foi alterado.

---

### 8.1.8 D-033 (Rodada 11, 1A; 4B; 5A; 7A) — duração, validação e replay — **CONFIRMADO como design; NÃO IMPLEMENTADO**

- **1A — interpolação contínua:** completar a D-032 eliminando arredondamento de blocos de oito. Duração em segundos:
  `T=clamp(1−0,00625×(ΔAGI+ΔSP),0,2,1)`.
  **6,25 ms por ponto combinado**, com os sinais e participantes já definidos. Exemplo: vantagem +5 → **0,96875 s** (redução de 31,25 ms). Preservar limites 0,2–1 s, captura AGI/SP no começo e duração fixa na travessia. A implementação atual ainda utiliza 0,05 s por ponto; não alterada.
- **4B — cobertura por prova intervalar:** particionar **todos os estados de atributos alcançáveis** em intervalos e **demonstrar matematicamente** que, em cada intervalo, há pelo menos uma variante expressamente declarada e válida (D-032 5A). Avaliar pontos de corte e limites de duração, cobertura 8%–16%, ≥40 ms por zona, três zonas somente com ≥300 ms, velocidade ≤4× média, aceleração ≤12×média/T e alterações de SP/AGI. Não substituir prova por amostras estatísticas. **PENDENTES:** domínio formal alcançável (inclusive progresso D-028), método/certificado de prova e representação das curvas; não inventar teto de progressão para tornar a validação trivial.
- **5A — marco atômico:** após eventual escolha pausada de reação, **capturar AGI/SP**, **avaliar a elegibilidade**, **selecionar a primeira variante válida** pela prioridade declarada (D-032 6A) e **só então iniciar o relógio monotônico de input em t=0**, sem permitir mudança de estado entre esses passos. Os atributos capturados valem para toda a barra (D-031), respeitando o primeiro input desde t=0. **PENDENTES:** ordenação de eventos simultâneos e o tratamento de ausência de variante elegível; não inventar fallback.
- **7A — identidade dupla de replay:** snapshots **JSON versionados** (D-032 7A) devem registrar **versão do esquema JSON e versão explícita do resolvedor mecânico como identificadores separados**, além da seed, IDs, índice da execução, AGI/SP capturados, trajetória/parâmetros completos e eventos de timing. **PENDENTES:** valores iniciais, nomes/tipos dos campos, precisão, compatibilidade e disponibilidade de resolvedores antigos; registrar a versão não significa poder executar automaticamente motores históricos. Nenhum JSON criado nesta rodada.

**Compatibilidade:** D-013 a D-025 e D-031/D-032 preservadas; nenhuma modificação de código, cadência, avaliação temporal ou HUD.

### 8.1.9 D-036 (Rodada 12, 4A; 5A; 6A; 7A; 8A) — estados, ordenação, replay e rastros — **CONFIRMADO como design; NÃO IMPLEMENTADO**

- **4A — domínio alcançável:** a prova intervalar de cobertura das variantes (D-033 4B) deve usar **limites efetivos verificados do motor e todas as transições de atributos permitidas**, incluindo o progresso persistente D-028 e as alterações de AGI/SP durante combate, **sem introduzir tetos novos**. O `ProgressStore.MAX_GAIN` atualmente limita ganhos individuais serializados a 10000, mas isso **não autoriza inferir um teto global de atributos ou SP**; a definição exata do conjunto alcançável permanece **PENDENTE**. A prova deve cobrir todo o domínio permitido e não somente as fichas de teste.
- **5A — eventos simultâneos no marco de ativação:** **resolver primeiro os eventos mecânicos já comprometidos até o instante de ativação**, depois **capturar AGI/SP**, validar elegibilidade, escolher a variante prioritária e iniciar o relógio do input, respeitando a preparação atômica da D-033 (5A). **PENDENTES:** ordenação determinística entre eventos realmente simultâneos, identidade e precedência de eventos não comprometidos. Não escolher tal ordem por suposição.
- **6A — unidade de snapshots:** armazenar **tempos mecânicos em inteiros de microssegundos** nos snapshots JSON versionados, convertendo apenas nas interfaces necessárias. Isso estabelece unidade de representação, **não comprova precisão física de captura de teclas em microssegundos**. Precisão do relógio, arredondamento na conversão, limites numéricos e convenção de bordas permanecem **PENDENTES**.
- **7A — resolvedor ausente:** quando a **versão mecânica exigida pelo snapshot não estiver disponível**, **recusar a reprodução mecânica exata**, informar a incompatibilidade e **preservar integralmente o registro original**. Não reexecutar silenciosamente em versão mais nova, não migrar ou excluir registros por inferência. Leitura/inspeção não constitui reprodução mecânica comprovada.
- **8A — igualdade de rastro:** com mesma seed, configuração mecânica resolvida e inputs temporais controlados, exigir **igualdade exata dos rastros de eventos mecânicos**, **além dos resultados finais**, a **30, 60 e 120 FPS**. Comparar identidades, ordem, alterações de HP/SP/atos, reações, efeitos, cancelamentos, duração e marcos temporais pertinentes. A exigência **não é** igualdade visual quadro a quadro. **PENDENTES:** esquema canônico dos eventos, timestamp/ordenação, matriz de casos, determinismo de RNG e implementação dos testes; **nenhum teste foi executado**.

**Precedência documental e código atual:** a **D-034**, aprovada depois da D-033, determina **barra de 1 segundo com velocidade fixa e largura POINT dependente de AGI/SP**; **D-035** aplica a mesma largura à IA. Logo, a fórmula variável de duração da D-033 (1A) é **histórica e substituída**, não deve voltar a ser usada durante a implementação da D-036. A antiga cadência variável das D-020/D-023 não deve ser reintroduzida silenciosamente contra D-034. O motor ainda julga o input pela posição do último frame da barra e resolve timing de IA por amostragem, divergências das exigências temporais/reprodutíveis pendentes. A prova de variantes deve refletir a regra vigente da D-034 e os demais limites aprovados aplicáveis.

**Exemplo de viabilidade:** com travessia uniforme de **1 segundo** (D-034), cada zona POINT precisa ocupar ao menos **4% do percurso** para oferecer os **40 ms** individuais da D-021; três zonas exigem ao menos **12% de cobertura total**, dentro do intervalo global de 8%–16%. Esse é um **cálculo condicional**, não certificado de que os perfis atuais já estejam válidos.

### 8.1.10 D-037 (Rodada 13, 1A; 2B; 4A; 5A; 6B; 7A) — perfis, prova e rastreabilidade — **CONFIRMADO como design; NÃO IMPLEMENTADO**

- **1A — velocidade e duração:** **todos os perfis**, comuns ou especiais, seguem **travessia uniforme de 1,0 segundo** da **D-034**, já implementada. A variação entre perfis especiais decorre das **posições, larguras e quantidades de regiões POINT**, respeitando o orçamento total de cobertura e as condições de validade pertinentes. A D-037 **não restaura** acelerações/desacelerações das D-020/D-023, duração variável das D-032/D-033, nem cria exceção para chefes. As formulações antigas permanecem como histórico. Sob velocidade uniforme, **40 ms mínimos por região** da D-021 exigem largura individual **≥4%** do percurso; com três regiões, exige-se cobertura total **≥12%**, mesmo com orçamento permitido de 8%–16%. Não existe implementação de múltiplas regiões especiais no código atual.
- **2B — IA comum e IA especial:** preservar a **D-035 implementada** para o perfil comum: sorteio uniforme de posição na barra e classificação pela mesma largura POINT do jogador, com ajustes atuais de AGI/SP. Para **perfis especiais**, usar **execução temporal com erro triangular limitado** aprovado nas D-023/D-024, visando o **centro temporal** da região POINT de maior janela efetiva (D-031), sem alterar a **mesma geometria/largura POINT autorizada** para ambos os lados. Não transformar essa decisão em sorteio direto de POINT/BEAM/MISS nem substituir a IA comum sem autorização. Preservar as rolagens extras por SP e o acerto inimigo garantido da D-014/D-022 se o jogador **não declarar reação**. **PENDENTES:** classificação formal de perfis comuns/especiais, desempate de regiões, atribuição de habilidade de IA e implementação do caminho temporal. O código atual `BattleController._zone_roll()` e `_ai_roll()` usa posição uniforme; somente o comportamento comum está implementado.
- **4A — certificado intervalar:** o validador de cobertura de variantes aprovado na D-032/D-033/D-036 deve produzir **um certificado para cada intervalo** do domínio de estados alcançáveis, indicando os **limites do intervalo, condições verificadas e variantes que demonstram cobertura**. Na falha, apresentar **contraexemplo** (estado/condição que não tem variante válida), não somente mensagem genérica. Os certificados devem ser sustentados pelas fórmulas e limites **vigentes da D-034/D-035**, não por velocidade variável histórica. **PENDENTES:** formato do certificado, método da prova, estados alcançáveis e comportamento diante de condições indecidíveis; não considerar amostragem como prova universal.
- **5A — simultaneidade comprometida:** eventos mecânicos que compartilham timestamp recebem **número de sequência estável atribuído no momento em que cada evento é comprometido**. Essa sequência define a **ordem determinística** entre eles antes da captura atômica do estado para a barra (D-036, 5A), sem depender da ordem incidental de callbacks ou frames. **PENDENTES:** contrato de atribuição de sequência, escopo/unicidade, eventos derivados, precedência de eventos ainda não comprometidos e persistência dessa identidade para replay. Não substitui o desempate por AGI/ID da D-025/D-031 para disputas entre combatentes.
- **6B — quantização temporal:** converter instantes mecânicos dos snapshots JSON em **microssegundos inteiros pelo arredondamento ao microssegundo mais próximo**. Exemplo: **0,1234567 s → 123457 µs**. A alternativa escolhida **exige regra explícita de desempate** para valores exatamente a meio microssegundo, mas **não especifica qual** (para par, afastando de zero etc.); essa política continua **PENDENTE**, sem definição presumida. Preservar a D-036: a unidade serializada não implica precisão física de input em microssegundos, nem garante determinismo anterior à conversão.
- **7A — registro canônico de eventos:** o rastro mecânico deve incluir, no mínimo, **ID do evento, número de sequência, timestamp em µs, tipo de evento, participantes, alterações de estado, decisões mecânicas, configuração/versão aplicável e dados de RNG necessários à reprodução**. Eventos precisam distinguir fase/execução e evitar duplicação no consumo; nomes de campos, formato, identidade exata e volume de dados RNG permanecem **PENDENTES**. Preservar as versões separadas de esquema JSON e resolvedor (D-033), o snapshot completo e a igualdade exata dos rastros a 30/60/120 FPS com entradas/seeds controladas (D-036).

**Compatibilidade com a implementação atual:** `BattleMath.rhythm_duration()` já retorna 1 s e `point_half_width()` implementa o cálculo D-034; `RhythmBar` mantém movimento uniforme, mas ainda julga entrada pela posição do último quadro renderizado. A IA usa sorteio uniforme da D-035; o modo especial triangular, os certificados, os timestamps e a trilha canônica **não foram implementados** por esta decisão.

### 8.1.11 D-039 (Rodada 14, 4A; 5B; 6A) — sequência, microssegundos e autoacerto — **CONFIRMADO como design; NÃO IMPLEMENTADO**

- **4A — sequência por encontro:** manter **contador inteiro monotônico próprio de cada encontro**, começando no início do combate e associado a **ID estável do encontro**. Cada evento mecânico recebe seu número estável quando comprometido (D-037), para formar ordem total reproduzível **no mesmo encontro**. Um novo encontro pode reiniciar o contador porque a identidade do encontro o distingue. A numeração deve resultar das regras mecânicas, não da ordem incidental dos callbacks ou quadros. **PENDENTES:** valor inicial, identidade única do encontro e atribuição em compromissos simultâneos/derivados. Preservar o desempate por AGI/ID entre combatentes (D-025/D-031).
- **5B — empate exato em µs:** converter tempos dos snapshots e rastros JSON para **microssegundos inteiros**, arredondando ao inteiro mais próximo; quando o valor estiver **exatamente na metade**, arredondar para o **inteiro par** (*round half to even*). Exemplos: `123456,5 µs → 123456 µs` e `123457,5 µs → 123458 µs`. Essa regra deve ser implementada **explicitamente**; não assumir sem teste que o `round()` do motor se comporta assim. A quantização do registro **não altera por si só a autoridade do instante mecânico original** nem prova que o teclado mede microssegundos físicos.
- **6A — autoacerto prioritário:** se o jogador **não declarar reação**, executar a exceção D-014/D-022 com **precedência sobre o erro temporal triangular da IA especial**: tal erro não pode produzir MISS. Isso **não cria crítico automático** e não altera as demais rolagens de SP/efeitos por suposição. **PENDENTE:** contrato de consumo e isolamento de RNG para essa exceção, inclusive rastreabilidade da avaliação que foi dispensada.

**Compatibilidade vigente:** D-034 fixa todas as barras em **1 s de travessia uniforme**; D-035 implementa IA comum por posição uniforme; D-037 estabelece IA especial triangular apenas como design. D-039 não restaura cadência variável, nem reimplementa perfis especiais ou avaliação temporal de input.

### 8.1.12 D-040 (Rodada 15, 1A–7A) — contrato temporal de input e RNG — **DESIGN APROVADO, NÃO IMPLEMENTADO**

Rodada 15: **1A; 2A; 3A; 4A; 5A; 6A; 7A; 8A**. A escolha detalha a **Fase 1** de D-039; não autoriza código nesta rodada.

- **1A — registro imediato:** capturar, **na entrada do handler de input**, a leitura do **relógio monotônico** correspondente ao **recebimento** do evento, relativa à origem temporal da barra (D-024). Não julgar pela posição do último quadro, pelo próximo tick de física nem pelo momento físico estimado do dispositivo. **PENDENTES:** API, resolução e latência real do Godot, sem alegar precisão inexistente.
- **2A — ativação conjunta:** concluída a preparação atômica de D-033/D-036 (eventos comprometidos resolvidos, AGI/SP capturados e variante selecionada), **iniciar o relógio e aceitar entradas novas no mesmo marco, desde t=0**, sem aguardar novo frame/tick. O evento anterior usado para confirmar a reação não deve contar como input novo de ritmo (D-031).
- **3A — primeiro evento único:** **somente o primeiro pressionamento novo e elegível** decide o resultado; **fechar imediatamente** a barra para entradas posteriores, impedindo `echo`, repetições, eventos tardios e múltiplas resoluções de uma execução. Preservar identidade/deduplicação dos eventos D-037/D-039.
- **4A — deadline:** input cujo timestamp relativo satisfaça **t ≤ 1 segundo (1.000.000 µs)** tem precedência sobre o evento de **timeout** e é classificado normalmente. Input com **t > 1 s** não é elegível. Em t=1 s, a extremidade do percurso uniforme vigente é **MISS**; distinguir no rastro o MISS produzido por input e o timeout. **PENDENTE:** processamento/ordenação da fila quando callbacks de input e timeout chegarem fora da ordem mecânica, sem fazer a ordem de renderização decidir.
- **5A — linha temporal única:** uma **linha temporal mecânica autoritativa** calcula o progresso uniforme da barra fixa em **1 s** (D-034); a **renderização apenas consulta esse progresso para posicionar o marcador e não determina o resultado**. Não introduzir dois relógios independentes nem mexer na largura POINT por AGI/SP (D-034) ou IA comum (D-035).
- **6A — julgamento antes da gravação:** avaliar o input pelo **instante monotônico capturado com sua precisão efetiva**, somente depois convertendo para **microssegundos inteiros no registro JSON**, com arredondamento ao próximo e desempate para inteiro par da D-039. **Não modificar retroativamente o resultado** por quantização. **PENDÊNCIA CRÍTICA:** instantes distintos em lados diferentes de uma fronteira podem ser serializados no mesmo µs; armazenar µs por si só pode ser insuficiente para reproduzir o julgamento exato. Necessidade de evidência complementar deve ser decidida antes de garantir replay.
- **7A — RNG de autoacerto:** quando o jogador **não declara reação**, a D-014/D-022 prevalece e a **rolagem triangular de timing dispensada não é executada nem consome RNG**. Exigir **fluxos de RNG separados por finalidade**, de modo a não deslocar rolagens de dano/crítico; a chance crítica não se torna automática e outros sorteios conservam seus contratos. **PENDENTES:** derivação e identidade exatas dos fluxos a partir das seeds D-023, estado a serializar, ordem de sorteios e integração posterior com IA especial D-037. Não interpretar esta decisão como implementação imediata da IA especial na Fase 1.

**Divergência verificada no código:** `RhythmBar._unhandled_input()` ainda usa a posição de `_marker`, avançada por `_process(delta)`, para classificar o input. O novo modelo não está implementado. D-034/D-035 permanecem vigentes. **D-038 REST (sem ACT, +2 EN fixos e guarda dos atos) permanece separada e não implementada**, sem alteração nesta rodada.

### 8.1.13 D-041 (Rodada 16, 1A–4A; 6C; 7B; 8A) — relógio, concorrência, geometria especial e RNG — **DESIGN APROVADO; NÃO IMPLEMENTADO**

Decisões da Rodada 16: **1A; 2A; 3A; 4A; 5A; 6C; 7B; 8A**. Complementam a Fase 1 e definem contratos para a Fase 2 de D-039, mas **não autorizam alterações de código nesta rodada**.

- **1A — API de tempo:** usar **`Time.get_ticks_usec()`** do Godot para capturar a **origem temporal da barra** e o **instante de recebimento do evento na entrada do handler**; comparar diferenças relativas na mesma fonte monotônica. O método já retorna unidades de µs, mas **não comprova resolução física do teclado de 1 µs**. Validar seu comportamento na versão/configuração Godot do repositório antes de implementar. Preservar D-040 (tempo de recebimento, e não pixel do último frame).
- **2A — deadline e fila mecânica:** decidir entrada versus timeout **pelo instante mecânico do evento**, independentemente da ordem dos callbacks de renderização. Na igualdade **t = 1.000.000 µs**, **input novo elegível tem precedência** e só então se atribui o número de sequência mecânica estável (D-037/D-039), sem usar a sequência para inverter a prioridade já aprovada na D-040. Input posterior é inelegível. **PENDENTE:** protocolo concreto de coleta/drenagem de eventos que garanta essa precedência quando o callback de timeout rodar antes da entrega de um input fisicamente anterior; não inventar espera visual, tolerância ou buffer de latência.
- **3A — confirmação versus novo pressionamento:** aceitar **somente novas transições de pressionamento recebidas depois da ativação** da barra, ignorando o evento anterior de confirmação da reação e `echo`. Manter primeiro input elegível único (D-040), sem exigir que **todas** as teclas sejam liberadas antes da barra e sem obrigar teclas distintas. Um pressionamento **novo** de outra tecla válida pode ser recebido desde t=0. **PENDENTES:** estratégia concreta de identificação de transições/teclas mantidas e de deduplicação no Godot.
- **4A — evidência de fronteira e replay:** registrar, **além do timestamp inteiro em µs e do resultado**, o **instante capturado com a precisão de origem realmente disponível**, os **limites mecânicos resolvidos**, a **versão do resolvedor** e dados necessários ao julgamento. Preservar o resultado decidido **antes** da quantização (D-040); não alegar que o tempo já arredondado basta em todos os casos. Se a fonte for `get_ticks_usec()`, preservar o inteiro de origem, mas **não inventar frações submicrossegundo**. Referencial/representação, igualdade nas fronteiras, armazenamento de atributos e equivalência entre versões continuam sujeitos ao esquema JSON ainda **PENDENTE**.
- **6C — BEAM autoral nos perfis especiais:** um **perfil especial declara expressamente seus intervalos BEAM**, que devem ser **validados junto com as regiões POINT**. A faixa BEAM central **já implementada do perfil comum** permanece **inalterada**. Manter o resultado por prioridade de fronteiras **POINT > BEAM > MISS** da D-025 e a regra D-015 de defesa POINT contra ataque POINT. **PENDENTES:** orçamento/cobertura global de BEAM, interseções, distância mínima, ordenação de intervalos, critério de validação de sobreposição e eventual BEAM não contíguo a POINT; não presumir BEAM adjacente nem retirar BEAM dos especiais.
- **7B — divisão ponderada do orçamento POINT:** cada **perfil especial declara pesos relativos** para suas regiões POINT. O orçamento **total** é o calculado por AGI/SP segundo a **D-034 vigente**, no intervalo **8%–16%**, e é distribuído **proporcionalmente aos pesos declarados**, sem duplicar cobertura. Com barra uniforme de 1 s, **cada região deve ocupar ≥4% do percurso** para garantir os **40 ms** mínimos (D-021/D-037). Se a distribuição não respeitar a restrição, **aquela variante é inválida para esse estado**; não alterar pesos, diminuir o número de regiões, ampliar duração ou criar fallback silencioso. Usar somente **variantes explícitas, elegíveis, pré-validadas e com prioridade declarada** (D-031/D-032/D-033), exigindo cobertura de todos os estados alcançáveis (D-036/D-037). **PENDENTES:** domínio/validação de pesos (inclusive peso zero/negativo), precisão e arredondamento da distribuição, margem entre regiões e tratamentos de sobreposições.
  - Exemplo: cobertura total **12%** e pesos 1:1:1 → **4% por região**, válido quanto ao mínimo; cobertura **8%** nos mesmos pesos → aproximadamente **2,67% por região**, **inválido**. Com três regiões, cobertura conjunta precisa ser ≥12%; o perfil deve possuir variante viável para cada estado permitido, não suprimir uma região automaticamente.
- **8A — fluxos determinísticos por finalidade:** para cada fluxo de RNG derivar estado/seed de **seed do encontro, IDs estáveis dos participantes pertinentes, ID estável do perfil, índice da execução e identificador explícito de finalidade** (p.ex., timing especial, dano, crítico). Isso **especifica componentes de identidade**, não aprova um algoritmo de hash, serialização de tupla, nomes de streams, constantes numéricas ou estado interno. Preservar D-040: autoacerto sem reação D-022 **não executa nem consome** a rolagem triangular dispensada, e não desloca RNG de dano/crítico. **PENDENTES:** método/versionamento de derivação, sementes/estados persistidos, diferenciação entre várias rolagens da mesma finalidade e integração com o RNG uniforme da IA comum D-035. No código atual, `BattleController` usa **um RNG compartilhado `rng.randomize()`** para IA e dano, divergindo deste contrato ainda não implementado.

**Precedência:** D-034 (barra uniforme fixa de **1 s**) e D-035 (IA comum por posição uniforme com mesma largura POINT) continuam vigentes. A D-037 reserva timing triangular apenas para IA especial. Não restaurar cadência/duração variável das D-020/D-023/D-032/D-033, nem modificar os ganhos de absorção D-028 ou REST D-038.

### 8.1.14 D-042 (Rodada 17, 1A; 2A; 3A; 4A; 5A; 6A; 7D; 8A) — geometria dos perfis e IA especial — **DESIGN APROVADO; NÃO IMPLEMENTADO**

Aprovadas pelo diretor ao seguir as recomendações da Rodada 17, antes do retorno à série de perguntas. Esta decisão **não modifica código, configurações ou testes**; complementa a Fase 2 prevista na D-039 e preserva a D-034/D-035.

- **1A — orçamento especial POINT+BEAM:** em cada configuração válida de perfil especial, a **união de cobertura POINT e BEAM ocupa exatamente 30%** do percurso uniforme de 1 s, seguindo o orçamento combinado do perfil comum D-034. O orçamento POINT **dinâmico** da D-034 continua **8%–16%** conforme AGI/SP; o orçamento restante de BEAM é **30% − cobertura POINT**, portanto varia de **22% a 14%**. O BEAM central do perfil comum **não muda**. Os intervalos BEAM do especial seguem **declarados expressamente** (D-041), e sua compatibilidade com o orçamento deve ser validada para os estados alcançáveis. **PENDENTE:** representação e redimensionamento da distribuição BEAM entre múltiplos intervalos quando o total POINT variar; não inferir pesos BEAM nem normalização automática.
- **2A — interiores sem sobreposição:** **proibir interseção dos interiores de intervalos POINT e BEAM** em perfis especiais, inclusive entre regiões de mesma classificação. **Bordas coincidentes** são permitidas e continuam classificadas pela prioridade **POINT > BEAM > MISS** já aprovada na D-025; não considerar bordas isoladas como aumento de cobertura mensurável. Não permitir dupla contabilização de largura em BEAM/POINT. Configuração com sobreposição de interiores **é inválida**, sem corrigir automaticamente os intervalos.
- **3A — regiões POINT distintas:** exigir **separação estritamente positiva de espaço não-POINT** entre regiões POINT declaradas; **nenhum percentual mínimo adicional** foi homologado. Regiões apenas adjacentes não contam como regiões distintas. Mantêm-se máximo de três POINT e mínimo de **40 ms por região**, equivalentes a **4%** do percurso de 1 s; a legibilidade perceptual de separações muito pequenas continua **PENDENTE**.
- **4A — pesos POINT válidos:** todos os pesos por região (D-041 7B) devem ser **numéricos finitos e estritamente positivos**. Normalizar proporcionalmente pelo total de pesos e distribuir o **orçamento POINT efetivo da D-034**. Rejeitar a variante naquele estado se qualquer região ficar com **menos de 4%**, ou se posicionamento/intervalos violarem os contratos; sem peso zero como remoção, sem converter pesos negativos e sem redistribuição reparadora silenciosa. **PENDENTES:** precisão e regra de arredondamento das larguras, representação numérica e validação rigorosa nos limites.
- **5A — posição autoral estável:** cada região POINT declara **centro normalizado fixo no percurso**; sua largura aumenta/diminui **simetricamente em torno desse centro** conforme orçamento POINT e pesos relativos, **sem reposicionar automaticamente** regiões. Rejeitar a variante se alguma região sair de 0%–100%, colidir com outra região ou BEAM ou violar separação mínima. A geometria é resolvida a partir do snapshot de atributos no início da barra (D-031/D-033).
- **6A — ataque e defesa independentes:** os perfis especiais **ofensivo e defensivo são declarados e validados separadamente**, cada qual com seus intervalos POINT/BEAM, pesos, centros e variantes próprios, preservando a distinção da D-013 e a precedência defensiva da D-015. Isso não altera a geometria do perfil comum nem autoriza assumir que as duas fichas compartilhem uma declaração.
- **7D — desempate de janela temporal da IA:** para a IA **especial**, primeiro selecionar a região POINT com **maior duração temporal efetiva** (D-024/D-031); se duas ou mais empatarem, usar uma **prioridade estável entre regiões declarada no próprio perfil**. Mirar o centro temporal da região vencedora. **Não consumir RNG adicional** apenas para desempatar. A prioridade das regiões é **distinta da prioridade de seleção de variantes** aprovada em D-032; identidade, unicidade e validação dessa lista permanecem **PENDENTES**.
- **8A — erro triangular simétrico:** quando a IA especial efetivamente usar seu timing (D-037), sortear **dois valores uniformes independentes** no intervalo **[−L,+L]** e usar **sua média aritmética** como deslocamento temporal em relação ao centro escolhido. Isso produz erro triangular **simétrico e limitado a ±L**, com limites já aprovados de **70 ms / 40 ms / 20 ms** segundo a habilidade da IA (D-024), e **exatamente duas amostras por tentativa de ação elegível**, sem rejeição ou sorteios adicionais para corrigir erro. Utilizar o **fluxo de RNG de timing** separado conforme D-040/D-041. Se o jogador **não declarar reação**, preservar autoacerto D-022: **não executar nem consumir essas duas amostras** (D-039/D-040). **PENDENTES:** tratamento de tempo simulado <0 ou >1 s, classificação precisa de habilidade por inimigo, algoritmo de geração uniforme e versão/derivação dos streams.

**Critério de viabilidade:** o validador deve provar cobertura de **todos os estados alcançáveis** usando variantes declaradas, prioridade estável e certificados intervalares (D-032/D-033/D-036/D-037). Exemplos com POINT total **8%** e **três regiões** não satisfazem 4% por zona; com **12%** e pesos iguais, cabem três regiões de 4% desde que centros e BEAM produzam geometria válida e separações positivas. Combinado POINT+BEAM de 30% não substitui a prova de geometria nem convalida variantes inviáveis. Nenhum perfil especial ou IA triangular foi implementado por esta decisão.

### 8.2 Autoridade da barra e bloqueio — Rodada 2 (D-014) — **CONFIRMADO como design**

- **1E (ideia própria):** a **barra de ritmo determina acerto ou erro do
  ataque**, tanto do jogador como do inimigo. **Exceção explícita:** um
  ataque inimigo **sempre acerta quando o jogador não pode reagir**.
  **D-022 estende a exceção:** também acerta quando o jogador *pode*
  reagir e escolhe não declarar reação. A garantia se refere ao
  **acerto**, não a dano máximo, crítico obrigatório ou afinidade.
- **2A:** o **bloqueio na Trave reduz o dano em 50%**. A redução já
  estava implementada e agora está homologada como regra.
- **3A:** combatente sem atos não tem direito a bloqueio ou desvio.
- **4A:** escolher reação com o combate pausado, mas executar a barra
  com temporização e precisão normais.

**D-015:** POINT ofensivo contra POINT defensivo resolve a favor da
**defesa** — sem contato, 0 dano e nenhum crítico, Press Turn ou ganho de SP.
Implementado em `BattleMath.has_contact()`.

**PENDENTE:** decidir se o ataque inimigo acerta
automaticamente quando a reação **seria possível**, mas o jogador
**escolhe não reagir**. Essa situação é diferente de não poder reagir.

**D-019 (6A):** o acerto automático já aprovado quando **não é
possível reagir** admite uma rolagem **normal de crítico**; não
concede crítico obrigatório. O cálculo concreto deve respeitar a
fórmula crítica vigente até a calibração da nova regra D-019 (1A).

**Conflitos com o protótipo:** hoje a IA ainda pode falhar seu timing
mesmo contra personagem incapaz de reagir; a escolha de reação usa
temporizador fixo de 0,8 s; não há prioridade de reações ofensivas por AGI.
Essas regras exigem implementação posterior, não autorizada nesta rodada.
Não alteram nem substituem os perfis especiais de ritmo aprovados no §8.1
nem o posicionamento da linha aprovado no §17.2.

---

## 9. Magia, elementos, oração e afinidades — **PENDENTE** (Reza: **CONFIRMADO**, D-048)

O diretor confirmou que magia, oração humana, elementos e afinidades são partes
importantes do sistema, mas o protótipo atual os exclui explicitamente. Nomes de
elementos foram mencionados em conversa anterior e **não** devem ser tratados como
regras oficiais sem confirmação documental neste GDD. A oração humana (Reza) foi
definida pelo criador em D-048 (§9.1). **A forma como Fallen obtém magias será
discutida depois**; envolve a mecânica de absorção e a presença dos elementos do
jogo. **PENDENTE.**

### 9.1 D-048 — sistema de Reza (Pray Points) — **CONFIRMADO; IMPLEMENTADO no BattlePlayable (2026-11-23)**

Valores e regras técnicas em `docs/COMBAT_SPEC.md` §Reza.

- **Quem usa:** para conjurar **magias de luz**, os **personagens humanos** abrem
  mão de ações para rezar, em vez de usar EN. Yoch é humano.
- **Fluxo:** botão **PRAY** → ganha **1 Pray Point (PP)** por ato gasto → as magias
  com custo **≤ PP atuais** aparecem como habilidades na aba **PRAY** → o jogador
  escolhe uma magia como **Ação ou Reação** → executa. PRAY também pode ser usado
  como **Ação ou Reação**.
- **PP no lugar da EN:** Yoch **não tem EN**; o PP ocupa o lugar da EN, exibido
  na cor `#f5f58c` (amarelo claro quase branco). Teto de **8 PP**. Cada **PP atual
  vale +2 SP** para Yoch (8 PP = +16 SP). O REST de Yoch **só guarda atos**.
- **Persistência:** PP não gastos ficam armazenados e **persistem entre batalhas**
  até serem gastos.
- **Custo:** cada magia tem custo base de 1 a 4 PP. PP extras podem ser alocados
  selecionando uma magia **já em fila**; a alocação extra **não gasta ato** e não
  tem teto de 4 por magia (limite: os PP disponíveis). Várias alocações no mesmo
  alvo saem **de uma vez só**, não como conjurações múltiplas.
- **Magias iniciais (3):** os nomes usados são os hebraicos.

| Nome no jogo | Hebraico | PT / EN | Custo | Efeito |
|---|---|---|---|---|
| **Refuah** | רְפוּאָה | Cura / Healing | 2 PP | Cura um alvo em **20 HP + 10 por PP extra**, valor fixo. |
| **Haganah** | הֲגָנָה | Proteção / Protection | 2 PP | Escudo anti-condição de status em **um aliado** (inclusive Yoch) por **1 round inteiro** (da conjuração até o mesmo ponto do round seguinte); desfaz-se quando o personagem receberia uma condição de status. |
| **Ra'am** | רַעַם | Trovão / Thunder | 3 PP | **10 + 10 por PP extra** de dano em um alvo, como base da fórmula mágica. **Não tem efeito contra anjos.** |

- **Catálogo canônico ampliado (D-115):** além das 3 magias iniciais acima, todas as demais rezas criadas até o momento — **Sanverim**, **Nechamah**, **Cherev** (D-107) e **Tahorah**, **Magen**, **Gevurah**, **Mishpat**, **Zohar** (D-112) — fazem parte do **jogo canônico** (11 rezas no total em `PrayerBook`, tabela completa em `docs/COMBAT_SPEC.md` §Reza; todas sujeitas à regra de VFX hebraico D-113). Como e quando são obtidas/distribuídas na campanha: **PENDENTE**.

- **Log:** descrições simples em **inglês**, com texto do log também em `#f5f58c`.
- **Efeito visual das rezas (D-113):** todas as rezas usam obrigatoriamente VFX compostos
  100% por letras hebraicas em `scripts/battle/pray_fx.gd` (o antigo placeholder `Zio /
  Thunder1.png` do Ra'am foi substituído; detalhes em `docs/PRAYER_VFX_RULE.md`).
- **Reação inimiga:** inimigos podem reagir **apenas** ao **PRAY** e ao **Ra'am** (as
  demais rezas — `Refuah`, `Haganah`, D-107 e D-112 — permanecem sem reação inimiga); todos os inimigos com atos de reação podem reagir. Um ataque
  de reação que **acerta** interrompe a reza: no PRAY o ato se perde e não há PP; no
  Ra'am o ato se perde, não há efeito e os PP alocados (inclusive os extras) voltam ao Yoch. Na interrupção,
  **todos os comandos seguintes da fila de Yoch se perdem** com seus atos; PP alocados
  neles voltam ao Yoch. MISS ou bloqueio não interrompem. O PRAY não é ataque: o
  inimigo **ataca** em reação (não é contra-ataque). Um contra-ataque ao **Ra'am** usa a
  **barra dupla da D-049**. O inimigo que interrompe ganha **+1 ato por comando
  perdido** na fila de Yoch (teto 4, D-005). Respostas do criador em 2026-11-23.
- **Itens abençoados:** consumíveis que dão efeitos e PP quando usados no aliado (Yoch).
  Lista, efeitos e quantidades: **PENDENTE**.
- **Implementação e respostas do criador (2026-11-23):** detalhes técnicos em
  `docs/COMBAT_SPEC.md` §Reza ("Implementação"). Resumo: PRAY após FIGHT abre submenu; alvo
  escolhido no plano (mesmo alvo = +1 PP, outro alvo = nova conjuração); PP saem ao
  enfileirar; Ra'am = 10 + MAK + 10/PP extra − MEF com ritmo, crítico, SP e afinidade como o
  ATTACK; IA 33% contra PRAY e Ra'am; todos os inimigos atacam o PRAY, qualquer contato
  interrompe, o primeiro que acertou ganha os atos; Yoch sem barra contra ataque ao PRAY;
  Haganah como marca de 1 round (renova); Refuah só aliados; derrota zera os PP. Visual
  implementado (atualizado pela D-112/D-113 em `pray_fx.gd`, 100% letras hebraicas): PRAY faz
  letras subirem do cartão; Refuah sobe em dupla hélice com `רפואה`; Haganah exibe a letra **ה**
  ao lado do nome e uma barreira composta inteiramente por letras hebraicas (substituindo a antiga
  borda geométrica pulsando). Efeito do Ra'am: versão 2 de letras **aprovada e
  implementada** (raio de letras hebraicas com carga da palavra רעם, impacto e letras no chão).

---

## 10. Absorção e progressão sem níveis — **CONFIRMADO (conceito)**

Fallen absorve adversários. **D-051 (correção do criador, 2026-11-22; IMPLEMENTADO no
combate jogável, commit `dd0813e`):**
os ganhos vêm dos atributos do inimigo que são múltiplos de 8, até +2 em um atributo ou
+1/+1 em dois; o mash é uma disputa de SP (10 apertos, até 20 SP) e a absorção se
completa ao esgotar o SP do inimigo. **D-103 (criador, 2026-11-25; IMPLEMENTADO):** os
apertos só contam; nada é absorvido a cada tecla. O resultado (SP tirado e um único
sorteio) é aplicado uma vez, quando acaba o tempo de 2 s ou no 10º aperto, o que vier
primeiro; depois disso nenhum aperto conta. A regra anterior (1–3 pontos do maior atributo
mais SP base/HP/EN) e a D-029 estão revogadas. **D-017:** a absorção bem-sucedida
elimina o alvo. Detalhes em `docs/COMBAT_SPEC.md`.
**VFX da absorção (D-052, criador 2026-11-22):** a arte do inimigo se reparte em **letras
hebraicas soltas**, espaçadas **8 px**, **20% maiores** que a primeira versão de 12 px
(protótipo `prototypes/absorb-fragments`, opção `letters`, no layout do fundo D). Um golpe
branco em anel de raios chapados quebra o inimigo no instante do impacto, com tremor de tela
(`--hit=ringburst`, aprovado). No mash, cada aperto solta letras verdes do oponente intacto
até a barra de SP (`--mash`, aprovado). Ainda **PENDENTE:** cor, tempos, trajetória e
destino das letras da quebra, e visual da falha. **IMPLEMENTADO no jogo** em 2026-11-23
(`scripts/battle/absorb_vfx.gd`), substituindo a animação antiga do SMT.
Ambiguidade pendente em A-07.

---

## 11. IA inimiga — **PENDENTE**

Intenção confirmada: inimigos inteligentes e "profissionais", com variantes mais fracas
previstas em dados; escolha por aleatório ponderado no protótipo. Não há tabela de
pesos, perfis de comportamento ou critérios de dificuldade aprovados.
Implementado: apenas ataque físico com reações simuladas — ver A-04.
**D-035:** a IA rola uma posição na mesma barra do jogador, usando a largura
de POINT definida por AGI/SP (D-034). Rolagens extras continuam por SP.

---

## 12. Equipamentos, itens e economia — **PENDENTE**

Itens de cura em batalha custam +2 SP ao Fallen. **CONFIRMADO**. Equipamentos que
reduzem SP em troca de efeitos foram descritos pelo diretor, mas ficaram fora do
protótipo por decisão explícita. **CONFIRMADO como fora de escopo do protótipo**;
regras definitivas pendentes. Inventário, moeda e drop rules: **PENDENTE**.

---

## 13. Personagens, criaturas e facções — **PENDENTE**

Nomeados sem definição oficial: Fallen, THÉOS. Não há nomes, papéis ou hierarquias
aprovados para os três reis magos, Herodes, a figura equivalente a Jesus, anjos
ou demônios específicos. Nenhuma facção foi formalizada.

### 13.1 D-048 — raças e o aliado Yoch — **CONFIRMADO**

- **Yoch** é o nome do aliado jogável a partir de 2026-11-22 (antes "Ally"/"aliado
  placeholder"). Raça: **humano**. Usa o sistema de Reza (§9.1).
- **Fallen** é **demônio**.
- Em **Maesto** (nome do mundo/cenário) existem **4 raças**: humanos, animais,
  monstros e demônios.
- No jogo existe ainda a "raça" mecânica dos **Maziks**, os inimigos mais genéricos.
  A raça Mazik é uma categoria de mecânica.
- **PENDENTE:** efeitos mecânicos de cada raça (exceto a Reza dos humanos), a serem
  discutidos depois; também a classificação dos anjos, citados pela restrição do
  Ra'am, em relação às raças.

---

## 14. Narrativa, história, temas e estrutura dramática — **PENDENTE além da premissa**

A premissa do §1.1 está **CONFIRMADO**. A promessa de Fallen a THÉOS, a queda, o mar
de areia branca e o céu vermelho-escuro são fatos canônicos até nova decisão.
Ato, cena, arco, final, consequências das escolhas e a relação entre Fallen e as
figuras bíblicas reimaginadas permanecem sem decisão.

### 14.1 D-050 — roteiro do prólogo — **CONFIRMADO como roteiro; NÃO IMPLEMENTADO**

O criador entregou o roteiro de cenas da abertura (2026-11-22). O texto integral, sem
edição, a leitura estruturada e a lista de pendências estão em
`docs/PROLOGUE_SCRIPT.md`. Resumo: Play → cutscene → cutscene com diálogo → gameplay;
queda do demônio no mar de areia branca vista por um homem loiro; silhueta amarela de
letras hebraicas manda Fallen levantar-se como punição; pedido de ajuda no canto
superior direito; primeiro combate contra 2 criaturas-sombra com nomes hebraicos
(fichas e habilidades no roteiro); resgate pelo humano (nome censurado) controlado pela
IA, que cura Fallen e corta pela metade seu SP atual; absorção tutorial forçada (+2 MEF
sem mash, depois +2 MAK com mash, permanentes); o humano parte para sua mesquita a
oeste; o jogador escolhe oeste ou leste, com montanhas avermelhadas à frente.
**D-051:** o humano é Yoch (0 PP no início da batalha); reinício = Fallen com HP cheio
e **SP atual pela metade** (confirmado pelo criador em 2026-11-23);
absorção por disputa de SP (D-029 revogada). Conflito restante: fichas dos inimigos
versus o protótipo atual.

### 14.2 Temas centrais e simetria dos Maziks — **CONFIRMADO PELO DIRETOR (2026-11-25)**

A história de **EXODUS** aborda **simetria**, **perfeição** e **falsos Messias**. O diretor confirmou a presença de **um falso Jesus** e de **anjos caídos** na narrativa.

**Sentido da perfeição:** a perfeição consiste na **imperfeição** e na **não simetria** das coisas. Assim, a simetria não deve ser tratada como sinônimo da perfeição verdadeira.

**Maziks:** os Maziks são os **inimigos de silhueta** e possuem **simetria perfeita**. A perfeição simétrica dos Maziks deve ser distinguida do sentido de perfeição acima estabelecido. Essa definição descreve sua característica visual/temática; **não** determina origem, natureza espiritual, comportamento, hierarquia ou novas regras de combate.

**PENDENTE:** identidade, origem, função e relação do falso Jesus com outras figuras ou THÉOS; natureza, origem e relação dos anjos caídos com as raças existentes; explicação cosmológica da simetria dos Maziks; consequências narrativas ou mecânicas desses temas. Não converter interpretações editoriais anteriores (por exemplo, Maziks sem alma, produto de uma força criadora ou falso Messias necessariamente simétrico) em cânone sem aprovação explícita.

---

## 15. Cosmologia e teologia — **PENDENTE**

THÉOS existe como entidade citada na promessa de Fallen. Atributos, hierarquia
celestial, natureza dos anjos, relação entre céu, areia e superioridade: **PENDENTE**.
Nenhuma definição foi inventada neste GDD.

---

## 16. Regiões, ambientes e level design — **PENDENTE**

Imagens confirmadas: mar de areia branca, lugar desolado, céu vermelho-escuro.
**Cafarnaum e mapa-múndi (D-062).** A vista superior de Cafarnaum deve mostrar a saída
para o mapa-múndi por uma travessa lateral. Nas duas vistas, o filtro **Cartucho ocre +
Fita de horror** é obrigatório e a estética deve seguir a dos ambientes aprovados de
Cafarnaum. A transição jogável e sua integração com o Godot estão **PENDENTES**.

### Cratera de areia branca da abertura

O mesmo terreno serve às duas vistas. Na vista superior, a crista elevada
cerca a cratera quase circular. A parede interna íngreme desce até um fundo
amplo e baixo. A sombra da crista revela parte desse desnível. O quadro
inclui um trecho da Estrada Ocre reaproveitado de `Untitled.blend`, com rochas
da margem, uma árvore seca e parte do paredão. A primeira pessoa parte do local
onde Fallen desperta (cena 03 do prólogo), com as montanhas e as nuvens escuras
sob o céu vermelho acima da borda da cratera.

A revisão do relevo usou as vistas aéreas de Barringer e Wolf Creek e o perfil
de uma cratera de impacto simples como referências de forma.
[Barringer, USGS](https://www.usgs.gov/media/images/aerial-view-meteor-crater-color-coconino-county-arizona) ·
[Wolf Creek, LPI](https://www.lpi.usra.edu/publications/slidesets/craters/slide_12.html) ·
[Perfis de crateras, LPI](https://www.lpi.usra.edu/publications/slidesets/craters/slide_1.shtml)

Na animação aprovada, a areia desce pelas ladeiras, se junta no fundo, levanta
uma nuvem baixa e se assenta. As formas pixeladas acompanham superfícies 3D na
cena. As prévias usam o filtro **Cartucho ocre + Fita de horror**.
[Roteiro do prólogo](ROTEIRO_PROLOGO.md) ·
[Shader do filtro](../prototypes/dungeon-crawler/dungeon_mixed_filter.gdshader)

| Arquivo | Uso |
|---|---|
| [Abertura_Cratera.blend](../assets/generated/ambiente-e-interacoes/abertura/Abertura_Cratera.blend) | Modelo editável com as cinco câmeras e as prévias filtradas empacotadas. |
| [Abertura_Cratera_Areia.blend](../assets/generated/ambiente-e-interacoes/abertura/Abertura_Cratera_Areia.blend) | Animação editável em primeira pessoa, com formas pixeladas empacotadas e marcadores de descida, impacto e assentamento. |
| [cratera_vista_superior.png](../assets/generated/ambiente-e-interacoes/abertura/cratera_vista_superior.png) | Quadro 1. Vista vertical com a borda completa e a Estrada Ocre. |
| [cratera_primeira_pessoa.png](../assets/generated/ambiente-e-interacoes/abertura/cratera_primeira_pessoa.png) | Quadro 2. Vista do ponto onde Fallen desperta. |
| [cratera_aerea_obliqua.png](../assets/generated/ambiente-e-interacoes/abertura/cratera_aerea_obliqua.png) | Quadro 3. Cratera e Estrada Ocre vistas do alto em ângulo oblíquo. |
| [cratera_lado_estrada.png](../assets/generated/ambiente-e-interacoes/abertura/cratera_lado_estrada.png) | Quadro 4. Vista do lado da estrada, olhando para a parede interna em sombra. |
| [cratera_vista_da_borda.png](../assets/generated/ambiente-e-interacoes/abertura/cratera_vista_da_borda.png) | Quadro 5. Vista próxima da parede e do fundo a partir da borda. |
| [cratera_areia_impacto.gif](../assets/generated/ambiente-e-interacoes/abertura/cratera_areia_impacto.gif) | Prévia aprovada em loop, 804 × 490, 25 quadros e 2,45 s. |

As cinco imagens filtradas têm 804 × 490 px. No Blender, selecione os quadros de
1 a 5 do modelo estático para trocar de câmera. No arquivo animado, use os
marcadores da linha do tempo para inspecionar cada fase. A animação e o GIF
conservam o cenário da aprovação. O GIF já inclui o pós-processamento. Ao
exportar novos quadros, aplique o filtro do jogo depois do render. A montagem
da abertura e a integração no Godot estão **PENDENTES**.

Demais localizações, geografia, hubs, dungeons e regras de exploração: **PENDENTE**.

---

## 17. Direção de arte, HUD, UX e acessibilidade — **CONFIRMADO / PENDENTE**

- Resolução base **816×624** (D-055, era 544×416), visão frontal, filtro de textura nearest. **CONFIRMADO** em ambiente.
- HUD em janelas inspiradas em RPG Maker VX Ace, com battleback, sprites de inimigos,
  retratos, barras HP/EN e barra vertical de SP. **IMPLEMENTADO localmente**, ainda não
  publicado e ainda não julgado pelo diretor.
- Decisão do diretor em 2026-11-21: substituir todos os assets da fangame por
  placeholders próprios na cena de batalha. **CONFIRMADO como decisão**;
  **implementação pendente — não executada nesta entrega**.
- Idioma da UI: inglês. **CONFIRMADO**.
- **Layout de batalha (D-053, criador 2026-11-22/23): fundo D** (céu de plasma animado
  atrás da cena fixa) com **inimigos 15% menores**. Deve ser usado **SEMPRE** a partir de
  2026-11-23, no jogo, nos protótipos e nas capturas. **IMPLEMENTADO** em
  `PlayableController._build_ui`, com o shader `scenes/battle/battle_stage.gdshader`.
- Acessibilidade, navegação por teclado/gamepad, escalonamento e contraste: **PENDENTE**.

### 17.1 Tactical Altar — decisões de HUD das Rodadas Visuais 1 a 3 — **CONFIRMADO como design; NÃO IMPLEMENTADO**

A nova direção visual deve preservar o aspecto de **RPG clássico próximo de RPG
Maker XP**, a visão frontal e a escala nativa 544×416. **Tactical Altar** é a
direção aprovada: janelas e painéis legíveis, geometria contida, estética sombria e
atenção prioritária às artes dos inimigos. Não reproduzir integralmente interfaces
de jogos terceiros. A referência histórica a VX Ace acima descreve uma implementação
anterior e **não substitui esta direção criativa aprovada**.

**Rodada Visual 1 — 1A; 2D; 3D; 4B:**
- Base Tactical Altar; barra **comparativa de SP** acompanhada de valores **individuais**;
  inimigos com nome e HP discretos, com destaque do alvo; painéis de **Fallen e Yoch
  empilhados à esquerda**, comandos à direita.

**Rodada Visual 2 — 1B; 2B; 3B; 4B; 5A; 6D; 7A; 8C:**
- SP compara **combatente de referência × alvo em foco**; a comparação acompanha alvo
  ativo, último atacado ou selecionado conforme a precedência da Rodada 3.
- Atos exibidos por **quatro marcadores mais número**, para o estoque compartilhado
  por ações e reações; não apresentar REACT como recurso separado.
- Alvos navegáveis manualmente por **esquerda/direita**; apenas o alvo destacado
  exibe **HP numérico**; os demais podem mostrar a barra de HP.
- **Menu vertical** ancorado à direita; **Battle Log compacto**, com histórico
  expansível; **números flutuantes** de feedback com atualização animada de SP/ACT.
- A antiga escolha **7A** previa sobreposição central para reflexos; foi
  **SUBSTITUÍDA** pela correção posterior de integração da linha ao alvo, sem
  janela central.

**Rodada Visual 3 — 1D; 2B; 3A; 4A; 5A; 6B; 7A; 8B; 9C; 10A; 11A; 12D:**
- Referência SP: aliado **atuante** ou, durante ataque inimigo, aliado
  **ameaçado**. Precedência do foco: **ação em resolução > alvo selecionado >
  último atacado**.
- Comparação principal com **barra proporcional aos valores individuais**.
  Inimigos fora do foco recebem símbolos **↑/↓/=** ao lado da arte para
  indicar se o aliado de referência tem, respectivamente, mais/menos/igual SP;
  tais símbolos **não** representam aumento ou redução recente de SP.
- Seleção de alvo acontece **após escolher o comando**. Caso o alvo do cursor
  se torne inválido, o foco passa ao **próximo inimigo vivo**. Isso **não**
  estabelece redirecionamento automático de uma ação já declarada.
- Distribuição **horizontal adaptativa** para **1–4 inimigos**; números/marcadores
  ACT inimigos visíveis **somente no inimigo destacado**.
- Menu à direita **recolhido fora da seleção de comandos**; histórico do log
  acessível **apenas fora de interações temporizadas**.
- A informação contextual do reflexo inclui participantes, custo/ato e instrução,
  mas **não** exige janela central: aplica-se a correção de posicionamento abaixo.
- Tipografia **híbrida**: contornos pixelados, títulos de caráter ritualístico e
  números legíveis em monoespaçada.

### 17.2 Reflexos integrados e simplificação visual — **CONFIRMADO como design; NÃO IMPLEMENTADO**

Correções explícitas do diretor ao protótipo visual, seguidas da Rodada Visual 5
aprovada por **“sigo suas recomendações”**:

- **Ataque:** uma **linha de ritmo desenhada diretamente sobre a arte do inimigo
  selecionado**, sem janela que obstrua os personagens. **Rodada Visual 5, 1B:**
  a linha cresce da esquerda para a direita.
- **Defesa:** a barra aparece **dentro do painel de Fallen ou Yoch que está sendo
  atacado**, conforme o alvo efetivo. **Rodada Visual 5, 2D:** destacar
  discretamente a borda desse painel.
- **Rodada Visual 5, 3B:** feedback POINT/BEAM/MISS junto à linha com **iluminação
  localizada**, sem overlay central.
- **Rodada Visual 5, 4A:** seleção por **quatro cantos geométricos separados**
  ao redor do inimigo.
- **Rodada Visual 5, 5A:** largura da linha de reflexo **adaptável à quantidade
  de inimigos** visíveis; essa adaptação gráfica, por si, não altera a
  duração nem a proporção mecânica das zonas.
- **ABSORB pertence somente a Fallen**; não deve aparecer entre os comandos de
  Yoch, inclusive em mockups. A restrição mecânica já consta do código e da
  especificação.
- **Setas diagonais que colidem: REJEITADAS explicitamente pelo diretor.**
  Não integrar nem reabrir como proposta de efeito.
- O diretor rejeitou excesso de ornamentos e repetição de escolhas cosméticas.
  A prioridade passa a ser **linguagem clássica de RPG Maker XP**, boa
  legibilidade e diferenças efetivas no gameplay.

**PENDENTES exclusivamente visuais, sem aprovação implícita:** escolhas não
respondidas da Rodada Visual 4 (comportamento circular do cursor; foco inicial;
ordem concreta de passagem ao próximo alvo; confirmação/cancelamento; comunicação
da troca de referência SP; comparação 0/0; acabamento das setas ↑/↓/=; aspecto
do menu recolhido; acesso concreto ao histórico; feedback de eventos múltiplos;
paleta final). As propostas visuais não constituem aprovação automática.
As decisões da Rodada Visual 6 sobre ornamentos **não foram aprovadas**;
a ideia das setas diagonais foi posteriormente rejeitada.

---

## 18. Direção sonora — **PENDENTE**

Não há decisão aprovada sobre música, SFX, mixagem, leitmotiv ou identidade audiovisual.
A fangame fornece 128 arquivos OGG temporários, não publicados no repositório.

---

## 19. Estrutura técnica — **VERIFICADO**

- Engine: Godot **4.7.2 stable**, renderer `gl_compatibility`.
- Branch `main`; HEAD `11bf7a4dd7d01f12608a0cfb7b09e468e8769641` no momento da auditoria.
- Addons: GUT 9.7.1 e Dialogue Manager 4.2.0, ambos habilitados em `project.godot`.
- Autoload `DialogueManager` registrado manualmente porque os plugins foram habilitados
  por edição direta de `project.godot`.
- Testes: 16 testes GUT, 49 asserts (última execução: 16/16, exit 0).
- `.gitignore` exclui `assets/**`, `data/extracted/`, `captures/`, executáveis e a
  fangame. Isso torna o clone do repositório incapaz de reproduzir a cena de batalha
  visual atual. Decisão registrada no §17; correção pendente.

---

### 19.1 D-039 (Rodada 14, 1A; 2A; 8A) — fases e portões obrigatórios — **PLANO CONFIRMADO; NÃO EXECUTADO**

**1A — fases sequenciais de implementação futura:**

1. **Base temporal e testes:** tornar a avaliação temporal independente do último quadro renderizado, preservando duração e velocidade fixas D-034 e IA comum D-035; testar relógio, fronteiras e inputs controlados.
2. **Perfis POINT especiais e IA:** introduzir múltiplas regiões POINT, seleção/validação de perfis e IA especial triangular sob D-037, preservando a geometria e exceção D-022.
3. **Pacotes de dano:** introduzir Resource tipado com identidade e efeitos participantes (D-039 3A), piso por pacote D-036/D-037 e testes de contato/afinidades.
4. **Replay, certificados e integração:** integrar snapshots JSON versionados, rastros com sequência por encontro, certificados intervalares com contraexemplos e igualdade mecânica em 30/60/120 FPS para seeds/inputs controlados.

A fase 4 **não dispensa** instrumentação e testes pertinentes já nas fases anteriores. Nenhuma fase foi iniciada por este registro.

**2A — antes da primeira mudança de código:** auditar **HEAD remoto/local realmente acessível**, `AGENTS.md`, decisão vigente versus histórica/superada, estrutura de dados e código de Moves, dependências, configurações, scripts e **estado dos testes**, identificando os arquivos reais. Produzir **mapa de contratos por componente** e plano estritamente restrito ao necessário, com conflitos e riscos explícitos. Não pressupor arquitetura, funções ou Resources não verificados.

**8A — portão de liberação de cada fase:** exigir **parse executado**, testes **unitários e de integração pertinentes**, inspeção do diff e escopo, fidelidade às decisões vigentes e **evidência verificável** antes de declarar conclusão. Falhas exigem correção seguida de nova validação; sucesso de testes não substitui homologação visual ou estatística. Preservar o combate já jogável e todas as regras externas ao escopo, inclusive a **D-038 (REST sem gasto de ACT, +2 EN fixos e armazenamento dos atos remanescentes)**, cuja implementação **não foi incluída nem autorizada** nestas fases.

**Estado:** esta decisão apenas documenta a sequência e os portões; nenhuma fase, teste Godot, diff local, migração, Resource ou alteração de código foi executada nesta rodada.

### 19.2 D-040 (Rodada 15, 8A) — matriz mínima da Fase 1 — **CRITÉRIOS APROVADOS; NÃO EXECUTADOS**

**8A:** a liberação da Fase 1 depende de **parse executado**, testes **unitários e de integração pertinentes**, diff/escopo auditados, fidelidade às decisões vigentes e evidência real, conforme D-039. Exigir a seguinte **matriz mínima**:

- **Fronteiras mecânicas POINT/BEAM/MISS**, inclusive igualdade exata e ajustes de largura AGI/SP D-034, **t=0** e **deadline t=1 s** com input/timeout simultâneos ou com chegada fora de ordem; input posterior ao limite;
- **Primeiro input único**, `echo`, duplicidade, reentrância, evento anterior de confirmação de reação, fechamento único e nenhuma emissão duplicada;
- **Pausa e ativação**, relógio monotônico, avaliação pelo timestamp recebido e marcador visual subordinado ao mesmo progresso mecânico;
- **FPS 30/60/120** com timestamps controlados, exigindo **mesmas classificações e resultados mecânicos** nos casos comparáveis; regressões de combate, atos, reações e autoacerto D-022, preservando barra uniforme D-034 e IA comum D-035;
- **Fluxos de RNG**: quando a exceção D-022 dispensar erro triangular, não consumir esse sorteio nem deslocar rolagens de dano/crítico. A IA especial completa pertence à Fase 2.

A **comparação do rastro canônico completo** de D-036/D-037 é requisito da **Fase 4**. Na Fase 1, usar instrumentação suficiente para demonstrar os resultados pertinentes, sem afirmar que JSON/replay integral já existe. **PENDENTES:** harness real de input controlado, APIs/timestamps, evidência e testes executados. A divergência anterior de REST D-038 deve ser relatada como fora do escopo, não corrigida silenciosamente.

### 19.3 D-041 (Rodada 16, 5A) — testes de independência de FPS — **CRITÉRIO APROVADO; NÃO EXECUTADO**

**5A:** a validação deve conter **dois níveis complementares**:

1. **Avaliador mecânico testável por tempos injetados**, com eventos precisamente controlados, coberturas e limites POINT/BEAM/MISS, casos em t=0, t=1 s, instantes de fronteira, prioridade sobre timeout e bloqueio do segundo input;
2. **Testes de integração da cena/barra/controlador** que injetem eventos e comparem o julgamento mecânico e os estados observáveis a **30/60/120 FPS**, sob seeds e timestamps equivalentes.

Testes puros **não substituem** os de integração. Variação de FPS não pode alterar classificações nem o resultado mecânico dos mesmos inputs controlados; o aspecto visual não precisa produzir pixels idênticos. Antes de fixar scripts ou comandos, verificar como o Godot e os testes existentes permitem injetar instantes, controlar frames e exercitar `RhythmBar`/`BattleController`. Conservar os portões de parse, testes, diff e evidência real da D-039/D-040. **Nenhum teste foi executado nesta rodada** e a Fase 1 não foi declarada liberada.

## 20. Critérios de balanceamento e validação — **PENDENTE**

Existem testes de execução das fórmulas e da cena, mas não há critérios aprovados de
dificuldade, curva de dano, tempo de combate, taxa de acerto ou orçamento de atos.
Nenhum número de balanceamento deve ser considerado oficial sem decisão do diretor.

**D-019 (Rodada 3):** calibrar a contribuição crítica de SP e o teto
crítico abaixo de 100%, validar a adoção de ±10% fixos no dano mantendo
`1dN`, e ajustar os poderes das habilidades com amostras de combate.
**PENDENTES de números:** ganho crítico por ponto de SP, teto crítico
global, poderes de referência e métricas de duração de combate.
Os números do código atual não são parâmetros aprovados para a nova
calibração. Não foram executadas simulações ou testes nesta rodada.

**D-020 (Rodada 4):** cobertura total POINT entre **8% e 16%**
nos perfis especiais, dividida entre regiões múltiplas, e duração
global preservada com cadência variável compensada. A duração
mínima do protótipo (0,2 s) pode resultar em janelas úteis muito
curtas: 8% do percurso, sob velocidade uniforme e em 0,2 s,
equivale a **16 ms**. **PENDENTES**: limites temporais de
acerto, função AGI/SP por faixas, erro da IA, seed, distribuição
das regiões e critérios de teste de responsividade. O percentual
de cobertura não representa automaticamente percentual de tempo.

---

**D-021 (7A) — objetivo inicial de balanceamento:** um inimigo de
força aproximadamente equivalente ao jogador deve ser derrotado
em **3 a 5 ataques físicos bem-sucedidos**, no cenário de referência
**sem bloqueios ou críticos**. Isso não equivale a 3–5 rodadas;
a quantidade real depende de atos, reações e Press Turn.
Não foram aprovados novos poderes dos ataques, nem estatísticas
de referência; esses números dependem de calibração posterior.
Preservar `poder × ATK ÷ DEF` conforme D-019.

---

**D-023 (Rodada 6):** interpolação contínua AGI/SP,
até três zonas POINT por perfil, distribuição
espacial declarada pelo inimigo, geração válida
por construção, curvas suaves normalizadas,
erro triangular limitado para IA, seed derivada
de encontro/IDs/índice de execução e resolução
por tempo registrado do input. **PENDENTES:**
parâmetros e prova de validade do gerador,
limites de velocidade, erro e habilidade da IA,
algoritmo/identidade para seeds, captura de
instantes de entrada e testes de sincronização
em taxas de quadros variadas. A exceção
D-014/D-022 de autoacerto sem reação não
pode ser anulada pelo modelo de erro da IA.

---

**D-024 (Rodada 7):** calibrados teto instantâneo
de **4× velocidade média**, restrição de **3 zonas
POINT apenas com duração ≥300 ms**, erros
triangulares de IA (**±70/40/20 ms** por
iniciante/comum/profissional), alvo de maior
tempo POINT, registro completo dos parâmetros
resolvidos para replay, relógio monotônico
com instante de recebimento de input, ficha
neutra a homologar e requisitos de teste de
propriedades, seeds, fronteiras, integração
e FPS. **PENDENTES:** curvas e acelerações
máximas, viabilidade dos domínios por
construção, classe de cada inimigo, esquema
de replay/seed, semântica real do relógio,
aprovação dos atributos da ficha neutra
e parâmetros de aceitação dos testes.
Nenhum teste ou implementação foi realizado
por esta decisão documental.

---

**D-025 (Rodada 8):** regras aprovadas de
validação de perfis inviáveis no carregamento,
limite de aceleração `12 × v_média/T`,
classificação das fronteiras a favor de POINT/BEAM,
origem temporal no início da barra após escolha
pausada, desempate de AGI por ID estável,
cancelamento apenas por eliminação ou interrupção
expressa e identidade mecânica exata em 30/60/120
FPS com timestamps controlados. A ideia própria
5E estabelece **atributos iniciais de personagens
e inimigos em 8 ou múltiplos de 8**, Fallen com
**32 HP, 8 EN e 8 nos demais cinco atributos
básicos**; seu SP base derivado é **80**.
**PENDENTES:** política de validade dinâmica
quando AGI/SP mudam, ordenação de IDs,
valores iniciais de outros personagens,
calibração de poderes, leitura do relógio
no Godot e testes de FPS. Regras de design
aprovadas, ainda não implementadas.

---

**D-031 (Rodada 9, 3A) — poder físico
básico aprovado como design:** o
ataque físico **básico** terá
**poder nominal 8**, preservando
a fórmula física `poder × ATK/DEF`.
Na referência neutra D-031 (2B)
com HP 32, ATK 8 e DEF 8,
o dano físico **nominal** é 8,
o que exige **quatro acertos
nominais** para zerar 32 HP,
antes de sorteios, ±10%
aprovados como design D-019
(ainda pendentes em código),
críticos, afinidades, bloqueios
e outros efeitos. Isso não
autoriza atribuir poder 8
a todos os outros ataques,
alterar o dano atual em
código ou considerar a
meta de 3–5 acertos
estatisticamente verificada.

**D-031 — risco de escala e SP:**
diferentes espécies podem
começar com múltiplos de 8
distintos e, portanto,
`SP_base` distintos. Como
SP participa de ritmo,
dano e dominância, verificar
interação com D-007/D-019,
economia de atos e a nova
ficha neutra. Progressão
por absorção da D-028
permanece acumulativa.
**PENDENTES:** definições
concretas das fichas por
espécie, esquema e versão
da referência neutra,
validação das variantes
dinâmicas, momento exato
da captura dos parâmetros
e execução de testes.

---

**D-032 (Rodada 10, 4A) — metas de durabilidade:**
para testes de **ataques físicos bem-sucedidos**,
manter alvos iniciais de **2–3 acertos para
inimigos frágeis**, **3–5 para equivalentes**
(D-021) e **5–7 para resistentes**. Trata-se
de **critério de balanceamento**, não
garantia de que as fichas aprovadas em
3A já o satisfaçam, nem de duração
em rodadas. Preservar o poder 8
do ataque físico básico (D-031) e a
fórmula `poder × ATK / DEF` (D-019).

**CONFLITO QUANTITATIVO NÃO RESOLVIDO:**
com o atacante de referência (ATK 8,
poder 8), a ficha de laboratório
resistente aprovada em D-032 (3A)
tem HP 48 e DEF 16: dano-base
`8 × 8 / 16 = 4`, exigindo
**12 acertos nominais** para
zerar 48 HP — fora da meta de
**5–7**. Além disso, o SP base
resistente é **104**, contra
**80** no equilibrado, e a
regra `1d24` de diferença
de SP pode reduzir ainda mais
o dano de quem tem SP menor.
**Não corrigir** os atributos
nem mudar o poder básico,
o modificador de SP, a
fórmula ou as metas
sem decisão adicional do
diretor. Esse conflito
impede homologar como
balanceado o cenário
resistente proposto.

**D-032 (Rodada 10, 8A) — aceitação estatística:**
em uma bateria de **10.000
casos controlados** contra a
referência equivalente, exigir
que **pelo menos 95%**
(`≥9.500` casos) resultem em
derrota com **3–5 ataques
físicos bem-sucedidos**.
Preservar a finalidade
dos testes de referência
sem bloqueios/críticos
e a separação de rolagens
de SP e variação de dano.
**PENDENTES:** especificação
completa do experimento
(afinidade, atributos,
estado inicial de SP,
seeds, arredondamento,
efeitos permitidos, forma
de contagem dos acertos
e ferramenta executável)
e validação da variação
fixa de ±10% da D-019,
que **ainda não está
implementada**.
O limiar de 95% foi
**aprovado como meta**;
não foram executadas
10.000 simulações nesta
rodada.

---

**D-033 (Rodada 11, 6A) — cenário do ensaio de 10.000 casos:** referência neutra contra cópia equivalente (HP 32, ATK 8, DEF 8, SP iguais), ataque físico básico poder 8, **afinidade Normal, sem críticos nem bloqueios, variação fixa ±10%** conforme D-019. Exigir a meta D-032 de **≥95% (≥9.500 casos)** com derrota após **3–5 ataques físicos bem-sucedidos**. Não aplicar vantagens de SP inexistentes; sem eventos extras não definidos no ensaio. **PENDENTES:** seeds, reinicialização dos estados, método de contagem, algoritmo de amostragem e execução real do teste. **Nenhuma simulação executada.** Dedução aritmética condicional: com arredondamento `int(round())`, dano-base 8 e ±10% produzem danos 7–9, levando a derrota em quatro ou cinco acertos; isso não comprova equilíbrio fora do cenário neutro.

**D-033 (Rodada 11, 8A) — validação integrada:** exigir testes de **duelos e combates contra múltiplos inimigos** com fichas distintas, verificando economia e armazenamento de atos (D-005), seleção e prioridade de reações (D-014/D-025/D-031), fraquezas/Press Turn, SP/dominância (D-007), duração e perfis de ritmo, sem dispensar os testes de propriedades, seeds, fronteiras e equivalência mecânica em 30/60/120 FPS (D-024/D-025). **PENDENTES:** matriz executável, seeds, métricas e expectativas por cenário.

**Revisão do conflito D-032:** a decisão posterior D-033 (2C) **substitui somente a ficha resistente de laboratório**, de HP 48/DEF 16/SP 104 para **HP 40/DEF 8/SP 88**. Isso corrige o cálculo **nominal** de 12 para 5 acertos com poder 8 e ATK 8, mas **não resolve o risco de desbalanceamento efetivo**: a diferença SP 80 versus 88 introduz `−1d8`, podendo resultar em mínimo de 1 por ataque. O teste neutro de 95% não cobre essa situação. Não ajustar outros poderes, atributos ou regras sem aprovação.

**D-036 (Rodada 12, 3D) — validação resistente em duas baterias independentes:** realizar **uma bateria com SP igual** entre atacante de referência e alvo resistente de laboratório (D-033: HP 40, DEF 8, SP_base derivado 88) para isolar resistência por HP/DEF, e **outra com SP reais de 80 (atacante) contra 88 (resistente)** para medir a penalidade SP (`−1d8`). A ficha resistente revisada e o ataque básico de poder 8 permanecem. **PENDENTES:** qual valor igual de SP adotar no primeiro cenário, modo de controlar SP sem alterar fichas por inferência, contagem de casos, seeds, regras de acerto/crítico/afinidade/variação e **taxa estatística de aceitação de cada bateria**. Não aplicar automaticamente às novas baterias o limiar **≥95% em 10.000 casos**, que continua homologado para o **ensaio neutro** da D-032/D-033 (6A). A meta resistente de **5–7 acertos** permanece objetivo de balanceamento, **sem evidência de aprovação estatística**. Nenhuma das baterias foi executada.

**D-036 — risco transversal:** a D-034 já implementou barra de duração fixa de 1 s; os textos históricos D-032/D-033 ainda mencionam duração variável. A especificação vigente deve tomar D-034 como autoridade para a duração. D-035 já compartilha largura POINT com a IA; seu modelo atual de amostragem uniforme não comprova o contrato temporal triangular anterior. D-036 não escolhe uma nova arquitetura de IA, não restaura fórmulas antigas e não valida automaticamente curvas ou variantes não implementadas.

**D-037 (Rodada 13, 8C) — metas distintas para as baterias resistentes:** para a bateria com **SP igual**, aprovar **≥95% dos casos** com derrota do resistente de laboratório (HP 40, DEF 8, SP_base derivado 88; D-033) em **5–7 ataques físicos bem-sucedidos**, preservando os controles a homologar da D-036. Para a bateria com **SP 80 do atacante versus SP 88 do resistente**, usar os resultados **somente como diagnóstico**, **sem limiar estatístico aprovado** e sem declarar falha/sucesso de homologação por porcentagem. O tamanho da amostra e a definição do SP igual (inclusive como controlá-lo sem alterar fichas) continuam **PENDENTES**; não transferir automaticamente a contagem de 10.000 do **ensaio neutro** D-032/D-033 para estas baterias.

**Risco de teste pouco discriminante:** com SP igual, ataque de poder 8, ATK/DEF 8 e variação ±10%, um ataque causa aproximadamente **7–9 de dano** sob arredondamento atual, de modo que 40 HP são eliminados em **5 ou 6 acertos** nas condições controladas sem outras alterações. Portanto, ≥95% dentro de 5–7 acertos pode verificar uma propriedade aritmética esperada, mas **não comprova equilíbrio** contra SP desigual. Não houve execução das baterias, testes de integração ou medições de distribuição nesta publicação.

**D-037 — riscos de integração:** não combinar silenciosamente cadência variável da D-023 com D-034; a IA especial temporal da 2B ainda diverge da IA uniforme implementada D-035; o piso por pacote carece de identidade mecânica; o validador ainda não oferece prova intervalar nem contraexemplo; a atribuição de sequência e conversão de timestamps precisam de contratos determinísticos antes de exigir comparação real de rastros. A documentação registra a direção aprovada, não funcionamento ou testes concluídos.

**D-039 (Rodada 14, 7A) — amostra de resistência com SP igual:** a bateria resistente da D-037 com **SP igual** terá **10.000 casos controlados**. Para aprovação, exigir **≥95% (≥9.500 casos)** de derrotas em **5–7 ataques físicos bem-sucedidos** contra a ficha resistente de laboratório D-033 (HP 40, DEF 8, SP_base 88), preservando o ataque físico básico de poder 8 e as demais condições a especificar. **PENDENTES:** qual SP igual usar e como isolá-lo sem alterar ficha por inferência, seeds, reinicialização e condições de teste. A bateria de **SP 80 vs 88** continua **somente diagnóstica**, sem limiar ou quantidade obrigatória aprovados. Não transferir esse limiar para outros encontros. Nenhum caso foi executado.

**Riscos e regressões da estratégia D-039:** `RhythmBar` ainda julga input pelo marcador do último frame; a IA especial triangular, os pacotes de dano e a prova por certificado intervalar não estão implementados. A ordem de RNG no autoacerto ainda não está fixada. D-038 estabelece REST sem gasto de ato no design, mas o código antigo ainda consome ato; esse sistema **permanece fora do escopo das quatro fases**, e não foi modificado. O critério de portão de testes deve impedir que mudanças de ritmo/dano provoquem regressões nesses subsistemas.

**D-040 — risco principal para a Fase 1:** `RhythmBar` ainda julga pelo último frame; entradas em fronteiras, confirmações reaproveitadas e timeout podem divergir do timestamp de recebimento. **A serialização inteira em µs com empate para par não preserva necessariamente toda a informação para repetir decisões feitas em precisão temporal superior**; é preciso decidir contrato de reprodução de fronteiras antes de declarar rastros idênticos. Fluxos de RNG por finalidade também exigem derivação e persistência explícitas. Critérios documentados não equivalem a testes concluídos.

**Preservação:** D-034 mantém barra de um segundo uniforme; D-035 mantém IA comum; D-038 continua REST sem gasto de ACT, +2 EN e guarda de atos, mas **não implementada e fora das alterações previstas na Fase 1**. Nenhum código, teste, asset, save ou Resource foi alterado por esta decisão.

**D-041 — riscos críticos de geometria e determinação temporal:** (1) a largura dinâmica da D-034 pode cair a **8% de POINT** enquanto três regiões requerem **≥12%** em barra uniforme de 1 s; as variantes/validação precisam demonstrar cobertura sem rejeições de execução, ajuste de pesos ou supressão de regiões; (2) BEAM declarado em especiais cria possibilidade de sobreposição entre intervalos BEAM/POINT e ainda não possui orçamento máximo aprovado — as fronteiras obedecem POINT > BEAM > MISS, mas não há autorização para decidir outras regras de geometria silenciosamente; (3) a entrega de um input de timestamp elegível após a execução incidental do callback de timeout exige política de enfileiramento que não foi aprovada; (4) a escolha de `Time.get_ticks_usec()` não prova latência real do dispositivo, e snapshots podem exigir operandos de fronteira além do tempo arredondado; (5) os fluxos de RNG hoje compartilhados no código não satisfazem a separação por finalidade da D-040/D-041.

**Estado:** D-041 apenas registra design/testes previstos; não implementa base temporal, múltiplas zonas, BEAM especiais, RNG separado, testes, certificados ou replays. D-038 (REST sem ACT, +2 EN fixos, guarda de atos) permanece **não implementada e fora do escopo**, sem alteração de regras ou arquivos de gameplay.

**D-042 — crítica geométrica e de integração:** em perfis especiais, a soma **POINT+BEAM = 30%** (D-042 1A) precisa coexistir com cobertura POINT dinâmica de 8%–16%, intervalos declarados, ausência de sobreposições interiores, centros POINT fixos e largura mínima de 4% por região. **Não está demonstrado** que todos os estados de atributos permitidos possam ser cobertos pelos perfis/variantes atuais; especialmente, três regiões POINT são impossíveis com cobertura total de 8%. Além disso, a D-042 não determina **como distribuir dinamicamente o orçamento BEAM restante** em intervalos autorais sem alterar silenciosamente seus limites; essa decisão permanece em aberto.

**D-042 — IA e RNG:** a IA especial triangular precisa de exatamente **duas amostras uniformes** de seu fluxo temporal por ação que realmente faça julgamento de timing, e de **nenhuma** no autoacerto D-022 sem reação. Resolver fora da barra (tempo <0 ou >1 s) e fixar o contrato de stream/serialização são pendências; não usar sorteios de rejeição por inferência. O código atual implementa apenas IA comum D-035 por posição uniforme; o motor ainda não oferece os múltiplos intervalos declarados D-042. **REST D-038 está IMPLEMENTADO** na `main` atual em commits posteriores à sua documentação inicial; relatos históricos que indicam `não implementado` não devem prevalecer sobre a verificação do código atual. Esta rodada não modifica esse sistema.

## 21. Riscos e pendências consolidadas

1. **A-02** - resolvido por D-007 (dominância em razão); sem pendência.
2. **D-014:** bloqueio Trave homologado em 50%. **D-015** resolve a precedência
   POINT/POINT; permanecem pendentes a escolha voluntária de não reagir, os empates
   de AGI e as regras de interrupção.
3. A-07/A-10 - dificuldade de absorção e persistência entre batalhas permanecem
   indefinidas; **D-017** homologou a eliminação do alvo.
4. A-08 — inventário de itens não implementado.
5. Reprodução de assets — **D-018:** placeholders visuais permanecem, com
   manifesto e script de setup locais; nenhum asset de terceiros é publicado.
6. Alterações locais permanecem não publicadas conforme decisão anterior do diretor.
7. Toda a narrativa além da premissa está indefinida.
8. Sem magia, equipamentos, save/load ou loop de jogo completo.
9. **D-005/D-007** - implementadas; nenhuma pendência restante nessas regras.
10. Perfis variáveis de ritmo aprovados como design (§8.1), ainda sem contrato
    mecânico ou implementação: posições, número de zonas, cadência, larguras por
    SP/AGI e compatibilidade com as regras fixas atuais.
11. HUD Tactical Altar aprovado em rodadas visuais (§§17.1–17.2), ainda não
    implementado no motor; a validação visual final pertence ao diretor.
12. **D-019 (Rodada 3):** especificação aprovada para reduzir impacto
    crítico por ponto de SP com teto inferior a 100% (valores pendentes);
    ±10% de variação fixa no dano; recalibração dos poderes de ataques;
    manutenção de ganhos +1 SP; comparação de dominância com adversário
    vivo de maior SP; críticos normais em acertos inimigos garantidos.
    Novas fórmulas e poderes ainda **não implementados**. O autoacerto
    sem reação foi implementado por **D-022**.
13. **D-020 (Rodada 4):** perfis especiais de ritmo aprovados como design
    em §8.1.1 e na especificação técnica, **NÃO IMPLEMENTADOS**.
    Contratos pendentes: largura-base por AGI, faixas de SP,
    mínimos temporais das zonas, distribuição em múltiplos POINT,
    perfil de erro temporal da IA e derivação/reprodução da seed.
    O risco crítico é a janela útil subquadro em durações curtas.
15. **D-022:** o acerto automático inimigo também vale quando o jogador
    pode reagir e opta por não declarar reação. **IMPLEMENTADO.**

---

14. **D-021 — Rodada 5:** números críticos (+2 p.p./SP, máximo
    +20 p.p., teto total 50%) — **IMPLEMENTADOS**;
    largura POINT base 10%, ajustes ±1 p.p./10 AGI e ±1 p.p./5 SP,
    mínimo de 40 ms por região POINT e objetivo de 3–5 ataques
    — **design aprovado, não implementado**. Pendentes:
    arredondamento, seleção de perfis válidos e poderes.

---

16. **D-023 — Rodada 6:** aprovada como design,
    **NÃO IMPLEMENTADA**. Interpolação contínua,
    até três zonas por perfil, geração válida
    por construção, cadência suave, erro
    triangular da IA, seeds derivadas e
    julgamento temporal dos reflexos.
    Detalhes e pendências em §8.1.3.

---

17. **D-024 — Rodada 7:** design aprovado, **NÃO
    IMPLEMENTADO**; limites de velocidade, três
    zonas condicionadas a ≥300 ms, amplitudes de
    erro temporal da IA, prioridade por janela
    temporal, snapshot integral para replay,
    relógio monotônico de input, ficha neutra
    pendente e testes obrigatórios de propriedades,
    reprodução, fronteiras, integração e FPS.
    Dependências e riscos detalhados em §8.1.4.

---

18. **D-025 — Rodada 8:** oito decisões
    aprovadas em design; **NÃO IMPLEMENTADAS**:
    invalidade de configuração bloqueia
    carregamento, limite de aceleração
    12× v_média/T, fronteiras favoráveis,
    relógio inicia após escolha, escala
    inicial de atributos 8 ou múltiplos,
    desempate por ID estável, interrupção
    condicionada a eliminação/efeito explícito
    e igualdade mecânica 30/60/120 FPS.
    Riscos e pendências em §§6.1, 7.2,
    8.1.5 e 20.

---

19. **D-031 — Rodada 9:** espécie com
    ficha inicial própria em
    múltiplos de 8, referência
    neutra independente e
    versionada com números
    iniciais de Fallen, poder
    básico 8, variantes de
    ritmo declaradas/validadas,
    desempate lexicográfico,
    novo input desde t=0,
    IA visando centro temporal
    e snapshot AGI/SP no
    início de cada barra.
    **Design aprovado; não
    implementado.**
    Pendências nas §§6.2,
    7.3, 8.1.6 e 20.

---

20. **D-032 — Rodada 10:** taxa
    de duração de 50 ms/8
    pontos combinados,
    preservação de SP base
    com sete atributos,
    três fichas de teste,
    metas de 2–3/3–5/5–7
    acertos, prova de
    cobertura de variantes,
    prioridade declarada,
    snapshots JSON versionados
    e limiar ≥95% em 10.000
    simulações controladas.
    **Design aprovado; NÃO
    IMPLEMENTADO.** O
    conflito de 12 acertos
    nominais contra a ficha
    resistente está detalhado
    em §20 e exige decisão
    futura, sem modificação
    desta rodada.
21. **D-034:** barra fixa em 1,0 s; AGI aumenta a cobertura POINT em
    +1 p.p. por ponto de vantagem; SP mantém faixas da D-021.
    **IMPLEMENTADO.** Substitui a taxa de duração da D-032 como direção
    vigente; a D-032 permanece registrada no histórico.

---

21. **D-033 - Rodada 11:** interpolação contínua da duração; ficha resistente de laboratório revisada para HP 40, DEF 8 e SP_base 88; piso de 1 dano sob contato e afinidade válida; demonstração intervalar de cobertura das variantes; transição atômica de captura/seleção/início; ensaio neutro de 10.000 casos; versões separadas de esquema JSON e resolvedor; testes completos de duelos e múltiplos inimigos. **Aprovado como design; NÃO IMPLEMENTADO.** Conflito nominal da D-032 corrigido somente na ficha de laboratório; risco de SP persiste (ver §§4.2, 6.4, 8.1.8 e 20).
22. **D-035:** IA usa a mesma largura de POINT do jogador; rolagens extras
    continuam por SP. **IMPLEMENTADO.**

---

23. **D-036 — Rodada 12:** cada efeito de dano declara participação no piso; piso de 1 aplicado após todos os modificadores e arredondamento final quando houver contato e afinidade que permita dano; duas baterias distintas para resistente (SP igual / SP 80 vs 88); domínio alcançável conforme motor e transições reais sem novos tetos; resolver eventos mecânicos comprometidos antes da captura atômica; tempos de replay JSON em inteiros de microssegundos; recusar replay mecânico exato sem resolvedor original preservando o registro; igualdade exata dos rastros mecânicos em 30/60/120 FPS para seeds e inputs controlados. **Design aprovado, NÃO IMPLEMENTADO.** Precedência da D-034 sobre a duração variável antiga explicitada no §8.1.9. Pendências e riscos nos §§4.3, 8.1.9 e 20.

24. **D-037 — Rodada 13:** manter todos os perfis em 1 s uniforme (D-034); IA comum com D-035 e IA especial com erro temporal triangular; piso por pacote mecânico de dano, mantendo declarações por efeito; certificados por intervalo com contraexemplo; ordenação de eventos simultâneos por sequência estável atribuída no comprometimento; arredondamento para microssegundo inteiro mais próximo (empates ainda pendentes); rastro canônico de eventos e RNG; validação resistente de SP igual com ≥95% em 5–7 acertos e bateria SP 80/88 apenas diagnóstica. **Design aprovado, NÃO IMPLEMENTADO nesta rodada.** Pendências nos §§4.4, 8.1.10 e 20; nenhuma substituição de D-034/D-035.

25. **D-038:** REST não gasta ato, encerra a participação na rodada,
    guarda os atos remanescentes (teto 4) e recupera 2 EN fixos.
    **IMPLEMENTADO** com três testes de regressão; substitui a regra antiga
    de D-006 sem alterar a regeneração automática de 20% no fim da rodada.

26. **D-044:** atos executados em bloco contínuo por combatente, com
    ordem entre combatentes por AGI. **IMPLEMENTADO.** Substitui a
    intercalação `A, B, A, B` sem alterar custo por comando ou reações.

27. **D-046:** fila de comandos com ACT verdes, UNDO/EXEC e linha de
    ritmo persistente entre ataques consecutivos. **IMPLEMENTADO.**

28. **D-048:** Reza de Yoch (PP) e renome do aliado **IMPLEMENTADOS** no
    BattlePlayable em 2026-11-23 (raças: só a marca `race`). Pendentes: lista,
    efeitos e PP dos itens abençoados; sistema de condições de status bloqueadas
    pelo Haganah; efeitos mecânicos das raças e classificação dos anjos; como
    Fallen obtém magias; efeito visual do Ra'am (o criador pediu 3 opções em
    protótipo: raio de letras hebraicas + duas originais, no lugar do Zio), marca
    da Haganah e VFX de PRAY/Refuah/Haganah (protótipos em `prototypes/pray-vfx`);
    magia cujo alvo cai antes de resolver.

29. **D-049:** contra-ataque com duas barras de ritmo e interrupção por ataque
    sofrido (perfeita rouba 16 SP; resultado melhor rouba 4 SP; +1 ato por
    comando da fila perdido, teto 4). **IMPLEMENTADO** no BattlePlayable; detalhes no §7.5.

30. **D-050:** prólogo aprovado como roteiro, **NÃO IMPLEMENTADO**. Pendentes (lista
    completa em `docs/PROLOGUE_SCRIPT.md`): estágios de ATK, dano mágico, IGNI, burn,
    EN extra, "dano o bastante", detalhes do resgate e conflito das fichas com o protótipo.

31. **D-051:** absorção por disputa de SP **IMPLEMENTADA** (`dd0813e`); o restante
    (prólogo, IA contextual do inimigo após a correção da D-047) é design, **NÃO
    IMPLEMENTADO**.

32. **D-052:** VFX da absorção em letras hebraicas, **IMPLEMENTADO** em
    `scripts/battle/absorb_vfx.gd` (2026-11-23). Pendentes: cor, tempos, trajetória
    e destino das letras da quebra, e visual da falha.

33. **D-103:** absorção resolvida no resultado (fim do tempo ou 10º aperto, um único
    sorteio), **IMPLEMENTADA** em `BattleController._run_absorb_mash` /
    `_resolve_absorb_mash` e `BattleMath.absorb_result` (2026-11-25).

## Apêndice A — Registro de decisões

Formato: ID · data · decisão · estado · impacto documental.

- **D-001 · 2026-11-21** · Estrutura documental: `docs/GDD.md` único, com histórico de
  decisões como apêndice; `COMBAT_SPEC.md` permanece como fonte técnica. **CONFIRMADO**.
  Impacto: este arquivo.
- **D-002 · 2026-11-21** · Os seis arquivos locais pendentes (visual VX Ace, doc de
  combate, scripts de captura) **não** devem ser publicados nesta etapa. **CONFIRMADO**.
  Impacto: nenhum; permanecem como alterações locais.
- **D-003 · 2026-11-21** · Assets da fangame devem ser substituídos por placeholders
  próprios na cena de batalha. **CONFIRMADO como decisão de design; implementação
  pendente, não executada.** Impacto futuro: §17 e `battle_controller.gd`.
- **D-004 · 2026-11-21** · O GDD inicial deve ser publicado em `main`, isolado das
  demais alterações locais. **CONFIRMADO**. Impacto: commit exclusivo de `docs/GDD.md`.
- **D-005 · 2026-11-21 (Rodada 1)** · O máximo de atos disponíveis por personagem é
  **4 no total**, incluindo atos recebidos por rodada, acumulados e bônus concedidos
  por SP ou Press Turn; aplica-se a todos os combatentes. Substitui a interpretação
  de até 4 armazenados somados a 2 novos simultaneamente disponíveis. **CONFIRMADO e
  IMPLEMENTADO:** excedente adiado ao estoque (máx. 4), podendo retornar em rodada
  posterior. Impacto: §§4.1, 5, 7, 21, `docs/COMBAT_SPEC.md`, `BattleUnit` e `BattleState`.
- **D-006 · 2026-11-21** · Correções inequívocas de economia de atos, ritmo, descanso,
  resolução de dano e absorção, executadas sob a missão de correção integral. Nenhuma
  nova regra de design foi criada. **EXECUTADO**; impacto: `COMBAT_SPEC.md`, `GDD.md`,
  scripts de combate e testes.
- **D-007 · 2026-11-21** · Limiar de superioridade passa a ser **dominância em razão**:
  +1 ato se `SP_próprio / (SP_próprio + SP_rival) > 0,7`. Substitui a interpretação
  literal de 70% do SP do oponente, que premiava ambos os lados. **CONFIRMADO e
  IMPLEMENTADO**. Impacto: `BattleMath.dominance_ratio`, `BattleState.start_round`,
  `COMBAT_SPEC.md` §Atos, GDD §5.
- **D-008 · 2026-11-21** · Regra principal de todos os agentes: auditar sempre as
  próprias implementações, caçar erros e esquecimentos, corrigir imediatamente até
  ficar completamente entregável, deixar sempre crítica extrema com recomendações e
  melhorias para o autor decidir, e não afirmar nada não verificado — cada
  implementação deve ser verificada minuciosamente. **CONFIRMADO**. Impacto: `AGENTS.md`
  (raiz) e GDD §0.3. Validação visual continua exclusiva do diretor.

- **D-009 · 2026-11-21** · Nas respostas que encerram rodadas de design com
  pendências, apresentar na própria mensagem a rodada seguinte completa, com
  alternativas, consequências, recomendação e a opção **"Ideia própria"** em
  cada pergunta. Evitar repetição de questões já resolvidas e nunca tratar
  alternativas como decisões antes da aprovação. **CONFIRMADO**. Impacto:
  GDD §0.4; nenhuma alteração de mecânica, especificação ou código.
- **D-010 · 2026-11-21** · Reforço da regra de agentes a partir das recomendações do
  autor: (1) cópia canônica em `AGENTS.md` com ponteiro em `CLAUDE.md` e nas regras
  globais; (2) evidência anexada (comando, resultado e hash do diff) em toda alegação
  de verificação; (3) crítica extrema com dimensões mínimas — correção, fidelidade ao
  design, bugs, omissões, regressões e riscos — e ao menos um problema concreto por
  entrega; (4) critério de parada e escalada de conflito de autoridade ao autor;
  (5) busca de `origin` antes de commit e preservação de trabalho concorrente;
  (6) subordinação explícita das regras globais à cópia canônica do projeto por
  ponteiro único — o conteúdo global foi preservado, não duplicado no repo.
  **CONFIRMADO**. Impacto: `AGENTS.md`, `CLAUDE.md` (raiz), regras globais e GDD §0.3.

- **D-011 · 2026-11-21** · Rodadas Visuais 1–3: direção **Tactical Altar**,
  barra SP contextual e individual, indicadores relativos ↑/↓/=, seleção por
  esquerda/direita após comando, painéis aliados empilhados, menu à direita,
  marcadores ACT, log expansível, distribuição horizontal para 1–4 inimigos,
  tipografia híbrida e precedência ação > seleção > último atacado. **CONFIRMADO
  como design; NÃO IMPLEMENTADO.** Impacto: GDD §17.1; nenhuma mudança de código.
- **D-012 · 2026-11-21** · Correção do protótipo visual e Rodada Visual 5
  (**1B; 2D; 3B; 4A; 5A**): linha ofensiva cresce sobre o alvo; linha
  defensiva fica no painel do aliado ameaçado; feedback localizado; seleção
  por quatro cantos; largura gráfica adaptativa. Janelas centrais de reflexo
  substituídas, **ABSORB só para Fallen**, setas diagonais descartadas e
  direção clássica próxima de **RPG Maker XP** reforçada. **CONFIRMADO como
  design; NÃO IMPLEMENTADO no motor.** Impacto: GDD §17.2.
- **D-013 · 2026-11-21** · Perfis especiais de ritmo por inimigo
  (**1C; 2B; 3C; 4C**): posição, velocidade e número de regiões POINT
  variáveis; padrões independentes para receber e executar ataques; largura
  das regiões influenciada por SP/AGI; padrão descoberto durante execução.
  **CONFIRMADO como intenção mecânica; CONTRATO NUMÉRICO PENDENTE;
  NÃO IMPLEMENTADO.** Conflito com zonas centrais fixas atuais documentado;
  não inventar fórmulas nem modificar a `COMBAT_SPEC.md` automaticamente.
  Impacto: GDD §8.1 e §21.

- **D-014 · 2026-11-21 (Rodada 2, 1E; 2A; 3A; 4A; 5C)** ·
  **CONFIRMADO como design; sem implementação nesta rodada**:
  (1E) barra de ritmo determina acerto/erro de ataques do jogador e inimigos,
  com **acerto automático do inimigo quando o jogador não pode reagir**;
  (2A) bloqueio Trave reduz dano em **50%** (já presente no código);
  (3A) sem atos não se pode bloquear/desviar;
  (4A) pausa para **escolher reação**, reflexo permanece temporizado;
  (5C) prioridade de **reações ofensivas por AGI**.
  **PENDENTES:** POINT ofensivo versus POINT defensivo quando coexistirem,
  opção voluntária de não reagir, empate de AGI e interrupção/cancelamento.
  **Impacto:** GDD §§4.1, 7.1, 8.2, 21; COMBAT_SPEC §§Atos e reações,
  Sistema de ritmo. Código, testes e demais documentos não alterados.

- **D-015 · 2026-11-21** · Precedência POINT/POINT: **a defesa prevalece** —
  ataque e defesa perfeitos resultam em 0 dano, sem crítico, Press Turn ou SP.
  **CONFIRMADO e IMPLEMENTADO.** Impacto: `BattleMath.has_contact()`,
  `battle_controller.gd`, GDD §8.2, `COMBAT_SPEC.md` §Sistema de ritmo.
- **D-016 · 2026-11-21** · Chance de crítico passa a ser
  `AGI% + clamp(ΔSP × 10%, 0%, 30%)`, limitada a 0–100%. Desvantagem de SP não
  reduz o valor abaixo do AGI; multiplicador ×1.5 inalterado. **CONFIRMADO e
  IMPLEMENTADO.** Impacto: `BattleMath.crit_chance`, `CRIT_SP_BONUS_CAP`,
  `COMBAT_SPEC.md` §Dano, GDD §5.
- **D-017 · 2026-11-21** · Uma absorção bem-sucedida **sempre elimina o alvo**
  (`current_hp = 0`), impedindo novas ações e recompensas repetidas; se for o
  último inimigo, o combate termina. **CONFIRMADO e IMPLEMENTADO.** Impacto:
  `BattleUnit.consume_by_absorption()`, `battle_controller.gd`,
  `COMBAT_SPEC.md` §Itens e absorção, GDD §10.
- **D-018 · 2026-11-21** · Os assets temporários **continuam sendo usados apenas
  como placeholder visual**; não são publicados nem substituídos nesta etapa.
  Reprodutibilidade por `assets/ASSET_MANIFEST.json` e
  `tools/setup_placeholder_assets.py`, com validação dos arquivos exigidos.
  **CONFIRMADO e IMPLEMENTADO.** Impacto: `.gitignore`, `assets/SOURCE_ASSETS.md`,
  `tests/test_asset_manifest.gd`, GDD §21.

- **D-019 · 2026-11-21 (Rodada 3, 1A; 2C; 3A; 4C; 5B; 6A)** ·
  **CONFIRMADO como design; NÃO IMPLEMENTADO nesta rodada**:
  (1A) contribuição crítica por ponto de SP menor que a vigente e teto
  crítico final **abaixo de 100%**, ambos numericamente pendentes;
  substituição parcial de D-016 apenas quanto à fórmula futura;
  (2C) dano com variação aleatória fixa **±10%**, mantendo a rolagem
  de SP `1dN` separada, em substituição à amplitude variável;
  (3A) preservar `poder × ATK ÷ DEF` e calibrar os poderes;
  (4C) preservar fontes existentes de **+1 SP** sem teto extra;
  (5B) dominância contra adversário vivo de **maior SP**, já
  presente em `BattleState.strongest_opposite()`;
  (6A) ataques inimigos garantidos quando não há possibilidade
  de reação podem obter crítico **pela chance normal**.
  **PENDENTES:** taxa crítica por SP, teto crítico, novos poderes
  e implementação da exceção de acerto da D-014.
  **Impacto:** GDD §§5.1, 8.2, 20, 21 e
  `docs/COMBAT_SPEC.md`; código, testes e arquivos locais intactos.
- **D-022 · 2026-11-21 (continuação da pergunta 1 da Rodada 3)** ·
  A exceção de acerto automático inimigo também se aplica quando o jogador
  **pode reagir e opta por não declarar reação**. O acerto é normal — sem
  crítico automático, dano máximo ou bônus extra. **CONFIRMADO e
  IMPLEMENTADO.** Impacto: `BattleController._enemy_turn()`,
  `_attack_timing()` e `_perform_attack()`, `tests/test_battle_combat.gd`,
  GDD §8.2, `COMBAT_SPEC.md` §Sistema de ritmo.

- **D-020 · 2026-11-21 (Rodada 4, 1B; 2A; 3B; 4A; 5A; 6B)** ·
  **CONFIRMADO como design; NÃO IMPLEMENTADO nesta rodada**:
  (1B) AGI define largura-base de POINT, SP ajusta por faixas;
  (2A) múltiplas zonas compartilham a cobertura POINT total;
  (3B) cobertura total de **8% a 16% do percurso**;
  (4A) cadência variável com compensação, preservando a
  duração global da barra;
  (5A) IA simula a execução temporal com erros por habilidade,
  respeitando a exceção de acerto automático da D-014;
  (6B) variação de perfil por seed de encontro reproduzível.
  **PENDENTES:** faixas e funções AGI/SP, divisão e largura
  mínima das zonas, janela temporal mínima, modelo de erro
  da IA e detalhes da seed. **Impacto:** GDD §§8.1.1, 20, 21
  e `docs/COMBAT_SPEC.md` §Sistema de ritmo. Demais documentos,
  código, testes, HUD e recursos preservados.

- **D-021 · 2026-11-21 (Rodada 5: 1B; 2B; 3B; 4B; 5A; 6B; 7A)** ·
  **CONFIRMADO como design; NÃO IMPLEMENTADO nesta rodada**:
  crítico +2 p.p./SP positivo, bônus SP máximo +20 p.p.
  e teto final 50%; cobertura POINT inicial 10%,
  ±1 p.p. por 10 AGI, ±1 p.p. por 5 SP até ±2 p.p.;
  mínimo temporal de 40 ms **por zona POINT**, com
  invalidação de perfis incompatíveis; meta de 3–5
  ataques físicos bem-sucedidos para derrotar oponente
  aproximadamente equivalente, sem bloqueio ou crítico.
  Complementa D-019/D-020 e substituiu os parâmetros de D-016.
  **Atualização posterior:** os números críticos (+2 p.p./SP,
  bônus +20 p.p., teto 50%) foram **IMPLEMENTADOS** em
  `BattleMath.crit_chance()`; os parâmetros de POINT/tempo
  seguem como design, não implementados. D-016 permanece no
  histórico como implementação anterior.
  **PENDENTES:** diferenças não múltiplas de AGI/SP,
  geração de perfis válidos, poder dos ataques e validação.
  **Impacto:** GDD §§5.2, 8.1.2, 20, 21 e
  `docs/COMBAT_SPEC.md`.

- **D-023 · 2026-11-21 (Rodada 6: 1A; 2B; 3B; 4D; 5A; 6B; 7A; 8A)** ·
  **CONFIRMADO como design; NÃO IMPLEMENTADO nesta rodada**:
  (1A) interpolação contínua de cobertura POINT:
  0,1 p.p. por ΔAGI e 0,2 p.p. por ΔSP, preservando
  os limites D-021; (2B) máximo de 3 regiões POINT;
  (3B) divisão de cobertura declarada por perfil;
  (4D) geração restrita por construção a configurações
  válidas, sem sorteio e rejeição iterativa;
  (5A) segmentos de aceleração/desaceleração com
  transições suaves e duração global mantida;
  (6B) IA com erro temporal triangular limitado,
  preservando a exceção de autoacerto D-014/D-022;
  (7A) seed de encontro combinada com IDs estáveis
  de inimigo/perfil e índice de execução; (8A)
  acerto julgado pelo instante registrado do input,
  não pela posição do último quadro.
  **PENDENTES:** viabilidade do gerador, limites de
  velocidade, parâmetros da IA, combinação de seed
  e contratos temporais de entrada.
  **Impacto:** GDD §§8.1.3, 20, 21 e
  `docs/COMBAT_SPEC.md` §Sistema de ritmo.
  D-022 já pertence à decisão aprovada e
  implementada de autoacerto sem reação; não
  houve alteração de código, testes, assets
  ou documentação fora do escopo.

- **D-024 · 2026-11-21 (Rodada 7: 1B; 2A; 3A; 4B; 5B; 6A; 7C; 8A)** ·
  **CONFIRMADO como design; NÃO IMPLEMENTADO nesta rodada**:
  (1B) pico máximo de 4× a velocidade média;
  (2A) três regiões POINT apenas com duração
  de barra ≥300 ms; (3A) amplitude do erro
  triangular da IA iniciante ±70 ms, comum
  ±40 ms e profissional ±20 ms; (4B) IA
  prioriza a região de maior tempo efetivo
  de passagem; (5B) snapshot completo de
  parâmetros resolvidos, além da seed e
  identidades D-023; (6A) relógio monotônico
  relativo ao início da barra, registrando
  instante do recebimento de input;
  (7C) ficha estatística neutra para
  calibração, **homologação separada**;
  (8A) exigir testes matemáticos,
  reprodutibilidade por seed, fronteiras,
  integração e comparação entre FPS.
  **PENDENTES:** limite de aceleração,
  prova de validade do gerador, precisão
  da API temporal, valores de referência
  e métricas/tolerâncias dos testes.
  **Impacto:** GDD §§8.1.4, 20, 21 e
  `docs/COMBAT_SPEC.md` §Sistema de ritmo.
  Preserva D-022/D-023. Nenhuma mudança de
  código, testes ou assets nesta publicação.

- **D-028 · 2026-11-21** · Os ganhos da absorção **persistem entre batalhas**
  em arquivo de save versionado (`user://exodus_progress.json`). Apenas os
  deltas de atributos são gravados; nenhuma regra nova de progressão foi
  inventada. **CONFIRMADO e IMPLEMENTADO.** Impacto: `ProgressStore`,
  `BattleController._create_units()` e `_perform_absorption()`,
  `tests/test_progress_store.gd`, GDD §10, `COMBAT_SPEC.md` §Itens e absorção.
- **D-029 · 2026-11-21** · **REVOGADA pela D-051: o criador declarou que nunca aprovou esta regra.** Dificuldade do button mashing da absorção mantida
  em **4 apertos = +1 ponto, 8 = +2, 12 = +3** (limiar fixo). **CONFIRMADO;
  nenhuma alteração de código necessária.** Impacto: `COMBAT_SPEC.md`
  §Itens e absorção.
- **D-030 · 2026-11-21** · Índice central de IDs em `docs/DECISIONS.md`: antes
  de criar decisão nova, reservar o próximo número; conflito com outra sessão
  sobe ao autor. **CONFIRMADO e IMPLEMENTADO.** Impacto: `docs/DECISIONS.md`
  e `AGENTS.md`.
- **D-025 · 2026-11-21 (Rodada 8: 1B; 2B; 3A; 4A; 5E; 6C; 7A; 8A)** ·
  **CONFIRMADO como design; NÃO IMPLEMENTADO nesta rodada**:
  (1B) bloquear validação/carregamento de encontro
  que contenha perfil sem solução válida;
  (2B) limite de aceleração `12 × v_média/T`,
  preservando velocidade máxima 4× v_média;
  (3A) fronteira exata favorece
  POINT > BEAM > MISS; (4A) tempo da barra
  começa após a escolha pausada da reação;
  (5E, ideia própria) atributos iniciais
  de todos os personagens e inimigos
  em 8 ou múltiplos de 8; Fallen
  inicia com HP 32, EN 8 e ATK/MAK/DEF/
  MEF/AGI 8, SP base derivado 80;
  (6C) AGI empatada entre ação e reação
  ofensiva: desempate por ID estável;
  (7A) reação prioritária só cancela
  ação posterior ao eliminar executor
  ou produzir interrupção explicitamente
  definida; (8A) exigir resultados
  mecânicos idênticos a 30/60/120 FPS
  com timestamps controlados.
  **PENDENTES:** estados dinâmicos de
  perfis válidos, ordem dos IDs,
  atributos específicos das outras
  criaturas, poderes e ficha neutra
  de testes da D-024. Mantidas
  D-022, D-023, D-024 e demais decisões.
  **Impacto:** GDD §§6.1, 7.2, 8.1.5,
  20, 21; `docs/COMBAT_SPEC.md`
  §§Atributos, Atos e reações e
  Sistema de ritmo; nenhuma modificação
  de código ou testes nesta publicação.

- **D-031 · 2026-11-21 (Rodada 9: 1A; 2B; 3A; 4B; 5A; 6A; 7A; 8B)** ·
  **CONFIRMADO como design; NÃO
  IMPLEMENTADO nesta rodada**:
  (1A) cada espécie possui
  ficha inicial própria com
  atributos básicos em 8
  ou múltiplos de 8 (D-025);
  (2B) referência neutra
  **independente**, com os
  mesmos valores iniciais
  de Fallen (HP 32, EN 8,
  ATK/MAK/DEF/MEF/AGI 8,
  SP_base derivado 80),
  **versionada separadamente**;
  (3A) ataque físico básico
  com **poder nominal 8**;
  (4B) variantes alternativas
  de ritmo expressamente
  declaradas e validadas,
  escolhidas antes da execução;
  (5A) ordem lexicográfica
  **crescente** de IDs estáveis
  para desempates de AGI;
  (6A) descartar input anterior
  ao início da barra e aceitar
  eventos novos desde t=0;
  (7A) IA mira o centro
  **temporal** do POINT de maior
  duração; (8B) capturar AGI/SP
  no início de cada barra e
  manter os valores até seu
  encerramento, com registro
  no snapshot de execução.
  **PENDENTES:** fichas por
  espécie, arquivo/versão
  de referência, parâmetros
  de variantes e política
  de impossibilidade dinâmica,
  definição do instante da
  captura e regras residuais
  de IDs/inputs. **Preservadas**
  D-022 a D-025 e D-028 a
  D-030. Nenhum código,
  teste ou asset alterado.
  **Impacto:** GDD §§6.2,
  7.3, 8.1.6, 20, 21;
  `docs/COMBAT_SPEC.md`;
  registro no índice canônico
  `docs/DECISIONS.md`.

- **D-032 · 2026-11-21 (Rodada 10: 1C; 2A; 3A; 4A; 5A; 6A; 7A; 8A)** ·
  **CONFIRMADO como design;
  NÃO IMPLEMENTADO nesta
  rodada**: (1C) reduzir
  influência combinada de
  AGI/SP na duração de
  50 ms por ponto para
  **50 ms por 8 pontos**,
  preservando duração-base,
  limites e congelamento
  de barra; frações de
  grupos de oito pendentes;
  (2A) preservar soma
  integral de HP, EN,
  ATK, MAK, DEF, MEF e AGI
  no SP base; (3A) três
  fichas de laboratório:
  ágil (SP 88),
  equilibrada (SP 80)
  e resistente (SP 104),
  com atributos completos
  em §6.3; (4A) metas
  frágeis 2–3, equivalentes
  3–5, resistentes 5–7
  acertos físicos;
  (5A) comprovar
  antecipadamente variante
  válida para todos os
  estados alcançáveis;
  (6A) escolher primeira
  variante elegível
  por prioridade declarada;
  (7A) snapshots JSON
  versionados independentes
  de apresentação visual;
  (8A) ao menos 95%
  de 10.000 casos controlados
  com derrota em 3–5
  acertos equivalentes.
  **Conflito preservado:**
  ficha resistente exige
  12 acertos nominais
  do ataque básico e
  não atende à meta 5–7.
  **PENDENTES:** taxa
  para diferenças
  não múltiplas de oito,
  domínio/prova de cobertura
  de variantes, esquema JSON,
  cenário estatístico e
  reconciliação do caso
  resistente. D-022–D-025,
  D-028–D-031 preservadas.
  **Impacto:** GDD §§5.3,
  6.3, 8.1.7, 20, 21;
  `docs/COMBAT_SPEC.md`;
  ID reservado e indexado
  em `docs/DECISIONS.md`.
  Nenhum código, teste,
  dado de criatura ou
  arquivo JSON alterado
  nesta rodada.

- **D-034 · 2026-11-21 (mudança de planos do diretor)** · A barra de ritmo
  passa a ter **velocidade própria e fixa de 1,0 segundo**. Diferença de AGI
  **não** altera mais a duração; ela passa a aumentar a **cobertura do POINT**
  em **+1 ponto percentual por ponto de AGI de vantagem**. O SP mantém os
  ajustes por faixa da D-021 (±1 p.p. por 5 SP, até ±2 p.p.) e a cobertura
  total respeita o limite de 8%–16% da D-023. **CONFIRMADO e IMPLEMENTADO.**
  Impacto: `BattleMath.rhythm_duration()`, `BattleMath.point_half_width()`,
  `RhythmBar.configure()`, `battle_controller.gd`, `test_battle_math.gd`,
  `COMBAT_SPEC.md` §Sistema de ritmo. Substitui a regra de duração variável
  por AGI/SP e o ajuste de largura por AGI da D-021; D-032 permanece no
  histórico como direção anterior, não executada.
- **D-033 · 2026-11-21 (Rodada 11: 1A; 2C; 3B; 4B; 5A; 6A; 7A; 8A)** · **CONFIRMADO como design; NÃO IMPLEMENTADO nesta rodada**: (1A) duração `clamp(1−0,00625×(ΔAGI+ΔSP),0,2,1)`; (2C) revisar apenas a ficha resistente de laboratório para HP 40, DEF 8 e SP_base 88, sem mudar espécies; (3B) manter `1dN` de SP e piso final de **1 dano** com contato e afinidade que permita dano, excluindo Null/Absorb; (4B) demonstrar matematicamente a cobertura integral das variantes em intervalos de estados alcançáveis; (5A) capturar AGI/SP, escolher variante válida e só então iniciar o relógio, em transição atômica; (6A) cenário neutro controlado para 10.000 casos com ±10%, Normal, sem crítico/bloqueio, meta ≥95% em 3–5 acertos; (7A) snapshots JSON com versão de esquema e versão de resolvedor distintas; (8A) testes de duelos e múltiplos inimigos cobrindo atos, reações, fraquezas, SP e duração. **PENDENTES:** implementação, testes, prova de intervalos, Moves sem dano nominal, semântica de timestamps e versões de replay. D-022–D-025 e D-028–D-032 preservadas; a ficha resistente antiga da D-032 permanece apenas no histórico. **Impacto:** GDD §§4.2, 6.4, 8.1.8, 20, 21; `docs/COMBAT_SPEC.md`; `docs/DECISIONS.md`. Nenhum código, recurso, save ou teste alterado.

- **D-035 · 2026-11-21** · A IA passa a usar a **mesma largura de POINT**
  do jogador: ataque e defesa inimigos rolam uma posição uniforme na barra e
  resolvem por `BattleMath.rhythm_zone()`. AGI e SP alteram essa largura
  conforme D-034; rolagens extras continuam dependendo apenas de SP, como
  já documentado. **CONFIRMADO e IMPLEMENTADO.** Impacto:
  `BattleController._zone_roll()`, `_ai_roll()`, `_defender_reaction()`,
  `tests/test_battle_combat.gd`, GDD §11, `COMBAT_SPEC.md` §IA.

- **D-036 · 2026-11-21 (Rodada 12: 1D; 2A; 3D; 4A; 5A; 6A; 7A; 8A)** · **CONFIRMADO como design; NÃO IMPLEMENTADO nesta rodada**: (1D) cada efeito danoso declara participação no piso mínimo; (2A) piso 1 após modificadores e arredondamento, somente com contato e afinidade válida, excluindo Null/Absorb; (3D) duas baterias resistentes separadas, com SP igual e SP 80 vs 88, sem limiar estatístico novo; (4A) domínio de estados dos limites efetivos do motor e transições permitidas, sem teto inventado; (5A) resolver eventos já comprometidos antes da captura de atributos/seleção atômica; (6A) snapshots JSON guardam tempos como inteiros em microssegundos; (7A) recusar replay exato sem versão mecânica disponível, preservando dados originais; (8A) exigir igualdade exata do rastro mecânico em 30/60/120 FPS sob inputs/seed controlados. **Precedência:** D-034 (barra fixa 1 s) e D-035 (mesma largura POINT para IA) já **IMPLEMENTADAS**, sem restaurar duração variável histórica D-033. **PENDENTES:** campos dos efeitos, proof de domínio de estados, parâmetros e limiares das baterias resistentes, precisão/quantização do relógio, ordenação de eventos e esquema dos rastros/replays. Preservadas as D-022–D-025 e D-028–D-035. **Impacto:** GDD §§4.3, 8.1.9, 20, 21 e `docs/COMBAT_SPEC.md`; índice em `docs/DECISIONS.md`. Nenhum código, save, teste ou asset modificado.

- **D-037 · 2026-11-21 (Rodada 13: 1A; 2B; 3C; 4A; 5A; 6B; 7A; 8C)** · **CONFIRMADO como design; NÃO IMPLEMENTADO nesta rodada**: (1A) travessia uniforme e fixa em 1 segundo para todo perfil, preservando D-034; (2B) IA comum preserva D-035 e IA especial usa erro temporal triangular D-023/D-024, com mesma largura POINT e autoacerto sem reação D-022; (3C) piso de 1 por **pacote mecânico de dano identificado**, associado a efeitos que declaram participação, sem multiplicação por efeito; (4A) prova de cobertura em certificados por intervalo com contraexemplo de falha; (5A) eventos mecânicos simultâneos ordenados por sequência estável atribuída no comprometimento; (6B) quantização ao microssegundo inteiro mais próximo, **política de empate ainda pendente**; (7A) rastro canônico com ID, sequência, tempo, tipo, participantes, alterações, decisões, configuração/versão e RNG necessário; (8C) **≥95%** de casos com SP igual e 5–7 acertos para resistente, mas bateria SP 80/88 **apenas diagnóstica**, sem limiar. **PENDENTES:** amostragem, política de empate de microssegundos, pacotes/identidades de efeitos, prova intervalar, esquema de trace/seed e implementação de IA temporal. **Preservadas** D-022–D-025 e D-028–D-036; D-034/D-035 seguem **IMPLEMENTADAS** no que já consta do código. **Impacto:** GDD §§4.4, 8.1.10, 20, 21; `docs/COMBAT_SPEC.md`; `docs/DECISIONS.md`. Nenhum código, teste, asset ou save modificado.

- **D-038 · 2026-11-21** · **REST / guardar ações — CONFIRMADO e IMPLEMENTADO:**
  escolher REST **não gasta ACT**, encerra a participação daquele
  personagem na rodada, guarda os atos ainda não utilizados para a próxima rodada
  (estoque até 4, respeitando D-005) e recupera **2 EN fixos**, limitado ao EN
  máximo. Não usar percentual para a recuperação concedida pelo REST nem permitir
  recuperar 2 EN repetidamente sem encerrar sua participação. Esta decisão
  **SUBSTITUI** somente o custo de um ato e a recuperação de 20% do REST
  documentados anteriormente (D-006). A regeneração automática de 20% do EN no
  fim da rodada permanece como regra separada; PASS e demais comandos não são
  modificados. **Implementado no motor Godot** por `BattleController._player_turn()`
  e `BattleUnit.recover_en_flat()`, com três testes de regressão. O HTML anterior
  permanece fora do escopo. Impacto: GDD §§4.1, 6, 7, `COMBAT_SPEC.md` e
  `docs/DECISIONS.md`.

- **D-039 · 2026-11-21 (Rodada 14: 1A; 2A; 3A; 4A; 5B; 6A; 7A; 8A)** · **CONFIRMADO como design/plano; NÃO IMPLEMENTADO nesta rodada**: (1A) quatro fases sequenciais: base temporal/testes; perfis POINT/IA especial; pacotes de dano; replay/certificados/integração; (2A) antes de mudar código, auditoria do HEAD, mapa de decisões vigentes e plano de arquivos/validação; (3A) **Resource mecânico tipado** para pacote de dano, com ID estável e efeitos individualmente associados/participantes; (4A) **sequência inteira monotônica por encontro**, associada à identidade do encontro; (5B) **empate para o inteiro par** na quantização em µs; (6A) **autoacerto D-022 tem precedência** sobre erro temporal da IA especial, sem crítico automático; (7A) resistência com SP igual: **10.000 casos, ≥95% (≥9.500)** concluídos em **5–7 ataques**, bateria SP 80/88 permanece só diagnóstica; (8A) cada fase exige **parse, testes unitários/integração, diff, fidelidade às decisões e evidência real** antes da liberação. **PENDENTES:** viabilidade/estrutura real de Moves, eventos/IDs, RNG, relógio, testes e implementação futura. **Preservadas** D-022–D-025, D-028–D-038, especialmente D-034/D-035 vigentes e D-038 (REST) fora do escopo desta sequência. **Impacto documental:** GDD §§4.5, 8.1.11, 19.1, 20 e `docs/COMBAT_SPEC.md`; índice `docs/DECISIONS.md`. Nenhum código, save, teste, asset ou Resource modificado.

- **D-040 · 2026-11-21 (Rodada 15: 1A; 2A; 3A; 4A; 5A; 6A; 7A; 8A)** · **DESIGN APROVADO; NÃO IMPLEMENTADO nesta rodada:** (1A) capturar timestamp monotônico do recebimento no handler; (2A) início do relógio e elegibilidade de input no mesmo marco t=0 após preparação atômica, sem reaproveitar confirmação; (3A) primeiro input novo e elegível resolve uma única vez, com bloqueio de `echo`/duplicidade; (4A) input com t≤1 s prevalece sobre timeout e é classificado normalmente, após deadline não elegível; (5A) linha temporal mecânica determina o progresso, renderização apenas observa; (6A) julgar com precisão capturada, arredondar para µs somente na gravação, preservar resultado; (7A) dispensar rolagem triangular no autoacerto D-022 e usar fluxos RNG separados por finalidade para não afetar dano/crítico; (8A) portão de Fase 1 exige testes de fronteiras, duplicação, pausa/ativação, timeout, 30/60/120 FPS, regressões, parse e diff. **PENDÊNCIAS:** captura efetiva no Godot, ordenação de input/timeout, fidelidade de replay em fronteiras após quantização, derivação de RNG e evidência de testes. **D-034/D-035 permanecem vigentes; D-038 (REST) preservada e fora do escopo.** Impacto documental: GDD §§8.1.12, 19.2 e 20; `docs/COMBAT_SPEC.md`; índice `docs/DECISIONS.md`. Nenhuma alteração de código ou execução de testes.

- **D-041 · 2026-11-21 (Rodada 16: 1A; 2A; 3A; 4A; 5A; 6C; 7B; 8A)** · **CONFIRMADO como design; NÃO IMPLEMENTADO nesta rodada**: (1A) `Time.get_ticks_usec()` na origem e no handler de input com verificação da API real; (2A) arbitragem por tempo mecânico e input elegível prioritário ao timeout em t=1 s, sem dependência dos callbacks; (3A) somente novas transições de tecla após ativação, sem reaproveitar confirmação nem `echo`; (4A) para replay de fronteiras, registrar instante capturado na precisão de origem disponível, limites resolvidos, resultado e versão além do µs arredondado; (5A) testes de avaliador puro com tempos injetados **e** integração de cena a 30/60/120 FPS; (6C) perfis **especiais declaram BEAM explícito** validado junto às regiões POINT, sem mudar BEAM comum; (7B) POINT total de D-034 dividido proporcionalmente por **pesos autorais** do perfil, invalidando variantes com região <4% sem fallback; (8A) streams de RNG independentes derivados de seed, IDs estáveis, perfil, índice de execução e propósito. **PENDENTES:** protocolo de eventos input/timeout, intervalos/overlaps BEAM, domínio de pesos, cobertura de estados por variantes, algoritmo/estado/versão de RNG, esquema JSON de replay e testes reais. **Preservadas** D-022–D-025 e D-028–D-040, especialmente D-034/D-035 vigentes, D-038 REST fora do escopo. **Impacto exclusivamente documental:** GDD §§8.1.13, 19.3, 20; `docs/COMBAT_SPEC.md`; `docs/DECISIONS.md`. Código, testes, recursos e saves não alterados.

- **D-042 · 2026-11-21 (Rodada 17: 1A; 2A; 3A; 4A; 5A; 6A; 7D; 8A)** · **DESIGN APROVADO; NÃO IMPLEMENTADO nesta rodada**: (1A) cobertura combinada **POINT+BEAM de 30%** para especiais, com POINT dinâmico 8%–16% (D-034) e BEAM restante 22%–14%; (2A) proibir sobreposição dos interiores dos intervalos, bordas coincidentes usam POINT>BEAM>MISS; (3A) regiões POINT separadas por intervalo não-POINT estritamente positivo, sem novo piso percentual; (4A) pesos POINT finitos, estritamente positivos e normalizados proporcionalmente, com mínimo 4% por região; (5A) centros POINT normalizados fixos, expansão simétrica e invalidação por colisão/limites; (6A) perfis especiais de ataque e defesa independentes; (7D) desempate de maior janela POINT pela **prioridade de regiões declarada**, diferente da prioridade de variantes; (8A) erro triangular da IA especial como **média de duas amostras uniformes independentes em [−L,+L]**, L de 70/40/20 ms conforme habilidade, sem amostras no autoacerto sem reação D-022. **PENDENTES:** orçamento BEAM dinâmico entre intervalos, condições de separação/overlap, viabilidade de variantes em todos os estados, tempos simulados fora da barra, esquema de RNG e testes. **D-034/D-035 preservadas e vigentes; D-038 REST verificada como IMPLEMENTADA na main atual**. Sem alteração de código/testes/assets/saves. **Impacto documental:** GDD §§8.1.14 e 20, `docs/COMBAT_SPEC.md`, índice `docs/DECISIONS.md`.

**COLISÃO DE ID RESOLVIDA:** D-043 foi usado por duas decisões diferentes; o criador decidiu manter D-043 para a fila de comandos e renumerar a reação de quem não é o alvo como **D-045**. Ambas estão registradas abaixo e indexadas em `docs/DECISIONS.md`.

- **D-045 · 2026-11-21** · **Reação de quem não é o alvo — CONFIRMADO e IMPLEMENTADO** (registrada antes como D-043; renumerada por conflito de ID, decisão do autor):
  quando um inimigo anuncia um ataque, só o personagem **atacado** pode bloquear
  (DEFEND) e mantém todos os comandos como reação (D-105: menos REST e PASS). Um aliado que **não é o alvo** não
  pode bloquear o ataque com sua reação: ela deve ser **contra-ataque (ATTACK) ou
  item/magia (ITEM)**; REST e ABSORB deixam de ser oferecidos a ele como reação.
  Implementado em `playable_controller.gd` (`_commands()`), com teste de regressão em
  `tests/verify_playable_reactions.gd`. Impacto: `COMBAT_SPEC.md` (Atos e reações) e
  `docs/DECISIONS.md`.

- **D-043 · 2026-11-21** · **Fila de comandos e ritmo de ataques encadeados**:
  o jogador pode compor previamente uma sequência que comprometa até quatro
  ACT disponíveis, com marcadores de ACT comprometidos em verde. Quando a
  sequência contém vários ataques, os reflexos usam a mesma linha sobre
  o alvo, iniciando o próximo timing após a resolução do anterior.
  **DESIGN CONFIRMADO no que é fila/visual; MOTOR NÃO ALTERADO por esta
  decisão.** O conflito de ordem foi resolvido por **D-044** (bloco
  contínuo), implementado em `BattleState.next_actor()`. Ações inválidas,
  reações durante a cadeia e detalhes de custo/compromisso seguem pendentes.
  Impacto documental: GDD §7.4 e `docs/COMBAT_SPEC.md`, índice D-043.

- **D-044 · 2026-11-21 (decisão do diretor sobre a ordem da fila D-043)** ·
  Os atos de um combatente são **executados em bloco contínuo**: o mesmo
  personagem resolve todos os atos disponíveis antes que outro combatente
  ajia. Dois atos produzem `A, A, B, B`, em vez da intercalação `A, B, A, B`.
  A ordem **entre** combatentes continua determinada por AGI.
  **CONFIRMADO e IMPLEMENTADO** em `BattleState.next_actor()`, com testes em
  `test_battle_state.gd`. Substitui apenas a intercalação de atos; não altera
  custo por comando, reações, D-005, D-038 nem fórmulas de dano/SP.
  Impacto: GDD §§1, 4.1, 7.4, 21, `COMBAT_SPEC.md` §Atos e reações.
  A fila visual com ACT verdes continua fora do motor Godot.

- **D-046 · 2026-11-21 (implementação da fila D-043 no Godot)** ·
  O Fallen pode **planejar de 1 a 4 comandos** antes da resolução. Cada ato
  comprometido acende um marcador **verde**; **UNDO** (Backspace) retira o
  último comando e **EXEC** (X) inicia a sequência. ↑/↓ navega e Z/Enter
  confirma no menu. Ataques consecutivos reutilizam a **mesma linha de ritmo**,
  com marcador reiniciado e novo julgamento de timing para cada golpe.
  **CONFIRMADO e IMPLEMENTADO** em `BattleController`, `RhythmBar` e
  `tests/test_battle_combat.gd`. Preserva D-038 (REST encerra o plano),
  D-044 (bloco contínuo) e as fórmulas vigentes. Permanecem pendentes reação
  entre passos, alvo invalidado na cadeia e mudança de ACT durante a execução.
  Impacto: GDD §7.4, `COMBAT_SPEC.md` §Atos e reações, `docs/DECISIONS.md`.

- **D-047 · 2026-11-22 (decisão do criador) — combo inimigo com número por golpe.**
  **Corrigida pela D-051:** o criador nunca aprovou que o inimigo gaste **sempre** dois
  atos em ataques independente do contexto; a IA contextual está pendente.
  O inimigo resolve **dois ataques anunciados no mesmo bloco de turno**, em vez
  de um. Cada golpe tem **anúncio próprio**, **oportunidade de reação própria**
  e **seu próprio número de dano** na camada principal de efeitos (`DamageLayer`).
  A cadeia para se o atacante cair, se o alvo cair ou se o combate terminar;
  sem reação declarada, vale a exceção de autoacerto D-022 para cada golpe.
  **CONFIRMADO e IMPLEMENTADO** em `playable_controller.gd` (`_enemy_turn()`),
  com `BattleState.skip_active_actor()` para que um jogador que reservou atos
  com REACT não trave o agendamento e faça a rodada avançar sem vez inimiga.
  Regressão em `tests/verify_playable_reactions.gd` (dois golpes, dois números).
  Preserva D-005, D-022, D-044, D-045 e todas as fórmulas de dano/SP/ritmo.
  Impacto: GDD §7.4, `COMBAT_SPEC.md` §Atos e reações, `docs/DECISIONS.md`.

- **D-048 · 2026-11-22 (decisão do criador) — Reza de Yoch, raças e renome do aliado.**
  O aliado passa a se chamar **Yoch** e é **humano**; Fallen é **demônio**. Em
  **Maesto** (mundo/cenário) há 4 raças: humanos, animais, monstros e demônios; no
  jogo há também a "raça" mecânica dos **Maziks**, os inimigos mais genéricos.
  **Reza:** humanos conjuram magias de luz rezando em vez de usar EN. **PRAY**
  (Ação ou Reação) gasta 1 ato e dá **1 PP**; Yoch não tem EN; PP fica no lugar
  da EN em `#f5f58c`, com teto de **8 PP**, e persiste entre batalhas até ser
  gasto. Magias com custo ≤ PP atuais aparecem na aba PRAY e são usadas como Ação
  ou Reação. Custo base de 1 a 4 PP; PP extra é alocado selecionando a magia já em
  fila, sem gastar ato, e alocações no mesmo alvo saem de uma vez. Magias
  iniciais: **Refuah** (2 PP, cura fixa 20 + 10/PP extra), **Haganah** (2 PP,
  escudo anti-condição de status em um aliado por 1 round inteiro, desfeito quando
  o personagem receberia uma condição; dura da conjuração até o mesmo ponto do
  round seguinte) e **Ra'am** (3 PP, 10 + 10/PP extra como base da fórmula
  mágica; sem efeito contra anjos). Nomes hebraicos no jogo;
  descrições simples em inglês no Log, com texto em `#f5f58c`. Itens abençoados
  consumíveis dão efeitos e PP quando usados no aliado (Yoch). Respostas do criador às
  ambiguidades: Haganah (não Shemirah); "Maesto" é o nome do mundo; PP persiste
  entre batalhas; Ra'am aceita alocação extra como a Refuah; +10 só por PP extra;
  liberação por PP ≥ custo; Haganah em um aliado (inclui Yoch); sem EN para Yoch;
  teto 8 PP; PRAY como Ação ou Reação; alocação extra sem ato; 1–4 é só o custo
  base; efeitos das raças ficam para depois; cada PP atual vale +2 SP para Yoch
  (8 PP = +16 SP); REST de Yoch só guarda atos; Haganah dura até o mesmo ponto do
  round seguinte. Complemento do mesmo dia: o Ra'am usa como efeito visual
  placeholder a animação **Zio** do SMT (animação 27 de `Animations.rvdata`, 7
  quadros a 15 fps, `Thunder1.png` do RTP do VX 1.02e), confirmado pelo criador
  ("ma'am" = Ra'am); destino do asset e implementação pendentes. Inimigos podem
  reagir ao PRAY e ao Ra'am, não à Refuah nem à Haganah; todos os inimigos com atos
  de reação podem reagir; um ataque de reação que acerta interrompe (PRAY: ato
  perdido, sem PP; Ra'am: ato perdido, sem efeito, PP alocados, inclusive extras, voltam ao Yoch) e
  todos os comandos seguintes da fila de Yoch se perdem com seus atos, com os PP
  alocados neles voltando ao Yoch; MISS ou bloqueio não interrompem. `Thunder1.png` do RTP segue a regra de não publicação da D-018.
  Complemento de 2026-11-23: contra o PRAY o inimigo ataca (não há contra-ataque a algo
  que não é ataque); contra-ataque ao Ra'am usa a barra dupla da D-049; o inimigo que
  interrompe ganha +1 ato por comando perdido na fila de Yoch (teto 4).
  A forma como Fallen obtém magias será
  discutida depois (absorção e elementos). **CONFIRMADO como design; NÃO
  IMPLEMENTADO** na data; **implementado no BattlePlayable em 2026-11-23** com as respostas
  do criador do mesmo dia (alvo no plano, PP ao enfileirar, Ra'am = 10 + MAK + 10/PP extra −
  MEF como o ATTACK, IA 33%, todos atacam o PRAY, qualquer contato interrompe, Yoch sem barra
  contra o ataque ao PRAY, Haganah como marca de 1 round, derrota zera PP; o efeito do Ra'am
  passa a ser escolhido entre 3 protótipos, não o Zio). Preserva D-005, D-038,
  D-018, D-044, D-046 e D-047; para o PRAY, amplia a D-045 (todos os inimigos com
  atos de reação podem reagir). Pendências no §21, item 28. Impacto: GDD §§4, 9, 9.1,
  13.1, 17, 21; `COMBAT_SPEC.md` §§Identidade, Atributos, Reza, Escopo;
  `docs/DECISIONS.md`.

- **D-049 · 2026-11-22 (decisão do criador) — contra-ataque com duas barras e interrupção.**
  **Interrupção:** um personagem é interrompido na sua ação por um ataque que sofre, seja ataque normal ou magia. Quem é interrompido **perde o ato** da ação interrompida, e a ação não acontece.
  **Contra-ataque com duas barras:** ao reagir a um ataque com contra-ataque, aparecem **duas barras de ritmo** em vez de uma. Em cima fica a do oponente, com ponteiro **vermelho** da **direita para a esquerda**. Embaixo fica a do jogador, com ponteiro **branco** da **esquerda para a direita**.
  **Ritmo:** MISS, BEAM e POINT funcionam normalmente, como dois ataques consecutivos, um de cada lado.
  **Velocidade do ponteiro do oponente:** diferente da do jogador e definida pela **AGI**. Oponente com AGI maior que a do jogador tem ponteiro vermelho **mais rápido**; com AGI menor, mais lento.
  **Interrupção perfeita:** se o jogador ou o oponente aperta na hora certa quando os dois ponteiros estão na mesma posição, a tela pisca num **impact frame**, quem foi interrompido recebe **shake** e quem interrompeu **rouba 16 SP** do outro.
  **Interrupção comum:** quem tira o **resultado melhor** (POINT > BEAM > MISS) interrompe e rouba **4 SP**, não importa quem apertou primeiro (confirmado pelo criador em 2026-11-23; ver Resolução da troca).
  **Magias:** mantêm seus efeitos normais e também usam esse sistema para causar interrupção.
  **Fila:** quem interrompe ações em fila ganha **+1 ato por comando da fila perdido**, respeitando o teto de 4 atos disponíveis da D-005 (excedente vai ao estoque).
  **Decisões anteriores:** substitui **só o cancelamento** da D-025 (7A), que cancelava apenas por eliminação ou efeito explícito. A ordem por AGI (D-014, 5C) e o desempate lexicográfico por ID (D-031) continuam valendo. A interrupção da reza da D-048 segue a mesma ideia: o ataque de reação que acerta interrompe.
  **Empate:** resultados iguais: **os dois golpes resolvem** (ambos acertam ou ambos erram), cada lado perde **só os comandos seguintes da sua fila** e **ninguém perde SP** (confirmado pelo criador em 2026-11-23; substitui a redação antiga "ambos se interrompem, perdendo os atos").
  **SP roubado:** é SP de combate, portanto **temporário**: vale até o fim da batalha, como o +1 SP por evento (GDD §5). Só o SP de absorção e de atributos é permanente (D-028).
  **Dano:** o contra-ataque **causa dano** normalmente, além de interromper.
  **Magias:** a barra dupla funciona **exatamente como nos ataques**.
  **IA:** o momento em que o inimigo aperta na barra de cima é **aleatório**.
  **Impact frame:** o **cenário pisca em branco** por **3 quadros** (~0,05 s).
  **Janela da interrupção perfeita:** os dois ponteiros a até **~2% da barra** um do outro (praticamente o cruzamento).
  **Velocidade pela AGI:** velocidade do ponteiro vermelho = velocidade base × **AGI do oponente / AGI do jogador**.
  **SP zero:** o roubo pode deixar a vítima com **0 SP**, nunca negativo.
  **Só contra-ataque:** a barra dupla aparece só no contra-ataque (e em magias, como nos ataques). DEFEND/desvio e item usam a barra única de sempre.
  **D-015 no contra-ataque:** se os dois tiram POINT, vale o **empate da D-049** (os dois golpes resolvem e **cada golpe causa seu dano**; cada lado perde só os comandos seguintes da fila; sem perder SP); a D-015 continua valendo para defesa contra ataque.
  **D-022 mantida:** sem reação declarada, o inimigo acerta automaticamente, sem barra dupla nem interrupção.
  **Shake:** treme **só o sprite/cartão** de quem foi interrompido, por **0,4 s**, com amplitude de **4 px**.
  **Resolução da troca:** os resultados são comparados (POINT > BEAM > MISS). Quem tem resultado **melhor** interrompe: o seu golpe acerta, o do outro não acontece, e ele rouba 4 SP. Com resultados **iguais**, os dois golpes resolvem (ambos acertam ou ambos erram) e cada lado perde **só os comandos seguintes da sua fila**, sem ato extra e sem SP.
  **Golpe da perfeita:** conta como **POINT**, onde quer que o alinhamento aconteça.
  **Alvo do contra-ataque:** sempre o inimigo que anunciou o ataque. Se quem contra-ataca não é o alvo anunciado (D-045) e tira resultado pior, **ele leva o dano** no lugar do alvo e perde o SP equivalente.
  **Posição das barras:** sobre o inimigo quando é o inimigo quem contra-ataca; no painel de status do jogador quando é o jogador.
  **IA:** inimigo atacado que tem ato de reação contra-ataca com **33%** de chance; senão usa a defesa atual.
  **Perfeita só em movimento:** o alinhamento só conta enquanto os dois ponteiros andam; alinhar com um ponteiro já parado não é perfeita.
  **Movimento do shake:** horizontal, alternando esquerda/direita a cada ~2 quadros (30 Hz).
  **Implementação (2026-11-22):** IMPLEMENTADO no `BattlePlayable` (`counter_rhythm_bar.gd`, `playable_controller.gd`, `playable_hud.gd`, `BattleMath.resolve_counter`), coberto por `tests/verify_playable_counter.gd` e pelos testes GUT de `test_battle_math.gd`. A perfeita encerra a troca na hora do aperto (o ponteiro do outro congela), por isso o flash e o shake saem no instante do aperto. **PENDENTE de confirmação:** quando a vítima tem menos SP que o valor do roubo, o código rouba só o que ela tem (nunca negativo).
  **IMPLEMENTADO** no BattlePlayable. Impacto: GDD §§7.2, 7.5, 21; `COMBAT_SPEC.md` §§D-025, Contra-ataque e interrupção; `docs/DECISIONS.md`.

- **D-050 · 2026-11-22 (roteiro do criador) — prólogo.** Roteiro integral em
  `docs/PROLOGUE_SCRIPT.md` (texto do criador sem edição + leitura estruturada +
  pendências). Define cutscenes de abertura, primeiro combate contra 2 inimigos com
  fichas 20/10/6/3/2/8/3 (Lunge, Bleedbuff) e 8/16/1/8/2/2/3 (Heat wave, Energy Eat),
  resgate pelo humano controlado pela IA (cura total, SP atual pela metade, combate
  reiniciado), absorção tutorial (+2 MEF; depois +2 MAK com mash; permanentes), fala de
  despedida e escolha oeste/leste. **CONFIRMADO como roteiro; NÃO IMPLEMENTADO.**
  Conflitos abertos com D-029/§10 (absorção), com as fichas do protótipo e com a
  identidade de Yoch (D-048). **Atualização pela D-051:** os conflitos com a D-029 e
  com a identidade de Yoch foram resolvidos (D-029 revogada; o humano é Yoch); resta o
  conflito das fichas com o protótipo. Impacto: GDD §14.1; `COMBAT_SPEC.md` §Prólogo;
  `docs/DECISIONS.md`.

- **D-051 · 2026-11-22 (correção do criador) — absorção por disputa de SP e respostas ao prólogo.**
  **Absorção** (revoga a D-029, que o criador nunca aprovou, e a regra antiga do §10):
  **Ganho:** baseado nos atributos do inimigo que são **múltiplos de 8** (o maior). Até **+2 em um atributo** ou **+1 e +1 em dois atributos diferentes** múltiplos de 8. Nem todo inimigo tem 8 em tudo: precisa ter **pelo menos 1 ou 2** atributos múltiplos de 8.
  **Mash como disputa de SP:** o inimigo resiste com o **SP restante dele** contra o SP do jogador. O mash rende **até 20 SP no total, em 10 apertos**. A absorção se completa quando o jogador **esgota por completo o SP do inimigo**.
  **SP baixo dos inimigos do prólogo é aceitável:** o combate começa com Fallen tendo **40 SP** (o criador confirmou que "40PP" era SP) mesmo com base 80; **só no prólogo**.
  **Fórmula da disputa (criador, 2026-11-22):** cada aperto tira **2 SP fixos** do inimigo, que **vão para o Fallen** (até 20 SP em 10 apertos, dentro de **2 s**). A cada aperto há um **sorteio**; o primeiro sucesso completa a absorção. **Corrigida pela D-103:** nada é tirado nem sorteado por aperto; o SP e um único sorteio são aplicados no resultado.
  **Chance:** base = **SP do Fallen − SP do inimigo**, em pontos percentuais, medida **uma vez no início** (diferença negativa = **0%**), mais **+1% por SP** já tirado pelo mash. Se o SP do inimigo chega a **0**, a absorção é **garantida**.
  **Falha:** se o mash acaba sem sucesso, a absorção falha, o ato é gasto e o **SP perdido pelo inimigo não volta**.
  **Atributos elegíveis:** ATK, MAK, DEF, MEF e AGI (sem HP e EN) cujo valor é múltiplo de 8. Com **dois ou mais**, **o jogador escolhe** entre +2 em um ou +1/+1 em dois; com **um**, +2 nele; com **nenhum**, o ganho vem do **maior** desses atributos.
  **HP/EN:** a absorção continua dando **+HP e +EN** do mesmo valor do ganho de atributo (como no código anterior).
  **Prólogo (D-050):** o humano do resgate é **Yoch**; o resgate é evento narrativo e
  Yoch começa a batalha com **0 PP**; "reiniciar o combate" significa Fallen
  **completamente recuperado, com HP cheio**; Lunge é **habilidade** (ataque normal todo
  mundo tem e não entra na ficha). **D-047:** o criador nunca aprovou que inimigos gastem
  **sempre** dois atos em ataques. **Absorção IMPLEMENTADA (commit `dd0813e`); o restante
  é design, NÃO IMPLEMENTADO.** Impacto: GDD §10, §14.1; `COMBAT_SPEC.md` §Itens e
  absorção, §D-047; `PROLOGUE_SCRIPT.md`; `docs/DECISIONS.md`.
- **D-052 · 2026-11-22 (decisão do criador) — VFX da absorção em letras hebraicas.** Entre
  cacos, blocos, faixas, partículas e letras, o criador aprovou as **letras hebraicas
  soltas**, pedindo letras **mais separadas (8 px)** e **20% maiores** que a versão de
  12 px. **Golpe que causa a quebra (aprovado pelo criador em 2026-11-22, protótipo
  `--hit=ringburst`):** expansão do anel com o visual do estouro, ou seja, um impacto de anime
  sem muito detalhe: 12 raios chapados **brancos**, alternando longos e curtos, que se abrem
  em anel a partir do ponto de impacto, com clarão central. O inimigo **se parte em letras
  no mesmo instante do impacto**. Há **tremor de tela**, com deslocamento aleatório a cada
  quadro e força decrescente; a borda exposta fica preta. Valores da captura aprovada: golpe
  0,35 s, tremor 6 px por 0,35 s. **Cena do mash (criador 2026-11-22):** acontece na própria
  batalha. A cada aperto saem **letras hebraicas verdes** (o verde do SP no HUD) do oponente,
  **sem desmantelá-lo**, e elas vão até a **barra de SP**. O protótipo `--mash` foi
  **aprovado pelo criador em 2026-11-23**, com 3 letras por aperto, voo de 0,6 s e chegada
  na divisa verde/vermelho da barra. **PENDENTE:** cor, tempos, trajetória e destino das
  letras da quebra, e visual da falha. **IMPLEMENTADO no jogo em 2026-11-23**
  (`scripts/battle/absorb_vfx.gd`; a animação antiga `ABSORB` do SMT saiu). Impacto: GDD §10;
  `COMBAT_SPEC.md` §Itens e absorção; `docs/DECISIONS.md`.
- **D-053 · 2026-11-23 (decisão do criador) — layout de batalha com o fundo D, sempre.**
  O criador aprovou em 2026-11-22, no protótipo `prototypes/battle-bg`, o **fundo D**: o
  céu de plasma animado, mais escuro (brilho 0,6) e 20% mais lento, com a cena fixa de
  lua, cordilheiras e chão em perspectiva por cima. Aprovou também os **inimigos 15% menores**,
  com os pés na mesma linha do chão. Em 2026-11-23 determinou que esse layout deve ser usado
  **SEMPRE a partir de agora**, no jogo e em todo protótipo e captura. **IMPLEMENTADO:**
  `PlayableController._build_ui` cria o nó `Stage` com `scenes/battle/battle_stage.gdshader`
  atrás do HUD e aplica `stage_backdrop = false` e `enemy_depth = 0.85`, com `enemy_horizon`
  no pé original. O fundo antigo desenhado pelo HUD deixa de ser usado. Impacto: GDD §17;
  `docs/DECISIONS.md`.

- **D-054 · 2026-11-23 (decisão do criador) — overworld em primeira pessoa, primeiro teste.**
  O criador definiu o overworld como **dungeon crawler** com movimento e ambientação no estilo
  Shin Megami Tensei, começando por testes. Para o teste escolheu: referência **SMT VX The
  Genesis**; render **3D real no Godot**; passo com **deslize animado de 0,15 s**; giro de 90°
  com **rotação animada de 0,15 s**; **texturas do próprio VX só no teste** (não vão para o
  jogo; a pasta de referência não é versionada); enquadramento **igual ao VX**; **labirinto de
  teste pequeno**; **automapa**; **tremor como no VX** ao andar contra a parede; **só setas, sem
  strafe**. Ajuste do mesmo dia: o passo reto ficou **30% mais lento** (0,15 s / 0,7 ≈ 0,214 s; depois, em 2026-11-23, **mais 30% mais lento**: 0,214 / 0,7 ≈ 0,306 s) e
  **segurar X corre** com o passo original de 0,15 s; o giro continua em 0,15 s. **Movimento do teste aprovado pelo criador em 2026-11-23**
  ("de resto está bom"); o visual segue em aberto. **Interface de exploração (criador, 2026-11-23):** estilo
  parecido com o HUD de batalha, porém **mais preto e branco**; painel de baixo com **status do
  grupo + nome do local**; automapa no **canto superior direito**; vista 3D com **moldura de
  linha fina**. Ambiente do teste: genérico; referência: a arte do Exodus. Visual **não
  aprovado**. **IMPLEMENTADO COMO TESTE** em `prototypes/dungeon-crawler/` (verificação
  `tests/verify_dungeon_proto.gd`, capturas `tools/capture_dungeon_proto.gd`). **Visual NÃO
  aprovado; aguarda o criador.** Escolhas do agente, tiradas do script 3D do VX e pendentes de
  confirmação: seta para baixo = meia-volta (como no VX); tela de exploração do VX (vista na
  largura toda e janela de status vazia embaixo) no lugar da moldura `999-BASE`, que no VX é
  só da batalha; escurecimento contínuo por distância; corte de visão em 5,5 tiles com a cor
  BG (10,10,10); deslize e giro lineares. §3 e §16 continuam **PENDENTES**. Impacto:
  `docs/MAP_PROTOTYPE.md`; `docs/DECISIONS.md`.

- **D-055 · 2026-11-23 (decisão do criador) — tela maior, diálogos e NPCs.**
  Motivo: deve haver muito espaço para diálogos e um Battle Log maior. **Resolução base do
  jogo inteiro: 816×624** (era 544×416, D-§17). **Manter o tamanho** de textos, sprites e painéis
  e usar a **área extra** para caixas de texto, log e vistas (não ampliar tudo 1,5×). **Battle
  Log com 3 linhas** visíveis (era 1). **Caixa de diálogo de 3 linhas, só nome e texto, sem
  retrato**; na exploração fica **sobre o painel de baixo** (cobre nome do local e status
  enquanto aberta). **NPCs na exploração como sprites no corredor 3D** (como os eventos do VX:
  menores com a distância; de frente + Z abre o diálogo), usando **assets do SMT VX, um humano e
  um demônio, só no teste**. Respostas do criador na implementação (2026-11-23): figura humana e
  demoniaca "qualquer uma" (o agente usou `Pictures/P15` e `Pictures/D_Brute Onia`); os dois no
  **corredor inicial**, um atrás do outro ((3,1) e (5,1)); **atravessáveis**. As sprites no
  corredor em perspectiva (50% e depois 1:1 no tile à frente) foram reprovadas ("MINÚSCULOS",
  "péssimos"). Referência conferida nos dados do VX: nenhum evento é desenhado no corredor 3D; a
  figura entra por "Mostrar Imagem" centrada na tela em (272, 170), 100%. **Decisão do criador:
  como o VX, 1,5×** — nada no corredor; ao falar, a figura aparece centrada sobre a vista
  (x 408, 10,5 px acima do horizonte), 1,5× o tamanho original, e some quando o diálogo fecha.
  **IMPLEMENTADO e aprovado pelo criador em 2026-11-23** ("está ótimo, podemos finalizar esta
  parte"): `project.godot` 816×624.
  Batalha (`playable_hud.gd`): fundo D (D-053) desenhado 1,5× como vista (816×447; cena 544×298
  inalterada), inimigos, textos e painéis no tamanho de antes, pés na linha do chão escalado (378);
  **Battle Log de 3 linhas** (a mais nova embaixo; explicações de menu/absorção só como linha
  temporária); status em y 540 e comando à direita (628, 540). Título: janela e fontes no mesmo
  tamanho, posições na proporção do XP na altura nova. Mapa top-down placeholder: **removido pelo
  criador** (2026-11-23); New Game abre o teste de dungeon. Corte da morte: composição do prólogo centrada, letras na tela
  toda. Diálogo (`scripts/ui/dialogue_box.gd`): 3 linhas, só nome e texto, quebra por pixels, página
  longa vira várias; na exploração, estilo P&B sobre o painel de baixo (6, 502, 804×116).
  Dungeon (`prototypes/dungeon-crawler`): parede a 1 tile 304×192, olho a 1/3, escurecimento e corte
  mantidos; vista 3D 804×490 com o horizonte no centro (y 251); fundo MP001 com a faixa preta em 1:1
  e teto/chão esticados; automapa em (676, 12); figura do NPC como `TextureRect` sobre a vista
  enquanto o diálogo está aberto. Verificação:
  `tests/verify_dungeon_proto.gd`, `tests/verify_playable_layout.gd` e demais `verify_*`.
  **Marca no automapa (criador):** o círculo do `AutoMapMarker` do VX em P&B (corpo branco, brilho
  preto), que aparece quando a célula do NPC entra na vista 3D (até 5,5 tiles, sem parede no
  caminho); na célula do jogador fica só a seta. **Figura de frente (criador, 2026-11-23, "é
  impossível saber que tem um NPC assim"):** parado com o NPC no tile logo à frente, a figura 1,5×
  centrada já aparece antes do Z; some ao andar ou girar; mais longe, só a marca no automapa.
  **Em cima do NPC (criador):** na célula dele a figura aparece (qualquer direção) e o Z fala com
  ele; se houvesse NPC na célula e à frente, vale o da célula (escolha do agente, sem caso no teste).
  **Texto do diálogo (criador, 2026-11-23, "o texto podia ser maior"):** a caixa passou de 3 linhas
  de 12 px para **2 linhas de 20 px**, com o nome no mesmo tamanho (negrito); a caixa continua do
  mesmo tamanho sobre o painel de baixo. **Pendente:** protótipos antigos (`prototypes/battle-bg`, `combat-ui`,
  `pray-vfx`, `hebrew-transition`) continuam em 544×416. Impacto: §17; `project.godot`; HUD de
  batalha; título; `prototypes/dungeon-crawler`; `docs/DECISIONS.md`.

- **D-056 · 2026-11-24 (decisão do criador) — Battle Log de 2 linhas, sem texto cortado.**
  Motivo: com o log de 3 linhas o criador via apenas uma linha e dizia que o texto estava cortado;
  pediu ``deixa duas linhas então``. **Battle Log com 2 linhas visíveis**, a mais nova embaixo.
  Nenhuma mensagem é cortada: frases longas quebram por palavra na fonte cheia (11 px) e as
  continuations ficam alinhadas sob o texto; uma mensagem antiga só sai inteira, nunca pela metade;
  o histórico é alimentado pela mensagem da batalha, então o anúncio do inimigo e a dica de reação
  aparecem juntos em vez de um apagar o outro. A escala de stretch é aplicada em tempo de execução
  (`scripts/core/layout_scale.gd`: canvas_items / keep / fractional), para que uma janela menor que
  816 px não recorte a borda direita do log nem os painéis de comando.
  A faixa do log tem 88 px de altura na tela (y 450 a 538) e as duas linhas ficam centralizadas,
  com folga idêntica acima das maiúsculas e abaixo dos descendentes (y≈474 a 516): nenhum glifo encosta na borda.
  Revoga a parte ``3 linhas`` da D-055. Impacto: `scripts/battle/playable_hud.gd`, `scripts/core/layout_scale.gd`,
  `tests/verify_playable_layout.gd`, `tests/verify_log_wrap.gd`, `project.godot`.

- **D-057 · 2026-11-25 (decisão do criador) — combate legível: fila, atos, log e papéis.**
  Motivo: o criador disse que o combate estava ``péssimo``: nunca dava para saber quem ataca,
  defende ou reage; o log era incompreensível; e a mecânica de atos falhava com várias ações num
  turno. Respostas do criador em 2026-11-25:
  - **Fila:** ao escolher 2 ou mais ações para um alvo, elas rodam **uma após a outra, sem
    confirmação**; o alvo de cada ATTACK / golpe (Lunge) / ABSORB é escolhido **ao montar a fila**
    (D-104: ABSORB saiu da fila; resolve na hora).
    Só se o alvo morrer o jogo pergunta por outro alvo; **recusar devolve o ato** (não é gasto).
    Entre os comandos da fila não há pausa de Z: a fila só espera o golpe e o número terminarem;
    a pausa do resultado vem depois do último comando (ou de uma interrupção da D-049).
  - **Afinidade nunca tira ato:** ``EU NUNCA DEFINI ROUBO DE ATO, SÓ GANHO DE ATO``. O -1 ato de
    RESIST/NULL/ABSORB (Press Turn do spec inicial) deixa de existir; WEAK continua dando +1.
  - **Turno até zerar atos:** atos que sobram depois da fila (não planejados, ganhos com WEAK ou
    devolvidos) são planejados de novo **no mesmo turno**; o turno só acaba com 0 atos ou REST
    (D-105: ou PASS).
    Substitui a parte ``se sobrar ato, ele planeja de novo quando o ciclo voltar`` da ordem de
    turnos de 2026-11-23 (a ordem por AGI entre combatentes continua).
  - **Log só com frases de evento** (inglês, como a interface): uma linha por acontecimento
    (``FOE B attacks FALLEN.``, ``FALLEN blocks: 5 damage.``, ``FOE A is down.``), sem instruções de
    tecla e sem números internos (ritmo, def, crit, afinidade, SP roll ficam só no histórico de
    diagnóstico). As explicações de menu (habilidade, reza, EN, item) e o contador da absorção
    continuam transitórios (D-055). Linhas de reza seguem em #f5f58c (D-048).
  - **Ataque básico com poder 8** (aplica a D-031 no jogo principal; o Survival segue com 10).
  - **Delegado ao agente pelo criador** (``sigo sua melhor recomendação`` / ``acha uma solução``),
    **aguardando o julgamento visual do criador**: (a) **rótulos de papel** ATTACK (vermelho),
    TARGET (escuro), DEFEND (azul), COUNTER (laranja) e REACT (verde) sobre o nome do inimigo e na
    borda de cima da janela do herói, do anúncio até a confirmação do resultado; (b) **log que não
    perde linha**: as linhas não lidas aparecem da mais antiga para a mais nova e cada Z mostra as
    seguintes antes de a batalha seguir (também antes de qualquer outra entrada do jogador).
  Impacto: `scripts/battle/playable_controller.gd`, `scripts/battle/playable_hud.gd`,
  `scripts/battle/prayer_flow.gd`, `scripts/battle/battle_controller.gd`,
  `scripts/core/battle_math.gd`, `scripts/survival/survival_battle.gd`, testes `verify_playable_*`,
  `verify_log_wrap.gd`, `test_battle_math.gd`; `docs/COMBAT_SPEC.md`, `docs/DECISIONS.md`.
- **D-058 · 2026-11-25 (decisão do criador) — de quem é o turno; reações no Battle Log.**
  Motivo: depois da D-057 o criador disse que ``ainda não tá bom, não da pra saber de quem é o
  turno direito`` e propôs que ``todas reações e defesas deviam acontecer na barra de log de
  batalha ao invés de encima do jogador``. Respostas do criador em 2026-11-25:
  - **Fila de turnos no topo:** a ordem dos turnos da rodada (a mesma ordem por AGI da
    BattleState) aparece numa faixa sob a linha do topo, com quem está agindo agora destacado.
    Quem caiu sai da faixa.
  - **Só as barras no log:** a barra de tempo da defesa e os dois trilhos do contra-ataque do herói
    rodam dentro da janela do Battle Log; o texto do log dá lugar às barras enquanto elas correm.
    O REACT/DENY continua no menu de comandos.
  - **Detalhes feitos pelo agente, aguardando o julgamento visual do criador:** fichas com o nome
    (heróis em verde, inimigos em vermelho, como a linha de SP do topo), separadas por ``›``; a ficha
    do turno atual é preenchida com a cor do lado; quem já não tem ato na rodada fica apagado.
    A barra de defesa e os trilhos ocupam a largura do log, centralizados na altura. A barra do
    ataque do jogador e os trilhos do contra-ataque do inimigo continuam sobre o inimigo (não ficam
    ``em cima do jogador``).
  Impacto: `scripts/battle/playable_hud.gd`, `scripts/battle/playable_controller.gd`, testes
  `verify_playable_feedback.gd`, `verify_playable_counter.gd`, `verify_timing_log.gd`;
  `docs/COMBAT_SPEC.md`, `docs/DECISIONS.md`.
- **D-059 · 2026-11-25 (decisão do criador) — caixas de papel com setas animadas.**
  Motivo: o criador disse que as caixas de texto ``meio que atrapalham a estetica visual do jogo``
  e pediu ``uma proposta visual de cada`` e depois vídeo (``como QUE VOU ESCOLHER SEM VIDEO``). Foram
  gravadas a mesma batalha em cinco estilos (caixas, ícones, texto solto, cor no nome, seta;
  `docs/plans/role-proposals/`). Escolha do criador: ``caixas e setas mas são setas animadas por .55
  segundos indo do atacante até o alvo, com setas se colidindo quando é um contra-ataque``; a seta
  ``some proceduralmente, perdendo opacidade bem rapido``; no contra-ataque elas se encontram ``No
  meio, faísca``.
  - As caixas ATTACK / TARGET / DEFEND / COUNTER / REACT da D-057 continuam.
  - Cada golpe: uma seta corre do atacante até o alvo em **0,55 s** e some perdendo opacidade.
  - Contra-ataque: uma seta sai do atacante e outra de quem contra-ataca; elas se encontram no meio
    em 0,55 s, uma faísca marca o choque e as duas somem.
  - **Feito pelo agente, aguardando o julgamento visual do criador:** sumiço em 0,15 s; faísca de
    0,25 s com raio 11; cores das setas (ataque vermelho, ponta na cor do papel do alvo, contra-ataque
    laranja); as setas dos heróis param na borda de cima do log para não cruzar o texto.
  Impacto: `scripts/battle/playable_hud.gd`, `scripts/battle/playable_controller.gd`, testes
  `verify_playable_feedback.gd`, `verify_playable_counter.gd`; `docs/COMBAT_SPEC.md`,
  `docs/DECISIONS.md`.
- **D-060 · 2026-11-25 (decisão do criador) — nomes coloridos no Battle Log.**
  Motivo: depois da D-059 o criador sugeriu ``a ideia das cores poderia estar no log`` e escolheu
  ``Só os nomes``: em cada frase, o nome de quem tem papel na ação ganha a cor do papel naquele
  momento — atacante vermelho, alvo amarelo, quem defende azul, quem contra-ataca laranja, quem
  reage verde (as cores das setas da D-059); o resto da frase fica como estava (linhas de reza
  continuam em #f5f58c, D-048). Linhas sem ação na tela (``FALLEN's turn.``, ``ROUND 02``) ficam sem
  cor. Impacto: `scripts/battle/playable_hud.gd`, `tests/verify_playable_feedback.gd`;
  `docs/COMBAT_SPEC.md`, `docs/DECISIONS.md`.
- **D-061 · 2026-11-25 (decisão do criador) — blocos de papel por 0,3 s.**
  Motivo: o criador pediu que ``esses blocos de attack defend e counter poderiam sumir .3 segundos
  depois de aparecerem``; respostas: ``Todos somem`` (os cinco blocos) e ``Corte seco``. Cada bloco
  aparece por 0,3 s e desaparece de uma vez. O papel continua valendo (setas da D-059, cores do log
  da D-060); um papel novo ou um novo golpe do atacante mostra o bloco de novo. Impacto:
  `scripts/battle/playable_hud.gd`, `tests/verify_playable_feedback.gd`; `docs/COMBAT_SPEC.md`,
  `docs/DECISIONS.md`. **REVOGADA pela D-102.**
- **D-100 · 2026-11-25 (pedido do criador) — letras hebraicas de SP flutuantes.**
  Motivo: o criador pediu ``faca flutuar letras ate o SP toda vez que um inimigo ganha ou jogador
  ganha SP tambem, de quem perdeu, verde e vermelho``; esclareceu ``com letras eu quero dizer letras
  hebraicas, nao valores`` e ``uma letra so aleatoria do alfabeto``. Toda mudança de SP (ganho,
  perda e roubo) faz **uma** letra hebraica aleatória (alfabeto da D-052) flutuar de quem mudou
  até o rótulo de SP do seu lado no topo (heróis à esquerda, inimigos à direita): verde no ganho,
  vermelha na perda. **Escolhas do agente, aguardando o julgamento visual do criador:** duração
  0,5 s para todas (rápido), em arco (lado e altura aleatórios) com curva de velocidade aleatória por letra, sumiço nos últimos 0,12 s, letra em 14 px, parada 7 px abaixo do rótulo. **Origem (pedido do criador):** o
  ganho de SP do herói sai do inimigo contra quem foi ganho (o atingido ou interrompido; no
  roubo, o que perdeu), no momento do ganho, e não do cartão do herói; a perda do herói sai da
  borda superior do log acima do seu cartão e o SP de inimigo sai do topo da arte dele. Impacto: `scripts/battle/playable_hud.gd`,
  `tests/verify_sp_float.gd`; `docs/COMBAT_SPEC.md`, `docs/DECISIONS.md`.

- **D-062 · 2026-11-25 (decisão do criador) — vista superior de Cafarnaum e saída para o mapa-múndi.**
  A vista superior deve mostrar uma saída para o mapa-múndi por uma travessa lateral.
  Usar obrigatoriamente o filtro **Cartucho ocre + Fita de horror** na cidade e no
  mapa-múndi e seguir uma estética visual semelhante à dos ambientes aprovados de
  Cafarnaum. A ligação jogável fica para uma etapa posterior no Godot.
  Referências de produção: [assets de Cafarnaum](../assets/generated/ambiente-e-interacoes/cafarnaum)
  com a [vista superior e saída](../assets/generated/ambiente-e-interacoes/cafarnaum/cafarnaum_vista_superior_saida.png)
  e o [shader do filtro](../prototypes/dungeon-crawler/dungeon_mixed_filter.gdshader).

- **D-063 · 2026-11-25 (aprovação visual do criador) — cratera e animação da areia da abertura.**
  O terreno de areia branca tem ladeiras que convergem no ponto de impacto, com
  vista superior e primeira pessoa desde o despertar de Fallen. O criador
  aprovou o GIF da areia que desce, levanta uma nuvem baixa e se assenta
  (“ok perfeito”). Fontes editáveis e prévias filtradas em [Cratera de areia
  branca da abertura](#cratera-de-areia-branca-da-abertura).

- **D-102 · 2026-11-25 (decisão do criador) — cartões de papel visíveis enquanto o papel existe;
  revoga a D-061.**
  Motivo: o criador pediu ``traga devolta os cartões attack defend counter, tirando a sumida de .3
  segundos (mas ainda sumindo normalmente como antes)``. Os cinco cartões (ATTACK, TARGET, DEFEND,
  COUNTER, REACT) ficam na tela enquanto o papel existe e somem como antes da D-061: quando o
  controlador limpa os papéis (resultado confirmado). As setas da D-059 e as cores do log da D-060
  não mudam. Impacto: `scripts/battle/playable_hud.gd`, `tests/verify_playable_feedback.gd`;
  `docs/COMBAT_SPEC.md`, `docs/DECISIONS.md`.
  `docs/DECISIONS.md`.
- **D-103 · 2026-11-25 (decisão do criador) — absorção resolvida no resultado.**
  Motivo: o criador pediu ``mude o sistema de absorção pra não ser a cada tecla mas sim após o
  tempo passar ou o jogador dar mash 20 vezes, no resultado``. Perguntado sobre o SP por aperto
  com 20 apertos, respondeu ``deixa 10 mashes``: o limite continua **10 apertos** (2 SP cada, até
  20 SP, D-051). Sobre o sorteio: ``Um sorteio só``. Sobre as letras verdes da D-052: ``A cada mash``.
  Regra: durante a janela de **2 s** os apertos **só contam** (e soltam as letras verdes); nada é
  tirado, dado ou sorteado por aperto. O resultado é aplicado **uma vez**, quando o tempo acaba
  ou **assim que o 10º aperto é contado**, o que vier primeiro; nenhum aperto conta depois disso.
  No resultado: SP tirado = 2 × apertos (só o que o inimigo ainda tem), que vai para o Fallen e
  não volta na falha; chance = max(0, SP do Fallen − SP do inimigo no início) + 1% por SP tirado;
  **um único sorteio**; se o SP do inimigo chega a 0 no resultado, a absorção é garantida;
  0 apertos = falha sem sorteio. O restante da D-051/D-052 (ganhos, HP/EN, contador, VFX) não
  muda. Impacto: `scripts/core/battle_math.gd` (`absorb_result` no lugar de `absorb_press`),
  `scripts/battle/battle_controller.gd`, `scripts/battle/playable_controller.gd`,
  `scripts/survival/survival_battle.gd`; testes `tests/verify_absorb_result.gd`,
  `tests/test_battle_math.gd`, `tests/test_battle_combat.gd`, `tests/verify_playable_fx.gd`;
- **D-104 · 2026-11-25 (decisão do criador) — ABSORB imediato, 2 ACT, só na ação.**
  Pedido do criador: ``faça com que o absorb seja uma ação imediata de custo 2ACT, sem colocar
  nada na fila, ocorrer na mesma hora. Além de só poder ser realizada em ação não em reação``.
  No plano do próprio turno, escolher ABSORB pede o alvo e a absorção começa na hora, gastando
  **exatamente 2 atos** antes do minigame; nada entra na fila, e os comandos já enfileirados
  (com seus alvos e marcadores) ficam como estavam e só rodam no EXEC. Depois do resultado (Z)
  o plano continua com os atos que sobraram. ABSORB **não aparece no menu de REACT** (nem para o
  atacado; a D-045 continua valendo para os outros comandos). **Menos de 2 atos livres da fila:**
  segue a regra já existente para o que custa mais do que o herói tem (habilidades do submenu
  FIGHT, criador 2026-11-23): a linha fica apagada e recusa a confirmação, sem gastar nada. Como a
  absorção resolve (fim do minigame, ganhos) não muda aqui. Substitui, para ABSORB, o custo de 1
  ato da D-038/§7 e o alvo escolhido na fila da D-057. Impacto: `scripts/battle/playable_controller.gd`,
  `scripts/battle/playable_hud.gd`; testes `verify_playable_absorb.gd`, `verify_playable_reactions.gd`;
  `docs/COMBAT_SPEC.md`, `docs/SURVIVAL_MODE.md`, `docs/DECISIONS.md`.
- **D-105 · 2026-11-25 (decisão do criador) — PASS volta; REST sai das reações.**
  Motivo: o criador escreveu ``Rest não devia fazer o jogador parar de realizar ações pelo round,
  só devia servir como um passe``; perguntado sobre a recuperação de EN, respondeu ``traga devolta
  o PASS pra servir pra passar vez sem gastar ações, deixe o REST como está no momento``. Respostas:
  quando ninguém mais tem vez e o herói passa, ``A rodada acaba``; REST ``sai das reações pra ficar
  só o pass``; PASS ``Só no turno próprio`` (não é reação); posição ``Logo antes do REST``; na fila
  ``Pode vir depois`` de outros comandos; PASS perdido numa interrupção D-049 ``Não conta`` para o
  +1 ato do inimigo; ``Fallen e Yoch`` têm PASS. Esclarecimento do criador: ``se vc tem 2 atos e
  usa 1 pra attack vc fica com 1 ato só e recebe 1 ato extra no próximo round se não reagir ou agir
  depois no mesmo round``. Regra: PASS gasta 0 ato, não dá EN/SP/PP, o herói guarda os atos para as
  vezes seguintes da rodada; a rodada acaba quando a vez volta a quem passou sem ninguém ter agido
  desde então. REST (D-038) fica igual no turno. Impacto: `scripts/battle/playable_controller.gd`,
  `tests/verify_playable_pass.gd` e testes que listavam os menus; `docs/COMBAT_SPEC.md`,
  `docs/DECISIONS.md`.
- **D-066 · 2026-11-25 (liberdade criativa dada pelo criador ao Survival) — estratos e guardiões.**
  Motivo: o criador pediu ``grandes melhorias no modo survival pra ser um roguelike bom de verdade``
  e deu ``completa liberdade criativa``; plano e referências em
  `docs/plans/2026-11-25-survival-roguelike.md`. A run do Survival passa a ter **5 estratos**; os 35
  demônios são ordenados por (tier, SP) e divididos em grupos de 7. O mais forte de cada grupo é o
  **GUARDIÃO** (HP ×1,5, +2 ATK/MAK/DEF/MEF, sempre com até 2 escoltas vivas do mesmo estrato, nunca
  elite, não persegue, espera na célula mais funda a pé e ganha moldura dourada no automapa).
  Derrotá-lo abre `DESCEND` no santuário (com confirmação); vencer o guardião do estrato 5 encerra a
  run com `SURVIVAL CLEARED`. Reforços de qualquer luta vêm do mesmo estrato e nunca são
  derrotados. Só vale no Survival. Impacto: `scripts/survival/survival_strata.gd` (novo),
  `survival_data.gd`, `survival_state.gd`, `survival_world.gd`, `survival_battle.gd`; testes
  `verify_survival_strata.gd`, `verify_survival_run.gd`.
- **D-067 · 2026-11-25 (liberdade criativa, Survival) — labirintos por estrato.** O estrato 1
  mantém o labirinto feito à mão; os estratos 2–5 usam um labirinto 25×21 gerado pela semente
  (backtracker + 35% dos becos abertos em laço), com o mesmo santuário 5×3 e a mesma célula
  inicial. Conexão total verificada por BFS em 800 labirintos. Impacto: `survival_strata.gd`,
  `survival_state.gd` (validação usa o labirinto do estrato salvo).
- **D-068 · 2026-11-25 (liberdade criativa, Survival) — cura com custo.** `HEAL` do santuário é
  grátis uma vez por estrato; depois custa 15 × estrato Macca (antes era grátis e infinito, o que
  tirava todo o atrito da run). Impacto: `survival_state.gd`, `survival_world.gd`.
- **D-069 · 2026-11-25 (liberdade criativa, Survival) — temperamentos e intenções.** Cada demônio
  tem um temperamento (BRUTE, CASTER, SUPPORT, HUNTER, TRICKSTER) que pesa a escolha entre ATAQUE e
  skills (cura só ferido; buff só sem buff ativo) e, no HUNTER, escolhe o herói com menor % de HP.
  No começo de cada rodada a 1ª ação de cada inimigo é sorteada, **mostrada acima dele** (temperamento
  e ``AÇÃO ▸ ALVO``) e executada de fato se ainda puder ser paga. Reação, defesa, contra-ataque,
  atos e REST seguem a COMBAT_SPEC sem mudança. Impacto: `survival_battle.gd` (overrides de
  `_enemy_choice`, `_player_with_most_sp`, `_enemy_turn`; camada `IntentLayer`).
- **D-070 · 2026-11-25 (liberdade criativa, Survival) — elites com efeito e saque.** Afixos com
  efeito real: BRUTAL +4 ATK, SWIFT +5 AGI, STONE afinidade RESIST e +4 DEF, BURNING ganha
  EMBER TOUCH, VAMPIRIC ganha LIFE DRAIN (somados ao +12 HP/+3 ATK/+2 MAK/+2 DEF antigos). Elite
  derrotado dá 1 relíquia; guardião dá Macca ×2 e a escolha de 1 entre 3 relíquias ao voltar ao
  mapa. Impacto: `survival_data.gd`, `survival_battle.gd`, `survival_world.gd`.
- **D-071 · 2026-11-25 (liberdade criativa, Survival) — absorção com raridade e herança.** Ofertas
  de atributo têm raridade COMMON (+1/+2), RARE (+3/+4) e EPIC (+6 ou +3/+3 em dois atributos), com
  peso que sobe por estrato; HP < 35% sobe um nível (substitui o ``+4 garantido``). A 1ª oferta de
  atributo é um dos 2 atributos mais fortes do demônio (herança). HP máximo (+6/+10/+16) e EN máximo
  (+3/+5/+8) entram no sorteio. 25% das ofertas trazem uma opção ``YOCH +n`` (ganhos próprios da
  Yoch, salvos na run). Os 30% de skill continuam. Impacto: `survival_absorb.gd`,
  `survival_battle.gd`, `survival_state.gd`.
- **D-072 · 2026-11-25 (liberdade criativa, Survival) — itens e loja.** Novos consumíveis:
  MEDICINE (+50 HP), SOMA (HP e EN/PP cheios), BLAST STONE (18 de dano fixo num inimigo). A loja
  vira o painel `SHOP` com BEAD e CHAKRA sempre, 2 dos 3 novos itens por estrato e 1 relíquia à
  venda; preços sobem 15% por estrato. Item em alvo cheio continua recusado sem gasto. Impacto:
  `survival_data.gd`, `survival_state.gd`, `survival_world.gd`, `survival_battle.gd`.
- **D-073 · 2026-11-25 (liberdade criativa, Survival) — relíquias com efeito e pactos.** A run
  começa com **1** relíquia inicial sorteada pela semente (antes 6). Entram 11 relíquias de efeito
  (Macca +50%, 4 opções de absorção, +25% de chance de skill, cura de 15 pós-vitória, +1 estágio de
  ATK na abertura, +2 PP da Yoch, itens +50%, imunidade a queimadura, skills identificadas, loja −25%,
  +4 ATK/MAK contra elite/guardião) e 7 **pactos**: pares no mesmo aliado que liberam um terceiro
  efeito (WRATH, PROPHECY, BASTION, EXODUS, BLOOD PACT, MAMMON, REVELATION). Continua o limite de 2
  relíquias por aliado. Corrige o validador do save, que recusava a run quando a relíquia de HP
  deixava o HP atual acima do máximo base. Impacto: `survival_relics.gd`, `survival_state.gd`,
  `survival_world.gd`, `survival_battle.gd`.
- **D-074 · 2026-11-25 (liberdade criativa, Survival) — eventos.** 3 eventos por estrato em células
  da semente, mostrados como figuras SMT no corredor e marcados no automapa como NPC (só no teste,
  como o atendente, D-018): BLOOD ALTAR (−25% do HP máximo → relíquia; recusa se mataria),
  WANDERING SPIRIT (descanso +50% HP ou −15 HP por +2 num atributo), HOODED ORACLE (skill por Macca ou
  aposta +3 atributo / −30 HP) e FROST MERCHANT (relíquia com 20% de desconto). Evento usado some;
  LEAVE mantém. Impacto: `survival_data.gd`, `survival_strata.gd`, `survival_world.gd`.
- **D-075 · 2026-11-25 (liberdade criativa, Survival) — OMEN, CODEX e score.** OMEN 0–5
  (dificuldade empilhada, escolhida no santuário só antes da 1ª luta; vencer no nível n libera o
  n+1): (1) inimigos +15% HP, (2) HEAL nunca grátis, (3) elites 35%, (4) 2 continues, (5) guardiões
  +3 ATK/MAK. CODEX guarda os demônios derrotados em qualquer run. Score novo: derrotados×100 +
  estrato×300 + guardiões×250 + Macca/2 + continues×100, ×(1 + 0,2×OMEN). Impacto:
  `survival_meta.gd`, `survival_world.gd`, `survival_state.gd`.
- **D-076 · 2026-11-25 (liberdade criativa, Survival) — save da run v2.** Versão 2 com migração da
  v1 (campos novos com padrão; run v1 mantém as 6 relíquias que já tinha e continua no estrato 1);
  validação de relíquias, itens, ganhos da Yoch, estrato, OMEN e célula no labirinto do estrato.
  Impacto: `survival_state.gd`, `verify_survival_strata.gd`.
- **D-101 · 2026-11-25 (decisão do criador) — SP parecido no Survival.**
  Motivo: o criador disse que o protagonista era ``mil vezes mais forte do que deveria`` e que os
  stats dos personagens não tinham sido corrigidos. Medição com a fórmula real: o dano soma um
  sorteio de até a diferença de SP, e o SP é a soma dos sete atributos; a ficha antiga (HP 140, EN
  32: SP 205) contra inimigos de SP 59 a 139 fazia o Fallen matar os tiers 1 a 4 em menos de 1
  golpe e ignorar 65 a 72% dos golpes inimigos. Escolha do criador: ``SP parecido, estilo D-032``
  e ``Inimigos acompanham o herói``. Regra: ficha inicial do Fallen = média dos 7 inimigos do
  estrato 1 (HP 26, EN 12, ATK 7, MAK 7, DEF 6, MEF 6, AGI 9; SP 73 contra 72) e da Yoch na
  proporção que tem no jogo base (HP 17, EN 0, ATK 8, MAK 3, DEF 6, MEF 3, AGI 8). Ao começar cada
  batalha o inimigo recebe (ou perde) a diferença entre o SP atual do Fallen e o SP esperado no
  estrato (média dos inimigos dele), repartida pelos sete atributos na proporção que ele já tem
  (nunca abaixo de metade do próprio SP; EN 0 continua 0); guardião, elite e OMEN somam depois.
  **Escolhas do agente, aguardando o criador:** a ficha derivada da média do estrato 1, a
  repartição proporcional e valer nos dois sentidos (herói abaixo do esperado enfraquece os
  inimigos). **Não alterado, pendente:** BEAD +20 HP, MEDICINE +50 HP e CHAKRA +10 EN continuam
  nos valores da ficha antiga (BEAD cura 77% do HP inicial). Impacto: `survival_data.gd`,
  `survival_strata.gd`, `survival_battle.gd`, `tests/verify_survival_balance.gd`;
  `docs/SURVIVAL_MODE.md`, `docs/DECISIONS.md`.
- **D-108 · 2026-11-25 (decisão do criador) — Desvantagem de SP não tira dano; variação fixa ±10%.**
  Motivo: o criador disse ``tira isso de NUNCA causar dano a inimigos com alta defesa, é impossível
  jogar assim``. Medição (golpe básico do survival, poder 10, herói no SP esperado de cada estrato):
  o dano base `poder × ATK ÷ DEF` fica entre 3 e 20, e a desvantagem de SP subtraía um sorteio de 1
  até ΔSP; com a variação de ±10% + 2% por ponto de ΔSP, o golpe do Fallen dava 0 em 61 a 83% das
  vezes contra Oni, Garuda, Succubus, Chimera, High Pixie, Nekomata, Incubus, Ganesha, Lakshmi, Hel,
  Pazuzu e Beelzebub (40 a 46% contra Pyro Jack, Vampire e Loki). Escolhas do criador, uma por
  pergunta: ``Só a vantagem soma``; ``Jogo todo``; e ``Sim, ±10% fixo`` (implementar a D-019, que
  estava aprovada e não implementada; sem ela o Beelzebub ainda zerava 10% dos golpes).
  Regra: `BattleMath.sp_bonus_roll` soma `1d(ΔSP)` só quando o atacante tem mais SP; com SP igual ou
  menor não há sorteio nem desconto. A variação é `±BASE_VARIATION` (10%) sempre. Vale para o
  ataque, a magia (`physical_damage`) e o Ra'am da Yoch (`PrayerBook.raam_damage`), na campanha, na
  dungeon e no survival. Afinidade NULL/ABSORB continua dando 0 (não mudou). Resultado medido: 0%
  de golpes de 0 nos dois sentidos contra os 35 inimigos do survival, com guardião, elite e OMEN 0 e
  5. Substitui a regra "subtrai se tem menos" da COMBAT_SPEC e o item 3B (piso de 1), que fica sem
  efeito. Impacto: `scripts/core/battle_math.gd`, `scripts/core/prayer_book.gd`,
  `tests/test_battle_math.gd`, `tests/verify_survival_balance.gd`, `tools/measure_zero_damage.gd`;
  `docs/COMBAT_SPEC.md`, `docs/SURVIVAL_MODE.md`, `docs/DECISIONS.md`.
- **D-109 · 2026-11-25 (decisão do criador) — Todo golpe com barra acerta; marcos 50/80/100%.**
  Pedido: ``para com ataques normais, só ocorrer desvio de verdade se o alvo reagir defendendo ao
  custo de 1ACT, não mais sempre, no caso, sempre causa dano, com marco branco 50%, marco cinza 80%
  e marco amarelo 100%``. Respostas do criador, uma por pergunta: marcos = ``Pontas, laterais,
  centro``; cores da barra = ``Não, só a regra``; defesa = ``Manter como hoje``; inimigos = ``Sim,
  para todos``; alcance = ``Todo golpe com barra``; ataque cinza + defesa lateral = ``Só a defesa:
  50%``; ACT da IA = ``Paga sempre que defende``; golpe branco = ``Sim, conta tudo``.
  Regra: `BattleMath.has_contact` só é falso com defesa no centro; `strike_multiplier` dá 1,0 / 0,8
  / 0,5 pelo marco do ataque, ou 0,5 se a defesa parou na lateral; `scaled_damage` arredonda (o
  arredondamento é escolha do agente, para um golpe de 1 não virar 0). `_defender_reaction` e
  `_skill_defense_timing` gastam 1 ACT do inimigo antes de rolar a defesa. Consequências
  diretas, aguardando o criador: o golpe do inimigo no PRAY sempre interrompe a reza (antes só
  quando não errava); o empate de contra-ataque na trilha branca faz os dois acertarem 50%; o
  inimigo com ACT sempre defende e por isso sempre perde 1 ACT ao ser atacado. Cues `MISS` e a frase
  "X misses." deixam de aparecer em golpes. Impacto: `battle_math.gd`, `battle_controller.gd`,
  `playable_controller.gd`, `prayer_flow.gd`; testes `test_battle_math`, `test_battle_combat`,
  `verify_playable_feedback/fx/prayer/reactions/skills`; `docs/COMBAT_SPEC.md`,
  `docs/DECISIONS.md`.

Decisões anteriores de combate (atos, reações, SP, Press Turn, ritmo, absorção, itens,
escopo do protótipo) foram aprovadas em rodadas anteriores e estão registradas em
`docs/COMBAT_SPEC.md`. Este apêndice não as duplica.

- **D-106 · 2026-11-25 (decisão do criador) — rework das habilidades do Survival.**
  Motivo: o criador pediu um rework com ``Identidade única para aqueles que não fui eu quem
  criou`` e ``Só o survival``, aprovou a proposta (`docs/plans/2026-11-25-survival-skills-rework.md`)
  com ``só muda os nomes que não fazem sentido com os efeitos equivalentes``. As 27 habilidades do
  pool ganham um efeito que nenhuma outra tem (SkillBook ``fx``, regras em `scripts/core/skill_fx.gd`):
  SHADOW BITE rouba SP, SOUL PIERCE ignora metade da DEF, FROST LANCE esfria (CHILL), STONE GRASP
  prende (SNARE), TWIN FANG combo, FANG FLURRY sangramento acumulável, BLADE DANCE poder crescente,
  HEAVY CRUSH quebra DEF, FINISHING BLOW executa abaixo de 40% de HP, PIXIE DUST sono, SOUL LEECH
  cura por golpe, SPIRIT BRAND marca, EMBER BURST detona a queimadura, HELLFIRE queimadura de 5
  rodadas, FROST BREATH lentidão, VENOM CLOUD enfraquece, MIND DRAIN drena EN, CURSE RAY drena SP,
  THUNDER CALL 1 ou 2 raios, VOID GAZE inesquivável, MEND limpa estados, DARK BOON cura um aliado,
  LIFE DRAIN cura pelo dano, RENEW regenera 3 rodadas, HOWL taunt, PRIMAL ROAR berserk e WAR CRY
  reforça a equipe. Renomeadas: SPIRIT WAVE -> SOUL LEECH, SPIRIT BOLT -> SPIRIT BRAND, EMBER TOUCH ->
  EMBER BURST, MIND BLAST -> MIND DRAIN, CRUSHING BLOW -> FINISHING BLOW, DARK SIPHON -> DARK BOON.
  **Escolhas do agente, aguardando o criador:** os valores dos efeitos (25%, 2 rodadas, 3 EN etc.) e
  a queimadura removida de PIXIE DUST, VENOM CLOUD, CURSE RAY e THUNDER CALL. Não alterado: LUNGE,
  BLEEDBUFF, HEAT WAVE, ENERGY EAT e as rezas da Yoch. Impacto: `skill_book.gd`, `skill_fx.gd`,
  `battle_unit.gd`, `battle_state.gd`, `battle_controller.gd`, `playable_controller.gd`,
  `survival_battle.gd`, `survival_data.gd`, `tests/verify_skill_fx.gd`; `docs/SURVIVAL_MODE.md`,
  `docs/DECISIONS.md`.

- **D-107 · 2026-11-25 (decisão do criador) — grupos de humanos e rezas inimigas.**
  Motivo: o criador pediu humanos como inimigos que rezam, com rezas próprias ``HOLY e com nomes
  hebraicos``. Respostas: ``Maziks não se juntam com humanos, humanos lutam em grupos de humanos e
  maziks em grupos de maziks``, ``1 grupo por estrato``, ``só humanos normais, sem lore nem nada``,
  HOLY ``ignora`` (sem efeito mecânico), humanos ``com PP como a Yoch``, humanos ``não são
  absorvíveis``, as rezas da Yoch ``não mudam``, arte = ``modelo de NPC humano`` do jogo (P15, depois P10 e P19 para variar) e, por correção do criador, ``só maziks são silhuetas``: humanos usam a arte colorida e não têm sombra no chão. As 3
  rezas foram desenhadas pelo criador: **SANVERIM** (2 PP) cegueira de luz até o fim do próximo round,
  o alvo erra mais (zona de acerto menor); **NECHAMAH** (1 PP) cura 5 HP por round durante 3 rounds,
  como o oposto da queimadura (acumula); **CHEREV** (3 PP; grafado inicialmente CHERAV, corrigido para a transliteração de חֶרֶב, id interno `cherav`) dano em área, um corte de luz, 10 + MAK −
  MEF (a fórmula do Ra'am) em todos os heróis. Nomes aprovados pelo criador. Os humanos usam também
  PRAY (+1 PP, +2 SP, 1 ato). **Escolhas do agente, aguardando o criador:** 3 humanos por grupo, todos
  com as 3 rezas, atributos = SP esperado do estrato repartido (HP 38%, MAK 16%, ATK/DEF/AGI 12%, MEF
  10%, sem EN) e ajustados ao SP do Fallen (D-101), a cegueira reduz a zona de acerto à metade, a IA
  (PRAY enquanto tem pouco PP, NECHAMAH só com aliado ferido, SANVERIM só com herói enxergando),
  a cura em quem tem menos HP, e a reza resolver na hora (sem reação dos heróis e sem cast lento).
  **Não alterado:** Refuah, Haganah e Ra'am da Yoch. Impacto: `skill_book.gd`, `skill_fx.gd`,
  `battle_unit.gd`, `battle_math.gd`, `battle_controller.gd`, `playable_controller.gd`,
  `survival_battle.gd`, `survival_data.gd`, `survival_strata.gd`, `survival_state.gd`,
  `survival_meta.gd`, `tests/verify_human_groups.gd`; `docs/SURVIVAL_MODE.md`, `docs/DECISIONS.md`.

- **D-112 · 2026-11-26 (decisão do criador) — cinco novas rezas em hebraico.**
  O criador aprovou e especificou 5 novas rezas para o sistema de Reza (D-048 / D-107 / D-111):
  - **Tahorah** (`טָהֳרָה`, 2 PP / 1 ACT): limpa condições negativas (queimaduras, sangramentos e debuffs) de um aliado.
  - **Magen** (`מָגֵן`, 2 PP / 2 ACT): aumenta a defesa física de todos os aliados em +1 estágio (+25% DEF física) até o fim do próximo round.
  - **Gevurah** (`גְּבוּרָה`, 1 PP / 1 ACT): aumenta o dano do próximo ataque do aliado escolhido em 15% + 5% por PP extra alocado.
  - **Mishpat** (`מִשְׁפָּט`, 2 PP / 2 ACT): causa dano em um inimigo igual ao dano que ele causou em sua última ação + 15.
  - **Zohar** (`זֹהַר`, 3 PP / 1 ACT): alarga a zona POINT da barra de ritmo de um aliado até o fim do próximo round (contraponto ao Sanverim).
  **Implementado** no catálogo canônico `PrayerBook`, `prayer_flow.gd`, `pray_fx.gd`, `battle_unit.gd`, `skill_fx.gd`, `battle_math.gd`, `battle_controller.gd`, `playable_controller.gd` e no pool humano de `survival_allies.gd` (as 3 rezas iniciais do Yoch na campanha continuam `Refuah`, `Haganah` e `Ra'am`). **VFX 100% letras aprovados pelo criador (2026-11-26) e implementados em `pray_fx.gd`** (removidos círculos, arcos, polylines e bordas geométricas de todos os efeitos de reza, inclusive Ra'am e Haganah): Tahorah (fileira horizontal de letras + `טהרה` subindo e convertendo glifos vermelhos em `#f5f58c`), Magen (grade descendente com `מגן` + marca persistente `מ` pulsando), Gevurah (colapso espiral + anel formado puramente por 16 letras + marca `ג` vibrando), Mishpat (letras vermelhas de retribuição em arco até o alvo + paredes de letras fechando com `משפט`, impact frame, shake e queda até o chão) e Zohar (`זוהר` abrindo em dois feixes horizontais + marca `ז`). Cobertura: `tests/verify_new_prayers.gd`.
  **Escolhas do agente, aguardando o criador:** multiplicador da zona POINT do Zohar (`×1,5`, limitado a 90% de `BEAM_HALF_WIDTH`), estágio de DEF física do Magen igual ao estágio de ATK (`+25%`), Tahorah focado em limpar condições negativas de 1 aliado (não dissipa buffs inimigos ainda), Mishpat como dano direto sem barra de ritmo/reação inimiga/exceção contra anjos.

- **D-113 · 2026-11-26 (decisão do criador) — regra obrigatória de VFX de letras hebraicas para todas as rezas.**
  Todos os efeitos de reza do jogo (atuais e futuros, campanha e Survival, heróis e inimigos humanos) devem **obrigatoriamente** possuir efeitos visuais compostos por letras hebraicas (`scripts/battle/pray_fx.gd`), sem geometria estrangeira substituindo os glifos, e com marca hebraica persistente sempre que a reza mantiver estado ativo por rodadas ou até a próxima ação. Documento dedicado com princípios, tabela de cobertura das 11 rezas atuais e critério de aceitação: `docs/PRAYER_VFX_RULE.md`. Impacto: `docs/PRAYER_VFX_RULE.md`, `docs/DECISIONS.md`, `docs/GDD.md`, `scripts/battle/pray_fx.gd`.

- **D-115 · 2026-11-26 (decisão do criador) — todas as 11 rezas criadas são canônicas.**
  O criador confirmou que todas as rezas criadas até o momento (`Refuah`, `Haganah`, `Ra'am` da D-048; `Sanverim`, `Nechamah`, `Cherev` da D-107; e `Tahorah`, `Magen`, `Gevurah`, `Mishpat`, `Zohar` da D-112) vão para o **jogo canônico**, deixando de existir qualquer reza exclusiva do modo Survival. Todas seguem unificadas em `scripts/core/prayer_book.gd` e sujeitas à regra de VFX hebraico (D-113). **PENDENTE:** como/quando essas rezas entram ou são distribuídas ao longo da campanha (as 3 rezas iniciais do Yoch permanecem `Refuah`, `Haganah` e `Ra'am`). Impacto: `docs/DECISIONS.md`, `docs/GDD.md` (§9.1 e Apêndice A), `docs/COMBAT_SPEC.md` (§Reza).
