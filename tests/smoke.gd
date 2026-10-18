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

	SaveSystem.delete_save()
	print("HASIL: ", "LULUS" if failures == 0 else "GAGAL (%d)" % failures)
	get_tree().quit(failures)
