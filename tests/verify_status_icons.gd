extends SceneTree
## Ícones de status (opção C): quais efeitos viram ícone, a ordem, a cor por tipo e o corte "+N" por largura.
var checks := 0


func check(ok: bool, reason: String) -> void:
	if not ok:
		push_error("FAIL: " + reason)
		quit(1)
	checks += 1


func _initialize() -> void:
	var u := BattleUnit.new(&"u", "U", UnitStats.new(), true)
	check(StatusIcons.of(u).is_empty(), "a clean unit has no icon")
	u.apply_sun_mark()
	u.add_bleed(2)
	u.burns.append(2)
	u.weaken_mef_penalty = 4
	u.atk_stages.append({"round": 1, "owner": &"x"})
	u.haganah = {"round": 1, "owner": &"x"}
	var ids: Array = StatusIcons.of(u).map(func(i: Dictionary) -> String: return i.id)
	check(ids == ["mark_of_sun", "bleed", "burn", "weaken_mef", "atk_up", "shield"], "order: marks, conditions, debuffs, buffs (%s)" % [ids])
	var by := {}
	for i in StatusIcons.of(u):
		by[i.id] = i
	check(by.mark_of_sun.kind == StatusIcons.Kind.MARK and by.mark_of_sun.count == 3, "Mark of Sun: orange, shows the charges")
	check(by.bleed.kind == StatusIcons.Kind.STATUS and by.bleed.count == 2, "BLEED: amber, shows the stacks")
	check(by.weaken_mef.kind == StatusIcons.Kind.DEBUFF and by.atk_up.kind == StatusIcons.Kind.BUFF, "debuff red, buff green")
	u.sun_mark_hits = 0
	u.remove_status(&"mark_of_sun")
	check(not StatusIcons.of(u).any(func(i: Dictionary) -> bool: return i.id == "mark_of_sun"), "the icon goes away with the mark")
	u.add_status(&"chaki", 2)
	u.add_status(&"gods_message", 2)
	var extra_ids: Array = StatusIcons.of(u).map(func(i: Dictionary) -> String: return i.id)
	check(extra_ids.has("chaki") and extra_ids.has("gods_message"), "prayer statuses chaki and gods_message appear in StatusIcons (%s)" % [extra_ids])
	var five: Array = [1, 2, 3, 4, 5]
	var f2 := StatusIcons.fit(five, 100.0)
	check(f2.shown.size() == 5 and f2.more == 0, "everything fits in a wide card")
	var f3 := StatusIcons.fit(five, 40.0)
	check(f3.shown.size() == 2 and f3.more == 3, "a narrow card shows what fits plus +N (%d/%d)" % [f3.shown.size(), f3.more])
	var f0 := StatusIcons.fit(five, 8.0)
	check(f0.shown.is_empty() and f0.more == 5, "no room: only +N")
	print("VERIFY_STATUS_ICONS_OK: %d checks" % checks)
	quit(0)
