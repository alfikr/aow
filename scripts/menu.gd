extends Control
## Menu modal: toko, inventori, dialog NPC, dan layar ending.

signal closed

enum Mode { NONE, SHOP, INVENTORY, DIALOG, COOK, ENDING, PAUSE, SETTINGS, HELP, SHRINE }

const PANEL := Rect2(120, 40, 720, 440)
const BODY_H := 96.0
const HELP_TEXT := "WASD / panah: jalan\nSpasi: pakai alat di tile depan (atau tarik pancing)\n1 cangkul   2 penyiram   3 benih   4 pancing   Q ganti jenis benih\nE: bicara, panen, ambil produk, buka pintu benda, tidur di kasur, masak di dapur\nI: inventori (Enter pada masakan untuk makan)   Esc: menu jeda   F11: layar penuh\n\nSiram tanaman tiap hari, panen, lalu masukkan ke kotak kirim (E). Uang diterima saat tidur.\nToko ada di desa (timur peternakan), buka 09:00-18:00. Tambang di utara desa, pantai di timur, rumah warga di selatan (Permukiman). Batu di ladang dipecahkan dengan cangkul. Ada rahasia di timur kebun..."

var mode := Mode.NONE
var return_to := Mode.NONE   # mode tujuan saat Esc dari Pengaturan/Bantuan
var allow_pause := true
var entries: Array = []   # {label, kind, arg}
var cursor := 0
var note := ""
var body := ""            # teks utama (dialog / ending)
var npc_id := ""
var pages: Array = []
var page := 0


func _ready() -> void:
	Events.open_shop.connect(func(): open(Mode.SHOP))
	Events.open_dialog.connect(open_dialog)
	Events.open_cook.connect(func(): open(Mode.COOK))
	Events.open_shrine.connect(func(): open(Mode.SHRINE))
	Events.show_ending.connect(func(): open(Mode.ENDING))


func open(m: Mode) -> void:
	mode = m
	cursor = 0
	note = ""
	body = ""
	pages = []
	page = 0
	if m == Mode.ENDING:
		body = Progress.ending_text()
	elif m == Mode.HELP:
		body = HELP_TEXT
	_rebuild()
	Events.menu_open = true
	Clock.paused = true
	queue_redraw()


func open_dialog(id: String) -> void:
	npc_id = id
	open(Mode.DIALOG)
	body = "%s menyapamu." % Data.npcs[id].name
	queue_redraw()


func close() -> void:
	mode = Mode.NONE
	return_to = Mode.NONE
	Events.menu_open = false
	Clock.paused = false
	queue_redraw()
	closed.emit()


## Esc / selesai: kembali ke menu pemanggil, atau tutup.
func back() -> void:
	if return_to != Mode.NONE:
		var m := return_to
		return_to = Mode.NONE
		open(m)
	else:
		close()


func _season_text(id: String) -> String:
	var names := []
	for s in Data.crops[id].seasons:
		names.append(Clock.SEASON_NAMES[int(s)])
	return "/".join(names)


func _giftable() -> Array:
	var out := []
	for id in Inventory.items:
		if not str(id).begins_with("seed:") and id != "feed" and Inventory.count(id) > 0:
			out.append(id)
	return out


func _rebuild() -> void:
	entries = []
	if mode == Mode.SHOP:
		_build_shop()
	elif mode == Mode.INVENTORY:
		_build_inventory()
	elif mode == Mode.COOK:
		_build_cook()
	elif mode == Mode.SHRINE:
		_build_shrine()
	elif mode == Mode.PAUSE:
		entries = [
			{"label": "Lanjut bermain", "kind": "resume"},
			{"label": "Simpan game", "kind": "save"},
			{"label": "Pengaturan", "kind": "settings"},
			{"label": "Bantuan & kontrol", "kind": "help"},
			{"label": "Ke menu utama", "kind": "title"},
			{"label": "Keluar dari game", "kind": "quit"}]
	elif mode == Mode.SETTINGS:
		_build_settings()
	elif mode == Mode.DIALOG:
		if page < pages.size() - 1:
			pass   # sedang membaca halaman: Enter untuk lanjut
		else:
			entries.append({"label": "Bicara", "kind": "talk"})
			for id in _giftable():
				entries.append({"label": "Beri hadiah: %s (x%d)" % [Data.item_name(id), Inventory.count(id)],
					"kind": "gift", "arg": id})
			entries.append({"label": "Selesai", "kind": "close"})
	cursor = clampi(cursor, 0, maxi(entries.size() - 1, 0))


func _build_shop() -> void:
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
			entries.append({"label": "%s sudah level maksimal (%s)" % [label, Inventory.LEVEL_NAMES[Inventory.tool_level(k)]],
				"kind": "none", "arg": k})
		else:
			var ore_text := ""
			for oid in Inventory.next_upgrade_ore(k):
				ore_text += " + %s x%d" % [Data.item_name(oid), int(Inventory.next_upgrade_ore(k)[oid])]
			entries.append({"label": "Upgrade %s -> %s  %dG%s" % [label, Inventory.LEVEL_NAMES[Inventory.tool_level(k) + 1], cost, ore_text],
				"kind": "upgrade", "arg": k})
	for iid in Data.items:
		if Data.items[iid].has("buy"):
			entries.append({"label": "%s  %dG" % [Data.item_name(iid), int(Data.items[iid].buy)], "kind": "buy", "arg": iid})


func _build_inventory() -> void:
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
	for id in Inventory.items:
		var s := str(id)
		if s.begins_with("dish:"):
			entries.append({"label": "Makan: %s x%d  (+%d stamina)" % [Data.item_name(s), Inventory.items[id], int(Data.recipes[s.substr(5)].stamina)],
				"kind": "eat", "arg": s})
		elif not s.begins_with("crop:") and not s.begins_with("seed:") and s != "feed":
			entries.append({"label": "%s x%d%s" % [Data.item_name(s), Inventory.items[id],
				"  (di kotak kirim: %d)" % int(Inventory.bin[id]) if Inventory.bin.has(id) else ""]})
	var ls := get_tree().get_first_node_in_group("livestock") as Livestock
	for a in ls.animals:
		entries.append({"label": "%s - kasih sayang %d%s" % [a.name, a.affection, ", ada produk" if a.product else ""]})
	var npcs := get_tree().get_first_node_in_group("npcs") as Npcs
	var friends := []
	for id in Data.npcs:
		friends.append("%s %d/10" % [npcs.npc_name(id), npcs.hearts(id)])
	entries.append({"label": "Hati: " + ", ".join(friends)})
	if Progress.spouse != "":
		entries.append({"label": "Pasangan: %s%s" % [Data.npcs[Progress.spouse].name, " (dan seorang anak)" if Progress.child else ""]})
	var fest := Clock.festival()
	if not fest.is_empty():
		entries.append({"label": "Hari ini: %s (harga jual +%d%%)" % [fest.name, roundi(float(fest.sell_bonus) * 100)]})


func _build_shrine() -> void:
	if body == "":
		body = "Patung Dewi Panen memancarkan cahaya hangat. Persembahkan hasil bumi agar tanamanmu diberkahi esok pagi.\n(Persembahan sejauh ini: %d)" % Progress.offerings
	for id in Inventory.items:
		var s := str(id)
		if (s.begins_with("crop:") or s.begins_with("forage:")) and Inventory.count(s) > 0:
			entries.append({"label": "Persembahkan %s (x%d)" % [Data.item_name(s), Inventory.count(s)], "kind": "offer", "arg": s})
	entries.append({"label": "Selesai", "kind": "close"})


func _bar(v: int) -> String:
	return "[" + "#".repeat(v) + "-".repeat(10 - v) + "] %d/10" % v


func _build_settings() -> void:
	entries = [
		{"label": "Volume utama   " + _bar(Settings.volumes.master), "kind": "vol", "arg": "master"},
		{"label": "Musik               " + _bar(Settings.volumes.music), "kind": "vol", "arg": "music"},
		{"label": "Efek suara       " + _bar(Settings.volumes.sfx), "kind": "vol", "arg": "sfx"},
		{"label": "Layar penuh (F11): " + ("Nyala" if Settings.fullscreen else "Mati"), "kind": "fullscreen"},
		{"label": "Kembali", "kind": "back"}]


func _ingredients_text(r: Dictionary) -> String:
	var parts := []
	for iid in r.ingredients:
		parts.append("%s x%d (punya %d)" % [Data.item_name(iid), int(r.ingredients[iid]), Inventory.count(iid)])
	return ", ".join(parts)


func _build_cook() -> void:
	body = "Dapur. Pilih resep untuk dimasak."
	for rid in Progress.recipes:
		var r: Dictionary = Data.recipes[rid]
		entries.append({"label": "%s - %s" % [r.name, _ingredients_text(r)], "kind": "cook", "arg": rid})


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		if mode != Mode.NONE:
			get_viewport().set_input_as_handled()
		return
	if mode == Mode.NONE:
		if allow_pause and event.keycode == KEY_I:
			open(Mode.INVENTORY)
			get_viewport().set_input_as_handled()
		elif allow_pause and event.keycode == KEY_ESCAPE:
			open(Mode.PAUSE)
			get_viewport().set_input_as_handled()
		return
	get_viewport().set_input_as_handled()
	match event.keycode:
		KEY_ESCAPE:
			back()
		KEY_LEFT, KEY_A:
			if mode == Mode.SETTINGS and entries[cursor].get("kind", "") == "vol":
				Settings.adjust(entries[cursor].arg, -1)
				Events.sfx.emit("select")
				_rebuild()
		KEY_RIGHT, KEY_D:
			if mode == Mode.SETTINGS and entries[cursor].get("kind", "") == "vol":
				Settings.adjust(entries[cursor].arg, 1)
				Events.sfx.emit("select")
				_rebuild()
		KEY_I:
			if mode == Mode.INVENTORY:
				close()
		KEY_UP, KEY_W:
			cursor = maxi(cursor - 1, 0)
			Events.sfx.emit("select")
		KEY_DOWN, KEY_S:
			cursor = mini(cursor + 1, maxi(entries.size() - 1, 0))
			Events.sfx.emit("select")
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_confirm()
	queue_redraw()


func _confirm() -> void:
	if mode == Mode.ENDING:
		close()
	elif mode == Mode.HELP:
		back()
	elif mode == Mode.DIALOG and page < pages.size() - 1:
		page += 1
		body = pages[page]
		_rebuild()
	elif entries.size() > 0 and mode in [Mode.SHOP, Mode.DIALOG, Mode.COOK, Mode.INVENTORY, Mode.PAUSE, Mode.SETTINGS, Mode.SHRINE]:
		_activate(entries[cursor])


func _activate(e: Dictionary) -> void:
	match e.get("kind", ""):
		"seed":
			var price := Data.seed_price(e.arg)
			if Inventory.spend(price):
				Inventory.add(Inventory.seed_id(e.arg))
				Events.sfx.emit("coin")
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
		"buy":
			var price := int(Data.items[e.arg].buy)
			if Inventory.spend(price):
				Inventory.add(e.arg)
				note = "Membeli %s (-%dG)." % [Data.item_name(e.arg), price]
			else:
				note = "Uang tidak cukup."
		"cook":
			var r: Dictionary = Data.recipes[e.arg]
			var ok := true
			for iid in r.ingredients:
				if Inventory.count(iid) < int(r.ingredients[iid]):
					ok = false
			if not ok:
				note = "Bahan tidak cukup untuk %s." % r.name
			else:
				for iid in r.ingredients:
					Inventory.remove(iid, int(r.ingredients[iid]))
				Inventory.add("dish:" + e.arg)
				Events.sfx.emit("cook")
				Progress.bump("dishes")
				note = "Kamu memasak %s! Makan lewat Inventori (I)." % r.name
		"eat":
			var player := get_tree().get_first_node_in_group("player") as Player
			var gain := float(Data.recipes[str(e.arg).substr(5)].stamina)
			if Inventory.remove(e.arg):
				player.stamina = minf(Player.STAMINA_MAX, player.stamina + gain)
				note = "Kamu makan %s. Stamina %d." % [Data.item_name(e.arg), int(player.stamina)]
		"upgrade":
			if Inventory.upgrade(e.arg):
				note = "%s ditingkatkan ke %s!" % [Inventory.TOOL_LABELS[e.arg], Inventory.LEVEL_NAMES[Inventory.tool_level(e.arg)]]
			elif not Inventory.has_upgrade_ore(e.arg):
				note = "Bijih tidak cukup."
			else:
				note = "Uang tidak cukup."
		"talk":
			var npcs := get_tree().get_first_node_in_group("npcs") as Npcs
			pages = npcs.talk(npc_id)
			page = 0
			body = pages[0]
		"offer":
			body = Progress.offer(e.arg)
			note = ""
		"gift":
			var npcs := get_tree().get_first_node_in_group("npcs") as Npcs
			pages = []
			body = npcs.gift(npc_id, e.arg)
		"close":
			close()
			return
		"resume":
			close()
			return
		"save":
			note = "Game disimpan." if SaveSystem.save_game() else "Gagal menyimpan."
		"settings":
			open(Mode.SETTINGS)
			return_to = Mode.PAUSE
			return
		"help":
			open(Mode.HELP)
			return_to = Mode.PAUSE
			return
		"title":
			SaveSystem.save_game()
			close()
			get_tree().change_scene_to_file("res://scenes/title.tscn")
			return
		"quit":
			get_tree().quit()
			return
		"vol":
			pass
		"fullscreen":
			Settings.toggle_fullscreen()
		"back":
			back()
			return
	_rebuild()


func _draw() -> void:
	if mode == Mode.NONE:
		return
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.5))
	draw_rect(PANEL, Color(0.15, 0.12, 0.1))
	draw_rect(PANEL, Color(0.9, 0.8, 0.5), false, 2.0)
	var title := "Toko"
	match mode:
		Mode.INVENTORY: title = "Inventori"
		Mode.ENDING: title = "Dua Tahun Berlalu"
		Mode.COOK: title = "Dapur"
		Mode.SHRINE: title = "Dewi Panen"
		Mode.PAUSE: title = "Jeda"
		Mode.SETTINGS: title = "Pengaturan"
		Mode.HELP: title = "Bantuan"
		Mode.DIALOG:
			var npcs := get_tree().get_first_node_in_group("npcs") as Npcs
			title = "%s   (hati %d/10)" % [npcs.npc_name(npc_id), npcs.hearts(npc_id)]
	if mode in [Mode.SHOP, Mode.INVENTORY]:
		title += "   (Uang: %dG)" % Inventory.gold
	draw_string(font, PANEL.position + Vector2(20, 34), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 0.9, 0.5))

	var y := PANEL.position.y + 70
	if body != "":
		var body_size := 17 if mode != Mode.ENDING else 16
		draw_multiline_string(font, Vector2(PANEL.position.x + 24, y), body, HORIZONTAL_ALIGNMENT_LEFT,
			PANEL.size.x - 48, body_size, -1, Color.WHITE)
		y += BODY_H if mode in [Mode.DIALOG, Mode.SHRINE] else (40.0 if mode == Mode.COOK else 0.0)
		if mode == Mode.DIALOG and page < pages.size() - 1:
			draw_string(font, Vector2(PANEL.position.x + 24, y), "(Enter untuk lanjut)", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.8, 1))
	if mode != Mode.ENDING:
		var selectable := mode in [Mode.SHOP, Mode.DIALOG, Mode.COOK, Mode.INVENTORY, Mode.PAUSE, Mode.SETTINGS, Mode.SHRINE]
		for i in entries.size():
			var selected := selectable and i == cursor
			if selected:
				draw_rect(Rect2(PANEL.position.x + 10, y - 18, PANEL.size.x - 20, 26), Color(0.4, 0.3, 0.15))
			draw_string(font, Vector2(PANEL.position.x + 24, y), entries[i].label,
				HORIZONTAL_ALIGNMENT_LEFT, PANEL.size.x - 48, 16,
				Color.WHITE if selected or not selectable else Color(0.85, 0.85, 0.85))
			y += 28 if mode == Mode.DIALOG else 30
	var hint := "W/S pilih, Enter beli, Esc tutup"
	match mode:
		Mode.INVENTORY: hint = "W/S pilih, Enter makan masakan, Esc / I tutup"
		Mode.COOK: hint = "W/S pilih, Enter masak, Esc tutup"
		Mode.SHRINE: hint = "W/S pilih, Enter persembahkan, Esc tutup"
		Mode.PAUSE: hint = "W/S pilih, Enter pilih, Esc lanjut"
		Mode.SETTINGS: hint = "W/S pilih, A/D atur volume, Enter ubah, Esc kembali"
		Mode.HELP: hint = "Enter / Esc kembali"
		Mode.DIALOG: hint = "W/S pilih, Enter pilih, Esc tutup"
		Mode.ENDING: hint = "Enter untuk terus bermain"
	draw_string(font, PANEL.position + Vector2(20, PANEL.size.y - 40), note, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.7, 1, 0.7))
	draw_string(font, PANEL.position + Vector2(20, PANEL.size.y - 16), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.7, 0.8, 1))
