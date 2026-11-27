# Dossiê de Validação do Criador — Skills Canônicas & VFX (D-131)

**Decisões associadas:** D-125 · D-131 · D-137 · **Data da conclusão:** 2026-11-27  
**Status final:** **7/7 APROVADOS** (design mecânico 100% fechado + aprovação visual concluída em modo **Inimigos** e **3 Aliados Survival**; validação final in-engine no Godot pendente após implementação)  
**Referência HTML canônica:** [`docs/vfx_refs/d131/d131_skills_vfx_canon.html`](vfx_refs/d131/d131_skills_vfx_canon.html) · **Índice:** [`docs/vfx_refs/d131/README.md`](vfx_refs/d131/README.md) · **Spec mecânica:** [`docs/CANON_SKILLS_D131.md`](CANON_SKILLS_D131.md) · **Guia de implementação:** [`docs/CLAUDE_PROMPTS_D131.md`](CLAUDE_PROMPTS_D131.md)

> [!NOTE]
> Este documento registra oficialmente o **processo real de validação do criador para cada uma das 7 habilidades da D-131** (tanto decisões mecânicas quanto rejeições, ajustes e aprovação visual final), além de consolidar os critérios aprendidos e o checklist de validação final no Godot para que nenhum agente futuro repita erros já rejeitados.

---

## 1. Princípios de Validação Extraídos Diretamente do Criador (Regras Permanentes)

1. **Contenção visual — sem exagero nem camadas supérfluas:** *"efeito demais, eu não pedi por exagero."* Cada ataque deve executar **exatamente o que sua descrição diz**, com silhueta limpa, leitura imediata e poucos elementos de alto impacto — nunca empilhar rasgos extras, bocas/costelas inventadas, raios elétricos, grilhões ou partículas gratuitas.
2. **Protótipos obrigatórios nos 3 cartões de Aliados Survival (`D-137`):** todo protótipo visual HTML de ataque/VFX deve funcionar tanto contra inimigos quanto nos **3 cartões de aliados do modo Survival**, com seletor direto, exibindo o efeito sobre o(s) cartão(ões) no mesmo tamanho (sem recorte ao cartão).
3. **Efeitos persistentes nunca obstruem o Battle Log:** efeitos transitórios de ataque podem cruzar sobre o cartão do aliado, mas **marcas persistentes** que ficam ativas por várias ações/rodadas (como **`Mark of Sun`**) **NÃO podem cobrir o Battle Log** nem impedir a leitura de `HP`, `EN/PP`, nome ou `ACT` no cartão do aliado.
4. **Lei do Outline Dourado (`D-125`):** outline dourado `#ffd84a` existe **somente** em evoluções `ZAHAV` (`Vital Claws`, `Weakenen`). Ataques normais — inclusive solares/ígneos como `Mark of Sun` — usam estritamente suas paletas naturais sem dourado.
5. **Validação visual final no Godot pertence exclusivamente ao criador (`AGENTS.md` Regra 7):** aprovação do HTML fecha a direção artística 1:1; após a implementação em `SkillGrotesqueFX`, quadros e vídeos reais do Godot (em modo Inimigos e Aliados) ainda precisam ser apresentados para o aceite final do autor.

---

## 2. Processo de Validação por Ataque — Lote 2 Canônico (D-131 · 7/7)

### 2.1 `Stone Crush` (`4ACT / 0EN / PHYS / 1T`) — Rework de `HEAVY CRUSH`
- **Validação mecânica (2026-11-27):**
  - Ficha e efeito definidos pelo criador: arremessa grande rocha causando `30 PHYS (+ATK)`.
  - Recomendação aceita pelo criador: respeitar o teto de 4 atos estocados (`PASS`/`REST`) e exibir explicitamente `4 ACT` no menu/descrição.
- **Histórico de validação visual:**
  - **v1 (`d131_skills_vfx_v1`, removida):** rocha monolítica irregular rabiscada em arco + impacto com shake `±11px`, Moiré sísmico (`stone`), fendas no chão e 14 estilhaços quicando. → **APROVADO DE PRIMEIRA pelo criador.**
  - **v2–v4 (modo 3 Aliados D-137):** estendido para o modo **Aliados Survival (3 cartões)** preservando a coreografia exata. → **CONFIRMADO APROVADO.**
- **Referência final:** `renderStoneCrush()` em [`d131_skills_vfx_canon.html`](vfx_refs/d131/d131_skills_vfx_canon.html#L881-L954).
- **Checklist de validação final no Godot:**
  - [ ] Custo `4 ACT / 0 EN`, fórmula `30 PHYS + ATK`, mitigado por `DEF`.
  - [ ] Rocha, Moiré `stone`, fendas e estilhaços rodando limpos contra inimigos e contra os 3 cartões de aliados.
  - [ ] Zero dourado e zero letras hebraicas.

---

### 2.2 `Energy Blow` (`3ACT / 0EN / MAGI / 1T`) — Rework de `FINISHING BLOW`
- **Validação mecânica (2026-11-27):**
  - Condição `COND`: apenas em **Alvo Vulnerável** (realizando ação não-ofensiva ou sob efeito que força `PASS`, como paralisação/aprisionamento/sono — também unificada em `Vuln Pierce` via `BattleUnit.is_vulnerable()`) **ou** com **≤ 1/4 da vida restante**.
  - Tipo de dano **`DMG` (sem tipagem):** confirmado pelo criador — **ignora `DEF` e `MEF`**, mantendo barra de ritmo, bloqueio/desvio, vantagem de SP e variação ±10%.
  - Roubo de metade do EN máximo: confirmado pelo criador — **vale até o fim da batalha atual** (não altera save; alvos sem EN como Yoch sofrem apenas o dano `25 DMG + MAK`).
- **Histórico de validação visual:**
  - **v1 (`d131_skills_vfx_v1`, removida):** olho `VULNERABLE` + Moiré `energy` implodindo + estouro informe rabiscado + 16 filamentos de EN arrancados até o conjurador (contador de EN no HUD corrigido na auditoria pré-entrega). → **APROVADO DE PRIMEIRA pelo criador.**
  - **v2–v4 (modo 3 Aliados D-137):** estendido para o modo **Aliados Survival (3 cartões)** com filamentos subindo do cartão atingido até o inimigo atacante. → **CONFIRMADO APROVADO.**
- **Referência final:** `renderEnergyBlow()` em [`d131_skills_vfx_canon.html`](vfx_refs/d131/d131_skills_vfx_canon.html#L955-L1024).
- **Checklist de validação final no Godot:**
  - [ ] Bloqueado no menu/alvo quando `not target.is_vulnerable() and target.current_hp > target.stats.max_hp / 4`.
  - [ ] Dano `25 DMG + MAK` ignora `DEF`/`MEF` e respeita barra de ritmo/bloqueio/SP.
  - [ ] EN máximo do alvo cai pela metade até o fim da batalha e soma ao conjurador (revertido ao terminar o combate).
  - [ ] VFX fiel em modo Inimigos e 3 Aliados Survival; zero dourado, zero hebraico.

---

### 2.3 `Drain Claw` (`2ACT / 15EN / PHYS / 1T`) — Rework de `LIFE DRAIN`
- **Validação mecânica (2026-11-27):**
  - Efeito base: finca uma garra no alvo, tomando `15 HP + 1/4 da vida máxima do alvo`.
  - Fechamentos do criador: usuário cura **80% do HP drenado** *(sujeito a `BLEED` canônico)*; segue barra de ritmo e `DEF` na parcela fixa; **teto de `40 HP`** na parcela `1/4 HP máx.` contra chefes, Guardiões e Anjos.
- **Histórico de validação visual (3 iterações até aprovação):**
  - **v1 (rejeitada):** mão anatômica de 4 dedos deslizando linearmente e tremendo sobre o alvo. → **REJEITADO pelo criador.**
  - **v2 (rejeitada):** 3 garras rasgando + 3 fendas sangrando + 12 artérias grossas de 3 traços + Moiré grande. → **REJEITADO pelo criador** (*"efeito demais, eu não pedi por exagero"*).
  - **v3 → v4 canônica (aprovada):** enxugada para literalidade absoluta — **1 única garra curva afiada (`drawSingleImpaleClaw`)** finca reto no alvo, treme brevemente e recua limpa + Moiré `blood` discreto (`70×56`) + **6 gotas simples de sangue** até o conjurador, em Inimigos e nos 3 cartões de Aliados. → **APROVADO pelo criador** (*"perfeito"*).
- **Referência final:** `renderDrainClaw()` em [`d131_skills_vfx_canon.html`](vfx_refs/d131/d131_skills_vfx_canon.html#L674-L739).
- **Checklist de validação final no Godot:**
  - [ ] Dano `15 + min(cap, max_hp/4)` (cap `40` em chefes/Guardiões/Anjos), cura `80%` do drenado (respeitando `BLEED`).
  - [ ] Exatamente 1 garra afiada + Moiré contido + 6 gotas (sem mão inteira, sem 3 rasgos, sem excesso).
  - [ ] Zero dourado, zero hebraico; idêntico em tamanho nos 3 cartões de aliados.

---

### 2.4 `Vital Claws [ZAHAV]` (`3ACT / 25EN / PHYS / 1T`) — Evolução ZAHAV de `Drain Claw`
- **Validação mecânica (2026-11-27):**
  - Evolução `ZAHAV` de `Drain Claw` (D-118: botão `A`, nome dourado, 20 SP após concluir).
  - Efeito fechado: finca duas garras no alvo, tomando `30 HP + 1/4 da vida máxima` (**teto `60 HP`** na parcela percentual contra chefes/Guardiões/Anjos) e **`15 EN`**; cura **80% do HP drenado** e recupera o `EN` roubado (até o máximo).
- **Histórico de validação visual (3 iterações até aprovação):**
  - **v1 (rejeitada):** duas mãos rígidas deslizando em pinça + rasgo em X. → **REJEITADO pelo criador.**
  - **v2 (rejeitada):** duplo rasgo de 4 garras + boca/costela aberta com dentes + 14 artérias + 12 nervos + Moiré gigante. → **REJEITADO pelo criador** (*"efeito demais, eu não pedi por exagero"*).
  - **v3 → v4 canônica (aprovada):** **exatamente 2 garras afiadas** (esquerda e direita, silhueta negra com **outline dourado `#ffd84a`** + 2º traço carmesim `#a81c2e`) fincam em pinça (`0.34 s` e `0.48 s`), recuam limpas + Moiré `zahavBlood` contido (`82×66`) + **6 gotas de HP** (sangue/ouro) + **5 partículas de EN** (azul/ouro), em Inimigos e nos 3 cartões de Aliados. → **APROVADO pelo criador** (*"perfeito"*).
- **Referência final:** `renderVitalClaws()` em [`d131_skills_vfx_canon.html`](vfx_refs/d131/d131_skills_vfx_canon.html#L740-L812).
- **Checklist de validação final no Godot:**
  - [ ] Evolução ZAHAV de `Drain Claw`; toma `30 HP + 1/4 max` (cap `60` chefes/Guardiões/Anjos) + `15 EN`; cura `80%` HP + recupera EN.
  - [ ] Outline `#ffd84a` presente (ZAHAV); exatamente 2 garras + gotas limpas (sem boca/costela nem exageros).
  - [ ] Zero hebraico; funcional em Inimigos e nos 3 cartões de Aliados.

---

### 2.5 `Weaken` (`1ACT / 10EN / STAT / 1T`) — Rework de `CURSE RAY`
- **Validação mecânica (2026-11-27):**
  - Esfera de energia azul reduz `MEF` em `5 (+50% MAK do usuário)` até o fim do combate.
  - Fechamentos do criador: múltiplos usos **acumulam** até o **teto máximo de −50% da `MEF` base** (piso efetivo `1`, sem mutar `sp_base()`); **dissipável** via `Tahorah` (D-112).
- **Histórico de validação visual:**
  - **v1 (`d131_skills_vfx_v1`, removida):** esfera azul rabiscada (`blueStat`, 2 anéis, zero dourado) voa ao alvo → colapso Moiré azul + setas descendentes + warp febril sem flash de dano (`STAT`). → **APROVADO DE PRIMEIRA pelo criador.**
  - **v2–v4 (modo 3 Aliados D-137):** estendido para os **3 cartões Survival** mantendo o mesmo visual limpo. → **CONFIRMADO APROVADO.**
- **Referência final:** `renderWeaken()` em [`d131_skills_vfx_canon.html`](vfx_refs/d131/d131_skills_vfx_canon.html#L1025-L1071).
- **Checklist de validação final no Godot:**
  - [ ] Categoria `STAT` (0 dano); reduz `MEF` efetiva em `5 + floor(0.5 * effective_mak)` até fim do combate, acumulando até `−50%` da base (piso `1`).
  - [ ] Removível integralmente por `Tahorah` (`SkillFx.cleanse_all`).
  - [ ] Zero dourado, zero hebraico, sem flash branco de dano.

---

### 2.6 `Weakenen [ZAHAV]` (`2ACT / 15EN / STAT / 2T`) — Evolução ZAHAV de `Weaken`
- **Validação mecânica (2026-11-27):**
  - Evolução `ZAHAV` de `Weaken` (`2T`: seleciona **2 alvos distintos** quando há ≥ 2 vivos, ou 1 se restar 1).
  - Reduz **`MAK` e `MEF`** em `10 (+50% MAK do usuário)` até o fim do combate, **acumulando até −50% do atributo base** (piso efetivo `1`, sem mutar `sp_base()`), **dissipável** via `Tahorah`.
- **Histórico de validação visual (3 iterações até aprovação):**
  - **v1 (rejeitada):** esfera pequena no canto superior esquerdo disparando cópias simples. → **REJEITADO pelo criador.**
  - **v2 (rejeitada):** esfera colossal central com 4 anéis + 6 arcos elétricos + mitose + 3 grilhões/espinhos gigantes por alvo + anel na base. → **REJEITADO pelo criador** (*"efeito demais, eu não pedi por exagero"*).
  - **v3 → v4 canônica (aprovada):** evolução limpa e direta do `Weaken` aprovado — **1 esfera azul maior com outline dourado `#ffd84a`** surge no conjurador e dispara **2 esferas** em arco limpo contra os **2 alvos (`2T`)**, cada uma desfazendo-se em Moiré `zahavBlue` contido (`84×76`) + 7 setas descendentes dourado/azul, tanto em Inimigos (`MAZIK A & C`) quanto em 2 cartões de Aliados (`FALLEN & PIXIE`). → **APROVADO pelo criador** (*"perfeito"*).
- **Referência final:** `renderWeakenen()` em [`d131_skills_vfx_canon.html`](vfx_refs/d131/d131_skills_vfx_canon.html#L813-L880).
- **Checklist de validação final no Godot:**
  - [ ] Seleção `2T` (2 alvos distintos; fallback para 1 vivo); aplica redução acumulável (teto −50% base, piso `1`) em `MAK` e `MEF`; dissipável via `Tahorah`.
  - [ ] Outline `#ffd84a` presente (ZAHAV); sem raios elétricos nem grilhões/espinhos extras.
  - [ ] Zero hebraico; funcional em Inimigos e nos 3 cartões de Aliados.

---

### 2.7 `Mark of Sun` (`4ACT / 20EN / STAT / 1T`) — Rework de `SPIRIT BRAND`
- **Validação mecânica (2026-11-27):**
  - Um sol surge marcando o alvo; todo ataque que o alvo sofrer até o fim do próximo round causa **`+20 MAGI` extra**.
  - Fechamentos do criador: dispara **por golpe individual** (inclusive em multi-hit), mitigado por `MEF` com **piso mínimo de `5` de dano por disparo**; **a marca desaparece no 3º golpe que o alvo levar** (ou no fim do próximo round, o que vier primeiro); dissipável via `Tahorah`.
- **Histórico de validação visual (2 iterações de ajuste até aprovação):**
  - **v1 (aprovada inicialmente em modo Inimigos):** sol grotesco rabiscado em paleta `sunNormal` (sem dourado) acima da cabeça do inimigo (altura ajustada na auditoria para ficar abaixo do HUD `y=22`).
  - **v3 em modo Aliados (rejeitada com captura do criador):** ao testar nos 3 cartões de Aliados, o criador apontou **3 defeitos concretos** com print:
    1. O sol persistente acima do cartão **invadia o Battle Log** (`y = 252..290`) cobrindo o texto por várias rodadas.
    2. Os **triângulos caindo** sujavam o cartão.
    3. O **efeito de luz ao levar dano** (cone trapezoide preenchido) precisava ser trocado em **ambos os lados** (Inimigos e Aliados).
  - **v4 canônica (aprovada):**
    1. **Posição no cartão aliado:** sol persistente compacto encaixado no **canto inferior-direito livre do cartão** (`×3`/`×2` ao lado, `min_y` estritamente abaixo do Battle Log — **0 px sobre o log**, sem cobrir nome, `HP`, `PP/EN` ou `ACT`). No inimigo, segue acima da cabeça (`y = 58`, abaixo do HUD superior).
    2. **Triângulos 100% removidos** (zero `fx.embers`).
    3. **Novo clarão solar em ambos os lados:** ao levar dano, dispara um **anel solar rabiscado expandindo + estrela de 8 raios finos + núcleo breve osso-quente `#f2d9b6` + pulso Moiré contido** (clamped abaixo do Battle Log nos aliados). → **APROVADO pelo criador** (*"perfeito"*).
- **Referência final:** `renderMarkOfSun()` em [`d131_skills_vfx_canon.html`](vfx_refs/d131/d131_skills_vfx_canon.html#L526-L673).
- **Checklist de validação final no Godot:**
  - [ ] Custo `4 ACT / 20 EN`, categoria `STAT`, guarda 3 cargas (`3 → 2 → 1 → some no 3º golpe`) ou expira ao fim do próximo round; dissipável via `Tahorah`.
  - [ ] Cada golpe recebido dispara `+20 MAGI` mitigado por `MEF` (mínimo `5` de dano) acompanhado do novo clarão solar.
  - [ ] Sol persistente **nunca invade o Battle Log** em aliados (canto livre do cartão com indicador `×3`/`×2`), **zero triângulos**, **zero dourado ZAHAV**, **zero hebraico**.

---

## 3. Referência Cruzada — Validação do Lote 1 (D-124 · 8/8 Aprovados em 2026-11-27)

Para rastreabilidade completa dos 15 ataques não-reza canônicos atuais (8 da D-124 + 7 da D-131):
- **Aprovados na rodada D-125 v2/v3/v4** (referências salvas em [`docs/vfx_refs/d124_d125/README.md`](vfx_refs/d124_d125/README.md)):
  1. `Mazz Bite` (`v2`, aprovado de 1ª na linguagem D-125)
  2. `Fang Sting` (`v2`, aprovado de 1ª)
  3. `Vuln Pierce` (`v3`, corrigido para remover outline dourado — exclusivo ZAHAV)
  4. `Umbral Gaze` (`v3`, escurecido via `abyssDark` + `darkBias` a pedido do criador)
  5. `Fang Spine [ZAHAV]` (`v3`, aprovado após revisão de vértebras/costelas com outline dourado)
  6. `Ignoma` (`v3`, aprovado após remoção do olho do centro da chama)
  7. `Dark Breath v2` (`v4`, aprovado após refazer o ar saindo diretamente de dentro da boca grotesca de perfil)
  8. `Ignoma Esh [ZAHAV]` (`v4`, aprovado com outline dourado + arcos Moiré sincronizados `52`/`82` + letras hebraicas tricolores `אש`)
- **Status in-engine da D-124:** mecânica e VFX já implementados em `SkillGrotesqueFX` (Fases 1–5 concluídas); aguardando aprovação final dos vídeos/quadros no Godot pelo criador.
