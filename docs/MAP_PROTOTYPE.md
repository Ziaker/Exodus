# Protótipo de exploração — apenas placeholders

Este documento descreve o que existe **hoje** para a exploração. Nada aqui é uma decisão
de design além das registradas em `docs/DECISIONS.md` (D-054, D-055): `docs/GDD.md` §3
(core loop) e §16 (regiões) seguem **PENDENTES**.

**2026-11-23 (criador): o mapa top-down placeholder foi removido** ("não vamos usar ele"):
saíram `scenes/map/`, `scripts/map/`, `data/maps/`, `tests/verify_map_navigation.gd` e
`tools/capture_map.gd` (com as 7 falhas antigas do teste de navegação). O New Game da tela
de título agora abre o teste de dungeon abaixo. A caixa de diálogo
(`scripts/ui/dialogue_box.gd`) ficou só com o estilo P&B da exploração.

## Teste de dungeon em primeira pessoa (D-054, 2026-11-23)

`prototypes/dungeon-crawler/DungeonProto.tscn` é um **teste**. O visual do overworld foi trocado
em 2026-11-24: paredes, fundo e retratos vêm de `assets/generated/dungeon/`, gerados por
`tools/generate_dungeon_art.py` na paleta do fundo D da batalha. A batalha continua com os
assets SMT como placeholder — a troca foi **só no overworld**. Geometria do VX:
parede a 1 tile = 304×192 px, horizonte em y = 177, olho a 1/3 da altura da parede,
escurecimento alpha 50 por tile, automapa 128×128 em (416,0) com célula de 16 px e tremor
`start_shake(3, 10, 10)`. Passo reto de 0,306 s (0,15 / 0,7 / 0,7: duas reduções de 30% pedidas pelo criador); segurar X
corre a 0,15 s; giro de 0,15 s. Interface P&B no estilo do HUD de batalha: moldura fina,
automapa no canto superior direito, nome do local e status de FALLEN e Yoch embaixo.

**D-055 (2026-11-23):** tela 816×624; vista 3D 804×490 com horizonte em y = 251 (a geometria
do VX acima continua: parede a 1 tile 304×192, olho a 1/3); automapa em (676, 12); painel de
baixo do mesmo tamanho. Dois NPCs (retratos gerados `npc_human.png` e `npc_demon.png`, só
no teste) no corredor inicial em (3,1) e (5,1), atravessáveis e sem nada desenhado no corredor
(como o VX); de frente + Z mostra a figura 1,5× centrada sobre a vista e abre a caixa de diálogo
P&B (2 linhas de 20 px, nome no mesmo tamanho) sobre o painel de baixo. No automapa, um círculo gerado em P&B marca o NPC assim
que a célula dele entra na vista 3D, e parado com o NPC no tile à frente a figura já aparece
antes do Z (some ao andar ou girar); em cima da célula de um NPC ele também aparece e o Z fala com ele (Z/Enter/Espaço avançam; movimento travado enquanto aberta).

## Inimigos e encontros (2026-11-24)

`prototypes/dungeon-crawler/dungeon_enemies.gd` mantém três inimigos placeholder
(`CRIMSON STALKER`, `ASH HOUND`, `CINDER WRAITH`). Eles aparecem como **pontos vermelhos**
no automapa quando a célula entra na vista 3D, avançam **um tile por passo do jogador**
(eixo maior primeiro, desviando de paredes e de outros inimigos) e o HUD avisa
`! HOSTILE AHEAD` quando há um à frente. Cada inimigo também aparece no corredor como **billboard 3D em silhueta**, extraída dos
battlers SMT de verdade (`Avatar Anubis.png`, `Avatar Chimera.png` e `Avian Garuda.png`)
por `tools/generate_dungeon_art.py`: mesma forma, sem arte colorida nem moldura. A silhueta
fica de pé no **centro da célula** (nunca na borda, onde ficam as paredes), com altura
ajustada para caber no corredor, e desliza para a nova célula no mesmo passo do jogador. Retratos de NPC e
marcador do automapa também voltaram aos assets SMT; só o ambiente (paredes/piso/fundo)
é gerado. O passo ganhou balanço de câmera e a linha `POS x,y DIR`. O piso é uma malha 3D com lajes quadradas
(`dungeon_floor.gdshader` + `floor_tile.png`) para dar referência de tile em perspectiva.
Contato — jogador entrar na célula do inimigo
ou o inimigo alcançar o jogador — troca para `scenes/battle/BattlePlayable.tscn`
(**combate novo**: FIGHT/habilidades, reza do Yoch, contra-ataque e fundo D). A cena de
batalha lê `exodus_dungeon_return_scene` e, ao terminar com Z/Enter, volta ao dungeon
restaurando posição, automapa e inimigos restantes. O inimigo encontrado sai do mapa.
A troca de cena passa pelo autoload `scripts/core/scene_fader.gd` (flash vermelho →
fade preto → troca → fade in), inclusive no retorno, para não haver corte seco.
Nada disso é decisão de design nova: é apenas o suporte de exploração pedido, com
valores placeholder aguardando o criador.

Rodar: `Godot_v4.7.2-stable_win64.exe --path . res://prototypes/dungeon-crawler/DungeonProto.tscn`.
Verificar: `Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 -s tests/verify_dungeon_proto.gd`
e `... -s tests/verify_dungeon_encounters.gd` (encontros, estado e ida/volta).
Capturas: `Godot_v4.7.2-stable_win64_console.exe --fixed-fps 60 -s tools/capture_dungeon_encounter.gd`
(gera `captures/dungeon_*.png`, que só registram o visual e aguardam o criador).
