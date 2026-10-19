extends Control
## Menu modal: toko (E di toko) dan inventori (tombol I).

enum Mode { NONE, SHOP, INVENTORY }

const PANEL := Rect2(160, 60, 640, 400)

var mode := Mode.NONE
var entries: Array = []   # toko: {label, kind, arg}; inventori: {label}
var cursor := 0
var note := ""


func _ready() -> void:
	Events.open_shop.connect(func(): open(Mode.SHOP))


func open(m: Mode) -> void:
	mode = m
	cursor = 0
	note = ""
	_rebuild()
	Events.menu_open = true
	Clock.paused = true
	queue_redraw()


func close() -> void:
	mode = Mode.NONE
	Events.menu_open = false
	Clock.paused = false
	queue_redraw()


func _season_text(id: String) -> String:
	var names := []
	for s in Data.crops[id].seasons:
		names.append(Clock.SEASON_NAMES[int(s)])
	return "/".join(names)


func _rebuild() -> void:
	entries = []
	if mode == Mode.SHOP:
		for id in Data.crop_ids():
			entries.append({"label": "Benih %s  %dG  (%s, %d hari%s)" % [
				Data.crop_name(id), Data.seed_price(id), _season_text(id), Data.growth_days(id),
				", berulang" if Data.regrow_days(id) > 0 else ""], "kind": "seed", "arg": id})
		entries.append({"label": "Pakan ternak  %dG  (dimiliki %d)" % [Inventory.FEED_PRICE, Inventory.count("feed")],
			"kind": "feed", "arg": "feed"})
		var ls := get_tree().get_first_node_in_group("livestock") as Livestock
		for type in Data.animals:
			var info: Dictionary = Data.animals[type]
			entries.append({"label": "Beli %s  %dG  (%s %d/%d, menghasilkan %s)" % [
				info.name, info.price, Data.areas[info.area].name,
				ls.count_of(type), info.capacity, Data.products[info.product].name],
				"kind": "animal", "arg": type})
		for k in Inventory.TOOL_KEYS:
			var label: String = Inventory.TOOL_LABELS[k]
			var cost := Inventory.next_upgrade_cost(k)
			if cost < 0:
				entries.append({"label": "%s sudah level maksimal (%s)" % [label, Inventory.LEVEL_NAMES[Inventory.tool_level(k)]], "kind": "none", "arg": k})
			else:
				entries.append({"label": "Upgrade %s -> %s  %dG" % [label, Inventory.LEVEL_NAMES[Inventory.tool_level(k) + 1], cost], "kind": "upgrade", "arg": k})
	elif mode == Mode.INVENTORY:
		entries.append({"label": "Uang: %dG" % Inventory.gold})
		entries.append({"label": "Cangkul: %s   Penyiram: %s (kapasitas %d)" % [
			Inventory.LEVEL_NAMES[Inventory.tool_level("hoe")],
			Inventory.LEVEL_NAMES[Inventory.tool_level("water")], Inventory.water_max()]})
		for id in Data.crop_ids():
			var seeds := Inventory.count(Inventory.seed_id(id))
			var crops := Inventory.count(Inventory.crop_id(id))
			var binned := int(Inventory.bin.get(Inventory.crop_id(id), 0))
			if seeds + crops + binned > 0:
				entries.append({"label": "%s - benih %d, dibawa %d, di kotak kirim %d" % [
					Data.crop_name(id), seeds, crops, binned]})
		entries.append({"label": "Pakan: %d" % Inventory.count("feed")})
		for prod in Data.products:
			var have := Inventory.count("prod:" + prod)
			var binned := int(Inventory.bin.get("prod:" + prod, 0))
			if have + binned > 0:
				entries.append({"label": "%s - dibawa %d, di kotak kirim %d" % [Data.products[prod].name, have, binned]})
		var ls2 := get_tree().get_first_node_in_group("livestock") as Livestock
		for a in ls2.animals:
			entries.append({"label": "%s - kasih sayang %d%s" % [a.name, a.affection, ", ada produk" if a.product else ""]})
		var fest := Clock.festival()
		if not fest.is_empty():
			entries.append({"label": "Hari ini: %s (harga jual +%d%%)" % [fest.name, roundi(float(fest.sell_bonus) * 100)]})
	cursor = clampi(cursor, 0, maxi(entries.size() - 1, 0))


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		if mode != Mode.NONE:
			get_viewport().set_input_as_handled()
		return
	if mode == Mode.NONE:
		if event.keycode == KEY_I:
			open(Mode.INVENTORY)
			get_viewport().set_input_as_handled()
		return
	get_viewport().set_input_as_handled()
	match event.keycode:
		KEY_ESCAPE:
			close()
		KEY_I:
			if mode == Mode.INVENTORY:
				close()
		KEY_UP, KEY_W:
			cursor = maxi(cursor - 1, 0)
		KEY_DOWN, KEY_S:
			cursor = mini(cursor + 1, maxi(entries.size() - 1, 0))
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			if mode == Mode.SHOP:
				_activate(entries[cursor])
	queue_redraw()


func _activate(e: Dictionary) -> void:
	match e.kind:
		"seed":
			var price := Data.seed_price(e.arg)
			if Inventory.spend(price):
				Inventory.add(Inventory.seed_id(e.arg))
				note = "Beli benih %s (-%dG)." % [Data.crop_name(e.arg), price]
			else:
				note = "Uang tidak cukup."
		"feed":
			if Inventory.spend(Inventory.FEED_PRICE):
				Inventory.add("feed")
				note = "Beli pakan (-%dG)." % Inventory.FEED_PRICE
			else:
				note = "Uang tidak cukup."
		"animal":
			var ls := get_tree().get_first_node_in_group("livestock") as Livestock
			var info: Dictionary = Data.animals[e.arg]
			if not ls.can_add(e.arg):
				note = "Kandang penuh."
			elif not Inventory.spend(int(info.price)):
				note = "Uang tidak cukup."
			else:
				ls.add_animal(e.arg)
				note = "Kamu membeli %s! Beri pakan setiap hari." % info.name
		"upgrade":
			if Inventory.upgrade(e.arg):
				note = "%s ditingkatkan ke %s!" % [Inventory.TOOL_LABELS[e.arg], Inventory.LEVEL_NAMES[Inventory.tool_level(e.arg)]]
			else:
				note = "Uang tidak cukup."
	_rebuild()


func _draw() -> void:
	if mode == Mode.NONE:
		return
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.5))
	draw_rect(PANEL, Color(0.15, 0.12, 0.1))
	draw_rect(PANEL, Color(0.9, 0.8, 0.5), false, 2.0)
	var title := "Toko" if mode == Mode.SHOP else "Inventori"
	draw_string(font, PANEL.position + Vector2(20, 34), "%s   (Uang: %dG)" % [title, Inventory.gold],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 0.9, 0.5))
	var y := PANEL.position.y + 70
	for i in entries.size():
		var selected := mode == Mode.SHOP and i == cursor
		if selected:
			draw_rect(Rect2(PANEL.position.x + 10, y - 18, PANEL.size.x - 20, 26), Color(0.4, 0.3, 0.15))
		draw_string(font, Vector2(PANEL.position.x + 24, y), entries[i].label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE if selected or mode != Mode.SHOP else Color(0.85, 0.85, 0.85))
		y += 30
	var hint := "W/S pilih, Enter beli, Esc tutup" if mode == Mode.SHOP else "Esc / I tutup"
	draw_string(font, PANEL.position + Vector2(20, PANEL.size.y - 40), note, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.7, 1, 0.7))
	draw_string(font, PANEL.position + Vector2(20, PANEL.size.y - 16), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.7, 0.8, 1))
