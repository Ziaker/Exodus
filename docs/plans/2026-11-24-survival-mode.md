# Survival Mode (for fun / combat sandbox) — Implementation Plan

> **For Codex:** REQUIRED SUB-SKILL: `executing-plans` to implement this plan task-by-task.
> **Project rule overrides:** never commit or push without explicit authorization; no
> worktree move (there are concurrent sessions); visual approval belongs exclusively to
> the creator; every phase ends with real evidence + a capture for his verification.

**Goal:** add a self-contained, non-lore survival mode: a large first-person overworld with
20 distinct SMT demons, an SMT healer and a vendor selling HP/EN recovery items, and 3
continues on death that never halve stats.

**Architecture:** reuse the existing first-person dungeon engine and the playable battle
controller through a `mode` profile and two subclasses. No fork of the 1.000-line dungeon
script, no rewrite of the combat system. All survival state (party HP/EN, Macca, items,
continues, visited map, remaining demons) lives in `Engine` metas/one small static helper,
so it survives the overworld → battle → overworld scene swaps without touching
`ProgressStore` (the main game's save).

**Tech Stack:** Godot 4.7.2 / GDScript, `BattleState`/`BattleUnit`/`UnitStats`/`SkillBook`,
`SceneFader` autoload, `DungeonEnemies`, procedural PNG extraction (Pillow), ffmpeg for
captures.

---

## Decisions taken under "de resto faça o que recomenda"

These are my proposed choices, **not** creator decisions. If any is rejected, only that
piece is redone; the rest of the plan stays.

1. **Entry point:** a 4th title-screen command, `Survival` (between `Continue` and
   `Shutdown`), opening `res://scenes/survival/SurvivalWorld.tscn`. Main game untouched.
2. **Currency:** `MACCA`, earned per victory (`20 + 5 × demons_defeated`). Not stored in
   `ProgressStore`.
3. **Healer:** free, full restore of party HP/EN; uses the SMT battler `Herald Raphael.png`
   as the picture (healing angel).
4. **Vendor:** uses the same command/option bar as the rest of the game, with rows
   `BEAD 20` (heals 40 HP), `CHAKRA 20` (restores 20 EN), `LEAVE`. Uses `Vile Mammon.png`
   (greed demon) as the picture. Both are real SMT sprites from the project.
5. **Battles:** 2 heroes vs **1** demon (the HUD already supports N opponents). Each of the
   20 demons is a distinct roaming silhouette; touching it starts its own fight.
6. **Items in battle:** the existing `ITEM` command consumes a BEAD (HP) or CHAKRA (EN)
   automatically (prefers the stat that is lower); `ITEM` disappears from the command bar
   when the bag is empty.
7. **Continues:** on Fallen's death, a `CONTINUE n/3` overlay offers Z (revive the whole
   party to full, same battle resumes with no stat loss) or X (end the run → title).
   `ProgressStore.halve_gains()` is never called from survival.
8. **Silhouettes:** same rule as the current overworld — the full SMT battler art is never
   shown in corridors; 20 dark silhouettes are extracted from their battlers by the
   existing procedural tool. Battles keep the project's SMT battle art.

---

## Files

**Create**
- `scripts/survival/survival_data.gd` — `class_name SurvivalData`; roster (20), maze, NPC
  definitions, shop items, prices, constants.
- `scripts/survival/survival_state.gd` — `class_name SurvivalState`; static
  get/set/clear/reset over `Engine` meta `exodus_survival_state`.
- `scripts/survival/survival_world.gd` — extends `DungeonProto`; sets `mode = "survival"`
  before `_ready` via a preconfigured `.tscn`; adds the vendor option bar and survival HUD.
- `scenes/survival/SurvivalWorld.tscn` — instances the dungeon scene with the survival
  script + profile.
- `scripts/survival/survival_battle.gd` — extends `PlayableController`; 1-demon encounter,
  persistent party HP/EN, items, Macca reward, 3 continues.
- `scenes/survival/SurvivalBattle.tscn` — instances `BattlePlayable.tscn` with the survival
  controller.
- `tools/generate_survival_silhouettes.py` — extracts 20 silhouettes from battlers (reuses
  the crop/outline logic of `tools/generate_dungeon_art.py`).
- `tests/verify_survival_data.gd`, `tests/verify_survival_world.gd`,
  `tests/verify_survival_battle.gd`.
- `tools/capture_survival.gd` — windowed gameplay capture (map → vendor → demon → battle →
  continue).
- `docs/SURVIVAL_MODE.md`.

**Modify**
- `scripts/title/title_screen.gd:15,131-135` — add `Survival` command + scene change.
- `tests/verify_title_screen.gd:32,35,39,42-64` — 4 commands, new wrap indices, survival
  scene check.
- `prototypes/dungeon-crawler/dungeon_proto.gd:126-139,189-203,529-541,345-360` —
  `mode` switch for maze/NPC/enemy data; hook for the vendor option bar; survival HUD rows.
  All existing defaults stay identical when `mode == ""`.
- `scripts/battle/battle_controller.gd:664,691` — add `var persist_progress := true` and
  guard the two `ProgressStore.save_*` calls with it. Default `true` = main game unchanged.
- `scripts/core/skill_book.gd:24-36` — additive placeholder skills (`frost_breath`,
  `hellfire`, `howl`, `curse_ray`, `mend`, `shadow_bite`, `spirit_bolt`, `primal_roar`).
  `KIND_SKILLS` is NOT touched: the main game's two genetic foes keep their moves.

---

## Data schema

`SurvivalData.DEMONS` — each entry is a Dictionary with:
`id`, `name`, `picture` (SMT battler path), `silhouette` (`assets/generated/survival/<id>.png`),
`cell` (map position), `stats` (`max_hp,max_en,atk,mak,defense,mef,agi`), `skills`
(2 distinct placeholder skills), `affinity` (`WEAK`/`RESIST`/`NORMAL`), `macca` (reward).

Roster (20 real SMT battlers present in `assets/graphics/battlers/`):

| # | id | name (SMT) | sprite | profile (HP/EN/ATK/MAK/DEF/MEF/AGI) | skills |
|---|----|-----------|--------|--------------------------------------|--------|
| 1 | pixie | Pixie | Fairy Pixie.png | 14/6/5/6/4/5/9 | pixie_dust, mend |
| 2 | jack_frost | Jack Frost | Fairy Jack Frost.png | 18/8/5/8/5/6/7 | frost_breath, spirit_bolt |
| 3 | pyro_jack | Pyro Jack | Fairy Pyro Jack.png | 20/8/6/8/5/5/6 | hellfire, howl |
| 4 | cerberus | Cerberus | Beast Cerberus.png | 30/8/9/3/8/4/7 | primal_roar, lunge |
| 5 | oni | Oni | Brute Oni.png | 34/10/10/2/9/3/5 | howl, lunge |
| 6 | garuda | Garuda | Avian Garuda.png | 26/9/7/5/6/6/11 | spirit_bolt, lunge |
| 7 | anubis | Anubis | Avatar Anubis.png | 32/10/8/5/8/5/8 | curse_ray, mend |
| 8 | chimera | Chimera | Avatar Chimera.png | 36/10/9/6/7/5/7 | hellfire, shadow_bite |
| 9 | andras | Andras | Fallen Andras.png | 28/9/9/4/6/4/10 | shadow_bite, curse_ray |
| 10 | succubus | Succubus | Night Succubus.png | 24/12/4/9/5/8/9 | curse_ray, mend |
| 11 | ganesha | Ganesha | Yoma Ganesha.png | 38/11/8/6/9/6/4 | primal_roar, mend |
| 12 | vritra | Vritra | Dragon Vritra.png | 44/12/8/9/9/7/5 | spirit_bolt, hellfire |
| 13 | wyvern | Wyvern | Drake Wyvern.png | 34/9/8/6/7/5/8 | lunge, hellfire |
| 14 | lich | Lich | Haunt Lich.png | 30/14/5/11/5/10/5 | curse_ray, spirit_bolt |
| 15 | matador | Matador | Fiend Matador.png | 42/12/11/5/8/5/12 | lunge, primal_roar |
| 16 | mara | Mara | Tyrant Mara.png | 48/14/11/8/9/7/7 | hellfire, howl, mend |
| 17 | loki | Loki | Vile Loki.png | 40/13/8/11/7/8/11 | shadow_bite, spirit_bolt |
| 18 | zouchouten | Zouchouten | Kishin Zouchouten.png | 46/12/12/4/11/4/6 | primal_roar, lunge |
| 19 | lakshmi | Lakshmi | Megami Lakshmi.png | 36/16/6/11/7/10/6 | mend, spirit_bolt |
| 20 | hel | Hel | Reaper Hel.png | 52/15/10/12/10/9/6 | curse_ray, hellfire, mend |

`SurvivalState` dictionary keys: `hp`, `en`, `macca`, `bead`, `chakra`, `continues`,
`defeated`, `cell`, `facing`, `visited`, `seen`, `remaining`. Defaults:
`hp/en = base party max (60/20)`, `macca = 0`, `bead/chakra = 0`, `continues = 3`,
`defeated = 0`, everything else empty. `reset()` is called only on the title-screen entry.

`SurvivalData.MAZE` — 25×21 grid (`#` wall, `.` floor, `S` start), a central plaza plus four
wings, camp at the start with healer and vendor on adjacent walkable cells, 20 demons spread
over the wings. Exact rows are written in Fase 1 together with the tests that assert size,
walkability and cell uniqueness.

---

## Phase 1 — data, silhouettes and state (gate: data + art)

### Task 1.1 — failing data test
**Files:** `tests/verify_survival_data.gd`
- `_check(SurvivalData.DEMONS.size() == 20, ...)`
- for each demon: unique id, unique name, `ResourceLoader.exists(picture)`, 7 stats > 0,
  skills non-empty and `SkillBook.def(skill)` non-empty, silhouette path declared.
- `_check(SurvivalData.MAZE.size() == 21)` and each row 25 chars; exactly one `S`.

Run:
```powershell
$exe = "C:\Users\zerke\OneDrive\Área de Trabalho\Exodus\Godot_v4.7.2-stable_win64_console.exe"
& $exe --headless --fixed-fps 60 --path . -s res://tests/verify_survival_data.gd
```
Expected: EXIT=1, `FAIL: ...` for the missing class.

### Task 1.2 — implement `SurvivalData` and placeholder skills
- Write `scripts/survival/survival_data.gd` with the table above and the maze.
- Add the 8 new skill defs to `scripts/core/skill_book.gd` (additive, no `KIND_SKILLS` change).
Run the same test. Expected: `SURVIVAL DATA CHECKS PASSED`, EXIT=0.

### Task 1.3 — silhouettes
- Write `tools/generate_survival_silhouettes.py` reusing the alpha crop + MaxFilter outline
  from `tools/generate_dungeon_art.py`; output `assets/generated/survival/<id>.png` (dark
  body + thin red rim, transparent background).
- Run `python tools\generate_survival_silhouettes.py`; check 20 PNGs and open a contact sheet
  with ImageMagick before presenting it to the creator.

### Task 1.4 — state helper
- `scripts/survival/survival_state.gd`: `static func data()`, `patch(dict)`,
  `reset()`, `clear()` (Engine meta `exodus_survival_state`).
- Extend `verify_survival_data.gd`: defaults, patch, reset, no `ProgressStore` writes.
- **Gate evidence:** test output + `git status --short` + list of 20 generated PNGs.

---

## Phase 2 — overworld profile, healer and vendor (gate: still captures)

### Task 2.1 — profile switch in `dungeon_proto.gd`
- Add `var mode := ""` and `var profile_data := {}`.
- In `_ready`, select `grid`, `npcs`, `enemies` from `SurvivalData` when `mode == "survival"`,
  otherwise keep the current constants. No behavior change for `mode == ""`.
- Add `const SURVIVAL_SCENE`, survival HUD constants (Macca / continues / bag).
- `verify_survival_world.gd`: instantiate `DungeonProto.tscn`, set `mode`/`profile_data`
  before `add_child`, check 21×25 grid, 20 enemies, healer/vendor cells, no overlap.

### Task 2.2 — survival world scene + script
- `scenes/survival/SurvivalWorld.tscn` instances `DungeonProto.tscn` with
  `survival_world.gd` attached; the script sets mode in `_init()` (before `_ready`).
- `_save_state/_restore_state` store the survival state into `SurvivalState` in addition to
  the normal Engine metas; the return scene points to `SurvivalWorld.tscn`.

### Task 2.3 — healer and vendor option bar
- `survival_world.gd` overrides `talk()`: for `role == "heal"`, restore party HP/EN from
  `SurvivalState`, show a 1-page dialogue; for `role == "shop"`, open a code-drawn option
  bar in the HUD (same style/position as the battle command bar) with
  `BEAD 20 / CHAKRA 20 / LEAVE`; up/down selects, Z buys, X closes; insufficient Macca
  shows `NOT ENOUGH MACCA` in the bar feedback.
- Tests: buy BEAD (Macca −20, bead +1), buy CHAKRA, reject with 0 Macca, LEAVE closes,
  healer restores HP/EN, portraits are the two SMT sprites.

### Task 2.4 — capture
- `tools/capture_survival.gd` records stills: start, healer menu, vendor menu after a win,
  demon silhouette in the corridor. Windowed run with `--fixed-fps 60`.
- **Gate evidence:** `verify_survival_world.gd` EXIT=0, editor parse 0 errors, 4 stills
  opened and inspected by me, then presented for the creator's judgment.

---

## Phase 3 — survival battle, items and 3 continues (gate: battle tests)

### Task 3.1 — failing battle test
`tests/verify_survival_battle.gd`:
- encounter meta with `pixie` → 1 opponent named Pixie, sprite path from the roster,
  `hud.opponents.size() == 1`, party HP/EN read from `SurvivalState`.
- Victory: `defeated +1`, `macca +20 +5*defeated`, return meta points to survival world.
- `ITEM` with bead > 0 heals HP and decrements bag; with chakra > 0 recovers EN;
  with empty bag the command is absent.
- Death: `continues 3 → 2`, party restored to full, `ProgressStore.load_gains()` byte-equal
  before/after (no halving), same battle resumes; at `continues 0` → game over → title.

### Task 3.2 — `survival_battle.gd`
- Override `_create_units`: party from `SurvivalState` HP/EN and base stats (no saved gains,
  no learned skills, no PP), 1 enemy built from `SurvivalData` (stats, skills, affinity,
  `sprite_path`).
- Override `_refresh_all` for `state.units[2..2]` (one opponent).
- Override `_commands` to drop `ITEM` when bag empty; override `_execute_command` for
  `ITEM` to consume bead/chakra and log the amount.
- Set `persist_progress = false` (new guard in `battle_controller.gd`) so absorption never
  writes the main save.
- Override `_play_death`: if continues > 0, show a code-drawn overlay `CONTINUE n/3` with
  `Z: continue | X: end run`, wait for input, revive party, `await run_battle()` (depth ≤ 3);
  else fade to title. Never call `ProgressStore.halve_gains()`.
- Override `_show_result`: award Macca + write party HP/EN back to `SurvivalState` before
  calling `super`.
- `SurvivalBattle.tscn` instances `BattlePlayable.tscn` with this script.

### Task 3.3 — regression
Run GUT + all `verify_*.gd`. Expected: all EXIT=0; the new survival tests pass; the normal
battle still has 2 genetic foes and still halves gains on death.
- **Gate evidence:** battle test output + parse + regression summary + `git diff --stat`.

---

## Phase 4 — title entry and full loop (gate: full regression + clip)

### Task 4.1 — title command
- `COMMANDS := ["New Game", "Continue", "Survival", "Shutdown"]`; `confirm()` maps
  `Survival` → `SURVIVAL_SCENE`; `reset()` the survival state on entry.
- Update `verify_title_screen.gd`: 4 rows, wrap `KEY_UP` from 0 → 3, disabled index stays 1,
  `Survival` confirmation opens `res://scenes/survival/SurvivalWorld.tscn`.

### Task 4.2 — full loop capture
- `tools/capture_survival.gd` extended: walk → shop → fight → continue → victory → return.
- Encode with `C:\Users\zerke\go\bin\ffmpeg.exe` to `captures/survival_gameplay.mp4`.
- **Gate evidence:** all 15+ `verify_*.gd` EXIT=0, GUT all passed, video audited frame by
  frame by me (no clipping/artifacts/off-map demons), then presented for the creator.

---

## Phase 5 — docs and final audit

- `docs/SURVIVAL_MODE.md`: entry, controls, roster table, shop prices, continue rule, what
  is deliberately isolated from lore/main save, and the recommendations rejected/accepted.
- Final audit checklist: every new line checked against the request; no `ProgressStore` write
  from survival; no SMT full art in overworld corridors; all sprite paths exist; no unhandled
  errors in any capture; `git status --short` + `git diff --stat` + HEAD recorded.
- Nothing is committed without explicit authorization.

---

## Verification commands (all phases)

```powershell
$p = "C:\Users\zerke\OneDrive\Área de Trabalho\Exodus"
$exe = "$p\Godot_v4.7.2-stable_win64_console.exe"

# parse
& $exe --headless --editor --quit --path $p

# one headless test
& $exe --headless --fixed-fps 60 --path $p -s res://tests/verify_survival_data.gd

# full suite
& $exe --headless --path $p -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
Get-ChildItem "$p\tests\verify_*.gd" | ForEach-Object {
  & $exe --headless --fixed-fps 60 --path $p -s ("res://tests/" + $_.Name)
}

# windowed capture (headless frames come out blank)
Start-Process -FilePath $exe -ArgumentList @('--path','.','--fixed-fps','60','--script','res://tools/capture_survival.gd') -WorkingDirectory $p -PassThru

# evidence
git -C $p status --short
git -C $p diff --stat
git -C $p rev-parse HEAD
```

## Status (2026-11-24)

Fases 1–3 foram implementadas pela sessão concorrente Antigravity e **integradas
sem sobrescrever trabalho alheio**. Fase 4 (entrada no título) e Fase 5 (docs e
auditoria) foram concluídas nesta sessão, junto com correções encontradas na
auditoria: `Array[String]` das silhuetas, testes de batalha com a IA agindo no
meio das asserções, barra de serviços sem transparência, crop da moldura dos
battlers VX (sombra descolada), escala do ataque básico e mensagem de retorno.

**Expansão posterior (pedido do criador):** 35 demônios (15 novos), 15 novas
skills placeholder, lutas com 1–3 demônios por tier, save da run em `user://`,
`NEW RUN`, tela `SURVIVAL CLEARED`, item em alvo cheio recusado, letras de VFX
que não cobrem o log, mais cobertura de testes e vídeo. Bug encontrado na
auditoria visual do overlay: o HUD dizia `ALL 20 CLEARED!` com 35 demônios —
corrigido para usar `DEMONS.size()`.

**Rodada final (pedido do criador):** `TITLE` na barra, `NEW RUN` com confirmação,
indicador `NEXT: D n` até o demônio mais próximo, validação de campos do save e
HP base do Fallen elevado a 140 (Yoch 90) para nenhum hit isolado matar. Novos
bugs corrigidos: derrotados renasciam com `enemies=[]` no save, `NEW RUN` sem
`current_scene`, e save corrompido aceito sem validação.

**Gate rule:** a phase is only presented when its tests pass, its captures have been opened
and inspected by me, and the evidence above is attached. Visual approval is always the
creator's; I present and await his judgment, never declare it approved.

## Risks / known constraints

- `battle_controller.gd` is shared with concurrent sessions — the `persist_progress` guard
  must be a 2-line additive change, nothing else.
- The playable HUD was written for 2 opponents; phase 3 verifies the 1-opponent path headless
  and visually before relying on it.
- Adding a title row changes wrap indices in `verify_title_screen.gd`; that test is updated
  in the same phase, never left failing.
- Survival must never write `ProgressStore`; phase 3 asserts this by comparing gains before
  and after a death.
- No commits, no pushes, no subagents, no worktree moves.
