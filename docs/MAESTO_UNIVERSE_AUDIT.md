# Auditoria Extrema do Universo Maesto / EXODUS

> **STATUS:** Documento de **auditoria histórica e referência** (gerado em 2026-11-27).
> **REGRA DE AUTORIDADE:** **Nenhuma informação listada abaixo torna-se cânone de EXODUS automaticamente.** Como as conversas cobrem mais de dois anos (`28/06/2023` a `30/11/2025`) e misturam projetos, épocas e iterações antigas, cada bloco carrega data, origem e status de cruzamento contra o cânone atual do repositório (`docs/DECISIONS.md` até `D-137`, `docs/GDD.md`, `docs/SURVIVAL_MODE.md` e `docs/MAGIC_VOCABULARY_BACKLOG.md`). Cabe exclusivamente ao autor aprovar, re-documentar ou descartar cada item.
> **HIGIENE DE DADOS:** Todo conteúdo pessoal, conversas cotidianas, links privados e referências fora do escopo ficcional foram estritamente excluídos.

---

## 1. Escopo, Fontes Auditadas e Fronteira de Universos

### 1.1 Fontes inspecionadas na íntegra
| Fonte | Período / Conteúdo | Volume auditado | Observação |
| :--- | :--- | :--- | :--- |
| `MAESTO.xlsx` | Sem datas internas (RPG de mesa / Goetia) | 10 abas (345 linhas preenchidas; 0 comentários; aba `Mecanicas` vazia; matriz `ELEMENTOS` 40×40 vazia) | Base estrutural de facções, 40 elementos, proficiências, Olímpios, raças/espécies, andares de Goetia e fichas curtas (`Descs`). |
| Arquivo de conversas completo (2023–2025) | `28/06/2023` – `02/09/2025` | 66.862 linhas analisadas via extração integral e dossiês temáticos completos | Principal fonte de cosmologia, sistema de magia, evoluções de 2024–2025, regras de espécies/animais e notas de EXODUS. |
| Recorte recente de conversas (2024–2025) | `23/11/2024` – `30/11/2025` | 485 linhas lidas integralmente | Contém notas recentes (`29/11/2025`: possível renomeação `Sambatia -> Sandarians`, `Muiraquitã`, termos *transmentalismo*, projetos paralelos). |
| Cânone atual do repositório EXODUS | `D-001` – `D-137` | `docs/DECISIONS.md`, `docs/GDD.md`, `docs/SURVIVAL_MODE.md`, `docs/MAGIC_VOCABULARY_BACKLOG.md`, `docs/plans/maesto-referencia-extraida.md` | Linha de base para marcar conflitos, omissões e compatibilidades. |

### 1.2 Legenda de classificação de auditoria
- **`[JÁ CANÔNICO]`** — Já documentado no repositório de EXODUS e consistente com as fontes.
- **`[RE-DOCUMENTAR / AMPLIAR]`** — Já existe de forma parcial ou rasa no repositório (`maesto-referencia-extraida.md` / `GDD.md`), mas as conversas trazem regras mais novas ou muito mais detalhadas.
- **`[NOVO / CANDIDATO]`** — Informação de universo relevante encontrada nas fontes que ainda **não existe** em nenhum documento do repositório.
- **`[CONFLITO / ULTRAPASSADO]`** — Contradiz o cânone atual de EXODUS ou uma iteração mais recente do próprio criador; exige decisão explícita.
- **`[OUTRA ERA / GOETIA]`** — Pertence ao mesmo universo **Maesto**, porém a eras muito posteriores a EXODUS (*2ª Guerra das Raças*, *Maestina/Maestena/Maestuna/Maestona*, *Goetia*, *Maesto F*).

### 1.3 Fronteira rigorosa entre universos (não misturar!)
Durante a auditoria, diversos termos homônimos ou obras paralelas apareceram nas conversas e foram **explicitamente segregados** para não contaminar Maesto/EXODUS:

| Obra | Autor | Exemplos excluídos do cânone de Maesto | Risco de confusão identificado |
| :--- | :--- | :--- | :--- |
| **Universo Maesto (ALVO)** | Criador | *EXODUS* (era primordial), *Masks* + *Uthópia* (2ª Guerra das Raças), *Maestina*, *Maestena*, *Maestuna*, *Maestona*, *Maestana*, *Goetia* (Torre Prisão / RPG), *Maesto F* (Futuro), *Dimensão Daema*. | Separar o que vale para a **era primordial (EXODUS)** do que só existe em eras posteriores (ex.: Eluminia, armas de fogo, Technomia). |
| **BV / Best Villain** | Criador | Zuzu, Zoa, Zaya, Zezé, Matai, Guido, Todd, Nyansuei, **Gimiqs**, ranques de Heróis, **Terminita** (mineral), Guffyn, Apockalos, temática biopunk/sci-fi. | **`Terminita` (mineral de BV) NÃO é `Terminia` (Daema de Maesto).** "Zona espiritual" via Gimiqs (`19/08/2024`) é de BV, não de Maesto. |
| **Outras obras do criador** | Criador | *Sekom Fokus* (Muiraquitã/Malverde), *DaiSpell* (projeto Godot separado de cartas / 3 chars: anjo, mago, fera), *Dynamo Skar*, *88 Cometas*, *Galagala*. | `Muiraquitã` (demônio da sorte que pinta pedras de verde, `11/2025`) aparece em contexto de *Sekom Fokus* / notas soltas — não assumir como Maesto sem aval. |

---

## 2. Cosmologia, THÉOS (Maesto), Tempo e Planos

### 2.1 Maesto (THÉOS) e o motivo cósmico do número 8
- **Design simbólico e base de Maesto** (`13–14/01/2024`) `[NOVO / CANDIDATO]`: forma construída simbolicamente por **8 linhas**, capa com o símbolo `8 / ∞`, 4 dedos, silhueta levemente robusta. Viaja em um **Cometa** (interior branco plano, janela panorâmica e uma pequena TV antiga no chão) junto aos **Regentes (Rulers) do universo** (nota em `07/06/2024` cogitando incluir um Regente de perfil tipo Nyarlathotep).
- **O número 8 como lei estrutural recorrente** (`2024–2025`) `[RE-DOCUMENTAR / AMPLIAR]`:
  - 8 linhas no design de Maesto e nos símbolos dos elementos (`24/09/2024`);
  - 8 dias para um terráqueo sem adaptação envelhecer e morrer na atmosfera de Maesto (`29/01/2024`) — mesma cadência dos 8 dias de regeneração Daema em EXODUS (`D-128` `[JÁ CANÔNICO]`);
  - Escala `0–8` em proficiências elementais, tipos de combate, atributos secundários e slots de habilidades (`18/01/2024`, `16/05/2025`);
  - 8 pontos de conjuração no corpo = prodígio raríssimo (`23/01/2024`);
  - 8 estilos de corte em Teccilia (`09/03/2025`), 8 usuários de `IKNI` no RPG de Goetia, 8 luas/dia na Torre Prisão (`12/06/2024`), 8 notas nos temas de entrada das facções (`30/08/2025`), limite de 8 frames por animação pensado para o jogo de Maestina (`15/08/2025`), nomes de 8 letras (*Masamune*, *Nephilim*).
- **Limites de jurisdição e intervenção de Maesto** (`03/12/2023`, `04/10/2024`) `[NOVO / CANDIDATO]`:
  - **Regra do "normita" (não-mágico)** (`03/12/2023`): Maesto **não pode interferir** se um evento 100% não-mágico (ex.: bomba nuclear puramente mundana) atingir um continente — só atua quando há magia envolvida; magia comum também não costuma conseguir barrar esse tipo de artefato diretamente.
  - **Jurisdição universal** (`04/10/2024`): THÉOS só possui poderes dentro de seu próprio universo (desejos só funcionam em Maesto).
- **Desejos, imortalidade e ressurreição** (`13/01/2024`, `30/01/2024`, `04/10/2024`, `07/05/2025`) `[NOVO / CANDIDATO]`:
  - **Oros** pediu imortalidade a Maesto e recebeu envelhecimento/rejuvenescimento livre e alteração de tamanho; **Skalemein** encara sua imortalidade como punição por assistir sua criação (`GENO`/`EMOT`) ser pervertida (`07/05/2025`).
  - **Ressurreição via Maesto** (`04/10/2024`): exige que o requerente reconstrua um quebra-cabeça de memórias pessoais profundas do falecido; Maesto envia a Morte (*La Muerte*) para buscar a alma, que retorna como um **Ghoskee** e precisa de um corpo preservado para ascender de volta.
  - **Alternativa via Noi** (`30/01/2024`): restaura o corpo a partir das cinzas, porém sem a alma (casca morta).

### 2.2 Atemporalidade, linha temporal linear e nomes
- **Gimmick da atemporalidade** (`17/05/2024`, `04/06/2024`) `[NOVO / CANDIDATO]`: regra explícita do universo — **nunca cravar datas/anos exatos**. Espadas, magia e armas de fogo caras coexistem em estética atemporal (armas de fogo equivalem aproximadamente ao dano de habilidades nível 3).
- **Linha do tempo estritamente linear (sem ramificações)** (`12/02/2025`) `[NOVO / CANDIDATO]`: o universo se autocorrige contra paradoxos. Retirar uma pedra do passado gera uma cópia de energia; puxar um ser vivo (ex.: Makultra) para o futuro gera apenas energia mágica que se dissipa; objetos imbuídos de energia levados por terceiros retornam ao passado após **8 minutos**.
- **Atmosfera e fisiologia** (`29/01/2024`) `[NOVO / CANDIDATO]`: terráqueos sem adaptação morrem de velhice em **8 dias** em Maesto; nativos se movem consideravelmente mais rápido.
- **Convenção de nomes** (`18/02/2024`) `[NOVO / CANDIDATO]`: Maesto usa nomes inventados; nomes com sonoridade terrestre indicam ascendência da Terra; nativos da Lua separam seus nomes com apóstrofos/acentos (ex.: `Diug'o`).

### 2.3 Planos, Dimensões, 5 Continentes e os 5 Submundos (Goetias)
- **Planos existentes** (`25/06/2025`) `[NOVO / CANDIDATO]`:
  1. **Mundo Físico**;
  2. **Estado Onírico (*Dream State*)**;
  3. **Mundo Espiritual (*Spirit World*)**;
  4. **Dimensão Daema** — plano hostil/inóspito. **Uthópia** (antiga cidade no norte de Maestuna da 2ª Guerra das Raças, estilo Wakanda, centrada em `MANA` e diplomacia não-violenta) migrou do Mundo Físico para dentro da Dimensão Daema; entrar lá exige abandonar o corpo físico (*ascensão*).
- **5 Continentes** (`16/05/2024`) `[RE-DOCUMENTAR / AMPLIAR]`: **Maestina**, **Maestena**, **Maestuna**, **Maestona** e **Maestana** (além de regiões como **Brassa** e **Hyperborea**).
  - Nota de tom entre continentes (`01/01/2024`, `20/08/2025`): **Maestina** tem foco pesado em magia (raros psíquicos fora dos magisters); **Maestena** e **Maestuna** quase não usam magia (foco físico/psíquico/mental; em Maestuna haveria ~4 usuários de magia além dos bombardeiros de Runan, mais o arco de *Spiralia* / ritual da *Zpyral*).
- **5 Submundos / Goetias e os Fencers** (`16–17/05/2024`, `27/06/2024`, `25/08/2024`) `[OUTRA ERA / GOETIA]`:
  - O ultra-submundo de cada continente corresponde a um conceito distinto de Inferno onde fica sua **Goetia** (Torre Prisão / purgatório), o **Daema da Morte** e os **Fencers** (ex.: Maestina = Inferno Cristão / Goetia do Fogo; Maestena = Inferno Grego / Rocha).
  - **Fencers:** facção estilo shinigami que caça alvos chamados **Anátemas** em troca de um desejo de nível Maesto, após entregar algo precioso à Morte. Ao matar um Anátema, seu corpo real fica selado no interespaço da arma do Fencer e ele é enviado para Goetia (reprogramado nas roupas exatas com que morreu — ex.: Tloin de cueca). Sair de Goetia de forma não-oficial transforma o fugitivo em um espírito físico; selar a arma do Fencer devolve o corpo real.
  - **Regra de morte dentro de Goetia** (`25/08/2024`): o prisioneiro revive exatamente como entrou (no RPG, discutido como penalidade roguelike de perder o progresso ao morrer, com preservação atrelada à **Heresia alta**, para impedir suicídio proposital para regenerar membros perdidos).
- **Relíquias de Oros e a Espada `Honjo`** (`16–17/05/2024`, `11/04/2025`) `[NOVO / CANDIDATO]`:
  - Relíquias (ex.: `Gallagofryied`, `Maça Spheria`, **`Honjo`**) são armas de Fencer/rituais esquecidas, invocadas com fluxo de sangue/energia + símbolo de 8 linhas.
  - **`Honjo`** (`11/04/2025`): espada mais afiada do universo, capaz de cortar dimensões e chave para encerrar a Dimensão Daema; forjada pelo mestre-sapo **Masamune** (técnica *Honjo Sunpô*) e guardada por um **Destiny Ruler**.

---

## 3. EXODUS Específico — Cruzamento com o Cânone Atual (`D-048`–`D-137`)

| Tema | Fonte & Data | Conteúdo encontrado | Cruzamento com EXODUS atual & Status |
| :--- | :--- | :--- | :--- |
| **Linha do tempo das Eras da Magia** | Chat `01/01/2024`, `11/04/2025`, `26/02/2025` | 1) **EXODUS (primordial):** só magia `HOLY` existe publicamente, com cast time de ~5 min; Deviron é o único usuário real de outros elementos (`26/04/2025`), sem cast time e com magia de baixo nível.<br>2) **2ª Guerra das Raças (*Masks* / *Uthópia*):** auge dos "magos verdadeiros" (magia em jarros, sub-elemento `SMOK` pleno, cura que nega a morte, magias Absolutas destruindo 4 cidades) e auge de **Teccilia**.<br>3) **3ª e 4ª Guerras das Raças → Maestina..Maestana / Goetia:** magos verdadeiros raros.<br>4) **Futuro (*Maesto F*):** declínio da magia, ascensão da **`Technomia` / `Tachiomia`** (`TECH`/`CODE`). | **`[CONFLITO / ULTRAPASSADO]`** — Em EXODUS canônico, `D-118` deu a Gabriel 5 rezas de fogo/luz (`Cherev`, `Or`, `Sanverim`, `Nechamah`, `Refuah`) e `D-124`/`D-131` deram skills diversas sem cast time de 5 min em batalha; além disso, o Survival já tem demônios usando múltiplos elementos e os Animais usarão `LEAF`/`VENO`/`AQUA`. Confirmar se "só HOLY público + 5 min" vale apenas como **lore diegético de humanos comuns na campanha** (enquanto Deviron, anjos e bestas/demônios são exceções) ou se foi revogado. |
| **Deviron e mutação visual de Devilmen** | Chat `06/10/2023` | Devilmen mudam de aparência e ganham novos sprites conforme fundem mais seres. | **`[JÁ CANÔNICO / AMPLIAR]`** — Alinha diretamente com `D-126`/`D-128` (Devilmen = humanos modificados fundidos com matéria Daema). Ainda não documentado no `GDD.md` o aspecto de evolução visual por fusões. |
| **Deviron como usuário original de `IKNI`** | Chat `16/05/2024` vs `17/05/2024` | Em `16/05/2024`, cogitou-se Deviron como usuário original de `IKNI` (para ligar EXODUS a Goetia). Um dia depois (`17/05/2024`), nomeou-se **Inin** como mestre original de `IKNI`, preso no 7º andar de Goetia. | **`[CONFLITO / ULTRAPASSADO]`** — Contradição interna de 24h entre Deviron e Inin como originador de `IKNI`. Decidir qual vale (ou se Inin é sucessor/derivado). |
| **1º companheiro de Deviron & Anjos "espers"** | Chat `06/10/2023` | Rascunho antigo: 1º companheiro de Deviron era uma criança (único membro são da party); anjos vilões descritos como *espers*. | **`[CONFLITO / ULTRAPASSADO]`** — Muito antigo (`2023`); em `D-118`/`D-128` os anjos seguem chave bíblica/hebraica (Gabriel, orações, Daema primordial). Provavelmente obsoleto; confirmar descarte. |
| **Judas em EXODUS** | Chat `18/12/2023` | Arco previsto para Judas: entra na party → sai por metade do jogo → volta como chefe → some → retorna como aliado → tenta ser chefe de novo → aliado permanente. | **`[NOVO / CANDIDATO]`** — Não consta em `docs/GDD.md`. Confirmar se esse arco ainda existe na campanha de EXODUS. |
| **Rei Herodes & `Permavenom`** | Chat `26/04/2025` | Herodes é a **primeira vítima de `Permavenom`**; vive acorrentado pelo pescoço (correntes largas tipo cinto) a **3 clérigos** que rezam cura 24/7 nele; para derrotá-lo é obrigatório matar os clérigos antes. | **`[RE-DOCUMENTAR / AMPLIAR]`** — Já aparece citado em `docs/plans/maesto-referencia-extraida.md` e como pendência em `GDD.md` §13; `Permavenom` é chave direta para ligar a lore de EXODUS ao elemento `TOXI`/`VENO`. |
| **Eluminia ≠ EXODUS** | `MAESTO.xlsx` + Chat `14/03/2025` + Nota `25/11/2026` | Ordem cristã de **Goetia** (muito posterior a EXODUS). | **`[OUTRA ERA / GOETIA]`** — Já vetada para EXODUS pelo criador em `25/11/2026`. Manter separada. |
| **Direção musical (OST) de EXODUS** | Chat `31/07/2024`, `22/10/2024` | Música clássica em **techno / synthwave**; temas de anjos como **ópera eletrônica** (em contraste com Maestina, que usa rock progressivo brasileiro/africano e percussão tribal). | **`[NOVO / CANDIDATO]`** — Direção sonora fortíssima ainda não registrada no `GDD.md`. |

---

## 4. Sistema de Magia, Energias e os 40+ Elementos

Esta é a área com o **maior volume de conteúdo novo** ausente de `docs/plans/maesto-referencia-extraida.md`.

### 4.1 Fundamentos da energia, corpo e cura
- **Três Energias e Harmonia** (`11/01/2024`, `27/03/2024`, `30/05/2024`) `[NOVO / CANDIDATO]`: energias de **Corpo**, **Mente** e **Alma** derivam todas da **Energia Vital / Escudo Mágico (`ES`)**. Conjurar exige harmonia entre as três (se a alma estiver desalinhada do corpo, a conjuração falha). Quebrar o Escudo Mágico drena a energia vital.
- **Escudo Mágico como MP emergencial** (`16/05/2025`) `[NOVO / CANDIDATO]`: pode ser gasto no lugar de `EN`/`MP` pagando **custo dobrado (2×)** (ex.: magia de custo 5 gasta 10 de Escudo Mágico).
- **Pontos de Conjuração e *Energy Flow*** (`01/01/2024`, `23/01/2024`, `04/08/2024`, `10/08/2024`, `12–19/12/2024`, `21/02/2025`) `[RE-DOCUMENTAR / AMPLIAR]`:
  - Magistas conduzem energia (*Energy Flow*) até **pontos de conjuração** no corpo; com maestria, o trajeto torna-se automático. **8 pontos bem posicionados** = prodígio raríssimo.
  - **0 pontos de conjuração:** impede conjuração corporal direta (exige armas mágicas ou conjuração vocal pela boca, como Bael em `21/02/2025`), porém **retém a energia dentro do corpo**, deixando o usuário "mais pesado" → **vantajoso para lutadores físicos** (mais dano físico e teoricamente menos dano mágico sofrido sem escudo, `10/08/2024`).
  - **Psíquicos** não dependem de pontos de conjuração, mas os usam para facilitar o fluxo de liberação psíquica (`10/08/2024`).
  - ***Shigan*** (selo físico `ZERO`): retira a energia do membro atingido; acertar o peito sela toda a conjuração (`19/12/2024`).
  - **Cortar magia** (`10/08/2024`): possível em Maesto, pois toda magia é energia condensada que pode ser dissipada ao meio.
- **Regra da Cura Impossível** (`25/08/2024`) `[NOVO / CANDIDATO]`: se o ser **nasceu com** uma condição/deficiência ou sofreu um dano **100% físico sem influência mágica**, a magia de cura comum **não consegue curar**.
- **Olho Mágico e Paradigmas Continentais** (`28/05/2024`, `27/06/2024`, `10/08/2024`) `[NOVO / CANDIDATO]`: cada continente ensina um modelo conceitual diferente de como a magia funciona (ex.: Maestina = energia viscosa translúcida; Maestona = 3 mundos / portais abrindo nos pontos de conjuração soltando faíscas), e o **Olho Mágico** renderiza a magia visualmente de acordo com o paradigma aprendido pelo usuário. Também permite enxergar **Minhocas de Energia** (contraparte da superfície dos *Maghouls* de Goetia).

### 4.2 Tipos de Combate, Atributos, Velocidades, Tiers e Formato de Skills
- **3 (+1) Tipos de Combate** (`05/04/2024`, `30/05/2024`, `16/05/2025`, `22/08/2025`) `[NOVO / CANDIDATO]`:
  - **Físico** (corpo a corpo, alto dano alvo-único), **Mágico** (versátil, projéteis, área), **Psíquico** (buffs/debuffs/emoções, "modo difícil") e **Híbrido**.
  - **Evolução final (`16/05/2025` e `22/08/2025`):** os 3 tipos passaram a ser **valores numéricos (`0–8`)** que funcionam como modificadores de efeito das habilidades, determinam resistências e influenciam `ATK`/`DEF`/`SPD`.
  - **Regra de Híbrido (`16/05/2025`):** diferença `≤ 2` entre os dois maiores tipos torna o personagem **Híbrido**, o que o deixa mais suscetível a dano do terceiro tipo não utilizado.
  - **Logo / 4º tipo (`26/02/2025`):** símbolo `8 / ∞` com 4 aberturas (Branco, Amarelo, Rosa, Azul); um 4º tipo **Verde** foi cogitado para a era futura (*Maesto F* / `Technomia`).
  - **Ubermage** (`30/05/2024`, `12/12/2024`): mestre simultâneo dos 3 tipos; consegue fluir todas as energias pelo corpo inteiro e voar.
- **8 Atributos finais do RPG Maesto** (`16/05/2025`, `22/08/2025`) `[OUTRA ERA / GOETIA]`: `HP`, `ES` (Escudo Mágico), `EN`/`MP`, `QI`, `SP`, `ATK`, `DEF`, `SPD`. Tetos discutidos: `HP/ES/EN` até 24; `SPD/QI` até 16 (ambos medem velocidade de ação e reação; psíquicos reagem com `QI`); demais até 8.
- **Velocidades e Tiers de Poder** (`08/04/2024`) `[OUTRA ERA / GOETIA]`:
  - **Velocidade:** `Charge < Normal < Nimble < Burst < Instant >< Ambush`.
  - **Tiers de Poder:** `T1 (0–2) Inferior` · `T2 (3–5) Intermediária` · `T3 (6–7) Superior` · `T4 (8–9) Absoluta` · `T5 (10) Ritual`.
- **Formato canônico de escrita de habilidades** (`22/08/2025`) `[NOVO / CANDIDATO]`:
  - 3 parágrafos: **Condição**, **Descrição**, **Efeito** + lista/FAQ de exceções.
  - **Pessoa gramatical define a raridade:** 3ª pessoa (`O magista`, `O lutador`, `O psíquico`) = habilidade genérica; 1ª pessoa = habilidade única de personagem (ex.: *Shock-mate!!!* do Warlock); `Discípulo de` / `Usuário de` = habilidade de mestre ou relíquia.

### 4.3 Regras Gerais dos Elementos
- **Afinidade hereditária** (`18/11/2023`, `20/08/2025`) `[NOVO / CANDIDATO]`: descendentes de usuários de um elemento aprendem-no com mais facilidade.
- **2 Elementos Iniciais + Enhances + Mestres de 4 Letras** (`29/05/2025`) `[RE-DOCUMENTAR / AMPLIAR]`: personagens começam com **2 elementos**; elementos adicionais são destravados via **Enhances**, entrada em facção (4 skills evoluíveis) ou **mestres com nomes de 4 letras** (regra oculta: `Tosh`/Azulmagia → `CELL`, `Thon` → `SMOK`, `Neva` → `EMOT`, `Onai`, etc.). Facções focadas num sub-elemento também podem usar seu elemento-pai.
- **Proficiência `0–8` e habilidades híbridas** (`MAESTO.xlsx`, `12/04/2024`, `30/05/2024`) `[RE-DOCUMENTAR / AMPLIAR]`: a proficiência em `Ofensiva / Defensiva / Utilitária / Suportiva` indica quantidade/potência das referências catalogadas (`0` não proíbe inventar uma skill). Habilidades podem combinar **2 categorias** e **2 elementos**.
- **Sub-elementos compensam fraquezas do elemento-pai** (`05/05/2025`) `[NOVO / CANDIDATO]`: ex., `AQUA` é fraco em Ofensiva/Defensiva (`2/0`), sendo compensado por `CRYO` (`6/6`).
- **Marcas Elementais (*Elemental Marks*)** (`30/05/2024`) `[NOVO / CANDIDATO]`: receber **4 ou 8 acertos** do mesmo elemento aplica a condição negativa daquele elemento; usuários do mesmo elemento são **imunes às marcas dele**. *(Paralelo direto com `Mark of Sun` já em EXODUS `D-131` e excelente base para marcas de `LEAF`/`VENO`/`AQUA`!)*
- **Inversão de Magia** (`14/03/2025`) `[NOVO / CANDIDATO]`: conjurar uma magia no sentido inverso (ex.: veneno ↔ antídoto, cura ↔ dano), dispensando magias separadas para antídotos. *(Dúvida aberta registrada pelo criador: como funcionaria com Olímpios, por serem pura energia.)*
- **Composição elemental** (`01/02/2025`) `[NOVO / CANDIDATO]`: certos elementos derivam da composição de outros — exemplo confirmado: **`LEAF = AQUA + ROCK`**.
- **Meta de enxugamento da lista** (`12/05/2025`) `[RE-DOCUMENTAR / AMPLIAR]`: objetivo de reduzir o catálogo para **38–39 elementos** (com **`LAVA` riscado/cortado** e **`GENO` renomeado para `EMOT`** — pronúncia *Í-MO-TE*).

### 4.4 Magias de Cor e Magia Tradicional (Bruxaria)
- **Magias de Cor** (`27/06/2024`, `08/12/2024`, `22/08/2025`) `[RE-DOCUMENTAR / AMPLIAR]`: tingem permanentemente o Escudo Mágico do usuário no Olho Mágico.
  - **Magia Branca:** coloniza o alvo como um "summon" do usuário; ao sair do alcance, o alvo perde as memórias (usada por Makultra).
  - **Magia Negra:** *dispell* absoluto — cancela até **`Permavenom`**.
  - **Magia Verde:** usada por `Diug'o` e `Tloin` (futuro Leafian *Sudê Misê*); detalhes mecânicos ainda abertos.
  - **Magia Azul (`22/08/2025`):** além de copiar habilidades genéricas, cria **sintonia entre os tipos** do usuário — iguala o valor de outro tipo ao valor de Mágico e converte dano recebido de outro tipo em dano Mágico.
- **Magia Tradicional / Bruxaria (*Witchcraft*)** (`29/08/2025`) `[NOVO / CANDIDATO]`: manipula matéria e seres diretamente sem distorção de energia ("farmácia de manipulação"; alquimia = bruxaria). É **mais forte que magia de energia**, chegando perto do nível **Ubermage**. Exige 4 componentes: sangue menstrual (mulheres cis ou homens trans), caldeirão, chapéu e pet.

### 4.5 Catálogo Consolidado dos Elementos (`MAESTO.xlsx` + Atualizações 2024–2025)
> **Nota canônica (`D-138`):** A sistematização abaixo pertence ao **mundo mais recente** de Maesto (não ao contexto primordial de EXODUS), **porém as magias prevalecem**. Elementos podem ter múltiplos nomes (ex.: **`TOXI` = `VENO`**). Em EXODUS não há influência nem afinidade elemental — elementos são delegados por raça (`D-119`/`D-138`).
> Ordem de proficiência padronizada nesta tabela: **`Of / Df / Ut / Sp`** (na planilha original, a seção de sub-elementos invertia `Sp` e `Ut` nas linhas 11–12/17–18/23–24 — aqui todas as linhas já foram normalizadas para **`Of / Df / Ut / Sp`**!).

| Grupo | Elem | Sub-elementos | Olímpio (`xlsx`) | Proficiência (`Of/Df/Ut/Sp`) | Notas de lore & atualizações 2024–2025 |
| :--- | :--- | :--- | :--- | :---: | :--- |
| **Primordial** | **IGNI** | — | Prometheus | `8 / 2 / 4 / 1` | Único com texto no `xlsx`: fogo, combustão e raio; alto custo e dano explosivo/AoE; fraco em defesa/suporte. |
| ↳ sub | `RAIN` | de `IGNI` | Urano | `8 / 0 / 8 / 0` | Usado por Tunidria (`Warlock`: *Ultima Shockmate* = `RAIN + GRAV`). |
| ↳ sub | `BOMB` | de `IGNI` | Typhon | `8 / 0 / 8 / 0` | Explosões puras; zero defesa/suporte. |
| **Primordial** | **AQUA** | — | Poseidon | `2 / 0 / 6 / 8` | Foco altíssimo em **suporte/utilidade** (`8`/`6`), fraco em ataque/defesa (`2`/`0`). Magia ofensiva assinatura mais forte: **`Escarudô`** (inventada por **Iwain**, Major Guard do 7º andar, `26/06/2025`). Com `IKNI`, Bael molda insetos d'água (`21/02/2025`). |
| ↳ sub | `CRYO` | de `AQUA` | Boreas | `6 / 6 / 4 / 0` | Compensa a fraqueza ofensiva/defensiva de `AQUA` (`05/05/2025`). Equivalente de *Escarudô*: **`Coldô-Escarudô`** (`26/06/2025`). |
| ↳ sub | `BLOD` | de `AQUA` | Ares *(alt MEAT)* | `0 / 3 / 5 / 8` | Suporte/hemomancia; ligado originalmente a Sambatia (hoje secundário frente a `SAND`). |
| ↳ sub | `ACID` | de `AQUA` e `TOXI` | *(sem Olímpio)* | `8 / 0 / 8 / 0` | Aparece sob `AQUA` e sob `TOXI` na aba `Posições e elementos explicados`. |
| **Primordial** | **AERO** | — | Zéfiro | `2 / 1 / 7 / 6` | Utilitário/suporte; foco de Merrymen e secundário de Danzaria. |
| ↳ sub | `SMOK` | de `AERO` | Erebos | `8 / 0 / 8 / 0` | Teve auge pleno na 2ª Guerra das Raças (`01/01/2024`); mestre de 4 letras: `Thon`. |
| ↳ sub | `CLOD` | de `AERO` | Zephyros | `0 / 4 / 8 / 4` | Nuvens/controle utilitário (note duplicidade de nome grego `Zéfiro`/`Zephyros` no `xlsx`). |
| **Primordial** | **ROCK** | — | Gaia | `8 / 6 / 1 / 1` | Altíssimo ataque e defesa; foco puro de Terrafia; entra em `LEAF = AQUA + ROCK`. |
| ↳ sub | `SAND` | de `ROCK` | Rhea | `5 / 5 / 6 / 0` | Equilibrado; virou foco central de Sambatia (*Sandarians*, `29/05/2025`, `29/11/2025`). |
| ↳ sub | `IRON` | de `ROCK` | Hefesto | `4 / 6 / 6 / 0` | Defesa/utilidade; foco de Teccilia (`29/05/2025`). |
| *(cortado)* | ~~`LAVA`~~ | *(só aba ELEMENTOS)* | *(nenhum)* | — | **`[CONFLITO / ULTRAPASSADO]`** — Riscado/cortado pelo criador em `05/05/2025`. |
| **De Tipo** | **ZERO** | — | Hermes | `6 / 6 / 2 / 2` | Governa **Magia do Caos** (`10/12/2024`); base física de selamento (*Shigan*), Eluminia física (`14/03/2025`), Teccilia, Denagorma e Merrymen. |
| ↳ sub | `ARTS` | de `ZERO` | *(sem Olímpio)* | `4 / 4 / 4 / 4` | **Magia Ninja** (`05–06/12/2024`): custo minúsculo de energia, puxa de **2 fontes elementais do ambiente**; nomes no formato **`(Elemento) + Veil`**. |
| **De Tipo** | **MIND** | — | Deimos | `3 / 2 / 8 / 3` | Psíquico utilitário (`8`). |
| ↳ sub | `GENO` → **`EMOT`** | de `MIND` | Afrodite | `0 / 2 / 6 / 8` | Não-ofensivo, puro suporte/utilidade; criado pelo Grão-Mago **Skalemein**; renomeado para **`EMOT`** (*Í-MO-TE*, `05–07/05/2025`). Mestre de 4 letras: `Neva`. |
| **De Tipo** | **MANA** | — | Hecate | `6 / 6 / 4 / 0` | Energia pura; núcleo histórico de **Uthópia** (`25/06/2025`). |
| ↳ sub | `SOUL` | de `MANA` | Thanatos | `2 / 4 / 5 / 5` | Alma/espírito; usado por Merrymen. |
| **Iluminação** | **LUZI** | — | Iris | `4 / 0 / 8 / 6` | Utilitário/suporte; golpe puro assinatura no RPG: *Divine Ray* (`23/01/2024`). |
| ↳ sub | `HOLY` | de `LUZI` | Athena | `0 / 4 / 4 / 8` | Suporte/defesa (`0` ofensiva no `xlsx`!); único elemento público na era EXODUS segundo `01/01/2024`. |
| ↳ sub | `MOON` (luz) | de `LUZI` | Selene | `0 / 6 / 8 / 2` | Vertente defensiva/utilitária da Lua (ex.: *Shirã Mikô* de Teccilia). |
| **Iluminação** | **DARK** | — | Erebus | `8 / 0 / 6 / 2` | Alto dano/utilidade, zero defesa. |
| ↳ sub | `VODO` | de `DARK` | Phobos | `3 / 3 / 6 / 6` | Maldições/efeitos; usado por Vecnalia (`29/05/2025`). |
| ↳ sub | `MOON` (dark) | de `DARK` | Selene | `8 / 0 / 8 / 0` | Vertente puramente ofensiva/utilitária da Lua (dupla entrada intencional na planilha). |
| **Natureza** | **LEAF** | — | Demeter | `1 / 4 / 5 / 8` | **Composição de `AQUA + ROCK`** (`01/02/2025`). Proficiência fortemente **suportiva/utilitária/defensiva** (`8`/`5`/`4`), ataque direto baixo (`1`). Usado por Vecnalia e Traidor Agin (*Maduga Ray*). |
| ↳ sub | `WOOD` | de `LEAF` | Persephone | `2 / 6 / 6 / 2` | Compensa defesa/utilidade de `LEAF`; base da *Bambúsia* de Teccilia e de Merrymen. |
| **Natureza** | **TOXI / VENO** | — | Achlys | `8 / 0 / 8 / 0` | **Máxima ofensiva e utilidade (`8`/`8`), zero defesa/suporte.** **`TOXI` e `VENO` são o mesmo elemento (`D-138` — elementos podem ter vários nomes).** Na reformulação de Vecnalia (`14/03/2025`, `28/08/2025`), gira em torno de **efeitos colaterais** (drogas = buffs, venenos = debuffs de stats), uniformes envenenados (imunidade ao próprio veneno) e **inversão de magia** (antídoto = inverso do veneno). |
| ↳ sub | `FUNG` | de `TOXI` | Dionísio | `6 / 0 / 4 / 6` | Fungos/esporos; compensa `TOXI` trazendo **Suporte (`6`)** mantendo ataque (`6`). |
| **Espacial** | **ETER** | — | Aether | `4 / 4 / 8 / 0` | Governa **Espaço E Sonhos** (`12/05/2025`). |
| ↳ sub | `STAR` | de `ETER` | Hélio | `8 / 0 / 4 / 4` | Ofensiva estelar (`8`). |
| ↳ sub | `VOID` | de `ETER` | Tártaro | `4 / 4 / 8 / 0` | Vazio espacial/utilidade (`8`). |
| **Biológico** | **IKNI** | — | Pan | `4 / 4 / 4 / 4` | Perfeitamente balanceado (`4/4/4/4`). Biológico; gangrena conta como `IKNI`; 8 usuários no RPG de Goetia; origem disputada entre Deviron (`16/05/2024`) e **Inin** (`17/05/2024`). |
| ↳ sub | `CELL` | de `IKNI` | Asclépio | `6 / 2 / 2 / 6` | Celular/regeneração (*Biocell* criado por **Ikna**; mestre de 4 letras: `Tosh`/Azulmagia). |
| ↳ sub | `BONE` | de `IKNI` | Hades | `0 / 6 / 4 / 6` | Defesa e suporte ósseo (`0` ofensiva). |
| ↳ sub | `MEAT` | de `IKNI` | *(alt Ares)* | `4 / 2 / 4 / 6` | Carne/músculo; aparece nas abas de proficiência/explicação/Olimpios (alt Ares) mas faltou na matriz `ELEMENTOS`. Usado por Sambatia. |
| **Físico** | **GRAV** | — | Crios | `6 / 2 / 8 / 0` | Gravidade; compõe *Ultima Shockmate* (`RAIN + GRAV`). |
| ↳ sub | `ELEC` | de `GRAV` | Zeus | `6 / 0 / 8 / 2` | Eletricidade; foco de Tunidria. |
| ↳ sub | `SONG` | de `GRAV` | Apolo | `5 / 0 / 6 / 5` | Som/música; usado por Danzaria e Teccilia. |
| ↳ sub | `TIME` | de `GRAV` | Cronos | `4 / 4 / 8 / 0` | Tempo (sujeito às regras de linha temporal linear de `12/02/2025`). |
| **Futuro (*Maesto F*)** | **`TECH` / `CODE`** | — | *(nenhum)* | — | **`[OUTRA ERA / GOETIA]`** — `Technomia` / `Tachiomia` (`17/01/2025`, `26/02/2025`): tecnologia orgânica/tribal da era futura quando a magia entra em declínio. |

---

## 5. Raças, Espécies, Animais e Genética

### 5.1 Raças Humanas (`MAESTO.xlsx` vs `28/08/2024` vs `28/04/2025`)
- **Humanos Normais** (`28/04/2025`) `[NOVO / CANDIDATO]`: maior longevidade que muitas espécies, alta adaptabilidade física (temperatura/ferimentos) e **genética recessiva** na reprodução interespecífica — **88% dos descendentes** herdam a raça não-humana; quando cruzam com espécies sem corpo ou de "corpo inferior", o filho recebe um corpo adaptado ao padrão humano.
- **Elfmen** (`28/04/2025`) `[NOVO / CANDIDATO]`: mutações geomágicas humanas; orelhas/nariz pontudos, olhos mais estreitos, ágeis em florestas. **Habilidade de espécie:** camuflagem florestal perfeita adaptando-se a árvores, plantas e fauna.
- **Fishmen** (`15/01/2024`, `28/04/2025`) `[NOVO / CANDIDATO]`: mutações geomágicas com traços aquáticos; vivem no fundo do mar; a maioria sofre de **rinite aquática** (não respira continuamente em terra sem aparato/remédio); ostracizados tanto em terra quanto debaixo d'água.
- **Orcmen** (`MAESTO.xlsx` + `28/08/2024`) `[CONFLITO / ULTRAPASSADO]`:
  - **Habilidade de espécie (`28/08/2024`):** **imunidade completa à magia** (zero energia mágica no corpo; não conseguem sequer usar varinhas). Não existem em Goetia.
  - **Contradição:** `MAESTO.xlsx` lista `Orcman` como sub-raça de `Human`, mas o texto detalhado de `28/04/2025` lista apenas **3 raças humanas** (Normais, Elfmen, Fishmen) sem mencionar Orcmen. Confirmar se Orcmen continuam como 4ª raça humana, viraram outra categoria ou foram cortados.

### 5.2 Demônios vs Daemas, Animais, Híbridos e Tiers (`0–4`)
- **Demônio ≠ Daema** (`28/04/2025`) `[JÁ CANÔNICO / AMPLIAR]`: o termo "Demônio" segue o sentido etimológico de *algo novo/diferente do normal*, enquanto o arquétipo clássico de "demônio infernal" pertence aos **Daemas** (alinhado com `D-126`/`D-128`).
- **Tiers de Animais e proibição do Tier 5** (`08/02/2024`, `15/03/2024`, `28/04/2025`) `[NOVO / CANDIDATO]`:
  - Os animais antropomórficos/animalescos seguem a escala furry de **Tiers 0 a 4**; **Tier 5 (humanos apenas com orelhas/cauda de animal) NÃO existe** no universo.
  - **Herança de Tiers (`28/04/2025`):**
    - Pais de tiers diferentes → filho nasce no **tier mais alto**;
    - Pais do mesmo tier → filho nasce em **tier + 1**;
    - Cruzamento entre espécies diferentes com mãe de espécie diferente → filho nasce no tier mais alto, porém **perde a habilidade de espécie**, exceto em caso de **genes abso-dominantes**.
- **Híbridos animais e Demônios Organos (*Ogademon*)** (`28/04/2025`) `[NOVO / CANDIDATO]`:
  - Cruzamentos entre espécies animais distintas são normalmente inférteis (biologia real) e **não** contam como demônios.
  - **Exceção raríssima:** se o híbrido nascer fértil **e** com habilidade de espécie, funda uma nova espécie de Demônio sem um Daema originador — chamados **Demônios Organos** (*Ogademon*, paralelo a *Nephilim*).
- **Espécies específicas documentadas nas conversas** `[NOVO / CANDIDATO]`:
  - **Succubas Primordiais** (`30/04/2025`): evolução literal para uma nova espécie.
  - **Nefarros** (`14/01/2024`): animam areia ao consumir um único grão de açúcar.
  - **Marmekianos** (`28/10/2024`): nativos de Maestona, dizimados em Maestina durante as Guerras das Raças.
  - **Plantanas** (`12/01/2024`): a árvore *Alraune* erradica a vida ao redor para gerar novos Plantanas.
  - **Kobolds** (`05/04/2024`): demônio híbrido cachorro + lagarto.
  - **Daemas nomeados na planilha (`MAESTO.xlsx`):** `Aglasis (Satoro)`, `Cypher (Warlock)`, `Anathia (Ivara)`, `Lanperroh (Landlord)`, `Perspecto`, `Terminia`, `Amnerita`, `Anglesmiller (Smiley)`, `Mathrus`, `Paradox`, `Mantarine (Queen Island)`.

---

## 6. Evolução das 9 Facções e Estrutura de Goetia (`[OUTRA ERA / GOETIA]`)

Comparativo entre a planilha `MAESTO.xlsx` (sem data) e as reformulações de `2024–2025` nas conversas:

| Facção | Alinhamento (`xlsx`) | Elementos (`29/05/2025`) | Resumo base (`xlsx`) + Atualizações 2024–2025 |
| :--- | :--- | :--- | :--- |
| **Teccilia** | Lawful Neutral | `(IRON) / WOOD / ZERO / (SONG)` | Assassinos de *Bambúsia* (`Bambushidô`, `Mokumahou Ninjutsu`, `Shirã Mikô`). **Atualizações:** proíbe humanos (`26/09/2024`); código de morte da lâmina — desembainhou, tem que matar (`23/02/2025`); 8 estilos de corte (`09/03/2025`); auge na 2ª Guerra das Raças; **Ubarãn** e vassalos usam o **Sol Vermelho** em homenagem ao sapo-mestre **Masamune** (`11/04/2025`, `24/08/2025`); reformulação completa via Masamune (`21/04/2025`); gimmick = lâminas (`28/08/2025`). |
| **Tunidria** | Neutral Evil | `ROCK / (RAIN) / ELEC / MANA / (CRYO)` | Reino expansionista de 1 rei + 3 Warmasters (`Warlock`, `Warruler`, `Warseal`). **Atualizações:** os 3 Warmasters guardam **Hyperborea** (Ruler julga entrada, Lock guarda o portão, Seal guarda o perímetro, `28/09/2024`); **Warseal** é uma foca/peixe-boi idoso e o **único mortal não-Daema** dos 3, com a Absoluta *Crownthunder* (`18/10/2024`, `22/11/2024`); *Warlock* tem *Ultima Shockmate* (`RAIN + GRAV`). |
| **Vecnalia** | Chaotic Evil | `(TOXI) / LEAF / VODO / (FUNG)` | Ladrões/contrabandistas de venenos (`Larápio Venenoso`, `Empresário Intimidador`, `Corsário Oportunista`). **Atualizações:** **uniformes envenenados** concedendo imunidade permanente ao próprio veneno (`14/03/2025`); gimmick reformulada para **efeitos colaterais** (drogas = buffs, venenos = debuffs de atributos, `28/08/2025`); adição de uma **Bruxa** (Magia Tradicional, `29/08/2025`). |
| **Sambatia** *(→ Sandarians?)* | Neutral Good | `(SAND) / MEAT / (BLOD) / EMOT` | Irmãos de sangue punidores de "denunciados" com Luvas Mercuriais (`Hemolinfa`, `Salvaguarda`, `Intervenção`). **Atualizações:** capuzes cabeça-de-crocodilo para nadar na areia + *Blood Seekers* (`11/02/2025`); foco migrado de sangue para **areia** (`29/05/2025`); proposta de renomear para **Sandarians** (`29/11/2025`). |
| **Eluminia** | Lawful Evil | `LUZI` (e `ZERO` físico) | **EXCLUSIVA DE GOETIA (vetada para EXODUS).** Era 80% mágica no `xlsx`; em `26/09/2024` proíbe monstros; em `14/03/2025` virou **70% física** (`ZERO` + `LUZI/HOLY`) com doutrinas de **auto-punição** e **overheal**. |
| **Merrymen** | `?` | `(AERO) / ZERO / WOOD / SOUL` | Só esqueleto no `xlsx` (50% Psíquico / 50% Físico). **Atualizações:** 1ª doutrina = **Belomancia** (adivinhação com flechas: intel/buffs psíquicos, `06/08/2024`); 2ª doutrina = instrumentos africanos de corda/arco (`05/09/2024`); uniforme inspirado em estética mongol. |
| **Terrafia** | Chaotic Neutral | `ROCK` | Monges solitários de Gaia em templo de quartzo insular (proibida cooperação); disputam o **Elmo de Gaia** (`Terraformação`, `Geomância`, `Blindagem`). |
| **Denagorma** | Lawful Good | `(IGNI) / MANA / ZERO / (AQUA)` | Fundação anti-drogas mágicas (`Punho Flamejante`, `Frigidez Ardente`, `Alucinação Inflamada`); pune fortalecimentos inimigos e marca fugitivos com o Selo de Denagorma. |
| **Danzaria** | Chaotic Good | `AQUA / (EMOT) / (SONG) / AERO` | Culto de *Gaga Babylon*; dançarinas que convertem luto em coreografias astrais (`Abalo`, `Graça`, `Tumulto`). |
| **Outras / Internas** | — | — | Facções internas da prisão Goetia (**Fencers**, lutadores, saqueadores, fazendeiros) e os saqueadores **Caça-Doletas** em Maestina. |

- **Torre Prisão de Goetia (`MAESTO.xlsx`, aba `Niveis rpg`):** 10 andares (`0 Dornaim` [1 km] → `1 Aganophér` [5 km; sub: *Stone Furnaces*] → `2 Santhbound` [10 km] → `3 Letuarn` [5 km] → `4 Ruinrain` [3 km; sub: *Vodyan Sanctuary*] → `5 Dorromika` [15 km] → `6 Kogubesh` [20 km; sub: *Plantinae Garden*] → `7 Windcast` [2 km] → `8 Anhalyca` [1 km] → `9 Granlorde` [666 m]), com 8 luas/dia (`12/06/2024`).

---

## 7. Implicações Diretas para o EXODUS e os Animais do Modo Survival (`LEAF`, `VENO`, `AQUA`)

> **ATUALIZAÇÃO CANÔNICA (`D-138`, 2026-11-27):** Decisões fechadas pelo autor aplicadas abaixo:
> - **Sinônimos elementais:** elementos podem ter vários nomes — **`TOXI` e `VENO` são o mesmo elemento**.
> - **Era vs Magias:** a estrutura/classificação elemental de Maesto (Seção 4) pertence ao **mundo mais recente**, não ao contexto primordial de EXODUS — **porém as magias prevalecem**.
> - **Sem influência nem afinidade elemental (`D-119` + `D-138`):** não existe mais influência nem afinidade elemental no jogo; elementos são **delegados especificamente às raças**. Por enquanto, **apenas os Animais** têm elementos definidos (`LEAF`, `VENO`/`TOXI`, `AQUA` — 2 por animal); as demais raças permanecem **PENDENTES**.

Pontos ativos para a implementação dos **Animais no Modo Survival** (2 elementos entre **`LEAF`**, **`VENO`/`TOXI`** e **`AQUA`**):

1. **Sinônimo `TOXI` = `VENO` (`[JÁ CANÔNICO — D-138]`):** `TOXI` e `VENO` designam o mesmo elemento; no EXODUS/Survival podemos usar `VENO` livremente preservando o repertório mágico de venenos/efeitos colaterais (`Permavenom`, debuffs, toxinas).
2. **Repertório mágico de referência dos 3 elementos (`D-138` — magias prevalecem, sem afinidade/influência elemental):**
   - **`LEAF`** (referência Maesto: `Of 1 / Df 4 / Ut 5 / Sp 8`): magias voltadas a **suporte, cura/regeneração, defesa e controle de campo** (e construtos vegetais/madeira).
   - **`AQUA`** (referência Maesto: `Of 2 / Df 0 / Ut 6 / Sp 8`, assinatura ofensiva rara: `Escarudô`): magias de **suporte e utilidade**, com técnicas ofensivas pontuais (como equivalentes de `Escarudô`).
   - **`VENO` / `TOXI`** (referência Maesto: `Of 8 / Df 0 / Ut 8 / Sp 0`): **o motor ofensivo e disruptivo do trio** — venenos como **debuffs de atributos + dano contínuo**, toxinas/drogas como **buffs com efeito colateral** e **inversão** (veneno ↔ antídoto).
   - **Nota de design em batalha:** sem influência/afinidade elemental no jogo (`D-119`/`D-138`), o papel de cada elemento aparece exclusivamente no **kit de magias/efeitos** de cada animal; um animal **`LEAF + AQUA`** deve receber ao menos 1 magia ofensiva expressiva (ex.: equivalente de `Escarudô` ou espinhos/raízes) para não ficar passivo demais.
3. **Mecânica de Marcas (`30/05/2024`):** opcional para kits de `LEAF`/`VENO`/`AQUA` sem criar imunidade/afinidade elemental automática (respeitando `D-119`/`D-138`).
4. **Identidade biológica dos Animais (`28/04/2025`):** confirmar que os 8–9 sprites SMT escolhidos respeitam a regra **Tiers 0–4 (sem Tier 5)**.
5. **Conflito de sprite já detectado no Survival:** dos 9 sprites escolhidos, **`Anubis`** (`Avatar Anubis.png`, id `"anubis"`) **já está cadastrado** como um dos 35 demônios do Survival em `scripts/survival/survival_data.gd` e `scripts/survival/survival_strata.gd`. Os outros 8 (`Neko Shogun`, `Bastet`, `Azumi`, `Sobek`, `Hamsa`, `Girimekhala`, `Camazotz`, `Flauros`) estão 100% livres.

---

## 8. Matriz de Decisões Pendentes para o Autor

| # | Tema | Situação atual | Pergunta / Decisão para o autor |
| :-: | :--- | :--- | :--- |
| **1** | **`TOXI` vs `VENO`, era dos elementos e delegação por raça** | **`[DECIDIDO — D-138]`** Elementos têm múltiplos nomes (`TOXI = VENO`); classificações elementais são do mundo mais recente, mas as magias prevalecem; não há influência nem afinidade elemental no jogo; elementos são delegados por raça (por ora só **Animais**: `LEAF`, `VENO`/`TOXI`, `AQUA`). | **Pendente apenas:** definir futuramente a delegação elemental das demais raças (além dos Animais). |
| **2** | **Magia na Era EXODUS** | Chat `01/01/2024` diz "só `HOLY` público, 5 min cast"; `D-118`/`D-124`/`D-131` e Survival usam vários elementos sem 5 min. | "Só HOLY + 5 min" fica só como lore de humanos comuns na campanha ou está descartado? |
| **3** | **Origem de `IKNI`** | Chat `16/05/2024` = Deviron; chat `17/05/2024` = Inin. | Quem é o originador canônico de `IKNI` (ou nenhum dos dois)? |
| **4** | **Herodes & `Permavenom`** | Citado em `26/04/2025`, pendente no `GDD.md` §13. | Promover Herodes (3 clérigos acorrentados + 1ª vítima de `Permavenom`) para cânone de EXODUS? |
| **5** | **Judas & OST Techno-Clássica** | Chat `18/12/2023` (arco Judas) e `31/07/2024` (OST synthwave clássica / anjos ópera eletrônica). | Algum desses dois continua valendo para EXODUS? |
| **6** | **Orcmen como raça humana** | `MAESTO.xlsx` inclui `Orcman`; `28/04/2025` lista só 3 raças humanas (Normais, Elfmen, Fishmen). | Orcmen (imunidade absoluta à magia) ainda existem e são humanos ou outra raça? |
| **7** | **Regra da Cura Impossível & Escudo Mágico** | Chat `25/08/2024` (dano 100% não-mágico/congênito não cura com magia) e `16/05/2025` (Escudo Mágico como MP 2×). | Vale só para Maesto/Goetia ou também para o lore de EXODUS? |
| **8** | **Cosmologia geral (THÉOS, Regra do 8, Linha Temporal Linear, Dimensão Daema/Uthópia, Bruxaria)** | 100% ausentes da doc atual de EXODUS. | Aprova promover o resumo cosmológico (Seções 2, 4 e 5) como **bíblia canônica do universo Maesto** em `docs/`? |
| **9** | **Catálogo de Elementos do mundo mais recente (`LAVA` fora, `GENO→EMOT`, `LEAF=AQUA+ROCK`)** | Segundo `D-138`, essa sistematização pertence ao **mundo mais recente** de Maesto (não à era EXODUS), enquanto as magias prevalecem. | Confirmar se vale manter a tabela da Seção 4.5 apenas como referência do mundo recente / banco de inspiração de magias. |
| **10** | **`Anubis` nos Animais do Survival** | `Avatar Anubis.png` já é demônio no Survival. | Manter os 8 animais livres, migrar `Anubis` para Animais ou escolher um 9º substituto? |
