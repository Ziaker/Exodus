# Ruptura · Interior da Necrópole Saturnina

Estudo experimental da câmara atrás do pórtico. [Modelo Blender](Necropole_Saturnina_Interior.blend) · [Prancha](galeria/prancha.png)

A passagem estreita abre para um salão funerário. A fenda atravessa a lateral esquerda da sala. Os túmulos dessa parede foram girados como um conjunto e a escadaria invertida interrompe-se sobre a passagem. A luz rubra entra por uma abertura na cobertura. A faixa de exploração segue ao nível do chão, com o espaço central livre para sprites.

## Vistas

- [Da entrada para a câmara](galeria/limiar.png)
- [Câmara na altura do jogador](galeria/camara.png)
- [Aproximação do sepulcro](galeria/sepulcro.png)
- [Escadaria e túmulos invertidos](galeria/gravidades.png)
- [Planta com teto removido](galeria/planta.png)
- [Corte sem materiais](galeria/geometria.png)

## Verificação

- `renderizar_interior.py` reabre a cena salva e verifica as seis câmeras, o FOV de 77,73° nas três vistas de exploração e a posição do pórtico. Foram reutilizadas as três peças do exterior nas mesmas coordenadas.
- Seis amostras do percurso encontraram piso entre 0,018 e 0,076 unidade Blender. O fundo da abertura lateral está em −3,777 unidades na amostra.
- Quatro retângulos de referência com 0,9 × 2,4 unidades Blender foram projetados lado a lado na câmera da câmara. As quatro caixas couberam sem sobreposição. Vale para a posição medida. A arte final e a composição com o HUD precisam de validação no jogo. [Dados da auditoria](auditoria.json)
- `galeria_interior.py` confere seis PNGs em 804 × 490, cinco com o Cartucho ocre + Fita de horror e um corte sem materiais. Na planta filtrada foi usada luz suplementar de inspeção, só para a captura.

## Crítica

O enquadramento na altura dos olhos favorece a rota pelo chão. A emenda entre a escada suspensa e o teto fica mais legível quando se olha para cima. A planta e o corte esclarecem essa relação. O interior foi salvo como cena independente, com os três módulos do pórtico incorporados. A ligação física em tempo de jogo e a iluminação no renderer Compatibility continuam pendentes da integração.
