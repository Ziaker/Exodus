# Necrópole Saturnina · Ruptura

Maquete experimental para comparar com Stone, Melancholy e Saturn. [Arquivo Blender](Necropole_Saturnina_Ruptura.blend) · [Sete vistas](prancha.png) · [Planta e geometria](planta_e_geometria.png)

A rua sepulcral foi virada como um trecho contínuo da cidade. Pórticos, degraus e esculturas seguem o mesmo piso invertido. Uma escadaria normal sobe da margem oposta e perde seu apoio. A escadaria invertida desce da rua suspensa em direção ao mesmo intervalo. Vista de baixo, as duas quase parecem parte do mesmo lance. A abertura entre as margens é modelada até o fundo. A rota visível em primeira pessoa segue a margem direita.

## Inspeção

- Duas câmeras de exploração usam o FOV vertical de 77,73° do protótipo e mantêm a razão entre altura dos olhos e tamanho da célula.
- `renderizar.py` reabriu a cópia do MCP e mediu as superfícies com raios verticais. A entrada encontrou terreno em −0,005 unidade, a posição na margem encontrou uma laje em 0,076, e o eixo da fenda encontrou o fundo em −17,441. A caixa de poeira foi excluída da medição. [Resultado](auditoria.json)
- `apresentar.py` confirmou sete PNGs em 804 × 490. Seis foram comparados com o render original após o filtro Cartucho ocre + Fita de horror. A vista da geometria usa Workbench. [Prancha](prancha.png)
- A maquete foi criada através do Blender MCP, e a cópia de entrega foi isolada no Blender em segundo plano. O arquivo final contém uma cena editável e 279 objetos de malha. Os modelos A, B e C continuam nos arquivos anteriores.

## Crítica

A rua invertida e as escadarias usam gravidades diferentes dentro da mesma composição. Da altura dos olhos, a borda da fenda encobre parte da profundidade e a leitura do segundo lance muda com o ângulo. A vista superior e a câmera da fenda deixam isso explícito. A maquete usa o corte distante estendido para mostrar a arquitetura. Agressividade da perspectiva, colisões, visibilidade com sprites e passagem no renderer Compatibility ainda precisam ser avaliadas quando houver integração.
