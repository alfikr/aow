extends Node
## Uji asap headless:
##   godot --headless --path . res://tests/smoke.tscn

var failures := 0


func check(cond: bool, label: String) -> void:
	if cond:
		print("  ok   ", label)
	else:
		failures += 1
		print("  FAIL ", label)


func _ready() -> void:
	SaveSystem.path = "user://smoke.json"
	SaveSystem.delete_save()
	Inventory.reset()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	var player: Player = main.get_node("Player")
	var farm: Farm = main.get_node("Farm")
	Clock.paused = true

	player.cell = Vector2i(12, 12)
	player.facing = Vector2i(0, -1)
	var c := player.front()

	player.tool = Player.Tool.HOE
	player.use_tool()
	check(farm.has_tile(c), "cangkul membuat tile")

	player.tool = Player.Tool.SEED
	player.selected_crop = 0
	player.use_tool()
	check(farm.crop_at(c) == "lobak", "menanam lobak")
	check(Inventory.count("seed:lobak") == 4, "benih berkurang")

	for i in 4:
		farm.water(c)
		Clock.end_day(false)
	check(farm.is_ripe(c), "lobak matang setelah 4 hari disiram")

	player.cell = Vector2i(12, 12)  # tidur memindahkan pemain ke pintu rumah
	player.facing = Vector2i(0, -1)
	player.interact()
	check(Inventory.count("crop:lobak") == 1, "panen masuk inventori")

	player.cell = Vector2i(8, 3)
	player.facing = Vector2i(0, -1)
	player.interact()
	check(Inventory.count("crop:lobak") == 0 and Inventory.bin.get("crop:lobak", 0) == 1, "hasil panen masuk kotak kirim")

	var gold_before := Inventory.gold
	Clock.end_day(false)
	check(Inventory.gold == gold_before + 60, "dibayar 60G saat tidur")

	await get_tree().process_frame
	var saved_gold := Inventory.gold
	var saved_day := Clock.day
	check(SaveSystem.save_game(), "simpan game")
	Inventory.gold = 0
	Clock.day = 1
	farm.tiles.clear()
	check(SaveSystem.load_game(), "muat game")
	check(Inventory.gold == saved_gold and Clock.day == saved_day, "uang & tanggal pulih")
	check(farm.has_tile(c), "ladang pulih")

	farm.tiles[c].crop = "kentang"
	Clock.season = 0
	Clock.day = Clock.DAYS_PER_SEASON
	Clock.end_day(false)
	check(Clock.season == 1 and farm.crop_at(c) == "", "tanaman musim semi layu saat musim panas")


	# --- tahap 2: tanaman berulang
	Clock.season = 1
	Clock.day = 3
	var c2 := Vector2i(13, 11)
	farm.till(c2)
	farm.plant(c2, "tomat")
	for i in 8:
		farm.water(c2)
		Clock.end_day(false)
	check(farm.is_ripe(c2), "tomat matang setelah 8 hari")
	check(farm.harvest(c2) == "tomat", "panen tomat")
	check(farm.crop_at(c2) == "tomat" and not farm.is_ripe(c2), "tomat tetap tumbuh setelah panen")
	for i in 3:
		farm.water(c2)
		Clock.end_day(false)
	check(farm.is_ripe(c2), "tomat berbuah lagi dalam 3 hari")

	# --- tahap 2: upgrade alat
	Inventory.gold = 600
	check(Inventory.upgrade("water") and Inventory.water_max() == 40, "upgrade penyiram -> kapasitas 40")
	check(Inventory.gold == 100, "biaya upgrade 500G terpotong")
	check(not Inventory.upgrade("water"), "upgrade perak gagal bila uang kurang")
	check(is_equal_approx(Inventory.stamina_mult("water"), 0.75), "stamina lebih hemat")

	# --- tahap 2: festival
	Clock.season = 0
	Clock.day = 8
	check(Clock.festival().get("name", "") == "Festival Bunga", "festival hari 8 musim semi")
	Inventory.bin = {"crop:lobak": 1}
	var g := Inventory.gold
	Clock.end_day(false)
	check(Inventory.gold == g + 75, "bonus festival +25% (60 -> 75)")

	# --- tahap 2: menu toko
	var menu: Control = main.get_node("UI/Menu")
	Inventory.gold = 100
	menu.open(menu.Mode.SHOP)
	check(Events.menu_open and Clock.paused, "menu toko membekukan game")
	menu._activate(menu.entries[0])  # benih lobak 20G
	check(Inventory.gold == 80, "beli benih dari menu")
	menu.close()
	check(not Events.menu_open, "menu ditutup")


	# --- tahap 3: dunia & perpindahan area
	var world: World = main.get_node("World")
	Clock.minutes = 10.0 * 60
	player.cell = Vector2i(28, 9)
	player.try_move(Vector2i.RIGHT)
	check(world.area_id == "village" and player.cell == Vector2i(1, 9), "keluar peternakan -> desa")
	check(not farm.visible, "ladang disembunyikan di luar peternakan")

	player.tool = Player.Tool.HOE
	player.facing = Vector2i.RIGHT
	player.use_tool()
	check(not farm.has_tile(player.front()), "cangkul tidak berfungsi di desa")

	player.cell = Vector2i(6, 8)
	Clock.minutes = 7.0 * 60
	player.try_move(Vector2i.UP)
	check(world.area_id == "village" and player.cell == Vector2i(6, 8), "toko tutup jam 07:00")
	check(world.closed_reason(Vector2i(6, 7)).contains("tutup"), "pesan toko tutup")
	Clock.minutes = 10.0 * 60
	player.try_move(Vector2i.UP)
	check(world.area_id == "shop" and player.cell == Vector2i(14, 11), "toko buka jam 10:00 -> masuk interior")
	check(not world.walkable(Vector2i(7, 7)), "dinding interior tidak bisa dilewati")

	player.cell = Vector2i(14, 6)
	player.facing = Vector2i.UP
	player.interact()
	check(Events.menu_open, "konter toko membuka menu")
	menu.close()

	player.cell = Vector2i(14, 11)
	player.try_move(Vector2i.DOWN)
	check(world.area_id == "village" and player.cell == Vector2i(6, 8), "keluar toko -> desa")

	SaveSystem.save_game()
	world.set_area("farm")
	SaveSystem.load_game()
	check(world.area_id == "village", "area tersimpan & dimuat")

	Clock.end_day(false)
	check(world.area_id == "farm" and player.cell == Player.SPAWN and farm.visible, "tidur -> bangun di rumah (peternakan)")


	# --- tahap 4: hewan
	var ls: Livestock = main.get_node("Livestock")
	var dog: Dog = main.get_node("Dog")
	Clock.season = 1
	Clock.day = 1
	Inventory.gold = 5000
	menu.open(menu.Mode.SHOP)
	var feed_entry: Dictionary = {}
	var chick_entry: Dictionary = {}
	for e in menu.entries:
		if e.get("kind", "") == "feed":
			feed_entry = e
		if e.get("kind", "") == "animal" and e.arg == "ayam":
			chick_entry = e
	menu._activate(feed_entry)
	check(Inventory.count("feed") == 1 and Inventory.gold == 4990, "beli pakan dari toko")
	menu._activate(chick_entry)
	check(ls.count_of("ayam") == 1 and Inventory.gold == 4690, "beli ayam dari toko")
	menu.close()
	for i in 3:
		ls.add_animal("ayam")
	check(ls.count_of("ayam") == 4 and not ls.can_add("ayam"), "kandang ayam penuh di 4 ekor")
	ls.animals.resize(1)

	player.travel("farm", [2, 10])
	player.try_move(Vector2i.UP)
	check(world.area_id == "coop" and player.cell == Vector2i(14, 11), "masuk kandang ayam")
	check(ls.animal_at("coop", Vector2i(12, 7)) == 0, "ayam berada di slot rumahnya")

	ls.animals[0].cell = Vector2i(12, 7)
	player.cell = Vector2i(12, 8)
	player.facing = Vector2i.UP
	player.interact()
	check(ls.animals[0].fed and Inventory.count("feed") == 0, "memberi pakan ayam")
	check(not player.walkable(Vector2i(12, 7)), "hewan menghalangi jalan")

	Clock.end_day(false)
	check(ls.animals[0].product and ls.animals[0].affection == 4, "ayam yang diberi pakan menghasilkan telur")
	player.travel("coop", [14, 11])
	ls.animals[0].cell = Vector2i(12, 7)
	player.cell = Vector2i(12, 8)
	player.facing = Vector2i.UP
	player.interact()
	check(Inventory.count("prod:telur") == 1 and not ls.animals[0].product, "mengambil telur")

	Clock.end_day(false)
	check(not ls.animals[0].product and ls.animals[0].affection == 1, "tanpa pakan: tak ada telur, kasih sayang turun")

	player.travel("farm", [8, 3])
	player.facing = Vector2i.UP
	player.interact()
	check(Inventory.bin.get("prod:telur", 0) == 1, "telur masuk kotak kirim")
	g = Inventory.gold
	Clock.end_day(false)
	check(Inventory.gold == g + 30, "telur dibayar 30G")

	ls.add_animal("sapi")
	check(ls.count_of("sapi") == 1 and ls.animal_at("barn", Vector2i(13, 7)) >= 0, "sapi masuk kandang sapi")

	SaveSystem.save_game()
	ls.animals.clear()
	SaveSystem.load_game()
	check(ls.count_of("ayam") == 1 and ls.count_of("sapi") == 1, "hewan tersimpan & dimuat")

	# --- tahap 4: anjing
	world.set_area("farm")
	player.cell = Vector2i(5, 5)
	dog._process(0.01)
	check(dog.cell == player.cell, "anjing muncul di dekat pemain saat ganti area")
	var steps := [Vector2i(6, 5), Vector2i(7, 5), Vector2i(8, 5), Vector2i(9, 5)]
	for st in steps:
		player.cell = st
		dog._process(0.01)
	check(dog.cell == Vector2i(6, 5), "anjing mengikuti 3 langkah di belakang")
	player.facing = Vector2i.LEFT
	player.cell = dog.cell + Vector2i.RIGHT
	var af := dog.affection
	player.interact()
	check(dog.affection == af + 3, "mengelus anjing")


	# --- tahap 5: NPC
	var npcs: Npcs = main.get_node("Npcs")
	check(npcs.schedule_target("mira", 10 * 60, 2, false) == {"area": "shop", "cell": Vector2i(14, 4)}, "Mira di toko jam 10:00")
	check(npcs.schedule_target("mira", 7 * 60, 2, false).area == "village", "Mira di desa jam 07:00")
	check(npcs.schedule_target("mira", 7 * 60, 2, true).area == "shop", "Mira di toko saat hujan")
	check(npcs.schedule_target("sari", 12 * 60, 6, false).area == "village", "Sari keluar penginapan hari Minggu")
	check(npcs.schedule_target("sari", 12 * 60, 1, false).area == "inn", "Sari di penginapan hari kerja")
	check(npcs.schedule_target("dodi", 12 * 60, 2, false).area == "hall", "Pak Dodi di balai hari kerja")
	check(npcs.schedule_target("dodi", 12 * 60, 6, false).area == "village", "Pak Dodi di desa akhir pekan")

	Clock.minutes = 10.0 * 60
	npcs.snap_all()
	Clock.weather = Clock.Weather.SUNNY
	var wd := Clock.weekday()
	var expected = npcs.schedule_target("mira", Clock.minutes, wd, false)
	check(npcs.npc_at(expected.area, expected.cell) == "mira", "Mira berada di lokasi jadwalnya")

	npcs.state["mira"].friend = 0
	npcs.state["mira"].talked = false
	npcs.state["mira"].gifted = false
	var pages := npcs.talk("mira")
	check(pages.size() == 1 and npcs.state["mira"].friend == 10, "bicara pertama +10 kasih sayang")
	npcs.talk("mira")
	check(npcs.state["mira"].friend == 10, "bicara lagi di hari sama tidak menambah")

	Clock.season = 1
	Clock.day = 1
	Inventory.add("crop:tomat")
	var msg := npcs.gift("mira", "crop:tomat")
	check(npcs.state["mira"].friend == 90 and Inventory.count("crop:tomat") == 0, "hadiah favorit +80")
	Inventory.add("crop:lobak")
	check(npcs.gift("mira", "crop:lobak").contains("sudah menerima"), "satu hadiah per hari")

	npcs.state["raka"].friend = 0
	Inventory.add("crop:jagung")
	npcs.gift("raka", "crop:jagung")
	check(npcs.state["raka"].friend == 80, "Raka suka jagung")
	npcs.state["lila"].friend = 100
	Inventory.add("stone")
	npcs.gift("lila", "stone")
	check(npcs.state["lila"].friend == 60, "hadiah yang dibenci -40")

	npcs.state["mira"].friend = 200
	var ev_pages := npcs.talk("mira")
	check(ev_pages.size() == 2 and npcs.state["mira"].seen.has("mira_2"), "event 2 hati terpicu")
	npcs.state["mira"].talked = false
	check(npcs.talk("mira").size() == 1, "event hanya sekali")

	npcs.state["mira"].friend = 400
	npcs.talk("mira")
	check(Progress.knows_recipe("salad_tomat"), "event 4 hati memberi resep")
	npcs.state["dodi"].friend = 200
	g = Inventory.gold
	npcs.talk("dodi")
	check(Inventory.gold == g + 200, "event Pak Dodi memberi 200G")

	# lamaran
	Inventory.add("gift:bulu_biru")
	npcs.state["mira"].friend = 700
	check(npcs.gift("mira", "gift:bulu_biru").contains("belum"), "lamaran ditolak sebelum 8 hati")
	check(Inventory.count("gift:bulu_biru") == 1, "Bulu Biru tidak terpakai saat ditolak")
	check(npcs.gift("raka", "gift:bulu_biru").contains("istimewa"), "NPC non-romantis menolak")
	npcs.state["mira"].friend = 800
	npcs.gift("mira", "gift:bulu_biru")
	check(Progress.fiance == "mira", "lamaran diterima")
	Clock.end_day(false)
	check(Progress.spouse == "mira" and Progress.fiance == "", "menikah keesokan hari")
	check(npcs.schedule_target("mira", 12 * 60, 1, false).area == "farm", "pasangan membantu di peternakan siang hari")
	check(npcs.schedule_target("mira", 7 * 60, 1, false).area == "home", "pasangan di rumah pagi hari")

	for i in 30:
		Clock.end_day(false)
	check(Progress.child, "anak lahir 30 hari setelah menikah")

	SaveSystem.save_game()
	npcs.state["mira"].friend = 0
	Progress.spouse = ""
	SaveSystem.load_game()
	check(npcs.state["mira"].friend >= 800 and Progress.spouse == "mira", "hubungan & pernikahan tersimpan")


	# jalur NPC
	world.set_area("village")
	player.cell = Vector2i(20, 9)
	npcs.where["mira"] = {"area": "village", "cell": Vector2i(3, 9)}
	npcs.goal["mira"] = {"area": "village", "cell": Vector2i(6, 9)}
	for i in 3:
		npcs._advance("mira")
	check(npcs.where["mira"].cell == Vector2i(6, 9), "NPC berjalan 3 langkah ke tujuan")
	npcs.where["mira"] = {"area": "village", "cell": Vector2i(3, 9)}
	npcs.goal["mira"] = {"area": "village", "cell": Vector2i(7, 9)}
	npcs._advance("mira")
	check(npcs.where["mira"].cell == Vector2i(4, 9), "NPC melangkah satu tile per giliran")
	npcs.snap_all()

	# dialog lewat menu
	Inventory.add("crop:lobak")
	menu.open_dialog("raka")
	check(Events.menu_open and menu.mode == menu.Mode.DIALOG, "dialog NPC terbuka")
	var kinds: Array = menu.entries.map(func(e): return e.kind)
	check(kinds.has("talk") and kinds.has("gift") and kinds.has("close"), "menu dialog punya Bicara/Hadiah/Selesai")
	menu._activate(menu.entries[0])
	check(menu.body.begins_with("Raka"), "dialog menampilkan ucapan NPC")
	menu.close()

	SaveSystem.delete_save()
	print("HASIL: ", "LULUS" if failures == 0 else "GAGAL (%d)" % failures)
	get_tree().quit(failures)
