# Combat specification — Exodus (protótipo)

## Identidade
- Jogo: conceito original com conceitos visuais/gameplay de SMT 1 e 2.
- Protagonista: **Fallen** (nome real desconhecido), demônio caído.
- Inimigos do teste: 2 placeholders genéricos, sem dependência de nomes dos .rvdata.
- Aliado do teste: placeholder genérico.
- Idioma da UI: **inglês**.
- Fundo da batalha: cor sólida **#333333**, visão frontal.

## Atributos
`HP`, `EN` (Energy Points), `ATK`, `MAK`, `DEF`, `MEF`, `AGI`, `SP` (Superiority Points).

- `SP_base = HP + EN + ATK + MAK + DEF + MEF + AGI` (soma dos 7 atributos).
- SP ganho em batalha é **temporário**; volta ao base ao fim da luta.
- `EN`: habilidades custam EP definido nos dados; recupera **20% do máximo por rodada**.
- **Descanso**: abrir mão de um ato recupera **+20% do máximo de EN**.
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
- Ordem de turnos por `AGI`.
- Quando o SP de um lado ultrapassa **70% do SP do oponente**, esse lado ganha
  **+1 ato por rodada**.

## Press Turn
- Acerto em fraqueza: **+1 ato** para quem acertou.
- Resistido / nulo / absorvido: **-1 ato** cada (independente do tipo).
- Afinidades consideradas: Weak, Normal, Resist, Null, Absorb.

## Dano (sem magia neste protótipo)
- Físico: `poder × ATK ÷ DEF`.
- Modificador de SP: rolar `1dN` onde `N = |SP_atuante - SP_alvo|`;
  soma se o atuante tem mais SP, subtrai se tem menos.
- Variação: `±10% ± 2% por ponto de diferença de SP` (sinal conforme vantagem).
- Crítico: multiplicador **×1.5**; chance = `AGI% + 10% por ponto de diferença de SP`.
- SP **não** multiplica o dano diretamente.
- Ganho de SP: **+1** por crítico, desvio perfeito, acerto em fraqueza e reação.

## Sistema de ritmo (ataques físicos)
- Aplica-se a **todos os ataques físicos**, de ambas as partes.
- Barra com marcador móvel; janela do oponente define as zonas.
- Zonas: **Ponto = 10% central**, **Trave = 20% ao redor**, resto = falha.
- Tecla: **Z / Enter**.
- Duração da janela: `1s - 0,05s por ponto de AGI/SP a favor do atuante`, mínimo `0,2s`.
- Ao atacar: Ponto → dano integral; Trave → oponente bloqueia; Falha → sem dano.
- Ao defender: Trave → bloqueia; Ponto → desvia e ganha +1 SP; Falha → dano integral.
- Bloqueio extra: **+1 rolagem de bloqueio a cada 2 pontos de SP de vantagem**.

## Itens e absorção
- Itens utilizáveis em batalha; itens de cura custam **+2 SP ao Fallen**.
- Absorção: sempre disponível, com button mashing; mais fácil quanto mais fraco o inimigo.
- Ganho: 1–3 pontos do maior atributo do inimigo (exceto EN/SP/HP), mais SP base, HP e EN extras.
- Sem equipamentos e sem magia neste protótipo.

## IA
- Inimigos: aleatório ponderado entre ataque e habilidades.
- Inimigos "profissionais" e inteligentes, mas com variações mais fracas previstas em dados.

## Escopo fora deste protótipo
Equipamentos, magia/elementos (AQUA/IGNI/AERO/ROCK/MANA/LUZI), oração de humanos,
progressão narrativa e absorção de longo prazo.
