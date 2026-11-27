# Referências HTML Aprovadas — VFX Não-Reza D-124 / D-125

Todos os **8 ataques** de [`docs/CANON_SKILLS_D124.md`](../../CANON_SKILLS_D124.md) foram **aprovados visualmente pelo criador em 2026-11-27** (estética oficial [`docs/NON_PRAYER_VFX_STYLE.md`](../../NON_PRAYER_VFX_STYLE.md), decisão **D-125**).

> [!CAUTION]
> Os arquivos `v2`, `v3` e `v4` registram a evolução das iterações. **USE APENAS A FUNÇÃO CANÔNICA INDICADA NA TABELA ABAIXO PARA CADA ATAQUE.** Não copie versões antigas que estejam em outro HTML (por exemplo, `Vuln Pierce` com dourado no `v2`, `Umbral Gaze` claro no `v2`, `Ignoma` com olho no `v2`, ou `Dark Breath` antigo no `v2`/`v3`).

## Mapa Canônico 1:1 (Qual HTML + Função Implementar)

| # | Ataque | ZAHAV? | Arquivo HTML Canônico | Função JS Exata | Paleta Canônica | Observação Crítica |
|---|---|---|---|---|---|---|
| 1 | **Mazz Bite** | Não | [`d124_skills_vfx_v2.html`](d124_skills_vfx_v2.html) | `renderMazzBite()` | `PALS.blood` (`#a81c2e` / `#efe6d5`) | Mandíbula grotesca assimétrica + 3 olhos + mini barra `HIGH SPEED (+20%)` + shake + Moiré radial |
| 2 | **Fang Sting** | Não | [`d124_skills_vfx_v2.html`](d124_skills_vfx_v2.html) | `renderFangSting()` | `PALS.blood` (`#a81c2e` / `#efe6d5`) | Ferrão ósseo diagonal + fenda horizontal de Moiré + 8 respingos rabiscados de sangue (`BLEED` só no `POINT`) |
| 3 | **Fang Spine** | **SIM** | [`d124_skills_vfx_v3.html`](d124_skills_vfx_v3.html) | `renderFangSpine()` | `PALS.zahavBlood` (`#a81c2e` / `#ffd84a`) | Coluna vertebral articulada (10 vértebras arqueadas entre alvos) + 4 pares de costelas curvadas + 8 gotas + **outline dourado ZAHAV** |
| 4 | **Vuln Pierce** | Não | [`d124_skills_vfx_v3.html`](d124_skills_vfx_v3.html) | `renderVulnPierce()` | `PALS.blood` (`#a81c2e` / `#e8ddd0`) | **ZERO dourado!** Olho aberto vulnerável → agulha/garra horizontal atravessando + 10 estilhaços rabiscados |
| 5 | **Dark Breath** | Não | [`d124_skills_vfx_v4.html`](d124_skills_vfx_v4.html) | `renderDarkBreath()` | `PALS.abyssDark` (`#361c52` / `#a997bd`) | **Boca grotesca de perfil** (garganta atrás, cone Moiré + 28 correntes de ar + 22 nuvens negras saindo **de dentro da boca**, maxilares com dentes na frente pulsando) + olhos riscados em X nos alvos |
| 6 | **Umbral Gaze** | Não | [`d124_skills_vfx_v3.html`](d124_skills_vfx_v3.html) | `renderUmbralGaze()` | `PALS.abyssDark` (`#361c52` / `#9b8ab0`) | **Versão mais escura!** `darken = 0.56 * env`, `darkBias = true`, olho gigante no chão (`darkIris = true`) + 5 espinhos/dedos curvos erguendo dos pés |
| 7 | **Ignoma** | Não | [`d124_skills_vfx_v3.html`](d124_skills_vfx_v3.html) | `renderIgnoma()` | `PALS.fireNormal` (`#c94c14` / `#f2d9b6`) | **Chama rabiscada pura (SEM olho, SEM dourado ZAHAV, SEM hebraico):** rastro de chama menor + projétil `drawSketchFlame` → explosão de 3 línguas erguendo |
| 8 | **Ignoma Esh** | **SIM** | [`d124_skills_vfx_v4.html`](d124_skills_vfx_v4.html) | `renderIgnomaEsh()` | `PALS.zahavFire` (`#d95b16` / `#ffd84a`) + `FIRE_HEBREW` | **Único com hebraico (`אש`)!** 2 bolas `drawSketchFlame` com **outline dourado ZAHAV** + Moiré sincronizado aos arcos (`52` e `82`) → explosão de 38 letras hebraicas tricolores + `אש` ascendente |

## Documentos relacionados
- **Guia de estilo artístico dos ataques não-reza:** [`docs/NON_PRAYER_VFX_STYLE.md`](../../NON_PRAYER_VFX_STYLE.md)
- **Especificação mecânica D-124:** [`docs/CANON_SKILLS_D124.md`](../../CANON_SKILLS_D124.md)
- **Prompts faseados para implementação no Claude:** [`docs/CLAUDE_PROMPTS_D124_D125.md`](../../CLAUDE_PROMPTS_D124_D125.md)
