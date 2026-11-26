# Necrópole Saturnina · maquete do percurso

O estudo segue as cinco zonas do briefing. A Ruptura faz parte do caminho principal e ocupa o trecho do pórtico. Os dois arquivos detalhados mostram a intenção visual da aproximação e do interior dessa passagem.

A versão de 55 salas usada no Survival está no [refinamento do percurso](refinamento_55/LEIA-ME.md).

[Maquete editável](Necropole_Saturnina_Percurso.blend) · [Mapa do trajeto](mapa_percurso.png) · [Cinco vistas e planta da maquete](galeria/prancha.png) · [Exterior detalhado](../ruptura/Necropole_Saturnina_Ruptura.blend) · [Interior detalhado](../ruptura/interior/Necropole_Saturnina_Interior.blend)

| Zona | O que muda no caminho | O que orienta o jogador |
|---|---|---|
| I · Pórtico dos Que Desistiram | Travessia junto à fenda e entrada comprimida | Ruas suspensas acima da rota no chão |
| II · Avenida Sepulcral | Corredores ordinários com dois laços entre túmulos | Vãos, estelas e um sarcófago sem tampa |
| III · Claustro da Melancolia | Pátio mais largo com oficinas às margens | Poliedro, bancada e escadas interrompidas |
| IV · Ossuário dos Astrônomos | Câmara circular com passagem central e teto aberto | Meridiano incompleto e nichos funerários |
| V · Sepulcro do Sétimo Peso | Espaço amplo e campo visual livre para Kazfiel | Altar, estrutura orbital e abertura para o céu |

## Montagem e conferência

- `renderizar.py` reabre a maquete, confere as seis câmeras e mede o piso na rota principal. `audit_layout` verificou 343 células ligadas, 54 na rota principal e dois laços laterais na Avenida. As amostras de piso variaram de 0,024 a 0,117 unidade Blender.
- `galeria.py` valida seis PNGs em 804 × 490. Nas cinco vistas de exploração está aplicado o Cartucho ocre + Fita de horror. A planta da maquete foi renderizada sem a camada de atmosfera, para facilitar a inspeção.
- A maquete usa uma amostra simplificada da Ruptura para marcar sua posição na circulação. A arquitetura detalhada continua nas duas cenas próprias. [Valores da auditoria](auditoria.json)

O traçado e as dimensões seguem provisórios. A circulação está legível na planta, mas as duas voltas da Avenida ainda carecem de marcos diferentes nas bifurcações. A iluminação e os adereços das outras zonas ainda estão no nível de maquete. A integração com o Godot, o teste com colisores e a cena de Kazfiel permanecem pendentes.
