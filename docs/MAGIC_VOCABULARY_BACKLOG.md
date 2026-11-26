# Banco de Vocabulário Mágico Hebraico — EXODUS (D-116)

**Status:** **BANCO DE REFERÊNCIA / CANDIDATOS PARA USO EVENTUAL** (D-116 · 2026-11-26).  
**Índice canônico:** [`docs/DECISIONS.md`](DECISIONS.md) · **GDD:** [`docs/GDD.md`](GDD.md) (§9 e Apêndice A) · **Combate:** [`docs/COMBAT_SPEC.md`](COMBAT_SPEC.md) (§Reza) · **Regra VFX:** [`docs/PRAYER_VFX_RULE.md`](PRAYER_VFX_RULE.md) (D-113).

> [!NOTE]
> Este documento registra ideias, nomes hebraicos e direções conceituais para **uso futuro/eventual** em EXODUS. **Nenhum item novo listado aqui está implementado nem possui custos, fórmulas, usuários autorizados ou regras de desbloqueio definidos**, salvo as **11 rezas já canônicas** (D-048, D-107, D-112, D-115). A associação entre palavras hebraicas e efeitos mágicos é autoral, e não uma atribuição de poderes presente na Bíblia.

---

## 0. Filosofia de nomenclatura e estado atual do catálogo

A filosofia central é nomear magias não apenas pelo fenômeno físico que produzem, mas pelo **significado daquilo que realizam**, construindo um vocabulário reconhecível próprio de EXODUS (análogo a *Agi/Bufu/Zio/Recarm* em SMT, mas com identidade hebraica).

### 0.1 Rezas já canônicas no projeto (11 — D-048 / D-107 / D-112 / D-115)
Qualquer adição futura deve respeitar estas 11 rezas já implementadas em `scripts/core/prayer_book.gd` (todas sujeitas a VFX 100% letras hebraicas pela D-113):
- **D-048:** `Refuah` (רְפוּאָה), `Haganah` (הֲגָנָה), `Ra'am` (רַעַם).
- **D-107 / D-115:** `Sanverim` (סַנְוֵרִים), `Nechamah` (נֶחָמָה), `Cherev` (חֶרֶב).
- **D-112 / D-115:** `Tahorah` (טָהֳרָה), `Magen` (מָגֵן), `Gevurah` (גְּבוּרָה), `Mishpat` (מִשְׁפָּט), `Zohar` (זֹהַר).

---

## 1. Conceito-âncora: Hineni — teleporte (הִנְנִי / הִנֵּנִי)

* **Hineni** (*Here I am · Eis-me aqui*) — referência à resposta de Moisés diante da sarça ardente (Êxodo 3:4). Grafia recomendada: **Hineni** (não *Hireni*).
* **Conceito:** magia de exploração / retorno espacial. Não significa literalmente "teleporte", mas a **manifestação da própria presença em outro lugar**.
* **Sugestão visual (pendente de aprovação/lore):** o conjurador se desfaz em letras hebraicas que desaparecem progressivamente até o corpo se reconstituir no destino, dialogando com os efeitos de absorção (D-052) e a regra tipográfica das rezas (D-113).
  * *Nota de lore pendente:* decidir se apenas humanos (Yoch/Reza) usam magia hebraica ou se Deviron (Fallen) também pode usar *Hineni*/vocabulário hebraico.

---

## 2. Magias de exploração e overworld (12 candidatos)

Voltadas a dar identidade própria ao dungeon crawler além do combate.

| Nome | Hebraico | Significado | Efeito proposto | Status |
|---|---|---|---|---|
| **Hineni** | הִנֵּנִי | Eis-me aqui | Teleporte para outros pontos do mapa. | Candidato |
| **Shuv** | שׁוּב | Retornar | Retorno à entrada da dungeon. | Candidato |
| **Zakhar** | זָכַר | Lembrar | Memoriza uma localização para retorno posterior. | Candidato |
| **Ot** | אוֹת | Sinal | Cria uma marca espiritual no ambiente. | Candidato |
| **Or** | אוֹר | Luz | Ilumina regiões escuras e revela inscrições. | Candidato |
| **Ra'ah** | רָאָה | Ver | Revela passagens ou objetos ocultos. | Candidato |
| **Yada** | יָדַע | Conhecer | Identifica propriedades de entidades e objetos. | Candidato |
| **Derek** | דֶּרֶךְ | Caminho | Indica uma rota até determinado destino. | Candidato |
| **Tzel** | צֵל | Sombra | Reduz a percepção de inimigos durante a exploração. | Candidato |
| **Natsal** | נָצַל | Resgatar, livrar | Permite escapar de um encontro. | Candidato |
| **Qara** | קָרָא | Chamar | Convoca uma presença ou entidade. | Candidato |
| **Menuchah** | מְנוּחָה | Repouso | Possibilita alguma forma de descanso durante a exploração. | Candidato |

* **Sinergia de destaque:** **Zakhar** (memória) + **Ot** (sinal) + **Hineni** (manifestação) como um sistema integrado de marcação e deslocamento espacial.

---

## 3. Magias ofensivas elementais (14 candidatos)

*(Exclui `Ra'am`, já canônica na §0.1, e `Nogah`, removida por sobreposição com `Zohar`/`Cherev`.)*

| Nome | Hebraico | Significado | Efeito proposto | Status / Observação |
|---|---|---|---|---|
| **Esh** | אֵשׁ | Fogo | Combustão. | Candidato |
| **Lahav** | לַהַב | Chama, lâmina | Chama cortante. | Candidato |
| **Lehavah** | לֶהָבָה | Labareda | Explosão de fogo. | Candidato |
| **Barak** | בָּרָק | Relâmpago | Descarga elétrica. | Candidato |
| **Sheleg** | שֶׁלֶג | Neve | Congelamento. | Candidato |
| **Kerach** | קֶרַח | Gelo | Formação de cristais de gelo. | Candidato |
| **Barad** | בָּרָד | Granizo | Bombardeio de fragmentos congelados. | Candidato |
| **Ruach** | רוּחַ | Vento, sopro, espírito | Rajada de vento. | Candidato |
| **Sa'ar** | סַעַר | Tempestade | Ataque atmosférico em área. | Candidato |
| **Even** | אֶבֶן | Pedra | Projétil mineral. | Candidato |
| **Afar** | עָפָר | Pó, terra solta | Nuvem de poeira ofensiva. | Candidato |
| **Mayim** | מַיִם | Água | Manipulação de água. | Candidato |
| **Choshekh** | חֹשֶׁךְ | Escuridão | Ataque de natureza sombria. | Candidato |
| **Mavet** | מָוֶת | Morte | Magia associada à morte. | Candidato |

---

## 4. Magias de suporte e oração (7 candidatos)

*(Exclui `Refuah`, `Haganah` e `Magen`, já canônicas na §0.1, e as redundantes/colidentes `Chazak`, `Oz`, `Machseh`, `Shalom`, `Tahor` e `Neshamah`.)*

| Nome | Hebraico | Significado | Efeito proposto | Status / Observação |
|---|---|---|---|---|
| **Berakhah** | בְּרָכָה | Bênção | Fortalecimento de atributos. | Candidato |
| **Chesed** | חֶסֶד | Misericórdia, bondade | Recuperação coletiva. | Candidato |
| **Qodesh** | קֹדֶשׁ | Santidade | Consagração ou proteção sagrada. | Candidato |
| **Tikvah** | תִּקְוָה | Esperança | Proteção contra derrota iminente. | Candidato |
| **Techiyah** | תְּחִיָּה | Revivificação | Ressurreição de um aliado. | Candidato |
| **Emunah** | אֱמוּנָה | Fidelidade, fé | Fortalecimento espiritual. | Candidato |
| **Chayim** | חַיִּים | Vida | Aumento temporário da vitalidade. | Candidato |

---

## 5. Magias de maldição e enfraquecimento (11 candidatos)

*(Exclui `Ivvaron`, removida por colisão com `Sanverim`.)*

| Nome | Hebraico | Significado | Efeito proposto | Status / Observação |
|---|---|---|---|---|
| **Qelalah** | קְלָלָה | Maldição | Enfraquecimento geral. | Candidato |
| **Tzara'at** | צָרַעַת | Afecção cutânea | Deterioração progressiva do corpo. | Candidato |
| **Dever** | דֶּבֶר | Pestilência | Afecção persistente. | Candidato |
| **Makkah** | מַכָּה | Golpe, praga | Dano acompanhado de condição negativa. | Candidato |
| **Kaved** | כָּבֵד | Pesado | Redução de AGI. | Candidato *(par possível para `SNARE`/`SLOW` do Survival)* |
| **Pachad** | פַּחַד | Medo, terror | Prejuízo à superioridade ou às ações. | Candidato |
| **Emah** | אֵימָה | Pavor | Intimidação sobrenatural. | Candidato |
| **Shever** | שֶׁבֶר | Ruptura, fratura | Redução de DEF. | Candidato *(par possível para `BREAK` do Survival)* |
| **Ra'av** | רָעָב | Fome | Drenagem de recursos. | Candidato *(par possível para `MIND DRAIN` do Survival)* |
| **Tame** | טָמֵא | Impuro | Condição de impureza. | Candidato |
| **Keliyah** | כְּלָיָה | Destruição, consumação | Deterioração extrema. | Candidato |

---

## 6. Magias metafísicas (10 candidatos)

Categoria voltada a propriedades da existência e à cosmologia dos Daemas / EXODUS.

| Nome | Hebraico | Significado | Conceito proposto |
|---|---|---|---|
| **Hayah** | הָיָה | Ser, acontecer, tornar-se | Materialização temporária de algo que ainda não possui existência física. |
| **Ayin** | אַיִן | Ausência, inexistência | Anulação temporária de determinada propriedade, efeito ou manifestação (ex.: dissipação de buffs/afinidades). |
| **Shem** | שֵׁם | Nome | Revelação da identidade ou natureza de uma entidade (afinidades, skills ocultas). |
| **Berit** | בְּרִית | Aliança | Ligação temporária entre duas existências, permitindo compartilhar efeitos. |
| **Nefesh** | נֶפֶשׁ | Vida, ser vivente, pessoa | Manipulação da vitalidade de uma entidade (não necessariamente alma separada do corpo). |
| **Davak** | דָּבַק | Aderir, unir-se | Fusão ou vinculação entre entidades (diálogo com a capacidade original de Deviron). |
| **Bala** | בָּלַע | Engolir, devorar | Nome candidato para manifestação específica da absorção de Deviron. |
| **Tehom** | תְּהוֹם | Abismo, profundidade | Manifestação de profundidade espacial incompreensível (associada às águas profundas). |
| **Tohu** | תֹּהוּ | Desolação, informe, vazio | Desestabilização da forma ou da organização da matéria. |
| **Kavod** | כָּבוֹד | Honra, glória | Manipulação da própria presença e imponência (excelente candidato para mecânicas de **SP / Superioridade**). |

---

## 7. Top 18 candidatos favoritos (referência criativa)

Notas subjetivas de direção criativa (sonoridade, significado, originalidade e potencial mecânico):

| # | Nome | Hebraico | Conceito | Nota |
|---:|---|---|---|---:|
| 01 | **Hineni** | הִנֵּנִי | Teleporte | 10.0 |
| 02 | **Tehom** | תְּהוֹם | Abismo | 10.0 |
| 03 | **Ayin** | אַיִן | Anulação | 10.0 |
| 04 | **Kavod** | כָּבוֹד | Superioridade (SP) | 9.8 |
| 05 | **Zakhar** | זָכַר | Memória | 9.7 |
| 06 | **Tohu** | תֹּהוּ | Desorganização da matéria | 9.6 |
| 07 | **Berit** | בְּרִית | Vínculo espiritual | 9.5 |
| 08 | **Qodesh** | קֹדֶשׁ | Consagração | 9.4 |
| 09 | **Nefesh** | נֶפֶשׁ | Manipulação vital | 9.3 |
| 10 | **Davak** | דָּבַק | Fusão | 9.2 |
| 11 | **Barak** | בָּרָק | Relâmpago | 9.0 |
| 12 | **Ot** | אוֹת | Marcação | 8.9 |
| 13 | **Choshekh** | חֹשֶׁךְ | Escuridão | 8.8 |
| 14 | **Shuv** | שׁוּב | Retorno | 8.8 |
| 15 | **Pachad** | פַּחַד | Medo | 8.7 |
| 16 | **Shever** | שֶׁבֶר | Ruptura | 8.7 |
| 17 | **Mavet** | מָוֶת | Morte | 8.6 |
| 18 | **Hayah** | הָיָה | Manifestação | 8.5 |

---

## 8. Linguagem de evolução / qualificadores (candidato)

Em vez de números ou sufixos arbitrários, explorar adjetivos/qualificadores hebraicos para variações de intensidade, abrangência ou persistência:

| Qualificador | Hebraico | Significado |
|---|---|---|
| **Katan** | קָטָן | Pequeno |
| **Gadol** | גָּדוֹל | Grande |
| **Elyon** | עֶלְיוֹן | Superior, altíssimo |
| **Rishon** | רִאשׁוֹן | Primeiro |
| **Acharon** | אַחֲרוֹן | Último |
| **Olam** | עוֹלָם | Eternidade, duração indefinida |
| **Ein Sof** | אֵין סוֹף | Sem fim, infinito *(reservar para algo excepcional)* |

> [!WARNING]
> **Concordância gramatical obrigatória:** ao combinar raiz + qualificador, respeitar o gênero gramatical em hebraico. Por exemplo, `Esh` (`אֵשׁ`, fogo) é **feminino**, logo o correto é **Esh Gedolah** (`אֵשׁ גְּדוֹלָה`), e não *Esh Gadol*.

---

## 9. Direção criativa — 3 linguagens mágicas (proposta)

| Categoria | Identidade | Exemplos |
|---|---|---|
| **Elemental** | Fenômenos físicos | `Esh`, `Barak`, `Ruach` |
| **Oração** | Conceitos religiosos | `Refuah`, `Berakhah`, `Chesed` *(e as 11 rezas canônicas)* |
| **Metafísica** | Propriedades da existência | `Ayin`, `Hayah`, `Tehom`, `Berit`, `Kavod` |

### Pendências antes de promover qualquer item deste banco
1. **Fronteira de lore/usuário:** definir se vocabulário hebraico é exclusivo de humanos (Reza/PP) ou se Fallen/demônios e magias de exploração/elementais também o utilizam.
2. **Padronização de raízes em combate:** definir se elementais usarão 1 raiz por elemento + qualificadores (melhor legibilidade em batalha) ou nomes distintos por conceito.
3. **Regra de VFX (D-113):** toda reza promovida deste banco ao jogo precisará de VFX 100% letras hebraicas em `scripts/battle/pray_fx.gd`.
