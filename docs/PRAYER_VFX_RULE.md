# Regra de VFX de Reza — Letras Hebraicas Obrigatórias (D-113)

**Decisão:** D-113 · 2026-11-26 (decisão do criador)  
**Índice canônico:** [`docs/DECISIONS.md`](DECISIONS.md)  
**Registro no GDD:** [`docs/GDD.md`](GDD.md) (Apêndice A)

---

## 1. Regra obrigatória

> **Todos os efeitos de reza do EXODUS devem obrigatoriamente possuir efeitos visuais feitos com letras hebraicas.**

Esta regra aplica-se indistintamente a **todas** as rezas do jogo — da campanha (Yoch), do modo Survival (humanos inimigos e humanos recrutados como aliados) e de qualquer reza criada futuramente. Nenhuma reza pode ser considerada completa ou entregável se resolver apenas com texto no Battle Log, números flutuantes ou efeitos genéricos sem tipografia hebraica.

---

## 2. Princípios visuais das rezas

1. **Linguagem 100% tipográfica hebraica:**  
   Os efeitos visuais de reza (implementados em `scripts/battle/pray_fx.gd`) devem ser construídos com glifos hebraicos — a palavra hebraica da própria reza e/ou letras do alfabeto hebraico (`אבגדהוזחטיכלמנסעפצקרשת`). Não usar círculos, arcos, polylines, barras geométricas ou partículas abstratas no lugar das letras.
2. **Coerência entre coreografia e mecânica:**  
   O movimento, a cor e a composição das letras devem comunicar imediatamente o efeito da reza (por exemplo: ascensão em hélice para cura, grade descendente para escudo coletivo, colapso espiral para amplificação de ataque, arco de corte luminoso para golpe em área, desintegração/ofuscamento para cegueira, conversão de letras vermelhas em luz dourada para purificação).
3. **Marcas hebraicas persistentes para efeitos contínuos:**  
   Rezas que deixam um estado ativo por rodadas ou até a próxima ação devem exibir uma marca persistente com a inicial hebraica da reza (ex.: `מ` para Magen, `ג` para Gevurah, `ז` para Zohar, `ס` para Sanverim, `נ` para Nechamah) enquanto o efeito durar.
4. **Legibilidade e segurança BiDi/RTL no Godot:**  
   - Usar grafia hebraica sem niqqud na renderização em tela para preservar legibilidade pixel-crisp em 816×624 (mantendo niqqud na documentação).
   - Nunca concatenar glifos hebraicos (RTL) com sufixos ASCII (como `x2`) na mesma chamada `draw_string`, pois o algoritmo bidirecional inverte a ordem visual (`x2נ`). Sempre desenhar o glifo hebraico e o sufixo numérico/ASCII em chamadas separadas.
5. **Rezas de impacto imediato e rezas com cast:**  
   Tanto rezas conjuradas em etapas (como `PRAY` / `Ra'am`) quanto rezas de resolução imediata (como `Refuah`, `Sanverim`, `Nechamah`, `Cherev` e D-112) devem disparar seu efeito visual em `pray_fx.gd`.

---

## 3. Cobertura atual do catálogo (`PrayerBook`)

| Reza | Hebraico (doc / tela) | Origem | Método em `scripts/battle/pray_fx.gd` | Resumo do VFX | Marca persistente |
|---|---|---|---|---|---|
| **Refuah** | רְפוּאָה / `רפואה` | D-048 | `play_refuah(target, extra_pp = 0)` | Dupla hélice ascendente verde-ouro + palavra `רפואה` (densidade escala com PP extra) | — |
| **Haganah** | הֲגָנָה / `הגנה` | D-048 | `_draw()` (estado ativo de `haganah`) | Barreira/domo puramente de letras hebraicas ao redor do protegido | Barreira ativa |
| **Ra'am** | רַעַם / `רעם` | D-048 | `play_raam(target)` | Tempestade/queda de raio composta por letras hebraicas com impacto | — |
| **Sanverim** | סַנְוֵרִים / `סנוורים` | D-107 | `play_sanverim(target)` | Flash cegante com letras dispersando em anel de ofuscamento + palavra `סנוורים` | `ס` (vermelho) |
| **Nechamah** | נֶחָמָה / `נחמה` | D-107 | `play_nechamah(target, stacks = 1)` / `play_nechamah_tick(target, stacks = 1)` | Fluxo suave ascendente verde/dourado com `נחמה` no cast + pulso por tick de rodada | `נ` + `xN` (acúmulo) |
| **Cherev** | חֶרֶב / `חרב` | D-107 | `play_cherev(on_enemies)` | Carga de lâmina + corte diagonal em arco de letras `חרב` cruzando todos os alvos | — |
| **Tahorah** | טָהֳרָה / `טהרה` | D-112 | `play_tahorah(target)` | Fileira horizontal de letras + `טהרה` subindo e convertendo glifos vermelhos em luz dourada | — |
| **Magen** | מָגֵן / `מגן` | D-112 | `play_magen(allies)` | Grade descendente de letras com `מגן` sobre todos os aliados | `מ` (pulsante) |
| **Gevurah** | גְּבוּרָה / `גבורה` | D-112 | `play_gevurah(target)` | Colapso espiral + anel formado por 16 letras sobre o aliado | `ג` (vibrante) |
| **Mishpat** | מִשְׁפָּט / `משפט` | D-112 | `play_mishpat(caster, target)` | Letras vermelhas de retribuição em arco + paredes de letras fechando com `משפט`, impact frame, shake e queda | — |
| **Zohar** | זֹהַר / `זוהר` | D-112 | `play_zohar(target)` | `זוהר` abrindo em dois feixes horizontais de luz sobre o aliado | `ז` |

---

## 4. Critério de aceitação para novas rezas

Qualquer nova reza adicionada ao jogo só pode ser considerada entregue após cumprir todos os itens abaixo:

1. Estar registrada em `scripts/core/prayer_book.gd` com sua grafia hebraica definida.
2. Possuir efeito visual dedicado em `scripts/battle/pray_fx.gd` composto por letras hebraicas (e marca persistente, se tiver duração contínua).
3. Estar ligada em todos os controladores que podem dispará-la (`scripts/battle/prayer_flow.gd`, `scripts/battle/playable_controller.gd`, `scripts/survival/survival_battle.gd`).
4. Ter cobertura de teste automatizado garantindo execução sem erro.
5. Ter captura visual (quadros e/ou vídeo no Godot) inspecionada pelo agente e **aprovada visualmente pelo criador** (conforme `AGENTS.md`).
