# Protótipo de exploração — apenas placeholders

Este documento descreve o que existe **hoje** no protótipo de navegação. Nada
aqui é uma decisão de design: `docs/GDD.md` §3 (core loop) e §16 (regiões) seguem
**PENDENTES**, e nenhum ID foi reservado em `docs/DECISIONS.md` para este trabalho.

## O que foi implementado

- `scenes/map/Map.tscn` / `scripts/map/map_scene.gd`: mapa top-down em grid de
  16 px (34×26 tiles), quatro direções por setas ou WASD, um tile por passo com
  interpolação visual de 0,12 s, colisão com paredes e objetos.
- `data/maps/placeholder_maps.gd`: duas áreas placeholder (`outskirts`, `ruins`)
  com portas de ida/volta, spawn por entrada e objetos: placa, NPC, baú e inimigo.
- `scripts/ui/dialogue_box.gd`: janela de diálogo estilo XP com nome, texto
  datilografado, múltiplas páginas e seta de continuação. Z/Enter/Space avançam.
- Interação com Z/Enter/Space sobre o tile à frente: diálogo, baú (inventário
  local e estado de "aberto" persistido entre as duas áreas) e porta.
- HUD mínimo: nome do local, itens e linha de controles.
- `scripts/title/title_screen.gd`: New Game abre o mapa placeholder. A cena de
  batalha existente (`BattlePlayable.tscn`) continua intacta e acessível pelas
  ferramentas/testes atuais.

## Pendente de decisão do criador (nada foi escolhido aqui)

1. Geografia, nomes de áreas e textos reais (hoje `[PLACEHOLDER]`).
2. Tamanho de tile, velocidade de passo e presença/ausência de câmera com scroll.
3. Regras de encontro: o objeto-inimigo hoje só fala; **não** há transição para
   a batalha nem volta da batalha ao mapa.
4. Inventário, salvamento e persistência entre partidas (hoje só memória da cena).
5. Como o título deve ligar exploração e batalha no loop completo.
6. Aparência dos placeholders (retângulos desenhados por código, sem assets).

## Verificação

`tests/verify_map_navigation.gd` cobre movimento, colisão, facing, diálogo,
baú, inventário, portas ida/volta e persistência do baú entre áreas. Capturas
em `captures/map_*.png` são apenas registro visual e aguardam o julgamento do
criador.
