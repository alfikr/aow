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
	farm.rocks.clear()   # tes lain memakai petak ladang bebas; batu diuji terpisah di bawah
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
	check(not Inventory.upgrade("water"), "upgrade butuh bijih tembaga")
	Inventory.add("ore:tembaga", 5)
	check(Inventory.upgrade("water") and Inventory.water_max() == 40, "upgrade penyiram -> kapasitas 40")
	check(Inventory.gold == 100 and Inventory.count("ore:tembaga") == 0, "biaya upgrade 500G + 5 bijih terpotong")
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

	player.cell = Vector2i(3, 8)
	Clock.minutes = 7.0 * 60
	player.try_move(Vector2i.UP)
	check(world.area_id == "village" and player.cell == Vector2i(3, 8), "toko tutup jam 07:00")
	check(world.closed_reason(Vector2i(3, 7)).contains("tutup"), "pesan toko tutup")
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
	check(world.area_id == "village" and player.cell == Vector2i(3, 8), "keluar toko -> desa")

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
	Clock.weather = Clock.Weather.SUNNY   # harus sebelum snap_all: cuaca acak mengubah jadwal
	npcs.snap_all()
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


	# --- rumah warga yang berbeda-beda & penginapan/kandang
	player.travel("village", [14, 14])
	player.cell = Vector2i(14, 14)
	player.try_move(Vector2i.DOWN)
	check(world.area_id == "lane" and player.cell == Vector2i(14, 1), "desa -> permukiman")
	var homes := {"raka": "house_raka", "lila": "house_lila", "dodi": "house_dodi"}
	var door_cells := {"house_raka": Vector2i(3, 7), "house_lila": Vector2i(9, 7), "house_dodi": Vector2i(19, 7)}
	for hid in door_cells:
		player.travel("lane", [door_cells[hid].x, 8])
		player.cell = Vector2i(door_cells[hid].x, 8)
		player.try_move(Vector2i.UP)
		check(world.area_id == hid, "pintu rumah menuju %s" % hid)
		player.cell = Vector2i(14, 11)
		player.try_move(Vector2i.DOWN)
		check(world.area_id == "lane" and player.cell.y == 8, "keluar %s ke permukiman" % hid)
	var own_area := {}
	for nid in homes:
		for e in Data.npcs[nid].schedule:
			if e.area.begins_with("house"):
				own_area[nid] = e.area
	check(own_area == homes, "Raka, Lila, dan Dodi masing-masing punya rumah sendiri")
	check(not Data.areas.has("house"), "tidak ada lagi satu rumah warga bersama")

	player.travel("village", [10, 8])
	player.cell = Vector2i(10, 8)
	player.try_move(Vector2i.UP)
	check(world.area_id == "inn" and player.cell == Vector2i(14, 11), "penginapan di deretan utara desa")
	player.cell = Vector2i(14, 11)
	player.try_move(Vector2i.DOWN)
	check(world.area_id == "village" and player.cell == Vector2i(10, 8), "keluar penginapan -> desa")

	player.travel("farm", [3, 15])
	player.cell = Vector2i(3, 15)
	player.try_move(Vector2i.UP)
	check(world.area_id == "barn", "pintu ganda lumbung sapi (tile 3)")
	player.travel("farm", [4, 15])
	player.cell = Vector2i(4, 15)
	player.try_move(Vector2i.UP)
	check(world.area_id == "barn", "pintu ganda lumbung sapi (tile 4)")


	# --- sprite karakter & hewan
	check(Sprites.char_row(Vector2i.DOWN) == 0 and Sprites.char_row(Vector2i.LEFT) == 1
		and Sprites.char_row(Vector2i.RIGHT) == 2 and Sprites.char_row(Vector2i.UP) == 3, "baris sprite sesuai arah hadap")
	for sheet in ["char_player", "char_mira", "char_sari", "char_raka", "char_dodi", "char_lila"]:
		var t := Sprites.tex(sheet)
		check(t != null and t.get_size() == Vector2(96, 192), "sprite %s 3x4 sel 32x48" % sheet)
	for sheet in Sprites.ANIMAL_CELLS:
		var t := Sprites.tex(sheet)
		check(t != null and t.get_height() == Sprites.ANIMAL_CELLS[sheet].y * 2, "sprite hewan %s dua baris" % sheet)
	for nid in Data.npcs:
		check(Sprites.tex("char_" + nid) != null, "NPC %s punya sprite" % nid)
	check(Sprites.walk_frame(false) == 0 and Sprites.walk_frame(true) in [1, 2], "bingkai jalan 1/2 saat bergerak")

	world.set_area("village")
	player.cell = Vector2i(20, 9)
	npcs.where["raka"] = {"area": "village", "cell": Vector2i(5, 9)}
	npcs.vis.erase("raka")
	npcs._animate(0.0)
	npcs.where["raka"] = {"area": "village", "cell": Vector2i(6, 9)}
	npcs._animate(0.1)
	check(npcs.vis["raka"].facing == Vector2i.RIGHT and npcs.vis["raka"].moving, "NPC menghadap arah jalan & beranimasi")
	for i in 10:
		npcs._animate(0.1)
	check(not npcs.vis["raka"].moving and npcs.vis["raka"].pos == Vector2(6 * 32, 9 * 32), "NPC berhenti di tile tujuan")
	npcs.face_towards("raka", Vector2i(6, 8))
	check(npcs.vis["raka"].facing == Vector2i.UP, "NPC menoleh ke pemain saat diajak bicara")
	npcs.snap_all()

	player.travel("coop", [14, 11])
	ls.animals.clear()
	ls.add_animal("ayam")
	var hen: Dictionary = ls.animals[0]
	ls.wander_t = -1000.0   # matikan gerak acak agar tes deterministik
	hen.cell = hen.cell + Vector2i.RIGHT
	ls._process(0.1)
	check(hen.moving and hen.right, "ayam berjalan ke kanan menghadap kanan")
	for i in 40:
		ls._process(0.1)
	check(not hen.moving and hen.pos == Vector2(hen.cell * 32), "ayam berhenti di tile tujuan")
	hen.peck_t = 0.0
	hen.idle_t = hen.next_peck
	ls._process(0.1)
	check(hen.peck_t > 0.0 and ls._frame_of(hen, "chicken") == 2, "ayam mematuk saat diam")
	check(ls._frame_of({"moving": false, "peck_t": 0.3}, "cow") == 3, "sapi merumput (bingkai 3)")
	ls.wander_t = 0.0

	player.travel("farm", [4, 4])
	player.cell = Vector2i(4, 4)
	dog._process(0.1)
	dog.snap = false
	dog.cell = Vector2i(5, 4)
	dog.face_right = false
	dog.trail = [Vector2i(6, 4), Vector2i(7, 4)]
	dog.last_player_cell = Vector2i(8, 4)
	player.cell = Vector2i(9, 4)
	dog._process(0.1)
	check(dog.cell == Vector2i(6, 4) and dog.face_right, "anjing menghadap kanan saat bergerak ke kanan")
	dog.trail = [Vector2i(3, 4), Vector2i(2, 4)]
	dog.last_player_cell = Vector2i(1, 4)
	player.cell = Vector2i(0, 4)
	dog._process(0.1)
	check(dog.cell == Vector2i(3, 4) and not dog.face_right, "anjing menghadap kiri saat bergerak ke kiri")


	# --- dekorasi dunia
	world.set_area("farm")
	var fence_c := Vector2i(12, 2)
	check(not world.walkable(fence_c) and world.feature_at(fence_c).kind == "fence", "pagar ladang menghalangi")
	check(not world.walkable(Vector2i(12, 1)), "pohon menghalangi")
	check(world.walkable(Vector2i(6, 3)) and world.feature_at(Vector2i(6, 3)).is_empty(), "bunga (overlay) tidak menghalangi")
	check(world.feature_at(Vector2i(27, 3)).get("kind", "") == "water", "daun teratai (overlay) tidak menutupi air untuk memancing")
	var tall := world.draw_list.filter(func(f): return f.raw.get("overhead", false))
	check(tall.size() > 8, "ada benda tinggi berlapis atas (%d)" % tall.size())
	check(world.light_points().size() == 2, "dua tiang lampu bercahaya di peternakan")
	var order_ok := true
	var last_y := -1
	for f in world.draw_list:
		if not world._is_flat(f):
			if f.rect.end.y < last_y:
				order_ok = false
			last_y = f.rect.end.y
	check(order_ok, "benda tinggi digambar urut dari atas ke bawah")
	world.set_area("beach")
	check(world.walkable(Vector2i(16, 8)) and not world.walkable(Vector2i(16, 7)), "dermaga bisa dilewati di atas air")
	check(world.feature_at(Vector2i(20, 8)).get("raw", {}).get("fish", "") == "beach", "air di ujung dermaga bisa dipancing")
	world.set_area("village")
	check(world.feature_at(Vector2i(23, 3)).get("kind", "") == "water" and not world.feature_at(Vector2i(23, 3)).raw.has("fish"), "air mancur bisa diisi tapi tidak bisa dipancing")
	check(farm.growth_stage("lobak", 0) == 0 and farm.growth_stage("lobak", 2) == 1 and farm.growth_stage("lobak", 3) == 2 and farm.growth_stage("lobak", 4) == 3, "tahap tumbuh tanaman 0-3")
	world.set_area("farm")


	# --- musim & cuaca visual
	Clock.season = 0
	check(Sprites.tex_season("grass").resource_path.ends_with("/grass.png"), "musim semi memakai tekstur dasar")
	for sidx in [1, 2, 3]:
		Clock.season = sidx
		for nm in Sprites.SEASONAL:
			var tv := Sprites.tex_season(nm)
			check(tv != null and tv.resource_path.ends_with("_%s.png" % Sprites.SEASON_KEYS[sidx]), "variasi %s musim %d" % [nm, sidx]) if nm in ["grass", "tree_oak", "water"] else null
		check(Sprites.tex_season("bin").resource_path.ends_with("/bin.png"), "sprite non-musiman tidak berubah di musim %d" % sidx)
	Clock.season = 1
	check(WeatherFx.kind_for(false, Clock.Weather.RAINY, 1, 600.0) == "rain", "hujan -> partikel hujan")
	check(WeatherFx.kind_for(false, Clock.Weather.SNOW, 3, 600.0) == "snow", "salju -> partikel salju")
	check(WeatherFx.kind_for(false, Clock.Weather.SUNNY, 0, 600.0) == "petals", "cerah musim semi -> kelopak")
	check(WeatherFx.kind_for(false, Clock.Weather.SUNNY, 2, 600.0) == "leaves", "cerah musim gugur -> daun gugur")
	check(WeatherFx.kind_for(false, Clock.Weather.SUNNY, 1, 600.0) == "" and WeatherFx.kind_for(false, Clock.Weather.SUNNY, 1, 20 * 60.0) == "fireflies", "kunang-kunang hanya malam musim panas")
	check(WeatherFx.kind_for(false, Clock.Weather.SUNNY, 3, 600.0) == "", "cerah musim dingin tanpa partikel")
	check(WeatherFx.kind_for(true, Clock.Weather.RAINY, 1, 600.0) == "", "tidak ada cuaca di dalam ruangan")

	var wfx: WeatherFx = main.get_node("Weather")
	world.set_area("farm")
	Clock.weather = Clock.Weather.RAINY
	wfx._process(0.1)
	check(wfx.kind == "rain" and wfx.parts.size() == WeatherFx.COUNTS["rain"], "node cuaca membuat 150 tetes hujan")
	for i in 30:
		wfx._process(0.1)
	check(wfx.parts.size() == WeatherFx.COUNTS["rain"] and wfx.parts.all(func(p): return p.pos.y < 600.0), "tetes hujan didaur ulang (tidak lepas layar)")
	world.set_area("shop")
	wfx._process(0.1)
	check(wfx.kind == "" and wfx.parts.is_empty(), "partikel hilang saat masuk ruangan")
	check(Audio.choose_ambient() == "", "tanpa suara hujan di dalam ruangan")
	world.set_area("farm")
	check(Audio.choose_ambient() == "ambient_rain" and ResourceLoader.exists("res://assets/audio/ambient_rain.wav"), "suara hujan di luar ruangan saat hujan")
	Clock.weather = Clock.Weather.SUNNY
	check(Audio.choose_ambient() == "", "tanpa suara hujan saat cerah")
	var winter_decor := 0
	var summer_decor := 0
	for f in Data.areas["village"].features:
		if int(f.get("season", -1)) == 3:
			winter_decor += 1
		if int(f.get("season", -1)) == 1:
			summer_decor += 1
	check(winter_decor > 0 and summer_decor > 0, "desa punya hiasan musim dingin & panas")
	Clock.season = 0

	# dialog lewat menu
	Inventory.add("crop:lobak")
	menu.open_dialog("raka")
	check(Events.menu_open and menu.mode == menu.Mode.DIALOG, "dialog NPC terbuka")
	var kinds: Array = menu.entries.map(func(e): return e.kind)
	check(kinds.has("talk") and kinds.has("gift") and kinds.has("close"), "menu dialog punya Bicara/Hadiah/Selesai")
	menu._activate(menu.entries[0])
	check(menu.body.begins_with("Raka"), "dialog menampilkan ucapan NPC")
	menu.close()


	# --- tahap 6: memancing
	var fishing: Fishing = main.get_node("Fishing")
	var mine: Mine = main.get_node("Mine")
	var got := [""]
	Events.message.connect(func(t: String): got[0] = t)
	check(fishing.candidates("pond", 3) == ["ikan_mas"], "kolam musim dingin hanya ikan mas")
	check(fishing.candidates("beach", 3).has("salmon") and not fishing.candidates("beach", 0).has("salmon"), "salmon hanya musim gugur/dingin")
	Clock.season = 1
	Clock.day = 1
	player.travel("farm", [26, 3])
	player.cell = Vector2i(26, 3)
	player.facing = Vector2i.RIGHT
	player.tool = Player.Tool.FISH
	player.stamina = 50.0
	player.use_tool()
	check(fishing.state == Fishing.State.WAIT and player.stamina == 47.0, "melempar kail memakai stamina")
	fishing.state = Fishing.State.BITE
	player.use_tool()
	var fish_count := 0
	for id in Inventory.items:
		if str(id).begins_with("fish:"):
			fish_count += Inventory.items[id]
	check(fishing.state == Fishing.State.IDLE and fish_count == 1 and Progress.stats.fish == 1, "menangkap ikan saat menggigit")
	player.use_tool()
	player.use_tool()
	check(fishing.state == Fishing.State.IDLE and Progress.stats.fish == 1, "menarik terlalu cepat gagal")
	player.travel("village", [14, 11])
	player.cell = Vector2i(14, 11)
	player.facing = Vector2i.DOWN
	player.use_tool()
	check(fishing.state == Fishing.State.IDLE and got[0].contains("Tidak ada ikan"), "air mancur tidak bisa dipancing")

	# --- tahap 6: tambang
	player.travel("village", [20, 2])
	player.cell = Vector2i(20, 2)
	player.try_move(Vector2i.UP)
	check(world.area_id == "mine" and mine.floor_n == 1 and player.cell == Vector2i(14, 12), "masuk tambang lantai 1")
	var rocks: Array = world.features.filter(func(f): return f.kind == "rock")
	check(rocks.size() > 20, "tambang berisi batu (%d)" % rocks.size())
	var n1 := rocks.size()
	world.set_area("mine")
	check(world.features.filter(func(f): return f.kind == "rock").size() == n1, "tata letak lantai konsisten dalam sehari")
	var target: Dictionary = {}
	for f in rocks:
		if f.raw.get("ore", "") != "" and not f.raw.get("big", false):
			target = f
			break
	check(not target.is_empty(), "ada batu bijih di lantai 1")
	var ore_id := "ore:" + str(target.raw.ore)
	var before := Inventory.count(ore_id)
	player.stamina = 50.0
	player.cell = target.rect.position + Vector2i.DOWN
	player.facing = Vector2i.UP
	player.tool = Player.Tool.HOE
	player.use_tool()
	check(Inventory.count(ore_id) == before + 1 and player.stamina == 47.0, "memecahkan batu bijih")
	check(world.features.filter(func(f): return f.kind == "rock").size() == n1 - 1, "batu hilang dari peta")
	world.set_area("mine")
	check(world.features.filter(func(f): return f.kind == "rock").size() == n1 - 1, "batu yang pecah tetap pecah sepanjang hari")
	check(Progress.stats.mine_floor == 1, "lantai terdalam tercatat")

	var stairs: Dictionary = {}
	for f in world.features:
		if f.kind == "exit" and f.raw.get("label", "") == "Turun":
			stairs = f
	player.cell = stairs.rect.position + Vector2i.DOWN
	player.try_move(Vector2i.UP)
	check(mine.floor_n == 2 and world.area_id == "mine", "tangga membawa ke lantai 2")
	mine.floor_n = 10
	var floor10: Dictionary = mine.generate()
	var has_down := false
	for f in floor10.features:
		if f.get("label", "") == "Turun":
			has_down = true
	check(not has_down, "lantai 10 tanpa tangga turun")
	mine.floor_n = 1
	Clock.end_day(false)
	check(world.area_id == "farm", "bangun di rumah setelah tidur di tambang")

	# --- tahap 6: memasak & makan
	check(Data.item_sell_price("dish:sup_lobak") == 150, "harga jual masakan")
	Inventory.items.erase("crop:lobak")
	Inventory.add("crop:lobak", 2)
	menu.open(menu.Mode.COOK)
	check(menu.entries.size() == Progress.recipes.size(), "dapur hanya menampilkan resep yang dikuasai")
	var cook_entry: Dictionary = {}
	for e in menu.entries:
		if e.arg == "sup_lobak":
			cook_entry = e
	menu._activate(cook_entry)
	check(Inventory.count("dish:sup_lobak") == 1 and Inventory.count("crop:lobak") == 0 and Progress.stats.dishes == 1, "memasak sup lobak")
	menu._activate(cook_entry)
	check(Inventory.count("dish:sup_lobak") == 1 and menu.note.contains("tidak cukup"), "bahan kurang menolak memasak")
	menu.close()
	player.stamina = 10.0
	menu.open(menu.Mode.INVENTORY)
	var eat_entry: Dictionary = {}
	for e in menu.entries:
		if e.get("kind", "") == "eat":
			eat_entry = e
	menu._activate(eat_entry)
	check(player.stamina == 50.0 and Inventory.count("dish:sup_lobak") == 0, "makan memulihkan stamina")
	menu.close()

	player.travel("home", [14, 11])
	player.cell = Vector2i(19, 6)
	player.facing = Vector2i.UP
	player.interact()
	check(menu.mode == menu.Mode.COOK, "dapur di rumah membuka menu masak")
	menu.close()
	Clock.forecast = Clock.Weather.RAINY
	player.cell = Vector2i(14, 5)
	player.facing = Vector2i.UP
	player.interact()
	check(got[0].contains("Hujan"), "TV menampilkan ramalan cuaca besok")
	Clock.end_day(false)
	check(Clock.weather == Clock.Weather.RAINY, "cuaca besok sesuai ramalan")

	Inventory.gold = 4000
	menu.open(menu.Mode.SHOP)
	var feather: Dictionary = {}
	for e in menu.entries:
		if e.get("kind", "") == "buy":
			feather = e
	menu._activate(feather)
	check(Inventory.count("gift:bulu_biru") == 1 and Inventory.gold == 1000, "membeli Bulu Biru 3000G")
	menu.close()

	# --- tahap 6: ending
	Progress.ending_seen = false
	Clock.year = 2
	Clock.season = 3
	Clock.day = 30
	Clock.end_day(false)
	check(Clock.year == 3 and Progress.ending_seen and menu.mode == menu.Mode.ENDING, "ending muncul setelah dua tahun")
	check(menu.body.contains("Skor") and menu.body.contains("Mira"), "ending merangkum progres")
	menu.close()



	# --- batu kecil & besar di ladang
	Progress.flags.erase("secret_open")
	farm.tiles.clear()
	farm.scatter_rocks(4242)
	var rock_kinds := {"small": 0, "big": 0, "sealed": 0}
	for r in farm.rocks:
		rock_kinds[r.kind] += 1
	check(rock_kinds.small == 12 and rock_kinds.big == 3 and rock_kinds.sealed == 1, "taburan batu: 12 kecil, 3 besar, 1 raksasa")
	var overlap := false
	var seen_cells := {}
	for r in farm.rocks:
		for x in r.size:
			for y in r.size:
				var cc: Vector2i = r.cell + Vector2i(x, y)
				if seen_cells.has(cc):
					overlap = true
				seen_cells[cc] = true
				if r.kind != "sealed" and (not Layout.FIELD.has_point(cc) or Farm.STARTER.has_point(cc)):
					overlap = true
	check(not overlap, "batu tidak bertumpuk, di dalam ladang, dan petak awal bersih")

	farm.rocks.clear()
	farm.rocks.append({"cell": Vector2i(11, 5), "size": 1, "kind": "small", "hp": 1})
	farm.rocks.append({"cell": Vector2i(14, 5), "size": 2, "kind": "big", "hp": 4})
	check(farm.blocks(Vector2i(11, 5)) and farm.blocks(Vector2i(15, 6)) and not farm.blocks(Vector2i(16, 5)), "batu menghalangi (besar = 2x2)")
	check(not farm.till(Vector2i(11, 5)), "tidak bisa mencangkul di atas batu")
	world.set_area("farm")
	player.cell = Vector2i(11, 6)
	player.facing = Vector2i.UP
	player.tool = Player.Tool.HOE
	player.stamina = 50.0
	var stone0 := Inventory.count("stone")
	player.use_tool()
	check(farm.rock_index_at(Vector2i(11, 5)) < 0 and Inventory.count("stone") > stone0 and player.stamina == 47.0, "batu kecil hancur sekali pukul + dapat batu")
	player.cell = Vector2i(14, 7)
	player.facing = Vector2i.UP
	Inventory.tool_levels["hoe"] = 0
	for i in 3:
		player.use_tool()
	check(farm.rock_index_at(Vector2i(14, 6)) >= 0, "batu besar bertahan setelah 3 pukulan (cangkul dasar)")
	player.use_tool()
	check(farm.rock_index_at(Vector2i(14, 6)) < 0, "batu besar hancur pada pukulan ke-4")
	farm.rocks.append({"cell": Vector2i(14, 5), "size": 2, "kind": "big", "hp": 4})
	Inventory.tool_levels["hoe"] = 1
	player.use_tool()
	player.use_tool()
	check(farm.rock_index_at(Vector2i(14, 6)) < 0, "cangkul tembaga: batu besar hancur dalam 2 pukulan")
	Inventory.tool_levels["hoe"] = 0
	check(farm.spawn_daily_rock(true) and farm.rocks.size() == 1, "batu kecil baru muncul tiap hari")
	farm.rocks.clear()

	# --- peta tersembunyi: Hutan Rahasia
	Progress.flags.erase("secret_open")
	farm.scatter_rocks(4242)
	var sealed_i := -1
	for i in farm.rocks.size():
		if farm.rocks[i].kind == "sealed":
			sealed_i = i
	check(sealed_i >= 0 and farm.rocks[sealed_i].cell == Vector2i(27, 5), "batu raksasa menutup jalan rahasia di timur kebun")
	check(world.exit_at(Vector2i(29, 5)).is_empty(), "pintu hutan rahasia belum aktif")
	player.cell = Vector2i(27, 7)
	player.facing = Vector2i.UP
	player.stamina = 100.0
	Inventory.tool_levels["hoe"] = 0
	player.use_tool()
	check(farm.rocks[sealed_i].hp == 4 and player.stamina == 100.0, "Cangkul Dasar tak bisa memecahkan batu raksasa (tanpa stamina)")
	Inventory.tool_levels["hoe"] = 1
	player.use_tool()
	check(farm.rocks[sealed_i].hp == 2, "Cangkul Tembaga meretakkan batu raksasa")
	player.use_tool()
	check(Progress.flag("secret_open") and farm.rock_index_at(Vector2i(27, 5)) < 0, "batu raksasa runtuh -> jalan rahasia terbuka")
	check(not world.exit_at(Vector2i(29, 5)).is_empty() and world.walkable(Vector2i(28, 5)), "pintu hutan rahasia aktif & terjangkau")
	Inventory.tool_levels["hoe"] = 0
	var recipes_before := Progress.recipes.size()
	player.cell = Vector2i(28, 5)
	player.try_move(Vector2i.RIGHT)
	check(world.area_id == "grove" and player.cell == Vector2i(1, 8), "masuk Hutan Rahasia")
	check(Progress.flag("grove_visited") and Progress.knows_recipe("sup_jamur") and Progress.recipes.size() >= recipes_before, "resep hutan dipelajari saat pertama masuk")
	check(world.walkable(Vector2i(5, 8)) and not world.walkable(Vector2i(15, 8)), "jalan setapak & kolam di hutan")

	# jamur & herba (tumbuh lagi tiap hari)
	var jamur: Dictionary = {}
	for f in world.features:
		if f.kind == "forage" and f.raw.forage == "forage:jamur":
			jamur = f
	check(not jamur.is_empty(), "ada jamur di hutan")
	player.cell = jamur.rect.position + Vector2i.DOWN
	player.facing = Vector2i.UP
	var j0 := Inventory.count("forage:jamur")
	player.interact()
	check(Inventory.count("forage:jamur") == j0 + 1, "memetik jamur")
	player.interact()
	check(Inventory.count("forage:jamur") == j0 + 1 and got[0].contains("Sudah dipetik"), "jamur tidak bisa dipetik dua kali")
	Clock.end_day(false)
	check(Progress.forage_taken.is_empty(), "jamur tumbuh lagi besok")
	player.travel("grove", [1, 8])

	# peti harta
	var gold_c := Inventory.gold
	player.cell = Vector2i(23, 4)
	player.facing = Vector2i.RIGHT
	player.interact()
	check(Inventory.gold == gold_c + 300 and Progress.flag("grove_chest"), "peti harta memberi 300G")
	player.interact()
	check(Inventory.gold == gold_c + 300 and got[0].contains("kosong"), "peti hanya bisa dibuka sekali")

	# patung Dewi Panen
	player.cell = Vector2i(15, 5)
	player.facing = Vector2i.DOWN
	Inventory.add("crop:lobak", 2)
	player.interact()
	check(menu.mode == menu.Mode.SHRINE, "patung membuka menu persembahan")
	var offer_e: Dictionary = {}
	for e in menu.entries:
		if e.get("kind", "") == "offer" and e.arg == "crop:lobak":
			offer_e = e
	menu._activate(offer_e)
	check(Progress.blessing and menu.body.contains("diberkahi"), "persembahan memberi berkah")
	menu._activate(offer_e)
	check(menu.body.contains("sudah menerima"), "satu persembahan per hari")
	menu.close()
	world.set_area("farm")
	farm.tiles.clear()
	farm.till(Vector2i(10, 11))
	farm.plant(Vector2i(10, 11), "lobak")
	Progress.blessing = true
	farm._on_day_started(false)
	check(farm.tiles[Vector2i(10, 11)].age == 1 and farm.tiles[Vector2i(10, 11)].watered and not Progress.blessing, "berkah: tanaman disiram & tumbuh +1")
	Progress.offerings = 9
	Progress.blessing = false
	Inventory.add("crop:lobak")
	var emas0 := Inventory.count("ore:emas")
	Progress.offer("crop:lobak")
	check(Progress.offerings == 10 and Inventory.count("ore:emas") == emas0 + 3, "persembahan ke-10 memberi 3 Bijih Emas")

	SaveSystem.save_game()
	Progress.flags.clear()
	farm.rocks.clear()
	SaveSystem.load_game()
	check(Progress.flag("secret_open") and Progress.flag("grove_chest") and farm.rocks.size() > 0, "bendera cerita & batu tersimpan")
	check(farm.rocks.all(func(r): return r.kind != "sealed"), "batu raksasa tidak muncul lagi setelah dipecahkan")

	# --- batu besar di tambang
	Inventory.tool_levels["hoe"] = 0
	mine.floor_n = 1
	mine.damage.clear()
	mine.broken.clear()
	player.travel("village", [20, 2])
	player.cell = Vector2i(20, 2)
	player.try_move(Vector2i.UP)
	var bigs: Array = world.features.filter(func(f): return f.kind == "rock" and f.raw.get("big", false))
	check(bigs.size() >= 1, "tambang punya batu besar (%d)" % bigs.size())
	var bf: Dictionary = bigs[0]
	player.stamina = 100.0
	player.cell = bf.rect.position + Vector2i(0, 2)
	player.facing = Vector2i.UP
	player.use_tool()
	player.use_tool()
	check(world.features.has(bf) and mine.damage.size() == 1, "batu besar tambang bertahan dua pukulan (dasar)")
	var ore_b: String = bf.raw.get("ore", "")
	var have_b := Inventory.count("ore:" + ore_b) if ore_b != "" else Inventory.count("stone")
	player.use_tool()
	var after_b := Inventory.count("ore:" + ore_b) if ore_b != "" else Inventory.count("stone")
	check(not world.features.has(bf) and after_b >= have_b + (2 if ore_b != "" else 4), "batu besar tambang hancur pukulan ke-3 + banyak hasil")
	mine.broken.clear()
	mine.damage.clear()
	world.set_area("farm")

	# --- tahap 7: audio, pengaturan, menu jeda, judul
	for sfx_name in Audio.SFX_NAMES:
		check(Audio.sfx.has(sfx_name), "efek suara %s termuat" % sfx_name)
	Audio.play("coin")
	Audio.set_track("music_day")
	check(Audio.music.stream != null and (Audio.music.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD, "musik hari termuat dan berulang")
	world.set_area("shop")
	check(Audio.choose_track() == "music_indoor", "musik interior di dalam ruangan")
	world.set_area("farm")
	Clock.minutes = 19.0 * 60
	check(Audio.choose_track() == "music_night", "musik malam setelah 18:00")
	Clock.minutes = 10.0 * 60
	check(Audio.choose_track() == "music_day", "musik hari di luar ruangan")

	var vol0: int = Settings.volumes.master
	Settings.adjust("master", 100)
	check(Settings.volumes.master == 10, "volume dibatasi maksimal 10")
	Settings.adjust("master", -100)
	check(Settings.volumes.master == 0 and AudioServer.get_bus_volume_db(0) <= -79.0, "volume 0 membisukan bus")
	Settings.adjust("master", vol0)
	check(AudioServer.get_bus_index("Music") > 0 and AudioServer.get_bus_index("SFX") > 0, "bus Music dan SFX tersedia")

	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	menu._unhandled_input(esc)
	check(menu.mode == menu.Mode.PAUSE and Events.menu_open, "Esc membuka menu jeda")
	var pause_kinds: Array = menu.entries.map(func(e): return e.kind)
	check(pause_kinds == ["resume", "save", "settings", "help", "title", "quit"], "isi menu jeda")
	menu._activate(menu.entries[2])
	check(menu.mode == menu.Mode.SETTINGS and menu.return_to == menu.Mode.PAUSE, "pengaturan dibuka dari jeda")
	menu.cursor = 1
	var music0: int = Settings.volumes.music
	var right := InputEventKey.new()
	right.keycode = KEY_D
	right.pressed = true
	menu._unhandled_input(right)
	check(Settings.volumes.music == mini(10, music0 + 1), "A/D mengubah volume musik")
	Settings.adjust("music", music0 - Settings.volumes.music)
	menu.back()
	check(menu.mode == menu.Mode.PAUSE, "Esc dari pengaturan kembali ke jeda")
	menu._activate(menu.entries[3])
	check(menu.mode == menu.Mode.HELP and menu.body.contains("WASD"), "bantuan menampilkan kontrol")
	menu.back()
	menu._activate(menu.entries[1])
	check(menu.note.contains("disimpan"), "simpan dari menu jeda")
	menu._activate(menu.entries[0])
	check(menu.mode == menu.Mode.NONE and not Events.menu_open and not Clock.paused, "lanjut menutup jeda")

	var title: Control = load("res://scenes/title.tscn").instantiate()
	add_child(title)
	await get_tree().process_frame
	var title_kinds: Array = title.entries.map(func(e): return e.kind)
	check(title_kinds.has("new") and title_kinds.has("settings") and title_kinds.has("quit"), "menu judul memuat pilihan utama")
	check(title_kinds.has("continue") == SaveSystem.has_save(), "Lanjutkan hanya bila ada simpanan")
	title._activate("settings")
	check(title.menu.mode == title.menu.Mode.SETTINGS and not title.menu.allow_pause, "pengaturan dari menu judul")
	title.menu.close()
	title.queue_free()
	await get_tree().process_frame

	SaveSystem.delete_save()
	print("HASIL: ", "LULUS" if failures == 0 else "GAGAL (%d)" % failures)
	get_tree().quit(failures)
