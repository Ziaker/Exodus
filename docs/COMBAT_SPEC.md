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
  **mais** 2 novos simultaneamente disponíveis. **CONFIRMADO como design; NÃO
  IMPLEMENTADO.** Destino dos excedentes e ordem de aplicação dos bônus: **PENDENTE**.
- Ordem de turnos por `AGI`. Na implementação atual, os atos são oferecidos em
  passagens intercaladas (`A, B, A, B`), e cada ato é consumido por uma ação ou reação.
- Quando o SP de um lado ultrapassa **70% do SP do oponente**, esse lado ganha
  **+1 ato por rodada**. **PENDENTE:** com limiar de 70%, qualquer par de SP positivos
  concede o bônus a pelo menos um lado; a intenção de premiar superioridade exige decisão.
- **Consequência de D-005:** o bônus de SP respeita o teto de 4 atos disponíveis;
  não autoriza um quinto ato. Destino de bônus excedente: **PENDENTE**. O limiar
  de 70% e o bônus de +1 não foram revisados.

## Press Turn
- Acerto em fraqueza: **+1 ato** para quem acertou.
- Resistido / nulo / absorvido: **-1 ato** cada (independente do tipo).
- **Consequência de D-005:** o +1 por fraqueza também respeita o teto de 4 atos
  disponíveis. Destino do +1 concedido no teto e ordem de aplicação com outros
  bônus: **PENDENTE**. A penalidade de -1 não foi alterada.
- Afinidades consideradas: Weak, Normal, Resist, Null, Absorb.

## Dano (sem magia neste protótipo)
- Físico: `poder × ATK ÷ DEF`.
- Modificador de SP: rolar `1dN` onde `N = |SP_atuante - SP_alvo|`;
  soma se o atuante tem mais SP, subtrai se tem menos.
- Variação: `±10% ± 2% por ponto de diferença de SP` (sinal conforme vantagem).
- Crítico: multiplicador **×1.5**; chance = `AGI% + 10% por ponto de diferença de SP`.
- SP **não** multiplica o dano diretamente.
- Ganho de SP: **+1** por crítico, desvio perfeito, acerto em fraqueza e reação.
- Crítico, Press Turn e ganhos de SP por fraqueza/crítico só são aplicados quando
  há **contato** (ritmo de ataque diferente de Falha e defesa diferente de Desvio).
  Ataques que falham não consomem rolagens de dano.
- **PENDENTE (balanceamento, sem alteração de fórmula):** `AGI + 10 × ΔSP` atinge
  100% com ΔSP=10 para AGI=0 (ou ΔSP=4 para o Fallen de teste, AGI=6). Qualquer
  mudança exige aprovação.

## Sistema de ritmo (ataques físicos)
- Aplica-se a **todos os ataques físicos**, de ambas as partes.
- Entrada manual: atacante controlado pelo jogador usa a barra visível para o
  ataque; defensor controlado pelo jogador usa a barra visível apenas quando declarou
  reação e pagou 1 ato. Atacante e defensor controlados pela IA resolvem seu próprio
  ritmo sem entrada humana.
- Barra com marcador móvel; janela do oponente define as zonas.
- **PENDENTE:** precedência quando atacante e defensor acertam POINT simultaneamente.
  O comportamento atual do código (defesa prevalece, 0 dano) foi preservado.
- Zonas: **Ponto = 10% central**, **Trave = 20% ao redor**, resto = falha.
- Tecla: **Z / Enter**.
- Duração da janela: `1s - 0,05s por ponto de AGI/SP a favor do atuante`, mínimo `0,2s`.
- Ao atacar: Ponto → dano integral; Trave → oponente bloqueia; Falha → sem dano.
- Ao defender: Trave → bloqueia; Ponto → desvia e ganha +1 SP; Falha → dano integral.
- Bloqueio extra: **+1 rolagem de bloqueio a cada 2 pontos de SP de vantagem**.

## Itens e absorção
- Itens utilizáveis em batalha; itens de cura custam **+2 SP ao Fallen**.
- Absorção: restrita a **Fallen**; requer button mashing; **0 pressionamentos = falha,
  sem ganhos**. Um alvo absorvido é marcado e não pode render recompensas repetidas.
- Ganho: 1–3 pontos do maior atributo do inimigo (exceto EN/SP/HP), mais SP base, HP e EN extras.
- **PENDENTE:** fórmula exata de dificuldade do mashing, eliminação do alvo, novas
  tentativas após falha, limite de HP e persistência entre batalhas. Nada disso foi
  inventado; os ganhos atuais permanecem apenas dentro da batalha.
- Sem equipamentos e sem magia neste protótipo.

## IA
- Inimigos: aleatório ponderado entre ataque e habilidades.
- Inimigos "profissionais" e inteligentes, mas com variações mais fracas previstas em dados.

## Escopo fora deste protótipo
Equipamentos, magia/elementos (AQUA/IGNI/AERO/ROCK/MANA/LUZI), oração de humanos,
progressão narrativa e absorção de longo prazo.
