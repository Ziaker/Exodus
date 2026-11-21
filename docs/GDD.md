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
- `AGENTS.md` (raiz) — **regra principal** para todos os agentes que mexerem no projeto:
  auditar sempre, caçar erros e esquecimentos, corrigir até ficar entregável, deixar
  crítica extrema e recomendações para o autor decidir, e nunca afirmar nada não
  verificado. A validação visual pertence exclusivamente ao diretor.

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
| A-05 | MÉDIO | Trave = 50% de dano, sem registro documental. | **REGISTRADO:** comportamento preservado; decisão pendente. |
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

Implementação parcial: ver A-01, A-03, A-04 e D-005.

---

## 8. Ritmo, bloqueio e desvio — **CONFIRMADO**

Aplica-se a todos os ataques físicos, de ambas as partes. Barra com marcador e janela
do oponente: ponto 10% central, trave 20% ao redor, resto falha. Tecla Z/Enter.
Duração `1s − 0,05s por ponto de vantagem de AGI/SP` (mínimo 0,2 s). Bloqueio extra:
+1 rolagem a cada 2 SP de vantagem. Ponto ao defender = desvio e +1 SP.

Implementado na cena; disputed details em A-04 e A-05.

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
quanto maior a superioridade do jogador. Detalhes em `docs/COMBAT_SPEC.md`.
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

---

## 21. Riscos e pendências consolidadas

1. **A-02** - resolvido por D-007 (dominância em razão); sem pendência.
2. A-05 — precedência POINT/POINT e resultado de Trave; preservado, sem decisão formal.
3. A-07/A-10 — dificuldade de absorção, eliminação do alvo e persistência entre
   batalhas permanecem indefinidas.
4. A-08 — inventário de itens não implementado.
5. Reprodução de assets — cena depende de arquivos ignorados pelo Git.
6. Alterações locais permanecem não publicadas conforme decisão anterior do diretor.
7. Toda a narrativa além da premissa está indefinida.
8. Sem magia, equipamentos, save/load ou loop de jogo completo.
9. **D-005/D-007** - implementadas; nenhuma pendência restante nessas regras.

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

Decisões anteriores de combate (atos, reações, SP, Press Turn, ritmo, absorção, itens,
escopo do protótipo) foram aprovadas em rodadas anteriores e estão registradas em
`docs/COMBAT_SPEC.md`. Este apêndice não as duplica.
