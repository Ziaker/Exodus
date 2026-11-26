# Necrópole Saturnina · refinamento das 55 salas

[Maquete Blender](Necropole_Saturnina_55_Salas_Refinadas.blend) · [Antes e depois da planta](comparacao_de_planta.png) · [Planta com marcos](planta_55_salas.png)

## Survival

A Necrópole é o primeiro estrato do Survival (D-114). A maquete foi exportada
para GLB. A grade navegável do jogo usa as células alcançáveis e as bordas
medidas na malha, com 2.639 células navegáveis, 66 bordas fechadas entre
células e 314 células na rota mínima.

[Captura no Survival](video/Survival_Necropole.mp4) ·
[Entrada, santuário e cinco zonas](video/prancha_survival.jpg)

[Travessia no ensaio com fundo animado](video/EXODUS_Necropole_Saturnina_Fundo_Animado.mp4) ·
[Amostra de iluminação e céu](video/Amostra_Fundo_Animado_e_Luz_Pendular.mp4) ·
[Travessia original do ensaio](video/EXODUS_Necropole_Saturnina.mp4)

O refinamento conserva as 11 salas por zona, as 67 ligações e os 13 circuitos. Os centros ganharam deslocamentos, as salas ganharam recortes e alcovas, e 61 passagens têm curvas em planta. A entrada continua sem uma rota alternativa à Ruptura.

| Vista lateral | Marco |
|---|---|
| I-C | Estela fendida e fragmento tombado |
| II-E | Cripta parcialmente coberta, sarcófago destampado e tampa fora da caixa |
| III-H | Bancada e esculturas em estágios diferentes de talhe |
| IV-H | Meridiano de parede sob cobertura quebrada |
| V-G | Sino rachado suspenso sobre uma base de pedra |

[Cinco marcos](galeria/marcos_laterais.png) · [Cinco zonas em primeira pessoa e planta 3D](galeria/zonas.png)

## Verificação e limites

- `python -B planta.py` verifica salas, ligações, alcance em planta e ausência de desvio em torno da Ruptura. As 2.676 células incluem os corredores. O menor trajeto passou de 263 para 314 células, incluindo os extremos.
- `blender --background --factory-startup Necropole_Saturnina_55_Salas_Refinadas.blend --python-exit-code 1 --python renderizar.py -- auditar` reabre a cena final e testa o piso e o deslocamento com raios. A maquete contém 11 câmeras e a rota física medida alcança todas as 55 salas. [Dados de auditoria](auditoria.json)
- `python -B apresentar.py` confere as 11 capturas de 804 × 490. O filtro Cartucho ocre + Fita de horror aparece nas dez vistas em primeira pessoa. A planta 3D usa a cor dos materiais e oculta as coberturas para mostrar a circulação.
- As formas e os marcos das outras salas laterais ainda têm variação limitada. A cripta e o observatório lateral receberam coberturas no passe final para separar a leitura dos espaços internos daquela dos pátios. O Survival usa deslocamento por célula sobre a malha medida.
