# Referência Canônica HTML — VFX D-139 (4/4 Aprovados de 1ª)

**Decisões:** D-125 · D-137 · D-139 · 2026-11-27 (validação visual concluída pelo criador — **4/4 aprovados de primeira**: *"absolutamente perfeitos todos"*)  
**Arquivo canônico único:** [`d139_skills_vfx_canon.html`](d139_skills_vfx_canon.html)  
**Estilo oficial:** [`docs/NON_PRAYER_VFX_STYLE.md`](../../NON_PRAYER_VFX_STYLE.md)  
**Especificação mecânica:** [`docs/CANON_SKILLS_D139.md`](../../CANON_SKILLS_D139.md)  
**Histórico de construção e validação:** [`docs/VALIDATION_LOG_D139.md`](../../VALIDATION_LOG_D139.md)  
**Prompts faseados de implementação:** [`docs/CLAUDE_PROMPTS_D139.md`](../../CLAUDE_PROMPTS_D139.md)

> [!IMPORTANT]
> Este diretório contém o arquivo HTML final aprovado (`d139_skills_vfx_canon.html`), cobrindo **todos os 4 ataques físicos canônicos do Lote 3 (D-139)** em ambos os modos obrigatórios pela **D-137** (**`Inimigos (3)`** e **`Aliados Survival (3 cartões)`**), além do seletor de `ACT` (`4 ACT → 5 hits` / `2 ACT → 3 hits`) para `Blade Dance`. Qualquer porte para `scripts/battle/skill_grotesque_fx.gd` deve reproduzir 1:1 as funções e tempos abaixo.

---

## Tabela de Mapeamento 1:1 (Função → Godot)

| # | Ataque | Função em `d139_skills_vfx_canon.html` | Linhas | Paleta (`PALS`, L67) | Duração / Impacto(s) | Regras de Alvo Aliado (3 cartões D-137) |
|---|---|---|---|---|---|---|
| 1 | **Twin Fang** | `renderTwinFang()` + `drawTwinFangPair()` + `drawParallelGashes()` | L497–L664 | `blood` *(normal, zero ouro)* | `2.35 s` · hits `0.28 s` e `0.86 s` | 2 pares de presas curvas em X em tamanho cheio (`unclipped`) direto sobre o cartão atingido; anel de ligação COMBO (`+50%`) entre o 1º e o 2º golpe; 2º par em escala `1.32×` + respingos rabiscados. |
| 2 | **Blade Dance** | `renderBladeDance()` + `drawCurvedBladeSlash()` | L669–L859 | `blade` *(normal, zero ouro)* | `0.34 + hits×0.33 + 0.95 s` (`2.94 s` com 5 hits) · cadência `0.33 s` | Rastro/fita rabiscada salta de cartão a cartão em **alvo intercalado** (`FALLEN → YOCH → PIXIE → FALLEN → YOCH`), com lâminas crescentes em tamanho cheio (`unclipped`), cicatrizes residuais e faíscas; se só houver 1 alvo vivo, usar arco de retorno sobre ele no Godot. |
| 3 | **Rock Body** | `renderStoneArmor(false)` + `drawRockPlate()` + `drawSturdyBadge()` | L864–L1095 | `stone` *(normal, zero ouro)* | `2.95 s` · lock `0.44 s` · demo counter `1.65 s` | `SELF` (`IMEDIATO`) no cartão do usuário com EN (`FALLEN`): 7 placas de pedra convergem em tamanho cheio → **estado persistente `STURDY`** com 4 cantoneiras pétreas + escudo hexagonal no **canto inferior-direito livre do cartão** (`y >= 298`, **0 px sobre o Battle Log**). |
| 3Z | **Stone Body** *(ZAHAV)* | `renderStoneArmor(true)` + `drawRockPlate()` + `drawSturdyBadge()` | L864–L1095 | `zahavStone` *(outline/veios `#ffd84a`)* | `3.15 s` · lock `0.62 s` · demo counter `1.78 s` | `SELF` (`IMEDIATO`, ZAHAV): 10 blocos pesados de rocha em 2 ondas com veios dourados `#ffd84a` + 6 setas ascendentes douradas (`+15 DEF`) → cantoneiras grossas e emblema dourado-pedra no **canto inferior-direito livre do cartão** (**0 px sobre o Battle Log**). |

---

## Invariantes Verificados em `d139_skills_vfx_canon.html`

- **Lei do Outline Dourado (D-125):** `#ffd84a` existe **exclusivamente** em **`Stone Body [ZAHAV]`** (`PALS.zahavStone` e ramos `isZahav`). Zero dourado em `Twin Fang`, `Blade Dance` e `Rock Body`.
- **Separação Hebraica (D-113 vs. D-125):** **zero letras hebraicas** (`0` caracteres Unicode `U+0590–U+05FF`) em todos os 4 ataques da D-139.
- **Modo 3 Aliados Survival (D-137):** alternância direta `Inimigos (3)` ↔ `Aliados Survival (3 cartões)` validada em todas as 4 funções, com efeitos transitórios em tamanho cheio sem recorte e elementos **persistentes** de `STURDY` estritamente dentro do cartão (`y >= 298`, abaixo do Battle Log).
- **Respeito à economia de recursos no modo Aliados:** como `Rock Body` (`10 EN`) e `Stone Body` (`25 EN`) consomem `EN` (e Yoch usa `PP`), o modo Aliados demonstra os buffs `SELF` sobre `FALLEN` (cartão esquerdo), descontando `EN` real.
