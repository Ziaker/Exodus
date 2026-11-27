# Novas Rezas, Magias Angelicais, Gabriel, IMEDIATO e ZAHAV (D-118)

**Decisão:** D-118 · 2026-11-26 (decisão do criador)  
**Estado:** **CANÔNICO — PARCIALMENTE IMPLEMENTADO (8/20: Chaki, Shachar, Lehavah, Esh Sinai, Hasneh Habo'er, Shalhevet, Nogah, Lior)**  
**Índice canônico:** [`docs/DECISIONS.md`](DECISIONS.md) · **GDD:** [`docs/GDD.md`](GDD.md) (§9.1 e Apêndice A) · **Combate:** [`docs/COMBAT_SPEC.md`](COMBAT_SPEC.md) (§Reza) · **Regra VFX:** [`docs/PRAYER_VFX_RULE.md`](PRAYER_VFX_RULE.md) (D-113)

> [!IMPORTANT]
> **Todas as 20 magias e habilidades listadas neste documento** (as 8 rezas, as 6 angelicais e as 6 de Gabriel) são **canônicas** do jogo principal. Todas as rezas/magias de luz estão sujeitas à regra **D-113** (VFX obrigatoriamente compostos por letras hebraicas em `scripts/battle/pray_fx.gd` quando forem implementadas).

---

## 1. Novas Rezas Canônicas (8 — custo em ACT / PP)

| Nome | Custo | Efeito |
|---|---|---|
| **Esh** | 2 ACT / 1 PP | Queima um alvo único causando **20 + MAK** de dano mágico, com **30% (+10% por PP extra alocado)** de chance de causar **BURN**. *(Ver evolução para **Ur Esh** na §2 e §5.)* |
| **Shalhevet** *(IMPLEMENTADO)* | 3 ACT / 4 PP | Queima **todos os oponentes** causando **30 + MAK** de dano mágico (respeitando `MEF`), com **50%** de chance de causar **BURN**. *(VFX 100% letras tricolor aprovado e portado em `pray_fx.gd`.)* |
| **Lehavah** *(IMPLEMENTADO)* | 2 ACT / 3 PP | Causa uma explosão de luz e fogo em um alvo: **40 + MAK** de dano e o **cega** (reduzindo o limiar de acerto do ponteiro) até o fim do próximo round. *(VFX 100% letras tricolor aprovado e portado em `pray_fx.gd`.)* |
| **Nogah** *(IMPLEMENTADO)* | 3 ACT / 2 PP | Causa **cegueira** em **todos os inimigos** até o fim do próximo round (marca `ס`, respeitando `Haganah`). *(VFX 100% letras — clarão estelar 24 feixes + anéis — aprovado e portado em `pray_fx.gd`.)* |
| **Chaki** *(IMPLEMENTADO)* | 3 ACT / 3 PP | Prende o alvo em um raio de luz, **impedindo-o de realizar ações** até o fim do round. *(VFX 100% letras aprovado e portado em `pray_fx.gd`.)* |
| **Lior** *(IMPLEMENTADO)* | 1 ACT / 2 PP | Uma luz envolve o usuário, curando sua vida em **5 + 5 por PP** durante uma **sequência de 5 ações** após o uso. *(VFX 100% letras — manto + 5 letras orbitais de `ליאור` + marca `ל` `xN` BiDi-safe — aprovado e portado em `pray_fx.gd`.)* |
| **Meir** | 1 ACT / 2 PP | Força os oponentes a **focarem o usuário** até o fim do round *(provocação / taunt)*. |
| **Shachar** *(IMPLEMENTADO)* | 3 ACT / 3 PP | Uma luz poderosa irradia do céu: causa **30 + MAK** de dano a **todos os inimigos no início do próximo round**. *(VFX 100% letras aprovado e portado em `pray_fx.gd`.)* |

---

## 2. Magias Específicas de Anjos (6 — EN para Anjos / PP para Yoch)

> **Regra de aprendizado (Yoch):** o custo em **EN** existe para **Anjos**. **Yoch pode aprender** estes ataques (usando o custo em **PP**) **ao derrotar um anjo**, em vez de absorver.

| Nome | Custo (PP / EN) | Efeito |
|---|---|---|
| **Ur Esh** | 2 ACT / 3 PP ou 15 EN | Queima um alvo único causando **20 + MAK** de dano mágico e **causa BURN**. Ao usar em um alvo já queimando, causa **+40 de dano mágico extra**. Se o usuário tiver acesso a **Ur Esh**, **Esh** se transforma nesta skill no próximo round após a primeira utilização *(e via **Zahav**, ver §5)*. |
| **Seraf** | 2 ACT / 2 PP ou 10 EN | Cura o equivalente ao **MAK** do usuário e concede **+20 SP**. |
| **Nitzotz** | 2 ACT / 3 PP ou 15 EN | Causa **20 de dano mágico** em um alvo já queimando e **aumenta a força da queimadura**, passando a causar **10 de dano por round**. |
| **Esh Ochelet** | 4 ACT / 5 PP ou 30 EN | Escolhe um alvo e causa **30 de dano mágico por ação que ele realizar no turno**. Não interrompe e tem velocidade **IMEDIATA**. |
| **Esh Sinai** *(IMPLEMENTADO)* | 4 ACT / 6 PP ou 40 EN | **IMEDIATAMENTE** causa **30 de dano mágico** em um alvo. Após isso, sucessivamente, causa **30 de dano** no mesmo alvo **mais 3 vezes** *(estas 3 repetições permitem reação)*. *(VFX 100% letras tricolor com flash apenas no 1º impacto aprovado e portado em `pray_fx.gd`.)* |
| **Gever** | 3 ACT / 4 PP ou 20 EN | Ganha **+4 estágios de ATK** até o fim do próximo round. |

---

## 3. Habilidades Específicas de Gabriel (6)

| Nome | Custo | Efeito |
|---|---|---|
| **Angel Hug** | 2 ACT / 5 EN | **Paralisa** o alvo (quem está paralisado **não pode agir nem reagir** a ações) durante **3 atos**. **IMEDIATO**. |
| **God's Message** | 1 ACT / 5 EN | No próximo turno, o alvo perderá **3 estágios de um status aleatório**. **IMEDIATO**. |
| **Hasneh Habo'er** *(IMPLEMENTADO)* | 4 ACT / 30 EN | Invoca um **arbusto vivo** incandescido pelo fogo divino como **inimigo extra real (`BattleUnit` de 10 HP)** em `BattleState.units` e `hud.opponents` (selecionável, atacável e presente na ordem de turno). Todos os ataques do arbusto causam **BURN** em quem ataca e causam o **dobro de dano** em alvos já queimando (**12** base / **24** queimando). Suporta múltiplas sarças simultâneas; VFX 100% letras (ramos verdes + chamas tricolores) ancorado ao slot do inimigo em `pray_fx.gd`. |
| **Adin** | 2 ACT / 0 EN | Recupera **15 MP** *(EN)*. No próximo round, esta skill evolui para **Adina**. |
| **Adina** | 2 ACT / 0 EN | Recupera **25 MP** *(EN)* e **25 HP**. No próximo round, esta skill evolui para **Adinut**. |
| **Adinut** | 1 ACT / 0 EN | **IMEDIATAMENTE** recupera **30 MP** *(EN)* e **30 HP**. |

---

## 4. Palavra-chave `IMEDIATO`

> **Regra:** toda magia ou reza marcada como **IMEDIATO** é resolvida **no exato momento em que é anunciada**, **sem possibilidade de reação**. **Dano imediato NÃO ignora defesas** (`MEF` é aplicado normalmente, assim como nas demais magias de dano — confirmado pelo criador em 2026-11-26).

* Aplica-se a: `Esh Ochelet`, 1º impacto de `Esh Sinai` (os 3 golpes subsequentes permitem reação), `Angel Hug`, `God's Message` e `Adinut`.

---

## 5. Sistema `ZAHAV` (Evolução e Amplificação Mágica)

* **Canonicidade e disponibilidade:** **ZAHAV** é **canônico**, porém **não está presente no jogo até a metade da campanha**.
* **Quem tem acesso:** **Anjos** e **inimigos de elite** têm acesso a Zahav. **Inimigos normais, humanos e maziks não** têm acesso. *(O jogador adquire acesso a partir da metade do jogo.)*
* **Acionamento:** segurando o botão **`A`**.
* **Efeito geral:** equivalente ao `+PP`, aplicável a **qualquer magia**:
  * Adiciona **2 estágios de boost de dano**;
  * Adiciona **+20% de chance de causar efeito**;
  * **Custo:** **20 SP**, cobrados **após a conclusão** da magia.
* **Evolução de skills com Zahav:** se o usuário tiver acesso à versão melhorada de uma magia que pode evoluir, segurar `A` (Zahav) **muda o nome da skill** para sua versão evoluída (ex.: `Esh` → `Ur Esh`, `Adin` → `Adina`).
* **Feedback visual no menu:** com Zahav acionado:
  * O texto das skills comuns muda para **amarelo**;
  * O texto das skills que **mudam de nome** (evoluem) muda para **dourado**.

---

## 6. Pendências técnicas para antes da implementação

1. **Terminologia `MP` em `Adin`/`Adina`/`Adinut`:** confirmar se `MP` equivale ao recurso `EN` do jogo.
2. **Mecânica exata de `Hasneh Habo'er` (arbusto de 10 HP):** definir atributos/poder do ataque do arbusto, posição na tela (slot extra de inimigo) e se pode existir mais de um arbusto simultâneo.
3. **Interação `Esh` → `Ur Esh` e `Adin` → `Adina`:** conciliar a transformação automática "no próximo round após o primeiro uso" com o acionamento sob demanda via botão `A` (`ZAHAV`).
4. **Fórmula exata de "2 estágios de boost de dano" no `ZAHAV`:** definir se corresponde a `+2 × bônus de PP extra` (ex.: +20 de base em Ra'am) ou a `+50%` (+2 estágios de 25% como `ATK_STAGE_BONUS`), e o que ocorre se o usuário tiver menos de 20 SP ao acionar `ZAHAV`.
5. **Regra de `Lior` ("5 + 5 por PP durante uma sequência de 5 ações"):** confirmar se conta apenas ações do usuário ou ações globais de qualquer combatente, e se `PP` refere-se aos PP extras alocados ou ao custo total.
6. **VFX hebraico (D-113):** definir grafia hebraica (ex.: `אש`, `שלהבת`, `להבה`, `נוגה`, `חכי`, `ליאור`, `מאיר`, `שחר`, `אור אש`, `שרף`, `ניצוץ`, `אש אוכלת`, `אש סיני`, `גבר`, `הסנה הבוער`, `עדין`/`עדינה`/`עדינות`) e coreografias em `pray_fx.gd`.
