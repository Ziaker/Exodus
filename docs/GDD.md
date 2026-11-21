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

### 5.2 D-021 — calibração crítica aprovada na Rodada 5 — **NÃO IMPLEMENTADO**

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

**Rastreabilidade:** D-021 quantifica a direção da D-019 e substitui
os parâmetros da D-016 **como design futuro**. A implementação atual
ainda usa +10 p.p./SP, bônus máximo +30 p.p. e teto final 100%;
a D-016 deve permanecer no histórico, sem ser reclassificada como
não executada. A variação de dano fixada pela D-019 em ±10%
também permanece pendente de implementação.

---

## 6. Atributos e recursos — **CONFIRMADO**

HP, EN (Energy Points), ATK, MAK (magic attack), DEF, MEF (magic defense), AGI e SP.
EN é usado para conjuração e se recupera no fim da rodada: 20% do máximo. Descanso:
+20% do máximo ao abrir mão de um ato. Mapeamento dos `.rvdata`: `LUK → AGI`,
`MAT → MAK`, `MDF → MEF`. Detalhes em `docs/COMBAT_SPEC.md`.

---

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

### 8.1.2 D-021 — largura e tempo POINT — **CONFIRMADO como design; NÃO IMPLEMENTADO**

**4B:** largura-base da **cobertura total POINT = 10% da linha**;
ajustar **±1 ponto percentual a cada 10 pontos de diferença de AGI**,
a favor do executante com maior AGI.

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

### 8.2 Autoridade da barra e bloqueio — Rodada 2 (D-014) — **CONFIRMADO como design**

- **1E (ideia própria):** a **barra de ritmo determina acerto ou erro do
  ataque**, tanto do jogador como do inimigo. **Exceção explícita:** um
  ataque inimigo **sempre acerta quando o jogador não pode reagir**.
  Essa garantia se refere ao **acerto**, não é aprovação para dano máximo,
  crítico obrigatório ou modificação de afinidade.
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
    Novas fórmulas e poderes ainda **não implementados**.
13. **D-020 (Rodada 4):** perfis especiais de ritmo aprovados como design
    em §8.1.1 e na especificação técnica, **NÃO IMPLEMENTADOS**.
    Contratos pendentes: largura-base por AGI, faixas de SP,
    mínimos temporais das zonas, distribuição em múltiplos POINT,
    perfil de erro temporal da IA e derivação/reprodução da seed.
    O risco crítico é a janela útil subquadro em durações curtas.

---

14. **D-021 — Rodada 5:** números críticos (+2 p.p./SP, máximo
    +20 p.p., teto total 50%); largura POINT base 10%,
    ajustes ±1 p.p./10 AGI e ±1 p.p./5 SP (até ±2 p.p.);
    mínimo de 40 ms por região POINT; objetivo de 3–5
    ataques físicos bem-sucedidos contra equivalentes.
    **Design aprovado; não implementado.** Pendentes:
    arredondamento, seleção de perfis válidos e poderes.

---

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
  Complementa D-019/D-020 e substitui parâmetros de D-016
  apenas como **design futuro**; D-016 ainda está implementada.
  **PENDENTES:** diferenças não múltiplas de AGI/SP,
  geração de perfis válidos, poder dos ataques e validação.
  **Impacto:** GDD §§5.2, 8.1.2, 20, 21 e
  `docs/COMBAT_SPEC.md`; código, testes, assets intactos.

Decisões anteriores de combate (atos, reações, SP, Press Turn, ritmo, absorção, itens,
escopo do protótipo) foram aprovadas em rodadas anteriores e estão registradas em
`docs/COMBAT_SPEC.md`. Este apêndice não as duplica.
