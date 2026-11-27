# EXODUS — Direção artística visual

Guia de referência para ambientação do dungeon crawler e geração procedural de assets via Blender MCP. Registro editorial de 2026-11-25, baseado nas referências enviadas pelo diretor e nas conversas sobre ambientação e filtros.

**Autoridade:** documento complementar, não substitui o [GDD](GDD.md), o [índice de decisões](DECISIONS.md) nem o [AGENTS.md](../AGENTS.md). Não cria regras narrativas, decisões numeradas ou requisitos de implementação novos. A homologação visual pertence ao diretor criativo. O escopo é exploração ambiental, não o battleback de combate da D-053.

## 1. Norte estético

Na época retratada em EXODUS, Maesto deve evocar desolação metafísica, monumentalidade mineral, silêncio e inquietação espiritual. Conforme D-126 (GDD §15), o restante do universo possui tom de fantasia alto-astral; a raça dos animais ainda não está presente nessa época. A D-127 permite, como possibilidade de design de criaturas, alguns Daemas de inspiração nos deuses egípcios (equivalentes aos animais de tier 4), sem grande impacto na história; isso não autoriza introduzir fauna nem define entidades específicas. O mundo parece envelhecido por sua própria existência, não necessariamente por uma catástrofe tecnológica. Um caminho de terra ocre atravessa grandes massas rochosas sob um firmamento rubro escuro. O ambiente é hostil, mas legível.

Referências máximas indicadas pelo diretor:
- **Zdzisław Beksiński:** linguagem de formas erodidas, paisagens mortas, monumentalidade inquietante, organicidade fossilizada e atmosfera fúnebre. Extrair princípios de composição, não copiar pinturas.
- **Shin Megami Tensei II (1994):** composição ambiental, perspectiva em primeira pessoa, leitura de corredores, contraste entre firmamento rubro e terreno terroso, identidade cromática e austeridade de RPG dos anos 1990.

A identidade autoral é bíblica, primordial e metafísica. Evitar que a ambientação se reduza a fantasia medieval genérica ou a um inferno convencional de lava e fogo.

## 2. Estados de decisão

| Elemento | Estado | Evidência / limite |
|---|---|---|
| Mar de areia branca, desolação, céu vermelho-escuro | CONFIRMADO | GDD §§1.1, 16; premissa canônica. Não significa que todo terreno seja branco. |
| Beksiński e SMT II como referências máximas; marrom de subtom amarelo queimado | Direção expressa pelo diretor | Conversa sobre ambientação de 2026-11-24. |
| Estrada ocre, montanhas e paredões de terra/rocha | Referência visual fornecida | Modelo de estrada; forma e distribuição finais não homologadas. |
| Filtro misto 1 + 3 | Escolha visual expressa na conversa | Retorno ao filtro anterior após experimentos noisy; comparação no Godot fornecida. Preset técnico e integração na revisão atual do jogo não verificados por estas imagens. |
| Prisma Febril 75%, Miragem Arcana, Sinal em Decomposição | EXPERIMENTAL | Não são o filtro-base. Uso narrativo, parâmetros e gatilhos ainda não aprovados. |
| Hexadecimais, técnicas procedurais, modularidade e critérios abaixo | Referências / PROPOSTAS técnicas | Não constituem especificação definitiva de shader, escala, geometria ou orçamento de performance. |

## 3. Paleta cromática

O contraste fundamental é **céu rubro escuro × chão ocre amarelado × sombras profundas**. Preservar o subtom amarelo queimado do chão; não converter a terra em vermelho por causa da iluminação. A areia branca óssea é uma família distinta.

Paleta de referência do prompt de ambientação (valores aproximados, não amostras calibradas ou constantes aprovadas):

| Cor | HEX | Aplicação sugerida |
|---|---|---|
| Negro rubro | `#200D0B` | Sombras profundas, nuvens |
| Vermelho escuro queimado | `#481612` | Céu dominante |
| Vermelho sanguíneo | `#8D2D20` | Variações de nuvens |
| Luminosidade rubra | `#B54A32` | Horizonte difuso |
| Marrom ocre profundo | `#3D2D13` | Rocha sombreada, fendas |
| Marrom amarelado escuro | `#65491D` | Terra escura |
| Ocre queimado | `#95702F` | Solo principal |
| Amarelo terroso | `#B38B42` | Estrada iluminada |
| Ocre dourado ressecado | `#CEAD69` | Poeira, planos iluminados |
| Areia branca óssea | `#DFD8C5` | Mares de areia |

A prancha-resumo gerada também apresenta uma paleta alternativa ilustrativa: `#B17A35`, `#8A5B33`, `#6E1817`, `#351216`, `#1C0E11`, `#C6A17E`. Não confundir essas amostras com substituição da paleta anterior. A calibração final depende de aprovação e comparação no motor.

## 4. Linguagem ambiental

| Domínio | Direção visual e critérios propostos |
|---|---|
| Terrenos e estradas | Solo seco, terra compactada e rachaduras, cascalho e pedregulhos concentrados nas margens; variações entre ocre claro e escuro. Caminho relativamente plano, eixo de fuga legível. Areia branca com ondulações e aspecto mineral, não neve. |
| Montanhas | Grandes volumes assimétricos e erodidos, faces rochosas inclinadas ou íngremes, cristas irregulares, picos distantes e desfiladeiros. Hierarquia de massas; evitar cones deformados por ruído uniforme. |
| Iluminação | Firmamento rubro, luz difusa quente e contraste entre faces iluminadas e sombra profunda. Separação entre céu e terra. Névoa em camadas e diminuição de contraste à distância como recursos de profundidade, a calibrar. |
| Texturas | Rocha áspera, estratificação irregular, desgaste seco, terra compactada e rachaduras. Detalhe em várias escalas, cor localizada, brilho baixo; evitar aspecto plástico e ruído homogêneo. A leitura retro pode vir de textura e pós-processamento, não de redução arbitrária de geometria. |
| Geometria | Silhuetas intencionais, massas grandes, detalhes secundários localizados. Modularidade e seeds reproduzíveis quando úteis. Na perspectiva de jogo, esconder emendas sem obstruir passagens; respeitar dimensões reais da câmera/grid depois de verificadas. |
| Atmosfera | Crepúsculo interminável, opressão, vazio, desolação e estranheza. Poeira e névoa podem reforçar planos; não sacrificar leitura de caminhos, obstáculos ou inimigos. |
| Composição | Primeiro plano: chão, fragmentos; plano médio: estrada e paredões; plano distante: cordilheiras, silhuetas e céu. A referência do jogo usa um corredor em perspectiva central e HUD separado; não transformar a organização de um placeholder em regra de todos os mapas. |

Vegetação morta, formas semelhantes a costelas fossilizadas, monólitos e ruínas orgânicas são famílias conceituais para exploração, não confirmação de biomas, civilizações ou significados religiosos.

## 5. Pós-processamento

### 5.1 Base escolhida: mix 1 + 3

As imagens de comparação mostram uma aparência mais escura e rubra no corredor, com textura/pixelização perceptível, granulação e linhas horizontais discretas. Na estrada, a referência mista preserva melhor a família ocre e o céu vermelho do que a opção fortemente cromática. Este é o alvo visual de referência, não uma reprodução dos valores do shader.

- Preservar leitura do eixo de fuga, contornos, inimigos e HUD.
- Manter o solo amarelado distinto do céu rubro.
- Não incorporar o efeito de tela permanentemente nas texturas dos assets.
- Pixelização, grão, scanlines, aberração cromática, vinheta, desaturação seletiva e bloom são componentes a investigar/calibrar; não há confirmação individual de que todos existam no preset real.
- Verificar a cadeia de renderização e os parâmetros do Godot antes de alegar equivalência; não alterar o shader como parte deste guia.

### 5.2 Variações experimentais (não padrão)

| Variante | Características observáveis | Estado |
|---|---|---|
| 01 Prisma Febril | Ruído cromático intenso, franjas de cor, tons azulados/arroxeados, leitura psicodélica | Experimental |
| Prisma Febril 75% | Versão solicitada com 25% menos efeito; a imagem mostra ruído e franjas ainda marcantes. Não implica multiplicador uniforme confirmado para cada parâmetro. | Experimental; escolha posterior retornou ao mix anterior |
| 02 Miragem Arcana | Névoa e partículas douradas, contrastes escuros, impressão mágica | Experimental |
| 03 Sinal em Decomposição | Ruído pesado, aspecto rubro/terroso dessaturado, linhas de varredura e aparência de sinal degradado | Experimental |

Visões, eventos sobrenaturais e estados alterados são aplicações possíveis, não funcionalidades aprovadas. Os filtros devem ser comparados com a mesma câmera, geometria e iluminação para separar o efeito de tela de alterações na cena.

## 6. Prompt mestre reutilizável — Blender MCP

Copiar a seção abaixo para o agente de Blender. Os campos entre colchetes devem ser preenchidos para cada tarefa. Este prompt é orientação de produção proposta e não autorização para alterar o repositório ou estabelecer novo cânone.

~~~text
Você é artista técnico sênior de Environment Art para EXODUS (Maesto),
dungeon crawler 3D em primeira pessoa. Referências máximas: Zdzisław
Beksiński (formas, erosão, monumentalidade e inquietação metafísica)
e Shin Megami Tensei II (composição, atmosfera, leitura de exploração
e identidade cromática). Preserve a personalidade autoral do jogo.

TAREFA: [ASSET OU FAMÍLIA]
FUNÇÃO NO MAPA: [CAMINHÁVEL / LIMITE / HORIZONTE / PROP / OUTRA]
REFERÊNCIAS: [IMAGENS E GUIA]
ESCALA / GRID / CÂMERA: [VALORES VERIFICADOS OU PROVISÓRIOS]
VARIAÇÕES E SEED: [QUANTIDADE E SEED]
SAÍDA: [CENA EDITÁVEL / BIBLIOTECA / EXPORTAÇÃO AUTORIZADA]

1. Inspecione a conexão MCP, versão do Blender, cena, objetos, coleções,
   materiais, câmera e ferramentas realmente disponíveis. Não apague nem
   sobrescreva conteúdo preexistente sem autorização. Informe bloqueios.
2. Construa efetivamente o asset no Blender via ferramentas disponíveis.
   Use bpy, bmesh, Geometry Nodes, malhas, instanciamento e modificadores
   não destrutivos quando apropriados. Exponha parâmetros úteis e seed.
3. Aplique as regras visuais: terreno marrom amarelado/ocre queimado,
   sombras terrosas profundas, céu vermelho-escuro quando houver cena,
   areia branca óssea quando pertinente. Não tingir todo o chão de rubro.
   Formas assimétricas, erosão direcional, estratificação e hierarquia
   de massas; não usar ruído uniforme como substituto de direção artística.
4. Materiais ásperos, secos, pouco brilhantes; controles de cor primária
   e secundária, escala, rugosidade, erosão, rachaduras, estratificação
   e poeira quando pertinentes. Não exigir todos os efeitos em todo asset.
5. Preserve passagem e silhuetas legíveis na câmera real de exploração.
   Para estrada, distribuir pedras sobretudo nas margens; para montanha,
   variar cristas, inclinação e perfil sem repetir primitivas evidentes.
   Em cena, separar primeiro plano, plano médio e horizonte.
6. Exponha, conforme o tipo: seed, altura, largura, profundidade,
   assimetria, inclinação, curvatura, fraturas, erosão, estratificação,
   densidade de detalhes, distribuição de cores e complexidade.
   Preserve os geradores originais editáveis.
7. Capture viewport/render real, de preferência no ponto de vista do jogo
   e em vista de inspeção do asset. Compare silhueta, paleta, material,
   repetição, escala e navegabilidade com as referências. Corrija e capture
   novamente. Não declare fidelidade sem inspeção; aprovação é do diretor.
8. Separe materiais/iluminação de apresentação dos assets exportáveis.
   Quando solicitado, preparar UVs, origens, escala, contagem de triângulos,
   colisão simplificada, LODs ou baking necessários e exportação GLB/glTF
   compatível com a versão e configuração verificadas do Godot. Não presumir
   que Geometry Nodes, shaders e volumetria migram automaticamente.
9. Entregue evidências reais, nomes dos objetos/coleções, seeds, controles,
   arquivos efetivamente salvos, limitações e pendências. Não modificar o
   jogo sem autorização específica.

Evitar cartoon, fantasia medieval convencional, vegetação vibrante, céu
azul limpo, superfícies plásticas, realismo fotográfico sem identidade,
ornamentação aleatória e excesso de ruído ou partículas. Em caso de
ambiguidade de escala, mapa ou lore, marcar provisório ou pedir decisão.
~~~

### Exemplos de aplicação

| Asset | Instrução adicional | Inspeção |
|---|---|---|
| Segmento de estrada ocre | Gerador por curva/máscara; variantes reta, curva, bifurcação; terra compactada, rachaduras e margens irregulares | Continuidade do chão, percurso livre, subtom amarelo queimado |
| Paredão rochoso modular | Famílias assimétricas; massas grandes, estratos, erosão diferencial e bases irregulares | Silhueta, junções, ausência de padrão de repetição |
| Cordilheira distante | Picos e cristas irregulares, escala monumental e perda gradual de contraste | Separação de planos e leitura do horizonte |
| Céu rubro e névoa | Nuvens escuras e iluminação atmosférica em cena de demonstração separada | Solo não fica integralmente rubro; contraste e visibilidade preservados |
| Mar de areia branca | Branco ósseo, ondulações minerais e transição para terra ocre | Não parecer neve nem praia tropical |
| Monólito/ruína orgânica | Estudo de formas arcaicas, fossilizadas e erosionadas | Não estabelecer lore sem aprovação |

Três cenas de exploração propostas no prompt original: A) mar de areia branca com árvores mortas e horizonte montanhoso; B) estrada ocre entre paredões monumentais; C) desfiladeiro surreal com formações esqueléticas e ruínas conceituais. São estudos, não mapas aprovados.

## 7. Critérios de consistência e revisão

- [ ] Céu rubro e terreno ocre/amarelo queimado continuam cromaticamente distintos.
- [ ] Silhuetas monumentais e assimétricas, sem deformações aleatórias dominantes.
- [ ] Caminho, interseções, limites e obstáculos legíveis na perspectiva real.
- [ ] Texturas ásperas e hierarquia de detalhes, sem repetição excessiva.
- [ ] Névoa, grão e filtros não ocultam elementos necessários à exploração.
- [ ] Materiais, geradores e pós-processamento permanecem separados quando aplicável.
- [ ] Capturas reais antes/depois e parâmetros/seed registrados; aprovação visual reservada ao diretor.
- [ ] Não atribuir a propostas experimentais o status de decisões consolidadas.

## 8. Proveniência das referências

Arquivos fornecidos na conversa (identificados pelos nomes originais; os binários não foram incorporados nesta publicação):

| Arquivo | Papel |
|---|---|
| Exodus-Modelo-Estrada-Ocre.png | Modelo-base: estrada e montanhas ocres, firmamento vermelho. |
| Exodus-Print-Do-Jogo.png | Referência da exploração em primeira pessoa e HUD. |
| Exodus-Filtro-Misto-No-Jogo.png | Comparação sem filtro / Mix 1 + 3 no Godot. |
| Exodus-Prisma-Febril-75.png | Estudo de filtro psicodélico com redução solicitada de 25%. |
| Exodus-Tres-Filtros-Noisy.png | Comparativo de Prisma Febril, Miragem Arcana e Sinal em Decomposição. |
| Exodus-Filtro-Misto.png | Referência do mix aplicado ao modelo de estrada. |
| guia_de_direção_artística_exodus.png | Prancha-resumo ilustrativa gerada na conversa, não fonte técnica de parâmetros nem prova de aprovação. |

Fonte textual complementar: conversa "Descrever atmosfera do jogo" (2026-11-24), prompt mestre para Blender MCP, e conversa sobre conexão Blender e filtros. O presente registro mantém a distinção entre o que foi solicitado/selecionado e o que ainda precisa de validação. Não documenta execução de modelagem, implementação de shader ou homologação visual.
