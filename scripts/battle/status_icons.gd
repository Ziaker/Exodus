class_name StatusIcons
extends RefCounted
## Ícones de efeitos de status, buffs, debuffs e marcas de uma unidade (criador 2026-11-27, opção C do protótipo
## docs/proto_status_icons.html): fileira sobre a borda inferior do cartão do herói e sob a figura do inimigo.
## Só dados (puro): o HUD desenha. Formas, letras e cores são PROVISÓRIAS até o criador dar a arte.

enum Kind { BUFF, DEBUFF, STATUS, MARK }

const COLORS := {
	Kind.BUFF: Color("2f7d4d"), Kind.DEBUFF: Color("9a2c3c"), Kind.STATUS: Color("7a5a1a"), Kind.MARK: Color("c94c14"),
}
const MORE_COLOR := Color("3a3450")


static func _add(list: Array, id: String, label: String, kind: int, count: int = 0) -> void:
	list.append({"id": id, "label": label, "kind": kind, "count": count})


## Ícones ativos de `u`, na ordem: marcas, condições, debuffs, buffs.
static func of(u: BattleUnit) -> Array[Dictionary]:
	var list: Array = []
	if u.sun_mark_hits > 0:
		_add(list, "mark_of_sun", "*", Kind.MARK, u.sun_mark_hits)
	if u.has_status(&"mark"):
		_add(list, "mark", "M", Kind.MARK)
	if not u.bleeds.is_empty():
		_add(list, "bleed", "B", Kind.STATUS, u.bleeds.size())
	if not u.burns.is_empty():
		_add(list, "burn", "F", Kind.STATUS, u.burns.size())
	if u.has_status(&"sleep"):
		_add(list, "sleep", "Z", Kind.STATUS)
	if u.trapped_actions > 0 or u.has_status(&"trapped"):
		_add(list, "trapped", "T", Kind.STATUS)
	if u.paralyzed_acts > 0 or u.has_status(&"paralyzed"):
		_add(list, "paralyzed", "P", Kind.STATUS)
	if u.has_status(&"blind"):
		_add(list, "blind", "X", Kind.STATUS)
	if u.weaken_mef_penalty > 0:
		_add(list, "weaken_mef", "M↓", Kind.DEBUFF, u.weaken_mef_penalty)
	if u.weaken_mak_penalty > 0:
		_add(list, "weaken_mak", "K↓", Kind.DEBUFF, u.weaken_mak_penalty)
	if u.has_status(&"weaken"):
		_add(list, "weaken", "W↓", Kind.DEBUFF)
	if u.has_status(&"chill"):
		_add(list, "chill", "C↓", Kind.DEBUFF)
	if u.has_status(&"snare"):
		_add(list, "snare", "G↓", Kind.DEBUFF)
	if u.has_status(&"break") or u.has_status(&"berserk"):
		_add(list, "break", "D↓", Kind.DEBUFF)
	if u.has_status(&"slow"):
		_add(list, "slow", "S↓", Kind.DEBUFF)
	if not u.atk_stages.is_empty():
		_add(list, "atk_up", "A↑", Kind.BUFF, u.atk_stages.size())
	if not u.mak_stages.is_empty():
		_add(list, "mak_up", "K↑", Kind.BUFF, u.mak_stages.size())
	if not (u.def_stages.is_empty() and u.def_round_stages.is_empty()):
		_add(list, "def_up", "D↑", Kind.BUFF, u.def_stages.size() + u.def_round_stages.size())
	if not u.mef_stages.is_empty():
		_add(list, "mef_up", "M↑", Kind.BUFF, u.mef_stages.size())
	if not u.agi_buffs.is_empty():
		_add(list, "agi_up", "G↑", Kind.BUFF)
	if not u.sp_buffs.is_empty():
		_add(list, "sp_up", "S↑", Kind.BUFF)
	if not u.haganah.is_empty():
		_add(list, "shield", "◆", Kind.BUFF)
	if u.gevurah_bonus > 0.0:
		_add(list, "gevurah", "G+", Kind.BUFF)
	if u.has_status(&"taunt"):
		_add(list, "taunt", "!", Kind.BUFF)
	if u.has_status(&"zohar"):
		_add(list, "zohar", "Z+", Kind.BUFF)
	if u.regen_rounds > 0 or not u.mends.is_empty():
		_add(list, "regen", "+", Kind.BUFF)
	if u.next_attack_high_speed:
		_add(list, "high_speed", "H", Kind.BUFF)
	var out: Array[Dictionary] = []
	out.assign(list)
	return out


## Quantos ícones cabem em `width` px lógicos (caixa de `box` px + `gap`); quando sobram, o último lugar vira "+N".
## Devolve {"shown": Array, "more": int}.
static func fit(icons: Array, width: float, box: float = 10.0, gap: float = 2.0) -> Dictionary:
	var slots := maxi(0, int(floor((width + gap) / (box + gap))))
	if icons.size() <= slots:
		return {"shown": icons.duplicate(), "more": 0}
	if slots <= 1:
		return {"shown": [], "more": icons.size()}
	return {"shown": icons.slice(0, slots - 1), "more": icons.size() - (slots - 1)}
