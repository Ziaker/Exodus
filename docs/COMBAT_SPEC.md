# Combat specification — Exodus (protótipo)

## Identidade
- Jogo: conceito original com conceitos visuais/gameplay de SMT 1 e 2.
- Protagonista: **Fallen** (nome real desconhecido), demônio caído.
- Inimigos do teste: 2 placeholders genéricos, sem dependência de nomes dos .rvdata.
- Aliado do teste: placeholder genérico.
- Idioma da UI: **inglês**.
- Visão frontal. Após revisão visual, o fundo plano `#333333` foi substituído por
  battleback e janelas no estilo RPG Maker VX Ace, usando assets temporários da fangame
  (`assets/graphics/parallaxes/BB01-001.png`, `Window.png`, battlers com fundo removido
  em `assets/graphics/battle_sprites/`). A referência visual buscada foi a screenshot
  oficial de batalha do VX Ace (Yanfly Channel, nov/2011).

## Atributos
`HP`, `EN` (Energy Points), `ATK`, `MAK`, `DEF`, `MEF`, `AGI`, `SP` (Superiority Points).

- `SP_base = HP + EN + ATK + MAK + DEF + MEF + AGI` (soma dos 7 atributos).
- SP ganho em batalha é **temporário**; volta ao base ao fim da luta.
- `EN`: habilidades custam EP definido nos dados; recupera **20% do máximo por rodada**.
- **Descanso**: abrir mão de **um** ato recupera **+20% do máximo de EN**.
- Mapeamento dos `.rvdata`: `MaxHP→HP`, `MaxMP→EN`, `ATK→ATK`, `DEF→DEF`,
  `MAT→MAK`, `MDF→MEF`, `LUK→AGI`.

## Atos e reações
- Cada personagem possui **2 atos por rodada**; cada ato pode ser **Ação** ou **Reação**
  (2 ações, 2 reações ou 1 de cada).
- Ação = executada no próprio turno. Reação = qualquer ação fora do turno, declarada
  em resposta ao anúncio de uma ação inimiga (inclusive mirando outro aliado).
- Todos os comandos podem ser usados como Reação. Inimigos também possuem 2 atos e
  também podem declarar Reações.
- Atos não usados podem ser **armazenados até 4** para a próxima rodada
  (podem guardar todos de uma vez); inimigos também.
- **D-005 (2026-11-21): teto de 4 atos disponíveis no total por personagem**, somando
  atos novos da rodada, atos armazenados e bônus de SP/Press Turn. Vale igualmente
  para Fallen, aliados e inimigos. Substitui a interpretação de 4 armazenados
  **mais** 2 novos simultaneamente disponíveis. **IMPLEMENTADO:** o excedente é
  **adiado** ao estoque (`stored_acts`), limitado a 4, e pode reaparecer em rodada
  posterior. Atos novos e bônus entram primeiro; o que sobrar volta ao estoque.
- Ordem de turnos por `AGI`. Os atos são oferecidos em passagens intercaladas
  (`A, B, A, B`), e cada ato é consumido por uma ação ou reação.
- **D-007 (2026-11-21): limiar de superioridade por dominância em razão.** Ganha
  **+1 ato** quem possui `SP_próprio / (SP_próprio + SP_rival) > 0,7`. Substitui a
  interpretação literal `SP_próprio > 0,7 × SP_rival`, que premiava ambos os lados
  para qualquer par de SP positivo. **IMPLEMENTADO.**
- **D-019 (Rodada 3, 5B):** em confrontos contra múltiplos oponentes,
  cada combatente compara a própria dominância com o **adversário vivo de maior SP**.
  Este é o comportamento já implementado em `BattleState.strongest_opposite()`.
  Não confundir com a referência visual contextual de SP definida no GDD.
- **Consequência de D-005:** o bônus de SP respeita o teto de 4 atos disponíveis;
  não autoriza um quinto ato. O excedente é adiado ao estoque pela mesma regra.

### Reações da Rodada 2 — D-014 (CONFIRMADO como design; não implementado)

- **3A:** sem atos disponíveis, o personagem **não pode bloquear nem desviar**.
- **4A:** o combate fica **pausado para a escolha da reação** quando elegível.
  A execução posterior da barra continua temporizada; a janela fixa
  de 0,8 s para escolher a reação deixa de ser o comportamento pretendido.
- **5C:** a ordem de resolução de **reações ofensivas** em relação à
  ação anunciada depende de **AGI**. Desempate, interrupção/cancelamento
  e detalhes de encadeamento permanecem **PENDENTES**. Nenhuma alteração
  implícita em custo ou comando foi autorizada.

## Press Turn
- Acerto em fraqueza: **+1 ato** para quem acertou.
- Resistido / nulo / absorvido: **-1 ato** cada (independente do tipo).
- **Consequência de D-005:** o +1 por fraqueza também respeita o teto de 4 atos
  disponíveis; o excedente é adiado ao estoque. A penalidade de -1 não foi alterada
  e apenas reduz atos disponíveis.
- Afinidades consideradas: Weak, Normal, Resist, Null, Absorb.

## Dano (sem magia neste protótipo)
- Físico: `poder × ATK ÷ DEF`.
- **D-019 (Rodada 3, 3A):** a fórmula física acima é **preservada**;
  devem ser recalibrados os **valores de poder dos ataques/habilidades**.
  Novos valores específicos ainda não foram aprovados.
- Modificador de SP: rolar `1dN` onde `N = |SP_atuante - SP_alvo|`;
  soma se o atuante tem mais SP, subtrai se tem menos.
- **Implementação anterior da variação:** `±10% ± 2% por ponto de diferença de SP`
  (sinal conforme vantagem); ainda presente no código, mas **SUBSTITUÍDA
  como design** pela D-019.
- **D-019 (Rodada 3, 2C) — novo design, NÃO IMPLEMENTADO:** a
  variação percentual aleatória do dano passa a ser **fixa em ±10%**,
  independente da diferença de SP, **preservando separadamente a
  rolagem `1dN` de superioridade**. Não alterou a ordem dos demais
  modificadores do dano.
- **Crítico — implementação vigente D-016:** multiplicador **×1.5**; chance =
  `AGI% + clamp(ΔSP × 10%, 0%, 30%)`, limitada a 0–100%.
  Desvantagem de SP não reduz a chance abaixo de AGI. Esta continua
  sendo a fórmula **no código atual**, não o novo design.
- **D-019 (Rodada 3, 1A) — novo design, NÃO IMPLEMENTADO:**
  a contribuição crítica por **ponto de vantagem de SP deve diminuir**
  em relação aos +10 pontos percentuais atuais e a **chance final de
  crítico deve ter um teto inferior a 100%**. O valor exato por ponto,
  o teto numérico global e a eventual revisão do limite de bônus
  +30 p.p. da D-016 permanecem **PENDENTES DE CALIBRAÇÃO**. A D-019
  substitui parcialmente a intenção anterior de D-016, sem reescrever
  seu histórico ou inventar novos valores.
- SP **não** multiplica o dano diretamente.
- Ganho de SP: **+1** por crítico, desvio perfeito, acerto em fraqueza e reação.
- **D-019 (Rodada 3, 4C):** manter essas fontes existentes e seus
  ganhos de **+1 SP**, sem introduzir limite extra por batalha nem
  ganhos decrescentes. O balanceamento da influência do SP deve
  ocorrer nas fórmulas; a mecânica de ganho continua igual.
- Crítico, Press Turn e ganhos de SP por fraqueza/crítico só são aplicados quando
  há **contato** (ritmo de ataque diferente de Falha e defesa diferente de Desvio).
  Ataques que falham não consomem rolagens de dano.
- **D-016 (2026-11-21):** o bônus de SP no crítico foi limitado a **+30 pontos
  percentuais** (`BattleMath.CRIT_SP_BONUS_CAP`). Substitui a fórmula irrestrita
  `AGI + 10 × ΔSP`, que chegava a 100% com ΔSP=4 para o Fallen de teste. O limite
  geral de 0–100% e o multiplicador ×1.5 permanecem. **IMPLEMENTADO.**

## Sistema de ritmo (ataques físicos)
- Aplica-se a **todos os ataques físicos**, de ambas as partes.
- Entrada manual: atacante controlado pelo jogador usa a barra visível para o
  ataque; defensor controlado pelo jogador usa a barra visível apenas quando declarou
  reação e pagou 1 ato. Atacante e defensor controlados pela IA resolvem seu próprio
  ritmo sem entrada humana.
- Barra com marcador móvel; janela do oponente define as zonas.
- **D-015 (2026-11-21):** quando atacante e defensor acertam **POINT** simultaneamente,
  a **defesa prevalece**: não há contato, o dano é 0 e não há crítico, Press Turn nem
  ganho de SP. **IMPLEMENTADO** em `BattleMath.has_contact()`.
- Zonas: **Ponto = 10% central**, **Trave = 20% ao redor**, resto = falha.
- Tecla: **Z / Enter**.
- Duração da janela: `1s - 0,05s por ponto de AGI/SP a favor do atuante`, mínimo `0,2s`.
- Ao atacar: Ponto → dano integral; Trave → oponente bloqueia; Falha → sem dano.
- Ao defender: Trave → bloqueia; Ponto → desvia e ganha +1 SP; Falha → dano integral.
- Bloqueio extra: **+1 rolagem de bloqueio a cada 2 pontos de SP de vantagem**.

### Acerto, bloqueio e exceção sem reação — D-014 (Rodada 2)

- **1E (ideia própria do diretor):** a **barra de ritmo** determina
  **acerto ou erro** do jogador e do inimigo durante os ataques.
  **Exceção:** o ataque inimigo **sempre acerta quando o jogador não
  pode reagir**. O acerto garantido não significa dano máximo,
  crítico automático ou alteração de modificadores de dano e afinidade.
  **PENDENTE:** qual o comportamento quando o jogador *pode* reagir,
  mas opta por não declarar reação.
- **2A:** um **bloqueio na Trave reduz 50% do dano**. Percentual
  já praticado no código e agora confirmado como regra de design.
- **D-019 (Rodada 3, 6A):** quando a exceção de D-014 garantir acerto
  de ataque inimigo por **impossibilidade de reação**, o ataque ainda
  pode causar **crítico pela chance normal**. Não é crítico
  automático, nem recebe bônus adicional. Usa-se a fórmula crítica
  implementada até a calibração aprovada na D-019 (1A).
  A exceção de autoacerto ainda precisa ser implementada.
- **3A e 4A:** sem atos não há bloqueio/desvio; com reação elegível,
  pausar a escolha e manter o tempo de execução da barra.
- A precedência POINT/POINT foi fixada por **D-015**: a defesa prevalece
  (0 dano, sem recompensas). O restante da resposta **1E** segue pendente
  conforme registrado no GDD §4.1.
- As zonas fixas descritas acima representam o **protótipo vigente**;
  os perfis variáveis de ritmo por inimigo e seus limites ainda
  estão em elaboração no GDD §8.1. D-014 não os cancela.
- **DIVERGÊNCIA COM O CÓDIGO:** o inimigo ainda pode falhar seu
  próprio timing quando o jogador não pode reagir; a pausa para
  escolha e a prioridade ofensiva por AGI ainda não foram
  implementadas. Nenhuma mudança de código foi autorizada.

## Itens e absorção
- Itens utilizáveis em batalha; itens de cura custam **+2 SP ao Fallen**.
- Absorção: restrita a **Fallen**; requer button mashing; **0 pressionamentos = falha,
  sem ganhos**. Um alvo absorvido é marcado e não pode render recompensas repetidas.
- **D-017 (2026-11-21): uma absorção bem-sucedida sempre elimina o alvo** (`current_hp =
  0`), que deixa de agir e pode encerrar o combate se for o último inimigo.
  **IMPLEMENTADO.**
- Ganho: 1–3 pontos do maior atributo do inimigo (exceto EN/SP/HP), mais SP base, HP e EN extras.
- **PENDENTE:** fórmula exata de dificuldade do mashing, novas tentativas após falha,
  limite de HP e persistência entre batalhas. Nada disso foi inventado; os ganhos
  atuais permanecem apenas dentro da batalha.
- Sem equipamentos e sem magia neste protótipo.

## IA
- Inimigos: aleatório ponderado entre ataque e habilidades.
- Inimigos "profissionais" e inteligentes, mas com variações mais fracas previstas em dados.

## Escopo fora deste protótipo
Equipamentos, magia/elementos (AQUA/IGNI/AERO/ROCK/MANA/LUZI), oração de humanos,
progressão narrativa e absorção de longo prazo.
