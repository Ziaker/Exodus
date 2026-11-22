# EXODUS — Roteiro de cenas: Prólogo (Parte 1)

**Projeto:** EXODUS — universo MAESTO  
**Origem:** roteiro e correções expressos pelo diretor nesta conversa, em 2026-11-22  
**Estado:** registro narrativo de trabalho; não é uma implementação nem uma homologação de regras mecânicas ainda conflitantes  
**Escopo:** sequência de abertura, primeiro encontro, primeiro combate, tutorial de absorção e liberação inicial da exploração  
**Referências existentes:** GDD §1.1, §§14–16; COMBAT_SPEC; decisões D-017, D-025, D-028, D-029, D-047 e D-048

Este arquivo é **específico do roteiro do prólogo**. Não deve ser confundido com um protótipo técnico de mapa ou tomado como autorização para modificar a arquitetura, o combate, a cosmologia ou outros documentos. As falas do diretor são preservadas como fornecidas, inclusive onde ainda demandam revisão linguística. As expressões em hebraico não foram inventadas nem preenchidas. As correções posteriores do diretor prevalecem sobre interpretações anteriores feitas durante a conversa; conflitos com decisões históricas são indicados sem editar retroativamente essas decisões.

## 1. Fluxo principal

**Play → cutscene de abertura → cutscene com diálogo → gameplay de exploração → encontro com humano e dois inimigos → primeiro combate → tutorial de absorção → despedida → exploração oeste/leste.**

## 2. Roteiro sequencial

### Cena 01 — Céu vermelho e queda de Fallen (cutscene)

- A imagem começa preta e se avermelha lentamente.
- Surgem horizontes, montanhas e nuvens escuras sob um céu vermelho.
- Um demônio cai de um ponto distante do céu escuro.
- A cena se aproxima da queda pela perspectiva de **um homem de cabelos loiros, vestindo roupagens fechadas de tecido**. A identidade desse observador não foi estabelecida nesta descrição.
- Fallen atinge violentamente um **mar de areia branca**.
- O impacto conduz a uma transição para uma tela escura.

### Cena 02 — Sentença em caracteres hebraicos (cutscene com diálogo)

- A tela escura começa a ser ocupada por letras e palavras em hebraico.
- Os caracteres se acumulam e depois se organizam até formar uma caixa de diálogo.
- Acima da caixa aparece uma **silhueta amarela feita de letras hebraicas**.
- A silhueta pronuncia as duas falas abaixo.

**Fala 1 — texto fornecido pelo diretor (sem normalização):**

> Levanta-te [palavras em hebraico ] , Tu és um fracasso de vosso, [Hebraico] não é te dado o ritual de repouso"

**Fala 2 — texto fornecido pelo diretor (sem normalização):**

> Sirva como punição, [hebraico], Levanta-te. Levanta-te.

- A figura, a caixa de diálogo e suas formas se desfazem em caracteres hebraicos separados.
- A tela volta ao preto.

**Restrições:** preservar a palavra **“vosso”**. Não atribuir identidade à voz ou à silhueta. Não substituir “ritual de repouso” por repouso comum. Não preencher as expressões hebraicas nem atribuir a elas significados não definidos. Revisões de ortografia, pontuação e tratamento arcaizante ficam separadas das falas originais até aprovação.

### Cena 03 — Despertar e primeiro controle (gameplay)

- Um pedido distante de ajuda desperta Fallen.
- A chamada ecoa como **letras comuns** no **canto superior direito da tela**, em contraste com a escrita hebraica da cena anterior.
- A visão se abre gradualmente para o ambiente de areia branca.
- O jogador recebe o controle de Fallen.
- O objetivo imediato é seguir em direção ao canto superior direito, de onde as palavras ecoam.

### Cena 04 — O humano e as duas sombras (encontro)

- Fallen encontra um **humano de pele marrom, cabelos e olhos amarelos, corpo coberto por tecidos**.
- O humano pede ajuda sem perceber a diferença de aparência e vestimentas entre ele e Fallen.
- Duas criaturas inteiramente pretas, semelhantes a sombras ou silhuetas, o atacam.
- O encontro inicia o **primeiro combate do jogo** contra os dois inimigos.
- As criaturas recebem **nomes em hebraico na HUD de combate**; os nomes específicos não foram fornecidos.

## 3. Primeiro combate — fichas fornecidas pelo diretor

As fichas e habilidades abaixo registram exatamente os valores apresentados para este encontro. **Ataques normais são universais e não devem constar como habilidades especiais nas fichas.**

### Inimigo 1 — silhueta preta (nome hebraico pendente)

| HP | EN | ATK | MAK | DEF | MEF | AGI |
|---:|---:|---:|---:|---:|---:|---:|
| 20 | 10 | 6 | 3 | 2 | 8 | 3 |

**Habilidades especiais:**

- **Lunge — 1 ACT / 4 EN:** causa **5 de dano físico** a um alvo **duas vezes**, em rápida sucessão de ritmo. Trata-se de uma habilidade, não de uma segunda ação básica obrigatória.
- **Bleedbuff — 2 ACT / 4 HP:** em troca da própria vida, recebe **+1 estágio de ATK** durante **1 round**.

### Inimigo 2 — silhueta preta (nome hebraico pendente)

| HP | EN | ATK | MAK | DEF | MEF | AGI |
|---:|---:|---:|---:|---:|---:|---:|
| 8 | 16 | 1 | 8 | 2 | 2 | 3 |

**Habilidades especiais:**

- **Heat wave — 2 ACT / 6 EN:** causa **5 de dano mágico do elemento IGNI** a todos os inimigos, com **25% de chance** de aplicar **Burn**; Burn causa **3 de dano por round durante 3 rounds**.
- **Energy Eat — 1 ACT / 6 EN:** recupera **5 HP +1 HP por ponto de EN extra alocado** à habilidade.

**Parâmetros do encontro indicados posteriormente pelo diretor:**

- Fallen possui **SP base 80**, mas inicia este combate com **40 SP atuais**. Não confundir SP (Superiority Points) com PP (Pray Points).
- O humano que intervém é **Yoch**, que começa a batalha com **0 PP**.
- A IA inimiga **não é obrigada a gastar sempre duas ações atacando**, independentemente do contexto; deve poder escolher suas ações. Não impor um ataque básico redundante sobre o uso de habilidades.
- A exigência de que todos os atributos iniciais sejam múltiplos de 8 foi corrigida pelo diretor: não é essa a regra pretendida; deve haver **pelo menos um ou dois atributos com valores múltiplos de 8**, sem impor múltiplos de 8 em todos os campos. A redação exata da regra geral ainda precisa ser conciliada com a D-025.

### Intervenção de Yoch

- Se Fallen estiver prestes a receber **dano mortal**, Yoch entra no combate.
- Seu nome aparece **censurado em hebraico**.
- Yoch **restaura completamente o HP de Fallen**, em troca da redução de seu **SP atual à metade**.
- A intervenção é um **evento narrativo**, não uma execução convencional de Refuah sujeita aos custos comuns de PP.
- **“Reinício” não significa reiniciar a luta ou restaurar as unidades e turnos ao estado inicial.** O diretor esclareceu que se refere a Fallen estar novamente com a vida cheia.
- Durante essa batalha, Yoch é controlado **inteiramente pela IA**.

A condição exata de disparo (cálculo de dano mortal), o arredondamento da metade do SP e o tratamento de estados simultâneos ainda não têm especificação operacional.

## 4. Fraqueza e tutorial obrigatório de ABSORB

- Após sofrerem dano suficiente — **limiar numérico ainda não estabelecido** — os inimigos passam a **chacoalhar/tremular periodicamente, em referência a um intervalo de 2 segundos**, para indicar fraqueza. A descrição original foi “chacoalhar a casa 2 segundos”; a cadência visual exata permanece sujeita à especificação.
- A opção **ABSORB toma conta da interface de escolha**: todas as opções passam a representar ABSORB, obrigando sua seleção.
- **Primeira absorção:** ao selecionar, a energia vital do primeiro alvo é sugada por Fallen. A **arte do inimigo se reparte em fragmentos e segue na direção do jogador**. Fallen recebe **+2 MEF permanentemente**. Este primeiro uso do prólogo **não apresenta o button mashing normal**.
- **Segunda absorção:** apresenta o **sistema de button mashing** e concede **+2 MAK permanentemente**, conforme a direção expressa para o tutorial.
- A conclusão da absorção elimina o alvo, e o progresso permanente deve continuar existindo entre combates. Os ganhos específicos do tutorial não autorizam substituir silenciosamente outros contratos de progressão do jogo.

### 4.1 Regra de absorção corrigida pelo diretor

A regra abaixo **substitui, como diretriz atual do diretor, a interpretação anteriormente atribuída à D-029**. A documentação histórica e o código ainda devem ser reconciliados separadamente.

- A absorção é uma **disputa de SP** de Fallen contra o **SP restante do inimigo**.
- O inimigo resiste utilizando seu SP restante, em oposição ao SP de Fallen.
- O button mashing envolve **10 pressionamentos** e um limite declarado de **até 20 SP no total**; a conversão operacional exata entre pressionamentos, SP ganho e SP retirado do alvo **não foi especificada**.
- A absorção **somente se completa quando o SP do inimigo é inteiramente esgotado**.
- O ganho de atributos não é calculado como “4 apertos = +1 / 8 = +2 / 12 = +3”. Essa regra foi **expressamente rejeitada pelo diretor**.
- A recompensa de atributos está vinculada ao(s) maior(es) atributo(s) elegível(is) do inimigo com valor **múltiplo de 8**: **até +2 em um atributo** ou **+1 e +1 em dois atributos diferentes**.
- O critério de seleção/desempate entre atributos elegíveis, as categorias elegíveis e o tratamento de casos sem atributos elegíveis exigem definição adicional; não presumir sorteio nem escolha do jogador.
- Persistência de progresso: **sim**, conforme D-028; sem presumir que a fórmula antiga de acréscimos de HP, EN e SP base permaneça igual após a revisão.

### 4.2 VFX de absorção — somente o que já foi direcionado

**Direção visual expressa:** no primeiro tutorial, a energia vital é sugada, a arte do alvo **se parte** e as partes **vão até o jogador**. No segundo, o efeito deve ser associado ao novo mashing, cuja visualização detalhada ainda não foi decidida.

**Ainda não especificado:** formato e número dos fragmentos, temporização, trajetórias e destino exatos em visão frontal, resposta visual a cada aperto e variação de SP, indicadores de sucesso/falha e comportamento de restauração do sprite na falha. Não inventar esses elementos como decisões aprovadas.

## 5. Pós-combate e início da exploração

- Ao término do primeiro combate, Yoch **sai imediatamente do grupo**, afasta-se de Fallen e sai da tela.
- Sua fala, preservada conforme fornecida pelo diretor, é:

> Ser de estranhas roupas, não sei como te agradeço, [hebraico] lhe abençoe por abrir mão de seu tempo. Devo me abster a minha mesquita ao oeste. Rezo pelo seu sucesso.

- **Direções cardeais têm cor própria nos blocos de diálogo.** A cor exata não foi estabelecida.
- A partir desse momento, o jogador pode explorar **a oeste ou a leste**.
- À frente há **uma parede de montanhas avermelhadas**, impedindo avanço nessa direção.
- A continuação dos caminhos é matéria da Parte 2, ainda não registrada neste documento.

## 6. Questões em aberto e divergências documentais

Este roteiro **não altera** as regras gerais de combate nem reescreve decisões históricas. Antes da implementação, são necessárias resoluções pontuais:

1. **D-025 — valores iniciais:** a redação histórica exige todos os atributos em múltiplos de 8; o diretor esclareceu outra intenção, com um ou dois atributos múltiplos de 8. Ajustar a regra geral em etapa documental autorizada e sem modificar as fichas fornecidas.
2. **D-029 — mashing:** sua fórmula histórica por grupos de quatro apertos contradiz a disputa de SP agora determinada. Implementação, testes e documentação precisam de substituição formal.
3. **D-047 — ações inimigas:** o código/documento histórico do combo não autoriza inferir que todo inimigo deva sempre executar duas ações de ataque. Preservar a liberdade de uso de habilidades, reações e ações conforme o contexto.
4. **Disputa de SP:** definir precisamente cálculo por pressionamento, transferência ou drenagem, limite de 20 SP, condições de falha, repetição e relação com HP/estado de fraqueza.
5. **Elegibilidade e distribuição de atributos:** especificar como se escolhem um ou dois atributos múltiplos de 8 e o que acontece em empates e exceções.
6. **Intervenção de Yoch:** precisar gatilho de dano mortal, arredondamento de SP e apresentação do evento sem reinicialização da luta.
7. **ABSORB obrigatório:** especificar o limiar de dano que ativa a fraqueza, o controle do menu e o comportamento especial da primeira absorção sem mash.
8. **Identidade e texto:** nomes hebraicos dos inimigos; termos censurados da voz e de Yoch; identidade da silhueta e do observador da queda; revisão de linguagem somente se solicitada.
9. **VFX:** faltam contratos de fragmentação, ritmo, feedback e sincronização mecânico-visual.
10. **Caminhos e diálogos:** cores das direções e conteúdo dos mapas oeste/leste ainda não estão neste roteiro.

## 7. Limites desta entrega

- Este arquivo **registra a Parte 1 que o diretor forneceu** e suas correções posteriores. Não cria a Parte 2 e não antecipa acontecimentos da história.
- Não atribui significado ou tradução às palavras hebraicas em aberto.
- Não identifica a voz celestial, o observador loiro da queda ou a natureza da mesquita além do que foi declarado.
- **Não é** o documento técnico MAP_PROTOTYPE.md; não autoriza converter mapa placeholder em cânone.
- Não cria uma decisão numerada D-xxx, não altera o índice de decisões e **não afirma que os contratos mecânicos pendentes foram homologados ou implementados**.
