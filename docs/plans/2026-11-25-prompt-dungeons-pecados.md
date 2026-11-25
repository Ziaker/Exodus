# Prompt para planejar as 8 dungeons dos pecados (Survival Mode de EXODUS)

Você vai **planejar** (não implementar) as 8 dungeons do modo Survival do meu jogo, EXODUS.
Leia tudo antes de responder.

## O jogo

- RPG em **Godot 4.7.2 / GDScript**, resolução 816×624, inspirado em Shin Megami Tensei.
- Combate por turnos com pontos de ATO, trilhos de ritmo/timing para ataque, defesa e
  contra-ataque, reza da aliada Yoch e **absorção** de inimigos pelo protagonista Fallen
  (o criador o chama de Deviron).
- A batalha usa sempre o mesmo layout: fundo plasma animado e inimigos como silhuetas pretas
  15% menores. **Não proponha mudanças no layout de batalha.**
- A exploração é um **dungeon crawler em primeira pessoa**, em 3D real. Grade 25×21, um tile por
  passo, giro de 90°, automapa no canto, painel de status embaixo. NPCs aparecem como uma figura
  2D centrada quando você fica de frente para eles. Inimigos aparecem como silhuetas no corredor
  e perseguem o jogador.
- Assets de terceiros (SMT VX The Genesis) só são usados como placeholder de teste.

## O modo Survival hoje

O modo já é um roguelike:
- estratos com labirinto gerado pela semente da run, guardião no ponto mais fundo e DESCEND
  para descer;
- intenções dos inimigos mostradas na batalha;
- absorção com raridade;
- relíquias com efeito e pactos;
- eventos no corredor (altar de sangue, espírito, oráculo, mercador);
- loja, cura paga, dificuldade OMEN e CODEX.

Hoje **todos os estratos têm a mesma textura, cor e música**: só o desenho do labirinto muda.

## Decisões do criador (fixas, não mude)

1. **8 dungeons**, cada uma com um anjo SMT de chefe, nesta ordem e com este pecado:

| # | Chefe | Pecado |
|---|---|---|
| 1 | Kazfiel | Preguiça |
| 2 | Zaphkiel + Tzaphkiel (dupla, mesmo design) | Inveja |
| 3 | Ophaniel | Avareza |
| 4 | Aniel | Gula |
| 5 | Uriel | Ira |
| 6 | Raphael | Luxúria |
| 7 | Michael | Soberba |
| 8 | **Gabriel original do criador** (arte própria, dourada) — o mais forte | **Perfeição** (o oitavo pecado) |

2. **88 criaturas no total:** 9 anjos + 79 demônios comuns sorteados aleatoriamente entre os
   534 battlers do SMT.
3. Metatron e o Gabriel do SMT ficam fora. Samael fica fora por enquanto.
4. **Cada dungeon tem que ser visualmente diferente em textura, mapa, interações e NPCs**,
   seguindo uma ideia estética do seu pecado.

## O que eu quero de você

Para **cada uma das 8 dungeons**, proponha:

1. **Conceito estético do pecado:** o tema visual em 2 ou 3 frases e **referências reais**
   (jogos, filmes, arte sacra, pintores, arquitetura), dizendo o que tirar de cada uma.
2. **Textura e cor:** paredes, piso, céu ou fundo distante e paleta (cores em hex), mais a
   iluminação ou névoa. Lembre que é um corredor 3D simples de quads, com shader de parede e
   de piso.
3. **Mapa:** a forma do labirinto que expressa o pecado (por exemplo corredores longos e
   vazios, salas, becos, simetria, loops, armadilhas de caminho). Tem que caber numa grade
   25×21, ser gerável por semente e ter um santuário central seguro.
4. **Interações:** 1 ou 2 mecânicas de exploração próprias do pecado. Elas têm que funcionar
   num crawler de grade e por turnos de passo, e não podem mudar as regras de combate.
5. **NPCs e eventos:** quem aparece nessa dungeon e que escolha de risco e recompensa oferece.
6. **Chefe:** como a luta contra o anjo expressa o pecado, só com o que o combate já permite
   (status, habilidades, afinidade, temperamento da IA, escoltas). Na dungeon 2, como funciona
   a dupla.
7. **Música e som:** uma direção curta.

Depois, à parte:
- uma **curva de força** dos 8 chefes (do 1º ao Gabriel), em termos relativos;
- **riscos e custos**: o que é caro de produzir (arte nova, shaders, sistemas novos) e o que
  dá para fazer com recolor/shader sobre o que já existe;
- uma **lista de perguntas** que só o criador pode responder.

## Regras

- **Não decida por mim.** Quando houver escolha (cor, forma, mecânica, valor), ofereça 2 ou 3
  opções e diga qual recomenda e por quê. Uma decisão por pergunta.
- Não invente regras de combate novas. Não mude o layout de batalha.
- Não escreva código. É só o plano.
- Seja concreto: nada de "atmosfera sombria" sem dizer o que isso é em textura, cor e forma.
- Responda em **português**.
