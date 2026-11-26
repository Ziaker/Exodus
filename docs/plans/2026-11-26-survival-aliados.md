# Survival — aliados além do Yoch (D-111, decisão do criador 2026-11-26)

Respostas do criador, uma por pergunta, em 2026-11-26. Nada aqui foi decidido pelo agente;
o que não está escrito continua **pendente** e não entra no código.

## Grupo

- A run **começa com o Fallen sozinho**. O Yoch não está mais no grupo inicial.
- Podem virar aliados **demônios e humanos** (nunca anjos).
- No máximo **Fallen + 2 aliados** na batalha.
- Extras vão para a **reserva do santuário** (até **8**); a troca grupo↔reserva é feita no santuário.
- Aliado que cai (HP 0) fica caído (não luta) até o **HEAL** do santuário (o HEAL normal revive).
- **Relíquias: 1 por unidade (Fallen incluído); humanos (Yoch incluído) 2.**
- Saves de run antigos (com o Yoch no grupo) são **descartados**: começa run nova.

## Como se ganha um aliado

1. **Oferta ao vencer** — 25% das vitórias (pela semente da run): um derrotado (qualquer um,
   inclusive elite, guardião e humanos; nunca anjo) pede para se juntar. Painel na vitória com a
   arte do derrotado e `<NOME> wants to join you. Z: ACCEPT  X: REFUSE`. Entra com **os mesmos
   status que tinha na luta**, com **HP/EN/PP cheios**.
2. **Santuário** — **2 demônios do estrato atual** (sorteados pela semente, sem guardião) para
   contratar. Preço = **SP × 2 Macca** (SP = soma dos 7 status). Status = **os que teria numa luta
   naquele estrato** (ajuste ao SP do Fallen, sem elite/OMEN).
3. **Encontros no mapa** — por estrato, quantidade sorteada: 0 (15%), 1 (35%), 2 (35%), 3 (15%).
   Candidato: **75% demônio do estrato (sem guardião) / 25% humano** (P15/P10/P19). Figura no
   corredor **como os eventos**; ao falar, a arte aparece de frente. Tipo sorteado entre:
   - **conversa**: entra;
   - **pede um consumível**: sorteado entre BEAD, CHAKRA, MEDICINE, SOMA, BLAST STONE;
   - **pede dinheiro**: SP × 1 Macca;
   - **luta-teste**: luta contra ele; **entra só se vencer**. Não pode absorver nem morrer de verdade:
     ao fim (vitória ou derrota) HP/EN/PP/continues voltam ao que eram antes; **itens gastos não voltam**.
   Status = os que teria numa luta naquele estrato.

## Yoch

- **15%** por estrato (semente) de estar no mapa; uma vez recrutado não aparece mais.
- No início do estrato em que está presente: aviso **`YOCH IS SOMEWHERE IN THIS STRATUM`**.
- Figura no mapa: arte `assets/graphics/battlers/Zealot Masakado.png` **completamente amarela**.
- Status: **sempre o mesmo SP do Fallen**, inclusive quando o Fallen absorve.

## Crescimento

- A absorção só melhora o Fallen (a oferta `YOCH +n` foi **removida**).
- Cada aliado **vivo no fim da luta** conta lutas; a cada **2 lutas** ganha num status aleatório
  **+1 (65%) / +2 (20%) / +3 (15%)**.
- Aviso **no mapa**, ao voltar: linhas `<NOME> +n STAT` no canto da tela.
- Demônio recrutado: ficha **fixa** + esse crescimento.
- Humano recrutado (não o Yoch): **3 rezas aleatórias** do pool (rezas do Yoch + dos humanos + as 5 rezas da D-112: Tahorah, Magen, Gevurah, Mishpat, Zohar),
  **sem Ra'am**.

## Controle

- Cada aliado tem **MANUAL / AUTO**.
- AUTO = **IA dos inimigos** (temperamento/rezas), mirando os inimigos; ataca **sem barra**
  (resultado sorteado como a IA inimiga) e **nunca reage**.
- Fora da batalha: **tecla C** abre o menu de status / itens / configurações (MANUAL/AUTO);
  consumíveis **podem ser usados** nele (BEAD/MEDICINE/CHAKRA/SOMA; BLAST não).
- Na batalha: comando **PARTY** no menu de comandos do Fallen abre o mesmo menu.

## HUD de batalha

- Os 3 painéis de herói lado a lado, mais estreitos, comandos no mesmo lugar à direita
  (escolha "3 estreitos" do criador).

## Pendente (não decidido)

- Textos exatos dos encontros do mapa e do painel de oferta além do que está acima.
- Mais rezas para humanos (o criador vai criar).
