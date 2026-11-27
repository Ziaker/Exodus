# Skills Canônicas Revisadas do Survival + Regras Globais de Combate (D-124)

**Decisão:** D-124 · 2026-11-27 (decisão do criador)  
**Estado:** **CANÔNICO — IMPLEMENTADO (MECÂNICA E VFX; AGUARDANDO VALIDAÇÃO VISUAL FINAL DO CRIADOR NO GODOT; ATIVAÇÃO ZAHAV, IA DE ESCOLHA DAS NOVAS SKILLS E DISTRIBUIÇÃO NA CAMPANHA PENDENTES)**  
**Índice canônico:** [`docs/DECISIONS.md`](DECISIONS.md) · **GDD:** [`docs/GDD.md`](GDD.md) (Apêndice A) · **Combate:** [`docs/COMBAT_SPEC.md`](COMBAT_SPEC.md) · **Fronteira Canônica:** [`docs/CANON_BOUNDARY.md`](CANON_BOUNDARY.md) · **Estilo VFX Não-Reza (D-125):** [`docs/NON_PRAYER_VFX_STYLE.md`](NON_PRAYER_VFX_STYLE.md) · **Prompts Faseados:** [`docs/CLAUDE_PROMPTS_D124_D125.md`](CLAUDE_PROMPTS_D124_D125.md)

> [!IMPORTANT]
> Após as correções definidas pelo criador em 2026-11-27, os **6 ataques abaixo** (mais suas **2 evoluções `ZAHAV`**) passam a ser **canônicos** e eventualmente presentes no jogo principal, acompanhados de **3 regras globais de combate** (`HIGH SPEED`, `BLEED` canônico e `Temporização de ação`).

---

## 1. Catálogo Canônico de Ataques (6 base + 2 evoluções `ZAHAV`)

| # | Nome | Evolução `ZAHAV` | Origem (Survival D-106) | Ficha (`ACT/EN/CAT/ALVO`, D-131) | Efeito Canônico |
|---|---|---|---|---|---|
| 1 | **Mazz Bite** | — | Rework de `SHADOW BITE` | `1ACT / 30% HP máx. / PHYS / 1T` | A troco de perder **30% do HP máximo** *(requer HP atual > custo)*, realiza um ataque físico de **alta velocidade (`HIGH SPEED`)** causando **10 `PHYS` base + 30% do HP máximo** de dano extra. |
| 2 | **Fang Sting** | **Fang Spine** | Rework de `FANG FLURRY` | `2ACT / 6EN / PHYS / 1T` | Causa **5 `PHYS` + ATK** de dano e aplica **`BLEED` somente no `POINT`** (se acertar no `BEAM`/blast, **não** aplica `BLEED`). |
| 2Z | **Fang Spine** *(ZAHAV)* | Evolução de `Fang Sting` | — | `3ACT / 10EN / PHYS / 1T–2T` *(alternável)* | Realiza **2 ataques consecutivos ou intercalados entre alvos** em uma mesma ação, causando **`15 PHYS + ATK` por golpe** *(autorizada calibração para baixo se excessivo no balanceamento)*, aplicando **`BLEED` ao contato** e **`BLEED ×2` no `POINT`**. |
| 3 | **Vuln Pierce** | — | Rework de `SOUL PIERCE` | `1ACT / 8EN / PHYS / 1T` | Causa **15 `PHYS` + ATK** de dano; causa o **dobro de dano** em **Alvos Vulneráveis** *(ação não-ofensiva ou efeito que força `PASS`, unificado pela D-131)*. |
| 4 | **Dark Breath** | — | Rework de `FROST BREATH` | `3ACT / 15EN / STAT / 3T` *(todos inimigos)* | Solta um bafo de trevas (**0 de dano**): reduz o **PP em 3** de quem não desvia e **cega** até o fim do round *(alvos sem PP sofrem apenas a cegueira)*. |
| 5 | **Umbral Gaze** | — | Rework de `VOID GAZE` | `3ACT / 15EN / MAGI / 1T` | Abre um círculo de sombras nos pés do alvo e o espeta com espinhos de trevas, causando **15 `MAGI` + MAK** e **aprisionando o alvo por 2 ações globais** *(ver §2.3)*. |
| 6 | **Ignoma** | **Ignoma Esh** | Nova skill canônica | `2ACT / 8EN / MAGI / 1T` | Lança uma bola de fogo no alvo causando **10 `MAGI` + MAK** de dano com **35% de chance de causar `BURN`**. |
| 6Z | **Ignoma Esh** *(ZAHAV)* | Evolução de `Ignoma` | — | `3ACT / 12EN / MAGI / 1T–2T` *(alternável)* | Lança **duas bolas de fogo** em 1 alvo ou em 2 alvos diferentes, causando cada uma **10 `MAGI` + MAK** de dano com **35% de chance de causar `BURN`**. *(Única skill da D-124 que usa **letras hebraicas `אש`** no VFX, por ter `Esh` no nome.)* |

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
6. **Direção visual oficial dos ataques não-reza (`D-125`):**
   * **Linguagem unificada:** **Anatômico Grotesco de Rabisco (12 FPS, silhueta negra + contorno orgânico)** combinado com **Interferência Hipnótica (Moiré / ondas febris)** em paleta sombria (sem neon).
   * **Regra de outline `ZAHAV`:** o **outline dourado só existe quando o ataque é realizado através de `ZAHAV`**; ataques normais sempre usam suas cores naturais.
   * **Hebraico:** **apenas `Ignoma Esh` usa letras hebraicas** (por conter `Esh` no nome — `אש`).
   * **Geometria:** reservada para **alguns outros anjos** (não usada em ataques demoníacos/não-reza comuns).
   * **Status de aprovação visual (2026-11-27):** **TODOS APROVADOS (8/8):** `Mazz Bite`, `Fang Sting`, `Fang Spine [ZAHAV]`, `Vuln Pierce` *(sem outline dourado)*, `Dark Breath v2` *(ar saindo diretamente da boca grotesca de perfil)*, `Umbral Gaze` *(versão mais escura)*, `Ignoma` *(chamas rabiscadas sem olho)*, `Ignoma Esh [ZAHAV]` *(outline dourado + `אש`)*. Referências HTML salvas em [`docs/vfx_refs/d124_d125/`](vfx_refs/d124_d125/README.md) e estilo documentado em [`docs/NON_PRAYER_VFX_STYLE.md`](NON_PRAYER_VFX_STYLE.md).

7. **Unificação de `Vuln Pierce` com `Alvo Vulnerável` (D-131):** fechado pelo criador em 2026-11-27 — `Vuln Pierce` dobra o dano contra qualquer **Alvo Vulnerável** (realizando ação não-ofensiva **ou** sob efeito que força `PASS`, como paralisação ou aprisionamento). Tabela acima padronizada para a taxonomia oficial da D-131 (`PHYS`/`MAGI`/`STAT`, `PHYS`/`MAGI`/`DMG`, `1T`–`3T`).

## 4. Fase 1 implementada (2026-11-27) — 3 regras globais

Implementadas em `skill_book.gd`, `skill_fx.gd`, `battle_unit.gd` e `playable_controller.gd`; testes em `tests/verify_d124_rules.gd` (38 checks). O catálogo das 6 skills (Fase 2) e os VFX (Fases 3–5) seguem NÃO IMPLEMENTADOS. Leituras adotadas, a confirmar pelo autor:

- **HIGH SPEED:** flag `high_speed` na skill; a barra de ataque/defesa dura `1/1,2` s e, no contra-ataque, o ponteiro do lado `HIGH SPEED` roda a `1/1,2` (o do oponente não muda). Nenhuma skill atual tem a flag (vem na Fase 2).
- **BLEED:** −20% da cura por acúmulo (máx. 4); sem dano; dura 2 ticks de round (leitura de "até o fim do próximo turno", como `BLIND`/`MAGEN`); o 5º acúmulo renova os 4. `MEND` cura e depois limpa, então a cura do próprio `MEND` ainda é cortada pelo BLEED que ele remove.
- **Prisão:** `BattleUnit.trap(n)` + status `trapped` (purificável pela `Tahorah`); o turno do preso é PASS automático (D-105), guardando atos; cada ação de turno concluída por qualquer unidade (comando do herói ou ato do inimigo; reações não contam) desconta 1. Um round sem nenhuma ação conta como 1 ação, para a prisão não travar a batalha.

## 5. Fase 2 implementada (2026-11-27) — catálogo das 6 skills + 2 ZAHAV

Em `skill_book.gd` (8 entradas, as 5 antigas removidas), `skill_fx.gd`, `playable_controller.gd`, `survival_data.gd`; testes em `tests/verify_d124_skills.gd` (271 checks). Sem VFX (Fases 3 a 5); a ativação `ZAHAV` (botão `A`, 20 SP) continua NÃO implementada, então `fang_spine` e `ignoma_esh` existem e são testáveis mas ainda não aparecem no menu. Leituras adotadas, a confirmar pelo autor:

- **"N + ATK" / "N + MAK":** usei o poder N na fórmula normal de combate (poder × ATK/DEF, ou MAK/MEF nas mágicas) — não soma aditiva.
- **Mazz Bite:** poder `10 + 30% do HP máx.`; custo `ceil(30% do HP máx.)`, exige HP atual maior que o custo.
- **Skills mágicas de 1 alvo** (`umbral_gaze`, `ignoma`, `ignoma_esh`) reaproveitam o caminho `kind: strike` com `magic: true`; `dark_breath` segue no caminho mágico em todos os inimigos.
- **Fang Sting:** BLEED só com a marca de ataque em `POINT`. **Fang Spine:** BLEED ×1 no contato e ×2 no `POINT` por golpe; o 2º golpe vai para um 2º alvo escolhido (herói: depois do 1º alvo; inimigo: herói vivo sorteado, podendo repetir).
- **Vuln Pierce (pendência do autor):** dobra o dano se o alvo está "passivo": a última ação do round foi PASS, REST, ITEM, buff, cura ou reza em aliado/si, ou se ele declarou DEFEND contra a skill; a postura zera a cada round e com qualquer ação ofensiva.
- **Dark Breath:** 0 de dano; só em quem toma contato (esquiva perfeita evita tudo): −3 PP (quem não reza só fica cego) e `BLIND` por 1 round.
- **Haganah** passa a bloquear BLEED, prisão, BURN e os status dessas skills.
- **Survival:** `ignoma` entrou no pool (28 skills) mas **nenhum demônio a usa ainda**; o nome hebraico dela (`כדור אש`) é só um provisório descritivo; `fang_spine`/`ignoma_esh` não estão no pool. Os hebraicos antigos das skills renomeadas foram mantidos.
- O recurso `UNBLOCKABLE` (do antigo `void_gaze`) ficou no motor, sem nenhuma skill que o use.
