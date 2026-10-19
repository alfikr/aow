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

	# peternakan dengan ladang
	for x in range(11, 17):
		for y in range(4, 8):
			farm.till(Vector2i(x, y))
	farm.plant(Vector2i(11, 4), "lobak")
	farm.plant(Vector2i(12, 4), "kentang")
	farm.plant(Vector2i(13, 4), "lobak")
	farm.tiles[Vector2i(13, 4)].age = 4
	farm.water(Vector2i(11, 4))
	farm.water(Vector2i(12, 4))
	player.cell = Vector2i(12, 8)
	player.position = Vector2(player.cell * Layout.TILE)
	player.facing = Vector2i.UP
	Events.message.emit("Selamat datang! WASD jalan, Spasi pakai alat, E interaksi.")
	await _shot(out, "01_farm")

	player.travel("village", [15, 9])
	Clock.minutes = 10.0 * 60
	main.get_node("Npcs").snap_all()
	await _shot(out, "02_village")

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

	player.travel("coop", [14, 11])
	await _shot(out, "06_coop")

	player.travel("beach", [13, 9])
	await _shot(out, "07_beach")

	player.travel("mine", [14, 12])
	await _shot(out, "08_mine")

	player.travel("farm", [4, 4])
	Clock.minutes = 20.0 * 60
	await _shot(out, "09_farm_night")

	menu.open(menu.Mode.INVENTORY)
	await _shot(out, "10_inventory")
	menu.close()

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
