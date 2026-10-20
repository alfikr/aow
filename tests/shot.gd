extends Node
## Mengambil screenshot untuk pemeriksaan visual (butuh display, mis. xvfb-run):
##   xvfb-run -a godot --path . res://tests/shot.tscn -- <folder-keluaran>

func _ready() -> void:
	var out := "/tmp"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	SaveSystem.path = "user://shot.json"
	SaveSystem.delete_save()
	Inventory.reset()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	Clock.paused = true
	var player: Player = main.get_node("Player")
	var farm: Farm = main.get_node("Farm")
	var world: World = main.get_node("World")
	var ls: Livestock = main.get_node("Livestock")
	var menu: Control = main.get_node("UI/Menu")

	# peternakan dengan ladang: semua tanaman, tiap tahap pertumbuhan
	var crops := ["lobak", "kentang", "tomat", "jagung", "labu"]
	for row in crops.size():
		var id: String = crops[row]
		var days := Data.growth_days(id)
		for col in 4:
			var c := Vector2i(11 + col * 2, 4 + row * 2)
			farm.till(c)
			farm.plant(c, id)
			farm.tiles[c].age = [0, int(days * 0.4), int(days * 0.8), days][col]
			if col % 2 == 0:
				farm.water(c)
	player.cell = Vector2i(10, 13)
	player.position = Vector2(player.cell * Layout.TILE)
	player.facing = Vector2i.UP
	Events.message.emit("Selamat datang! WASD jalan, Spasi pakai alat, E interaksi.")
	await _shot(out, "01_farm")

	player.travel("village", [15, 9])
	Clock.minutes = 10.0 * 60
	main.get_node("Npcs").snap_all()
	var dog: Node2D = main.get_node("Dog")
	dog._process(0.1)
	await _shot(out, "02_village")

	# pemain & anjing di peternakan berbagai arah
	player.travel("farm", [20, 14])
	for dir in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]:
		player.facing = dir
		await _shot(out, "02b_player_%d_%d" % [dir.x, dir.y])

	player.travel("shop", [14, 11])
	main.get_node("Npcs").snap_all()
	await _shot(out, "03_shop")

	menu.open(menu.Mode.SHOP)
	await _shot(out, "04_shop_menu")
	menu.close()

	Inventory.add("crop:tomat")
	menu.open_dialog("mira")
	await _shot(out, "05_dialog")
	menu.close()

	ls.add_animal("ayam")
	ls.add_animal("sapi")
	player.travel("home", [14, 11])
	await _shot(out, "05b_home")

	player.travel("hall", [14, 11])
	main.get_node("Npcs").snap_all()
	Clock.minutes = 10.0 * 60
	main.get_node("Npcs").snap_all()
	await _shot(out, "05c_hall")

	for hid in ["house_raka", "house_lila", "house_dodi"]:
		player.travel(hid, [14, 11])
		main.get_node("Npcs").snap_all()
		await _shot(out, "05d_" + hid)

	player.travel("lane", [14, 1])
	main.get_node("Npcs").snap_all()
	await _shot(out, "05e_lane")

	player.travel("inn", [14, 11])
	main.get_node("Npcs").snap_all()
	await _shot(out, "05f_inn")

	player.travel("barn", [14, 11])
	await _shot(out, "06b_barn")

	player.travel("coop", [14, 11])
	await _shot(out, "06_coop")

	player.travel("beach", [13, 9])
	await _shot(out, "07_beach")

	player.travel("mine", [14, 12])
	await _shot(out, "08_mine")

	player.travel("lane", [14, 1])
	main.get_node("Npcs").snap_all()
	await _shot(out, "07b_lane")

	# berdiri di belakang pohon (tajuk menutupi) dan di depannya
	player.travel("farm", [12, 0])
	player.cell = Vector2i(12, 0)
	player.position = Vector2(player.cell * Layout.TILE)
	await _shot(out, "07c_behind_tree")

	player.travel("farm", [4, 4])
	Clock.minutes = 20.0 * 60
	await _shot(out, "09_farm_night")

	menu.open(menu.Mode.INVENTORY)
	await _shot(out, "10_inventory")
	menu.close()

	# musim & cuaca di desa dan peternakan
	var combos := [
		[0, Clock.Weather.SUNNY, 600.0, "s0_spring"],
		[1, Clock.Weather.SUNNY, 600.0, "s1_summer"],
		[1, Clock.Weather.SUNNY, 1230.0, "s1_summer_night"],
		[2, Clock.Weather.SUNNY, 600.0, "s2_autumn"],
		[3, Clock.Weather.SNOW, 600.0, "s3_winter_snow"],
		[0, Clock.Weather.RAINY, 600.0, "s0_rain"],
	]
	for c in combos:
		player.travel("village", [14, 9])
		Clock.season = c[0]
		Clock.weather = c[1]
		Clock.minutes = c[2]
		Events.season_changed.emit(c[0])
		main.get_node("Npcs").snap_all()
		for i in 25:
			await get_tree().process_frame
		await _shot(out, "season_village_" + c[3])
	player.travel("farm", [12, 14])
	Clock.season = 3
	Clock.weather = Clock.Weather.SNOW
	Clock.minutes = 600.0
	Events.season_changed.emit(3)
	for i in 25:
		await get_tree().process_frame
	await _shot(out, "season_farm_winter")
	Clock.season = 0
	Clock.weather = Clock.Weather.SUNNY
	Events.season_changed.emit(0)

	menu.open(menu.Mode.PAUSE)
	await _shot(out, "11_pause")
	menu.open(menu.Mode.SETTINGS)
	await _shot(out, "12_settings")
	menu.open(menu.Mode.HELP)
	await _shot(out, "13_help")
	menu.close()

	Inventory.add("crop:lobak", 2)
	menu.open(menu.Mode.COOK)
	await _shot(out, "14_cook")
	menu.close()

	Progress.ending_seen = false
	Progress.stats.fish = 12
	menu.open(menu.Mode.ENDING)
	await _shot(out, "15_ending")
	menu.close()

	main.queue_free()
	var title: Control = load("res://scenes/title.tscn").instantiate()
	add_child(title)
	await _shot(out, "00_title")

	SaveSystem.delete_save()
	get_tree().quit()


func _shot(out: String, name: String) -> void:
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
	print("shot ", name)
