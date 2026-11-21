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

### 4.1 Divergências identificadas na auditoria — **PENDENTE**

| ID | Gravidade | Achado |
|---|---|---|
| A-01 | CRÍTICO | `BattleState.next_actor()` percorre cada unidade uma vez por rodada. Embora `acts_available` seja 2 (ou 3), cada unidade age uma vez. `end_round()` armazena os atos restantes, inflando o estoque. A regra central de 2 atos não está implementada, e um teste codifica o comportamento incorreto como esperado. |
| A-02 | ALTO | Limiar de 70% usa `SP_atual > SP_rival * 0,7`; com SP próximos, ambos os lados recebem +1 ato. Superioridade não é exigida. |
| A-03 | MÉDIO | Reação do jogador é sim/não em temporizador fixo de 0,8 s, sempre ataque. "Todos os comandos podem ser Reação" não implementado. |
| A-04 | MÉDIO | Bloqueio inimigo é `randi_range(0,2)` sem regra documentada de conversão em resultado. |
| A-05 | MÉDIO | Trave foi implementado como 50% de dano; o spec apenas diz "oponente bloqueia". |
| A-06 | MÉDIO | Descanso consome 2 atos (ação comum + ato extra); o spec diz abrir mão de 1 ato. |
| A-07 | BAIXO | "SP base extra" da absorção ambíguo; implementação recalcula SP pela soma dos atributos. |
| A-08 | BAIXO | Item de cura é `heal(6)` fixo, sem inventário. |

Nenhuma divergência foi corrigida nesta entrega.

---

## 5. Superiority Points — **CONFIRMADO**

`SP_base` = soma de HP, EN, ATK, MAK, DEF, MEF e AGI. SP ganho em batalha é temporário.
Fórmulas de dado, variação, crítico e limiar: `docs/COMBAT_SPEC.md`.

SP define superioridade, sorteio de dano extra, rolagens de bloqueio e vantagem geral.
Quando um lado ultrapassa 70% do SP do oponente, ganha +1 ato por rodada — a
implementação atual desse limiar está sob A-02.

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

Implementação parcial: ver A-01, A-03 e A-04.

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

1. **A-01** — os 2 atos por rodada não são efetivamente usados. Bloqueia a mecânica central.
2. **A-02** — limiar de 70% não exige superioridade.
3. Reprodução de assets — cena depende de arquivos ignorados pelo Git.
4. Seis alterações locais permanecem não publicadas por decisão do diretor.
5. Toda a narrativa além da premissa está indefinida.
6. Sem inventário, IA tática, magia, equipamentos, save/load ou loop de jogo completo.

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

Decisões anteriores de combate (atos, reações, SP, Press Turn, ritmo, absorção, itens,
escopo do protótipo) foram aprovadas em rodadas anteriores e estão registradas em
`docs/COMBAT_SPEC.md`. Este apêndice não as duplica.
