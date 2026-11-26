# EXODUS · Sloth · The Saturnine Necropolis

Estudos de direção de arte para aprovação. Abra [Sloth_Necropole_Saturnina.blend](Sloth_Necropole_Saturnina.blend) e use o seletor de cenas do Blender para alternar entre A, B e C. Em cada cena, a coleção Câmeras contém os mesmos sete tipos de enquadramento.

[Ruptura exterior](ruptura/LEIA-ME.md) · [Interior atrás do pórtico](ruptura/interior/LEIA-ME.md) · [Maquete de circulação das cinco zonas](percurso/LEIA-ME.md)

| Estudo | Composição | Capturas |
|---|---|---|
| A · Necropolis of Stone | Pórtico em desfiladeiro, passagem processional, túmulos menores e esculturas sentadas | [Prancha](a_prancha.png), [POV](galeria/a_pov.png), [planta](galeria/a_planta.png) |
| B · Necropolis of Melancholy | Claustro interrompido, bancada com ferramentas, manto incrustado no bloco, poliedro e escada sem chegada | [Prancha](b_prancha.png), [POV](galeria/b_pov.png), [planta](galeria/b_planta.png) |
| C · Necropolis of Saturn | Terraço funerário com anéis incompletos, esfera mineral, trilhas gravadas e sino rachado | [Prancha](c_prancha.png), [POV](galeria/c_pov.png), [planta](galeria/c_planta.png) |

[Comparação em primeira pessoa](comparacao_exploracao.png) · [Plantas filtradas](comparacao_plantas.png) · [Três atmosferas](atmosfera.png) · [Antes e depois](antes_depois.png) · [Capturas originais](raw)

## Base técnica

- Blender 5.2.2 LTS com EEVEE para a cena artística. A edição por MCP produziu e salvou a primeira versão. Os refinamentos e a rodada de 24 capturas rodaram em instâncias isoladas do mesmo Blender. O arquivo entregue tem três cenas locais, 21 câmeras e materiais nativos.
- O Survival atual é um `Control` que herda a exploração do protótipo. Usa grid de 25 × 21, cinco estratos, uma unidade por célula, parede de 192/304 de unidade, câmera a 64/304 de unidade, FOV vertical de 77,73° e corte em 5,5 células. O projeto está em `gl_compatibility`. [Survival](../../../../scripts/survival/survival_world.gd) · [Câmera e grid](../../../../prototypes/dungeon-crawler/dungeon_proto.gd) · [Renderer](../../../../project.godot)
- Nas maquetes, quatro unidades Blender representam uma célula de referência. O olho fica a 0,8421 unidade Blender. O FOV vertical e a proporção da área visível foram preservados. O plano distante das capturas artísticas usa uma distância estendida para mostrar a paisagem. Na integração, o panorama exigiria estudo separado de parallax ou composição. Larguras, alturas monumentais e posições destas cenas são provisórias.
- As capturas de apresentação, inclusive as plantas, reproduzem o Cartucho ocre + Fita de horror em pós, com a LUT do projeto, amostragem 288 × 176, Bayer, quantização e scanlines em 804 × 490. As três vistas de geometria foram renderizadas em Workbench. [Shader](../../../../prototypes/dungeon-crawler/dungeon_mixed_filter.gdshader) · [LUT original](../../../../prototypes/dungeon-crawler/dungeon_mixed_palette.res) · [Aplicação offline](galeria.py)
- Os três presets usam a mesma câmera do claustro. A densidade do volume é 0,007, 0,019 e 0,035. Edite o nó Volume Scatter no material de poeira.
- A premissa de oito dungeons temáticas pertence ao novo briefing. A implementação registrada do Survival ainda usa cinco estratos. A arte de Kazfiel e os seis PNGs citados no briefing por nome não foram localizados na pasta do projeto nem na busca nominal na Área de Trabalho do OneDrive. O cenário usa esculturas ambientais. Personagens e NPCs continuam a cargo dos sprites 2D.

## Biblioteca experimental

| Gerador | Peças presentes | Parâmetros no Python |
|---|---|---|
| Geologia e piso | Penhascos estratificados, bacia sedimentar, cordilheira, margens de detritos e lajes | Semente, largura, profundidade, altura, assimetria, estratificação, erosão |
| Arquitetura | Plintos, ombreiras, lintéis, cornijas, pilares, tumbas, escadas, terraços | Dimensões, desgaste, afunilamento, número de degraus, piso, espelho |
| Esculturas | Figuras sentadas, asas erodidas, manto e escultura parcialmente presa ao bloco | Escala, posição, figura em talhe ou acabada |
| Instrumentos | Perfis de revolução, anéis com intervalos, esfera, sino, traços orbitais | Perfil, resolução radial, raio, seção, inclinação e intervalo de fratura |
| Objetos | Estelas, bancada, malho, cinzel, suportes e poliedro | Proporção, orientação, material e desgaste conforme a família |

As malhas podem ser editadas no Blender. Os modificadores de desgaste e normais ficam acessíveis. Os campos dos penhascos registram os valores usados pelo gerador. Para gerar outra variação, edite os argumentos em [construir.py](construir.py) e execute o arquivo numa sessão de fábrica com um novo caminho de saída. O script também está no editor de texto do `.blend`.

Os materiais incluem calcário funerário, rocha sedimentar, bronze saturnino, chumbo ritual, osso fossilizado, areia funerária, dourado morto, madeira morta e cavidades. Ajustes de cor estão nas rampas dos nós. A estratificação, textura, rugosidade e relevo têm controles nos respectivos nós. O dourado morto está salvo na biblioteca para estudos posteriores.

## Referências e interpretação

- Em A, as escavações de Petra, Tebas, Beni Hasan, Saqqara e Naqš-e Rostam orientaram a profundidade das entradas e a relação entre fachada e penhasco. A escala menor das tumbas laterais evoca a repetição de câmaras e caminhos de Banditaccia. [Petra](https://whc.unesco.org/en/list/326/) · [Tebas](https://whc.unesco.org/en/list/87/) · [Beni Hasan](https://egymonuments.gov.eg/en/archaeological-sites/beni-hasan/) · [Saqqara](https://egymonuments.gov.eg/en/archaeological-sites/saqqara/) · [Naqš-e Rostam](https://www.iranicaonline.org/articles/naqs-e-rostam/) · [Banditaccia](https://whc.unesco.org/en/list/1158/)
- Em B, a proximidade entre instrumentos e trabalho suspenso vem de *Melencolia I*. O vazio que separa a escada das travessas superiores foi estudado a partir dos planos sobrepostos de Piranesi. [Dürer, Met](https://www.metmuseum.org/art/collection/search/360018) · [Piranesi, Met](https://www.metmuseum.org/art/collection/search/337060)
- Em C, a relação entre Saturno e melancolia é uma referência iconográfica histórica aplicada ao cenário fictício de Maesto. A armila partida é uma interpretação própria. [Kemper Art Museum](https://www.kemperartmuseum.wustl.edu/research/artwork-essays/durer-albrecht-melencolia-i-1514)
- Nos três, a paisagem indiferente e as massas fossilizadas foram estudadas na galeria de Beksiński. Perspectiva frontal e simplificação da leitura espacial seguem o recorte solicitado de SMT II. [Muzeum Historyczne w Sanoku](https://muzeum.sanok.pl/zbiory-muzealne/zdzislaw-beksinski/malarstwo/) · [Nintendo e Atlus](https://www.nintendo.com/jp/topics/article/4b934f20-f9fe-427b-a047-53b977f8fbc2)

## Autocrítica

Notas de trabalho para comparar as capturas, de 0 a 10. O total segue os pesos do briefing e não substitui a aprovação visual do autor.

| Critério | Peso | A | B | C |
|---|---:|---:|---:|---:|
| Identidade de EXODUS | 20% | 7 | 8 | 8 |
| Linguagem inspirada em Beksiński | 15% | 6 | 7 | 7 |
| Compatibilidade visual com SMT II | 10% | 7 | 8 | 8 |
| Representação de Sloth | 15% | 6 | 8 | 7 |
| Geometria | 10% | 7 | 7 | 8 |
| Composição e escala | 10% | 7 | 8 | 8 |
| Materiais e paleta | 10% | 7 | 7 | 7 |
| Legibilidade de exploração | 5% | 8 | 8 | 8 |
| Reutilização procedural | 5% | 7 | 7 | 8 |
| Total ponderado | 100% | **6,75** | **7,60** | **7,60** |

- **A.** A hierarquia entre caminho, pórtico e penhasco é fácil de ler. A sombra ainda esconde parte da postura da estátua. As ombreiras retas destacam a fachada da rocha e reduzem a impressão de que a abertura foi escavada nela. Se A for escolhida, estudar a transição entre ombreira e penhasco no nível da geometria.
- **B.** A escada que perde a ligação com a travessa e o bloco de escultura traduzem diretamente a ideia de obra interrompida. O cinzel aparece no close da bancada, mas desaparece na escala da exploração. Se B for escolhida, verificar quais pistas do abandono precisam de uma silhueta maior antes de aumentar a quantidade de adereços.
- **C.** O observatório tem o ponto de orientação mais legível. No POV, a simetria e o círculo dominante dão ao conjunto mais solenidade do que abandono. Se C for escolhida, é possível deslocar ou interromper os apoios e ainda preservar a leitura do instrumento.
- **Correção e regressões.** As três cenas reabrem no Blender e têm a mesma projeção de exploração registrada. O filtro foi aplicado offline e deve ser comparado no motor quando houver integração. O primeiro método de gravação encerrou a sessão anterior do Blender. O arquivo gravado da cratera preservou seu SHA-256 e a construção foi retomada numa sessão separada.
- **Omissões e riscos.** O pacote de aprovação tem três ambientes de estudo, sem as cinco zonas definitivas, colisor, ligação ao labirinto, exportação GLB ou ensaio com o sprite de Kazfiel. Os materiais procedurais e a volumetria exigem validação específica no renderer Compatibility. O acabamento depende ainda da aprovação artística.

## Evidência

- `blender --background --factory-startup Sloth_Necropole_Saturnina.blend --python-exit-code 1 --python renderizar.py` reabre o arquivo, mede a câmera, conta os triângulos e renderiza as três cenas. [Resultado estrutural](auditoria.json)
- `python galeria.py` valida dimensões e abertura de 24 PNGs e monta as pranchas. A auditoria visual abrange as sete vistas por cena e as três densidades sob o mesmo enquadramento. O primeiro passe do comparativo veio de prévias menores que as imagens finais.
- Na conferência original, `git status --short -- assets/generated/ambiente-e-interacoes/abertura` não retornou alterações nessa pasta. O rework D-106 aparecia no checkout e está fora do pacote da Necrópole. A cópia versionada mantém o código de modelagem, a LUT e os caminhos das capturas. O marcador `.gdignore` mantém os estudos fora da importação automática do Godot.
