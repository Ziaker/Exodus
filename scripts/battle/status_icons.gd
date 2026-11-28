class_name StatusIcons
extends RefCounted
## Indicadores adaptativos de status, buffs, debuffs e marcas (criador 2026-11-27):
## mix de gravura monocromática + tags escuras que se comprimem automaticamente conforme a lotação:
##   Density.FULL  -> gravura + nome legível (ex.: [gota] BLEED×2, [olho] BLIND, [losango] MEF-5)
##   Density.SHORT -> gravura + sigla curta  (ex.: [gota] BLD×2, [olho] BLND, [losango] M-5)
##   Density.ICON  -> apenas a gravura monocromática em moldura escura (+ contador compacto se >1)
## Só dados e cálculo de layout (puro): o HUD desenha. Efeitos com VFX persistente próprio (Mark of Sun)
## não duplicam aqui.

enum Kind { BUFF, DEBUFF, STATUS, MARK }
enum Density { FULL, SHORT, ICON }

## Paleta contida (filete sutil + tintura discreta do texto; fundo sempre escuro como o cartão).
const ACCENTS := {
	Kind.BUFF: Color("599d74"),
	Kind.DEBUFF: Color("b85c62"),
	Kind.STATUS: Color("b5945b"),
	Kind.MARK: Color("c96838"),
}
const TEXT_INKS := {
	Kind.BUFF: Color("d8eadf"),
	Kind.DEBUFF: Color("f0dada"),
	Kind.STATUS: Color("eee3ce"),
	Kind.MARK: Color("f2d9b6"),
}
const MORE_ACCENT := Color("6a6278")
const MORE_TEXT := Color("cfc7e2")
const GLYPH_INK := Color("ede3d8")
const UP_INK := Color("81e6a8")
const DOWN_INK := Color("ff9a92")


static func _add(list: Array, id: String, full: String, short_lbl: String, kind: int, count: int = 0, is_value: bool = false) -> void:
	list.append({
		"id": id,
		"full": full,
		"short": short_lbl,
		"label": short_lbl,
		"kind": kind,
		"count": count,
		"is_value": is_value,
	})


## Formata o texto da tag no nível pedido (FULL ou SHORT), incluindo magnitude (-5) ou pilhas (×2).
static func text_for(icon: Dictionary, density: int) -> String:
	var base := String(icon.full) if density == Density.FULL else String(icon.short)
	var ct := int(icon.get("count", 0))
	if ct <= 1:
		return base
	if bool(icon.get("is_value", false)):
		return "%s%d" % [base, ct]
	return "%s×%d" % [base, ct]


## Status ativos de `u`, na ordem: marcas, condições, debuffs, buffs.
## Mark of Sun fica fora da fileira pois já tem o sol persistente próprio no cartão/cabeça.
static func of(u: BattleUnit) -> Array[Dictionary]:
	var list: Array = []
	if u.has_status(&"mark"):
		_add(list, "mark", "MARK", "MRK", Kind.MARK)
	if u.has_status(&"gods_message"):
		_add(list, "gods_message", "DECREE", "DEC", Kind.MARK)
	if not u.bleeds.is_empty():
		_add(list, "bleed", "BLEED", "BLD", Kind.STATUS, u.bleeds.size())
	if not u.burns.is_empty():
		_add(list, "burn", "BURN", "BRN", Kind.STATUS, u.burns.size())
	if u.has_status(&"sleep"):
		_add(list, "sleep", "SLEEP", "SLP", Kind.STATUS)
	if u.trapped_actions > 0 or u.has_status(&"trapped"):
		_add(list, "trapped", "TRAP", "TRP", Kind.STATUS, maxi(1, u.trapped_actions))
	if u.paralyzed_acts > 0 or u.has_status(&"paralyzed"):
		_add(list, "paralyzed", "PARA", "PAR", Kind.STATUS, maxi(1, u.paralyzed_acts))
	if u.has_status(&"blind"):
		_add(list, "blind", "BLIND", "BLND", Kind.STATUS)
	if u.has_status(&"chaki"):
		_add(list, "chaki", "CHAKI", "CHK", Kind.STATUS)
	if u.weaken_mef_penalty > 0:
		_add(list, "weaken_mef", "MEF-", "M-", Kind.DEBUFF, u.weaken_mef_penalty, true)
	if u.weaken_mak_penalty > 0:
		_add(list, "weaken_mak", "MAK-", "K-", Kind.DEBUFF, u.weaken_mak_penalty, true)
	if u.has_status(&"weaken"):
		_add(list, "weaken", "ATK-", "W-", Kind.DEBUFF)
	if u.has_status(&"chill"):
		_add(list, "chill", "CHILL", "C-", Kind.DEBUFF)
	if u.has_status(&"snare"):
		_add(list, "snare", "AGI-", "G-", Kind.DEBUFF)
	if u.has_status(&"break") or u.has_status(&"berserk"):
		_add(list, "break", "DEF-", "D-", Kind.DEBUFF)
	if u.has_status(&"slow"):
		_add(list, "slow", "SLOW", "S-", Kind.DEBUFF)
	if not u.atk_stages.is_empty():
		_add(list, "atk_up", "ATK+", "A+", Kind.BUFF, u.atk_stages.size())
	if not u.mak_stages.is_empty():
		_add(list, "mak_up", "MAK+", "K+", Kind.BUFF, u.mak_stages.size())
	if not (u.def_stages.is_empty() and u.def_round_stages.is_empty()):
		_add(list, "def_up", "DEF+", "D+", Kind.BUFF, u.def_stages.size() + u.def_round_stages.size())
	if not u.mef_stages.is_empty():
		_add(list, "mef_up", "MEF+", "M+", Kind.BUFF, u.mef_stages.size())
	if not u.agi_buffs.is_empty():
		_add(list, "agi_up", "AGI+", "G+", Kind.BUFF)
	if not u.sp_buffs.is_empty():
		_add(list, "sp_up", "SP+", "S+", Kind.BUFF)
	if not u.haganah.is_empty():
		_add(list, "shield", "SHLD", "SHL", Kind.BUFF)
	if u.has_status(&"sturdy"):
		if u.sturdy_def_bonus > 0:
			_add(list, "sturdy", "STURDY+", "S+", Kind.BUFF, u.sturdy_def_bonus, true)
		else:
			_add(list, "sturdy", "STURDY", "STR", Kind.BUFF)
	if u.gevurah_bonus > 0.0:
		_add(list, "gevurah", "NEXT+", "G+", Kind.BUFF)
	if u.has_status(&"taunt"):
		_add(list, "taunt", "TAUNT", "TNT", Kind.BUFF)
	if u.has_status(&"zohar"):
		_add(list, "zohar", "ZONE+", "Z+", Kind.BUFF)
	if u.regen_rounds > 0 or not u.mends.is_empty():
		_add(list, "regen", "REGEN", "REG", Kind.BUFF, maxi(u.regen_rounds, u.mends.size()))
	if u.next_attack_high_speed:
		_add(list, "high_speed", "FAST", "FST", Kind.BUFF)
	var out: Array[Dictionary] = []
	out.assign(list)
	return out


## Escolhe o nível mais informativo que cabe em `max_w` sem cortar:
## FULL (gravura + nome) -> SHORT (gravura + sigla) -> ICON (só gravura; trunca com "+N" se ainda faltar espaço).
## `item_width_fn` recebe (icon: Dictionary, density: int) -> float.
static func layout(icons: Array, max_w: float, item_width_fn: Callable, gap: float = 2.0, icon_box: float = 11.0) -> Dictionary:
	if icons.is_empty():
		return {"density": Density.FULL, "shown": [], "widths": [], "total_w": 0.0, "more": 0}
	for d in [Density.FULL, Density.SHORT]:
		var widths: Array[float] = []
		var total := 0.0
		for i in icons.size():
			var w: float = float(item_width_fn.call(icons[i], d))
			widths.append(w)
			total += w + (gap if i > 0 else 0.0)
		if total <= max_w:
			return {"density": d, "shown": icons.duplicate(), "widths": widths, "total_w": total, "more": 0}
	# Fallback compacto: só gravuras (11×11), com "+N" apenas se nem as gravuras couberem.
	var fit_res := fit(icons, max_w, icon_box, gap)
	var shown: Array = fit_res.shown
	var more: int = fit_res.more
	var count := shown.size() + (1 if more > 0 else 0)
	var widths2: Array[float] = []
	for _i in shown.size():
		widths2.append(icon_box)
	var total2 := float(count) * icon_box + float(maxi(0, count - 1)) * gap
	return {"density": Density.ICON, "shown": shown, "widths": widths2, "total_w": total2, "more": more}


## Quantos ícones fixos cabem em `width` px lógicos (caixa de `box` px + `gap`); quando sobram, o último lugar vira "+N".
static func fit(icons: Array, width: float, box: float = 11.0, gap: float = 2.0) -> Dictionary:
	var slots := maxi(0, int(floor((width + gap) / (box + gap))))
	if icons.size() <= slots:
		return {"shown": icons.duplicate(), "more": 0}
	if slots <= 1:
		return {"shown": [], "more": icons.size()}
	return {"shown": icons.slice(0, slots - 1), "more": icons.size() - (slots - 1)}
