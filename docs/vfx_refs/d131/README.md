# Referência Canônica HTML — VFX D-131 (7/7 Aprovados)

**Decisões:** D-125 · D-131 · D-137 · 2026-11-27 (validação visual concluída pelo criador — **7/7 aprovados**)  
**Arquivo canônico único:** [`d131_skills_vfx_canon.html`](d131_skills_vfx_canon.html) *(versões preliminares v1–v3 removidas após aprovação final)*  
**Estilo oficial:** [`docs/NON_PRAYER_VFX_STYLE.md`](../../NON_PRAYER_VFX_STYLE.md)  
**Especificação mecânica:** [`docs/CANON_SKILLS_D131.md`](../../CANON_SKILLS_D131.md)  
**Histórico de validação do criador:** [`docs/VALIDATION_LOG_D131.md`](../../VALIDATION_LOG_D131.md)  
**Guia de implementação faseada:** [`docs/CLAUDE_PROMPTS_D131.md`](../../CLAUDE_PROMPTS_D131.md)

> [!IMPORTANT]
> Este diretório contém **apenas o arquivo HTML final aprovado** (`d131_skills_vfx_canon.html`), cobrindo **todos os 7 ataques da D-131** em ambos os modos obrigatórios pela **D-137** (**`Inimigos (3)`** e **`Aliados Survival (3 cartões)`**). Qualquer porte para `scripts/battle/skill_grotesque_fx.gd` deve reproduzir 1:1 as funções listadas abaixo.

---

## Tabela de Mapeamento 1:1 (Função → Godot)

| # | Ataque | Função em `d131_skills_vfx_canon.html` | Linhas | Paleta (`PALS`, L67) | Duração / Impacto(s) | Regras de Alvo Aliado (3 cartões D-137) |
|---|---|---|---|---|---|---|
| 1 | **Stone Crush** | `renderStoneCrush()` | L881–954 | `stone` *(normal, zero ouro)* | `2.55 s` · hit `0.62 s` | Rocha arremessada do inimigo sobre o cartão no mesmo tamanho (`unclipped`), fendas e estilhaços quicando na borda inferior. |
| 2 | **Energy Blow** | `renderEnergyBlow()` | L955–1024 | `energy` *(normal, zero ouro)* | `2.65 s` · hit `0.56 s` | Implosão + olho `VULNERABLE` + estouro direto sobre o cartão; 16 filamentos de EN sobem do cartão ao inimigo atacante. |
| 3 | **Drain Claw** | `renderDrainClaw()` | L674–739 | `blood` *(normal, zero ouro)* | `2.25 s` · hit `0.36 s` | **Contido:** 1 única garra afiada (`drawSingleImpaleClaw`, L395) finca no cartão e recua + Moiré discreto (`70×56`) + 6 gotas sobem ao inimigo. |
| 3Z | **Vital Claws** *(ZAHAV)* | `renderVitalClaws()` | L740–812 | `zahavBlood` *(outline `#ffd84a`)* | `2.40 s` · hits `0.34 s`, `0.48 s` | **Contido:** 2 garras (`drawSingleImpaleClaw`, esq./dir.) fincam em pinça + 6 gotas HP (sangue/ouro) + 5 partículas EN (azul/ouro) sobem ao inimigo. |
| 4 | **Weaken** | `renderWeaken()` | L1025–1071 | `blueStat` *(normal, zero ouro)* | `2.45 s` · hit `0.58 s` | Esfera azul (`drawSketchOrb`, L408) voa até o cartão → colapso Moiré (`92×84`) + 7 setas descendentes (`STAT`, sem flash de inversão). |
| 4Z | **Weakenen** *(ZAHAV)* | `renderWeakenen()` | L813–880 | `zahavBlue` *(outline `#ffd84a`)* | `2.50 s` · hits `0.78 s`, `0.90 s` | **Contido:** 1 esfera azul maior no conjurador dispara 2 esferas contra **2 cartões distintos (`2T`)** → colapso limpo + setas dourado/azul. |
| 5 | **Mark of Sun** | `renderMarkOfSun()` | L526–673 | `sunNormal` *(normal, zero ouro)* | `2.95 s` · marca `0.65 s` · disparo `+20 MAGI` `0.48 s` | **Regra especial de marca persistente:** sol encaixado no **canto inferior-direito livre do cartão** (`×3`/`×2` ao lado, `min_y` estritamente abaixo do Battle Log); **zero triângulos**; clarão solar limpo (anel + estrela de 8 raios finos + núcleo breve) ao sofrer dano em ambos os lados. |

---

## Invariantes Verificados em `d131_skills_vfx_canon.html`
- **Lei do Outline Dourado (D-125):** `#ffd84a` existe **exclusivamente** em `Vital Claws [ZAHAV]` e `Weakenen [ZAHAV]`. Zero dourado nas 5 skills normais.
- **Separação Hebraica (D-113 vs. D-125):** **zero letras hebraicas** em todas as 7 skills da D-131.
- **Contenção visual (aprendizado validado pelo criador):** sem sobreposição de camadas supérfluas, sem triângulos soltos em `Mark of Sun`, sem cone trapezoide no disparo solar.
- **Modo 3 Aliados Survival (D-137):** alternância direta `Inimigos (3)` ↔ `Aliados Survival (3 cartões)` validada em todas as 7 funções.
