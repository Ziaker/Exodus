# Skills Canônicas Revisadas do Survival + Regras Globais de Combate (D-124)

**Decisão:** D-124 · 2026-11-27 (decisão do criador)  
**Estado:** **CANÔNICO — DESIGN CONFIRMADO; NÃO IMPLEMENTADO**  
**Índice canônico:** [`docs/DECISIONS.md`](DECISIONS.md) · **GDD:** [`docs/GDD.md`](GDD.md) (Apêndice A) · **Combate:** [`docs/COMBAT_SPEC.md`](COMBAT_SPEC.md) · **Fronteira Canônica:** [`docs/CANON_BOUNDARY.md`](CANON_BOUNDARY.md)

> [!IMPORTANT]
> Após as correções definidas pelo criador em 2026-11-27, os **6 ataques abaixo** (mais suas **2 evoluções `ZAHAV`**) passam a ser **canônicos** e eventualmente presentes no jogo principal, acompanhados de **3 regras globais de combate** (`HIGH SPEED`, `BLEED` canônico e `Temporização de ação`).

---

## 1. Catálogo Canônico de Ataques (6 base + 2 evoluções `ZAHAV`)

| # | Nome | Evolução `ZAHAV` | Origem (Survival D-106) | Custo / Tipo / Alvo | Efeito Canônico |
|---|---|---|---|---|---|
| 1 | **Mazz Bite** | — | Rework de `SHADOW BITE` | `1 ACT / 30% HP máx.` · Físico · 1 alvo | A troco de perder **30% do HP máximo** *(requer HP atual > custo)*, realiza um ataque físico de **alta velocidade (`HIGH SPEED`)** causando **10 de dano base + 30% do HP máximo** de dano extra. |
| 2 | **Fang Sting** | **Fang Spine** | Rework de `FANG FLURRY` | `2 ACT / 6 EN` · Físico · 1 alvo | Causa **5 + ATK** de dano e aplica **`BLEED` somente no `POINT`** (se acertar no `BEAM`/blast, **não** aplica `BLEED`). |
| 2Z | **Fang Spine** *(ZAHAV)* | Evolução de `Fang Sting` | — | `3 ACT / 10 EN` · Físico · Alvo alternável | Realiza **2 ataques consecutivos ou intercalados entre alvos** em uma mesma ação, causando **`15 + ATK` por golpe** *(autorizada calibração para baixo se excessivo no balanceamento)*, aplicando **`BLEED` ao contato** e **`BLEED ×2` no `POINT`**. |
| 3 | **Vuln Pierce** | — | Rework de `SOUL PIERCE` | `1 ACT / 8 EN` · Físico · 1 alvo | Causa **15 + ATK** de dano; causa o **dobro de dano** em alvos que estejam realizando uma **ação não-ofensiva**. |
| 4 | **Dark Breath** | — | Rework de `FROST BREATH` | `3 ACT / 15 EN` · Mágico · Todos inimigos | Solta um bafo de trevas (**0 de dano**): reduz o **PP em 3** de quem não desvia e **cega** até o fim do round *(alvos sem PP sofrem apenas a cegueira)*. |
| 5 | **Umbral Gaze** | — | Rework de `VOID GAZE` | `3 ACT / 15 EN` · Mágico · 1 alvo | Abre um círculo de sombras nos pés do alvo e o espeta com espinhos de trevas, causando **15 + MAK** e **aprisionando o alvo por 2 ações globais** *(ver §2.3)*. |
| 6 | **Ignoma** | **Ignoma Esh** | Nova skill canônica | `2 ACT / 8 EN` · Mágico · 1 alvo | Lança uma bola de fogo no alvo causando **10 + MAK** de dano com **35% de chance de causar `BURN`**. |
| 6Z | **Ignoma Esh** *(ZAHAV)* | Evolução de `Ignoma` | — | `3 ACT / 12 EN` · Mágico · 1 alvo alternável | Lança **duas bolas de fogo** em 1 alvo ou em 2 alvos diferentes, causando cada uma **10 + MAK** de dano com **35% de chance de causar `BURN`**. *(Única skill da D-124 que usa **letras hebraicas `אש`** no VFX, por ter `Esh` no nome.)* |

*(Todas as evoluções `ZAHAV` obedecem à regra da D-118: acionadas segurando `A`, com nome exibido em dourado e custo de 20 SP após a conclusão; disponíveis a partir da metade da campanha para o jogador, além de Anjos e elites.)*

---

## 2. Regras Globais de Combate (D-124)

### 2.1 Ataques de Alta Velocidade (`HIGH SPEED`)
> Ataques com **"alta velocidade"** no texto são mais difíceis de bloquear por possuírem um **ponteiro 20% mais rápido** do que o ponteiro normal, além de também serem **mais rápidos do que o ponteiro do oponente no contra-ataque** (D-049).

* Aplica-se a: **Mazz Bite** e quaisquer ataques futuros marcados como `HIGH SPEED`.
* **Nota de integração com D-034 / D-049:** em vez da duração fixa padrão de `1,0 s`, a barra defensiva/ofensiva (e o trilho do atacante no contra-ataque) atravessa 20% mais rápido (`duração = 1,0 / 1,2 ≈ 0,833 s` ou velocidade `×1,20`).

### 2.2 `BLEED` (Sangramento Canônico)
> Condição de status que **reduz em 20% as curas recebidas** até o fim do próximo turno, podendo **acumular até 4 vezes** (até **−80%** de cura recebida).

* **Diferença em relação ao Survival D-106:** no Survival (D-106, provisório), `BLEED` causava `2` de dano/round por 3 rounds. A definição da **D-124** é a regra **canônica** oficial de `BLEED` no jogo principal.
* Continua sendo removível por **Tahorah** (D-112) e bloqueável por **Haganah** (D-048).

### 2.3 Temporização de Ação (Efeitos por X Ações/Atos)
> Quando um ataque diz que um efeito dura por **X ações/atos**, a duração conta o **número de ações realizadas após a efetuação do efeito** (ex.: se aprisionou uma unidade por 3 atos, após 3 ações o alvo é liberto).
>
> Para efeitos de prisão/imobilização temporizada, o estado funciona como um **`PASS` automático**: quem foi aprisionado **não perde** as ações ou reações que ainda não utilizou, **porém perde os atos que já estavam em fila**.

* **Impacto em habilidades já especificadas:**
  * **Umbral Gaze** (D-124): aprisiona o alvo por **2 ações** (perde a fila atual; age como `PASS` automático sem desperdiçar atos ainda não enfileirados; liberto após 2 ações).
  * **Angel Hug** (D-118): paralisa por **3 atos** (segue a mesma contagem de ações realizadas após o efeito; nota: na D-118 quem está paralisado não pode agir nem reagir durante os 3 atos).
  * **Lior** (D-118): cura durante uma sequência de **5 ações** após o uso.

---

## 3. Decisões complementares fechadas (criador, 2026-11-27)

1. **`Mazz Bite` (`30% HP`):** refere-se a **30% do HP máximo** (requer HP atual > custo, impedindo suicídio automático).
2. **`Fang Spine` (`15 + ATK`):** **2× `15 + ATK`** (por golpe), com liberdade criativa autorizada pelo criador para calibrar para baixo se ficar forte demais no jogo.
3. **`Dark Breath`:** **não causa dano** (0 de dano; apenas `−3 PP` em quem não desvia + cegueira até o fim do round; alvos sem PP sofrem apenas a cegueira).
4. **Temporização de Ação:** conta **qualquer ação global realizada na batalha** após a efetuação do efeito (liberando o alvo aprisionado após `X` ações globais).
5. **Substituição no código e migração de `BLEED`:** substituir os 5 antigos diretamente no Survival (`skill_book.gd`) e migrar `BLEED` para `−20%` cura ×4 no jogo todo.
6. **Direção visual (VFX):** **apenas `Ignoma Esh` usa letras hebraicas** (por conter `Esh` no nome — `אש`). As demais 7 entradas (`Mazz Bite`, `Fang Sting`, `Fang Spine`, `Vuln Pierce`, `Dark Breath`, `Umbral Gaze`, `Ignoma`) usam VFX não-tipográficos (mordidas/presas, estocadas/espinhos de sangue, perfuração de vulnerabilidade, bafo/névoa de trevas, círculo sombrio com estacas de sombra e bola de fogo).

*Única pendência menor:* confirmar se `Vuln Pierce` dobra o dano apenas em reação contra ação não-ofensiva anunciada ou também contra alvo com estado/postura não-ofensiva ativa no round.
