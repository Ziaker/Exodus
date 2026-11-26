# Rework das habilidades do Survival (D-106, aprovado pelo criador com troca de nomes)

Pedido do criador: rework das habilidades, **só no survival**, com **identidade única** para as que ele
não criou. Ficam como estão LUNGE, BLEEDBUFF, HEAT WAVE e ENERGY EAT. As 27 abaixo são as do pool
`SURVIVAL_SKILLS`. Hoje todas são variações de poder e custo; aqui cada uma ganha um efeito que
nenhuma outra tem. Números (poder, custo, atos) ficam como estão, salvo onde dito.

Referências de desenho: SMT (status que mudam a luta: Sukunda/Tarukaja, Mudo/Hama, Dia/Media),
Slay the Spire (ameaça em camadas: sangramento acumula, veneno enfraquece), Darkest Dungeon
(roubar recurso do inimigo, marcar alvo), Persona (golpe que ignora esquiva).

## Físicos (um alvo)

| Habilidade | Poder e custo (iguais a hoje) | Identidade nova |
|---|---|---|
| SHADOW BITE | 2 golpes de 6, 1 ato, EN 4 | Cada golpe que acerta **rouba 1 SP** do alvo |
| SOUL PIERCE | 1 golpe de 7, 1 ato, EN 4 | **Ignora metade da DEF** do alvo |
| FROST LANCE | 1 golpe de 9, 1 ato, EN 5 | **CHILL**: o próximo ataque do alvo causa 25% menos |
| STONE GRASP | 1 golpe de 6, 1 ato, EN 4 | **SNARE**: AGI do alvo −4 por 2 rodadas |
| TWIN FANG | 2 golpes de 5, 2 atos, EN 5 | **COMBO**: se o 1º acerta, o 2º causa +50% |
| FANG FLURRY | 3 golpes de 4, 2 atos, EN 5 | Cada golpe que acerta aplica **BLEED** (2 de dano por rodada, 3 rodadas, acumula) |
| BLADE DANCE | 4 golpes, 2 atos, EN 6 | **Crescente**: poder 3, 4, 5, 6 |
| HEAVY CRUSH | 1 golpe de 11, 2 atos, EN 5 | **BREAK**: DEF do alvo −25% por 2 rodadas |
| CRUSHING BLOW | 1 golpe de 13, 2 atos, EN 7 | **EXECUTE**: x1,5 se o alvo está abaixo de 40% de HP |

## Mágicos (todos os inimigos)

| Habilidade | Poder e custo | Identidade nova |
|---|---|---|
| PIXIE DUST | 4, 1 ato, EN 3 | **SLEEP**: 30% de cada inimigo perder o próximo ato |
| SPIRIT WAVE | 5, 1 ato, EN 4 | **Sifão**: cura 2 HP de quem usa por inimigo atingido |
| SPIRIT BOLT | 7, 1 ato, EN 5 | **MARK**: o próximo golpe de qualquer um no inimigo marcado causa +25% |
| EMBER TOUCH | 7, 1 ato, EN 5, 50% de queimar | **DETONATE**: inimigo que já queima recebe o dano de queimadura na hora |
| HELLFIRE | 8, 2 atos, EN 7, 35% de queimar | **INFERNO**: a queimadura dura 5 rodadas em vez de 3 |
| FROST BREATH | 6, 2 atos, EN 5 | **SLOW**: os inimigos atingidos agem por último na próxima rodada |
| VENOM CLOUD | 6, 2 atos, EN 6, 40% | **WEAKEN**: o inimigo envenenado causa 20% menos por 3 rodadas |
| MIND BLAST | 8, 2 atos, EN 8 | **Dreno de EN**: tira 3 EN de cada inimigo; sem EN ele não usa habilidade |
| CURSE RAY | 9, 2 atos, EN 8 | **Maldição**: cada inimigo atingido perde 2 SP |
| THUNDER CALL | 10, 2 atos, EN 9 | **STORM**: cada inimigo leva 1 ou 2 raios, sorteado |
| VOID GAZE | 12, 2 atos, EN 10 | **Inesquivável**: o inimigo não tem barra de defesa |

## Cura

| Habilidade | Custo | Identidade nova |
|---|---|---|
| MEND | 1 ato, EN 4, cura 8 | Também **limpa** as queimaduras e sangramentos de quem usa |
| DARK SIPHON | 2 atos, EN 7, cura 12 | Cura **um aliado à escolha** (Fallen ou Yoch) |
| LIFE DRAIN | 2 atos, EN 8 | Vira golpe de poder 6 num alvo e cura quem usa **do dano causado** |
| RENEW | 2 atos, EN 10 | **REGEN**: cura 6 por rodada durante 3 rodadas |

## Reforço

| Habilidade | Custo | Identidade nova |
|---|---|---|
| HOWL | 1 ato, EN 4 | +1 de ATK e **TAUNT**: os inimigos só atacam quem usou, na próxima rodada |
| PRIMAL ROAR | 1 ato, 3 HP | **BERSERK**: +2 de ATK, mas DEF −25% na rodada |
| WAR CRY | 2 atos, EN 6 | **Equipe**: +1 de ATK para o Fallen e para a Yoch |

## O que precisa ser construído

Estados novos nos combatentes (CHILL, SNARE, BLEED, BREAK, SLEEP, MARK, SLOW, WEAKEN, TAUNT,
BERSERK, REGEN), o golpe que ignora DEF, o roubo e a perda de SP e EN por golpe, o golpe sem barra de
defesa, cura em aliado à escolha e cura pelo dano. Estados acabam no fim da batalha e não entram no
save da run. Cada habilidade ganha um teste que prova o efeito, e o texto `info` de cada uma passa a
descrever o efeito novo.

**Sem alterar:** o combate principal, o custo e o poder base, e as quatro habilidades suas.

Marcado como escolha do agente aguardando o criador: todos os efeitos acima (a identidade de cada
habilidade) e os valores de cada efeito (25%, 2 rodadas, 3 EN etc.).

## Nomes trocados (pedido do criador: "só muda os nomes que não fazem sentido")

SPIRIT WAVE -> SOUL LEECH, SPIRIT BOLT -> SPIRIT BRAND, EMBER TOUCH -> EMBER BURST, MIND BLAST ->
MIND DRAIN, CRUSHING BLOW -> FINISHING BLOW, DARK SIPHON -> DARK BOON. Os ids internos não mudam.
Ajuste: a queimadura saiu de PIXIE DUST, VENOM CLOUD, CURSE RAY e THUNDER CALL, que agora têm só o
efeito novo; HELLFIRE e EMBER BURST mantêm a queimadura. O TAUNT dura até o início da próxima rodada.
