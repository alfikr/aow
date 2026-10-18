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

	SaveSystem.delete_save()
	print("HASIL: ", "LULUS" if failures == 0 else "GAGAL (%d)" % failures)
	get_tree().quit(failures)
