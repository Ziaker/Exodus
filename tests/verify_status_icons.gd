extends SceneTree
## Indicadores adaptativos de status (gravura monocromática + tags escuras progressivas):
## ordem, exclusão de Mark of Sun (tem VFX próprio), compressão FULL -> SHORT -> ICON e corte "+N".
var checks := 0


func check(ok: bool, reason: String) -> void:
	if not ok:
		push_error("FAIL: " + reason)
		quit(1)
	checks += 1


func _initialize() -> void:
	var u := BattleUnit.new(&"u", "U", UnitStats.new(), true)
	check(StatusIcons.of(u).is_empty(), "a clean unit has no status indicator")
	u.apply_sun_mark()
	check(StatusIcons.of(u).is_empty(), "Mark of Sun does not duplicate in StatusIcons (it has its own persistent sun VFX)")
	u.add_bleed(2)
	u.burns.append(2)
	u.weaken_mef_penalty = 4
	u.atk_stages.append({"round": 1, "owner": &"x"})
	u.haganah = {"round": 1, "owner": &"x"}
	var list := StatusIcons.of(u)
	var ids: Array = list.map(func(i: Dictionary) -> String: return i.id)
	check(ids == ["bleed", "burn", "weaken_mef", "atk_up", "shield"], "order: marks, conditions, debuffs, buffs (%s)" % [ids])
	var by := {}
	for i in list:
		by[i.id] = i
	check(StatusIcons.text_for(by.bleed, StatusIcons.Density.FULL) == "BLEED×2" and StatusIcons.text_for(by.bleed, StatusIcons.Density.SHORT) == "BLD×2", "BLEED full/short labels")
	check(StatusIcons.text_for(by.weaken_mef, StatusIcons.Density.FULL) == "MEF-4" and StatusIcons.text_for(by.weaken_mef, StatusIcons.Density.SHORT) == "M-4", "MEF debuff formats magnitude directly")
	check(by.weaken_mef.kind == StatusIcons.Kind.DEBUFF and by.atk_up.kind == StatusIcons.Kind.BUFF, "debuff and buff kinds")
	u.add_status(&"chaki", 2)
	u.add_status(&"gods_message", 2)
	var extra_ids: Array = StatusIcons.of(u).map(func(i: Dictionary) -> String: return i.id)
	check(extra_ids.has("chaki") and extra_ids.has("gods_message"), "prayer statuses chaki and gods_message appear in StatusIcons (%s)" % [extra_ids])
	# Progressive compression FULL -> SHORT -> ICON -> +N
	var measure := func(icon: Dictionary, d: int) -> float:
		if d == StatusIcons.Density.ICON:
			return 11.0
		return 16.0 + float(StatusIcons.text_for(icon, d).length()) * 4.5
	var p_full := StatusIcons.layout(list, 260.0, measure, 2.0, 11.0)
	check(p_full.density == StatusIcons.Density.FULL and p_full.more == 0, "wide space uses FULL engraving + readable name")
	var p_short := StatusIcons.layout(list, 175.0, measure, 2.0, 11.0)
	check(p_short.density == StatusIcons.Density.SHORT and p_short.more == 0, "medium space compresses to SHORT engraving + abbreviation")
	var p_icon := StatusIcons.layout(list, 90.0, measure, 2.0, 11.0)
	check(p_icon.density == StatusIcons.Density.ICON and p_icon.shown.size() == 5 and p_icon.more == 0, "crowded card collapses cleanly to engraving-only icons")
	var p_over := StatusIcons.layout(list, 40.0, measure, 2.0, 11.0)
	check(p_over.density == StatusIcons.Density.ICON and p_over.shown.size() == 2 and p_over.more == 3, "extreme overflow truncates to +N (%d/%d)" % [p_over.shown.size(), p_over.more])
	print("VERIFY_STATUS_ICONS_OK: %d checks" % checks)
	quit(0)
