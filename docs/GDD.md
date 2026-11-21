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

Turnos intercalados, ações e reações, reflexos, atos armazenáveis e Superiority Points.
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
- Formato: turnos intercalados com Ação e Reação; ordem por AGI; até 4 inimigos;
  protagonista + 1 aliado no protótipo. **CONFIRMADO**.
- Protótipo atual: cena `res://scenes/battle/Battle.tscn`, dois inimigos genéricos e
  um aliado placeholder. **IMPLEMENTADO**; interface em inglês. **CONFIRMADO**.
- Fundo plano `#333333` — **SUBSTITUÍDO** localmente por battleback e janelas inspiradas
  em RPG Maker VX Ace. Essa substituição ainda **não foi publicada**. A validação visual
  pertence ao diretor.

### 4.1 Divergências da auditoria — estado atual

| ID | Gravidade | Achado | Estado |
|---|---|---|---|
| A-01 | CRÍTICO | `next_actor()` oferecia cada unidade uma única vez por rodada. | **CORRIGIDO:** passagens intercaladas por AGI; atos consumidos por ações e reações; 12 testes de estado. |
| A-02 | ALTO | Limiar literal `SP_atual > 0,7 × SP_rival` premiava ambos os lados. | **CORRIGIDO:** D-007 substitui por dominância em razão. |
| A-03 | MÉDIO | Reação do jogador não era utilizável para defesa; ataques inimigos exigiam entrada manual. | **CORRIGIDO:** entrada manual apenas para personagens do jogador; IA resolve seus próprios tempos; defesa manual exige reação declarada e 1 ato. |
| A-04 | MÉDIO | IA não tinha resolução própria de ritmo. | **IMPLEMENTADO como execução provisória:** mesmas zonas POINT/BEAM/MISS com tentativas extras por vantagem; sem nova regra de design. |
| A-05 | MÉDIO | Trave = 50% de dano, sem registro documental. | **HOMOLOGADO pela D-014 (2A):** bloqueio Trave reduz 50% do dano, comportamento já presente no código. |
| A-06 | MÉDIO | Descanso consumia 2 atos. | **CORRIGIDO:** 1 ato, gasto antes da escolha do comando; teste de regressão. |
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
EN é usado para conjuração e se recupera no fim da rodada: 20% do máximo. Descanso:
+20% do máximo ao abrir mão de um ato. Mapeamento dos `.rvdata`: `LUK → AGI`,
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
inclusive mirando outro aliado. Todos os comandos podem ser Reação; inimigos também
reagem. Atos não usados podem ser armazenados até 4 para a próxima rodada.

**D-005:** teto de **4 atos disponíveis no total** por personagem, somando atos novos,
armazenados e bônus de SP/Press Turn; aplica-se a Fallen, aliados e inimigos.
**IMPLEMENTADO:** excedente é **adiado** ao estoque (máximo 4) e pode voltar em rodada
posterior. Substitui a soma de até 4 armazenados com 2 novos simultaneamente.

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
  nem define seus tipos; continuam pendentes a semântica
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

## 9. Magia, elementos, oração e afinidades — **PENDENTE**

O diretor confirmou que magia, oração humana, elementos e afinidades são partes
importantes do sistema, mas o protótipo atual os exclui explicitamente. Nomes de
elementos e regras de oração foram mencionados em conversa anterior e **não** devem
ser tratados como regras oficiais sem confirmação documental neste GDD.

---

## 10. Absorção e progressão sem níveis — **CONFIRMADO (conceito)**

Fallen absorve adversários; ganha 1–3 pontos do maior atributo do inimigo (exceto
EN/SP/HP), mais pontos de SP base, HP e EN. Realizada por button mashing, mais fácil
quanto maior a superioridade do jogador. **D-017:** a absorção bem-sucedida
elimina o alvo. Detalhes em `docs/COMBAT_SPEC.md`.
Ambiguidade pendente em A-07. Implementação atual é protótipo, sem o sistema completo
de mashing escalonado.

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
aprovados para os três reis magos, Herodes, a figura equivalente a Jesus, anjos,
aliados ou demônios específicos. Nenhuma facção foi formalizada.

---

## 14. Narrativa, história, temas e estrutura dramática — **PENDENTE além da premissa**

A premissa do §1.1 está **CONFIRMADO**. A promessa de Fallen a THÉOS, a queda, o mar
de areia branca e o céu vermelho-escuro são fatos canônicos até nova decisão.
Ato, cena, arco, final, consequências das escolhas e a relação entre Fallen e as
figuras bíblicas reimaginadas permanecem sem decisão.

---

## 15. Cosmologia e teologia — **PENDENTE**

THÉOS existe como entidade citada na promessa de Fallen. Atributos, hierarquia
celestial, natureza dos anjos, relação entre céu, areia e superioridade: **PENDENTE**.
Nenhuma definição foi inventada neste GDD.

---

## 16. Regiões, ambientes e level design — **PENDENTE**

Imagens confirmadas: mar de areia branca, lugar desolado, céu vermelho-escuro.
Localizações nomeadas, geografia, hubs, dungeons e regras de exploração: **PENDENTE**.

---

## 17. Direção de arte, HUD, UX e acessibilidade — **CONFIRMADO / PENDENTE**

- Resolução base 544×416, visão frontal, filtro de textura nearest. **CONFIRMADO** em ambiente.
- HUD em janelas inspiradas em RPG Maker VX Ace, com battleback, sprites de inimigos,
  retratos, barras HP/EN e barra vertical de SP. **IMPLEMENTADO localmente**, ainda não
  publicado e ainda não julgado pelo diretor.
- Decisão do diretor em 2026-11-21: substituir todos os assets da fangame por
  placeholders próprios na cena de batalha. **CONFIRMADO como decisão**;
  **implementação pendente — não executada nesta entrega**.
- Idioma da UI: inglês. **CONFIRMADO**.
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
  inimigos com nome e HP discretos, com destaque do alvo; painéis de **Fallen e Ally
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
- **Defesa:** a barra aparece **dentro do painel de Fallen ou Ally que está sendo
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
  Ally, inclusive em mockups. A restrição mecânica já consta do código e da
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
- **D-029 · 2026-11-21** · Dificuldade do button mashing da absorção mantida
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

Decisões anteriores de combate (atos, reações, SP, Press Turn, ritmo, absorção, itens,
escopo do protótipo) foram aprovadas em rodadas anteriores e estão registradas em
`docs/COMBAT_SPEC.md`. Este apêndice não as duplica.
