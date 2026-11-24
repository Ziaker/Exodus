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

`prototypes/dungeon-crawler/DungeonProto.tscn` é um **teste**. Ele usa texturas da pasta de referência do SMT VX (não
versionada), então só roda nesta máquina. Geometria tirada do script "3Dダンジョン" do VX:
parede a 1 tile = 304×192 px, horizonte em y = 177, olho a 1/3 da altura da parede,
escurecimento alpha 50 por tile, automapa 128×128 em (416,0) com célula de 16 px e tremor
`start_shake(3, 10, 10)`. Passo reto de 0,306 s (0,15 / 0,7 / 0,7: duas reduções de 30% pedidas pelo criador); segurar X
corre a 0,15 s; giro de 0,15 s. Interface P&B no estilo do HUD de batalha: moldura fina,
automapa no canto superior direito, nome do local e status de FALLEN e Yoch embaixo.

**D-055 (2026-11-23):** tela 816×624; vista 3D 804×490 com horizonte em y = 251 (a geometria
do VX acima continua: parede a 1 tile 304×192, olho a 1/3); automapa em (676, 12); painel de
baixo do mesmo tamanho. Dois NPCs (figuras `Pictures/P15` e `Pictures/D_Brute Onia` do VX, só
no teste) no corredor inicial em (3,1) e (5,1), atravessáveis e sem nada desenhado no corredor
(como o VX); de frente + Z mostra a figura 1,5× centrada sobre a vista e abre a caixa de diálogo
P&B (2 linhas de 20 px, nome no mesmo tamanho) sobre o painel de baixo. No automapa, o círculo do VX em P&B marca o NPC assim
que a célula dele entra na vista 3D, e parado com o NPC no tile à frente a figura já aparece
antes do Z (some ao andar ou girar); em cima da célula de um NPC ele também aparece e o Z fala com ele (Z/Enter/Espaço avançam; movimento travado enquanto aberta).

Rodar: `Godot_v4.7.2-stable_win64.exe --path . res://prototypes/dungeon-crawler/DungeonProto.tscn`.
Verificar: `Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 -s tests/verify_dungeon_proto.gd`.
Capturas: `Godot_v4.7.2-stable_win64_console.exe --fixed-fps 60 -s tools/capture_dungeon_proto.gd`
(gera `captures/dungeon_*.png`, que só registram o visual e aguardam o criador).
