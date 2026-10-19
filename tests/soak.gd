extends Node
## Uji ketahanan: aksi acak selama ratusan hari, mencari error runtime.
##   godot --headless --path . res://tests/soak.tscn -- [jumlah_hari] [seed]

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var days := int(args[0]) if args.size() > 0 else 250
	var seed_val := int(args[1]) if args.size() > 1 else 1
	seed(seed_val)
	SaveSystem.path = "user://soak.json"
	SaveSystem.delete_save()
	Inventory.reset()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	Clock.paused = true
	var player: Player = main.get_node("Player")
	var farm: Farm = main.get_node("Farm")
	var world: World = main.get_node("World")
	var npcs: Npcs = main.get_node("Npcs")
	var ls: Livestock = main.get_node("Livestock")
	var menu: Control = main.get_node("UI/Menu")
	var areas := ["farm", "village", "shop", "coop", "barn", "home", "hall", "inn", "house", "beach"]
	var dirs := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	Inventory.gold = 20000
	var days_done := 0

	for d in days:
		for step in 40:
			var r := randi() % 12
			Clock.minutes = minf(Clock.minutes + 20.0, 1430.0)
			match r:
				0:
					var a: String = areas[randi() % areas.size()]
					var spawn: Array = []
					for f in Data.areas[a].features:
						if f.kind == "exit":
							spawn = [int(f.spawn[0]), int(f.spawn[1])]
					# gunakan titik spawn pintu yang menuju area ini
					for src in Data.areas:
						for f in Data.areas[src].features:
							if f.kind == "exit" and f.to == a:
								spawn = [int(f.spawn[0]), int(f.spawn[1])]
					player.travel(a, spawn)
				1, 2, 3:
					player.tool = [Player.Tool.HOE, Player.Tool.WATER, Player.Tool.SEED, Player.Tool.FISH][randi() % 4]
					player.selected_crop = randi() % Data.crop_ids().size()
					player.facing = dirs[randi() % 4]
					player.stamina = 100.0
					player.use_tool()
					if fishing_active(main):
						main.get_node("Fishing").state = Fishing.State.BITE if randf() < 0.5 else Fishing.State.IDLE
						main.get_node("Fishing").reel()
				4, 5:
					player.facing = dirs[randi() % 4]
					player.cell += dirs[randi() % 4] if world.walkable(player.cell + dirs[randi() % 4]) else Vector2i.ZERO
					player.interact()
					if menu.mode != menu.Mode.NONE:
						_drive_menu(menu)
				6:
					player.try_move(dirs[randi() % 4])
				7:
					Inventory.add("feed", 3)
					Inventory.add("crop:" + Data.crop_ids()[randi() % Data.crop_ids().size()], 2)
					Inventory.add("prod:telur")
				8:
					npcs._process(0.3)
					for i in 6:
						npcs._advance(Data.npcs.keys()[randi() % Data.npcs.size()])
				9:
					if ls.can_add("ayam") and randf() < 0.3:
						ls.add_animal("ayam")
					ls._process(2.0)
				10:
					for id in Inventory.items.keys():
						if str(id).begins_with("dish:") or randf() < 0.1:
							pass
					menu.open(menu.Mode.INVENTORY)
					menu.close()
				11:
					Inventory.add("ore:tembaga", 1)
		Clock.end_day(randf() < 0.1)
		days_done += 1
		if d % 40 == 0:
			SaveSystem.save_game()
			SaveSystem.load_game()
		# invarian
		for id in npcs.where:
			var w: Dictionary = npcs.where[id]
			if not Data.areas.has(w.area):
				print("INVARIAN: NPC di area tak dikenal ", id, w)
		if world.area_id != "farm":
			print("INVARIAN: bangun bukan di peternakan: ", world.area_id)
		if Inventory.gold < 0:
			print("INVARIAN: uang negatif")
	print("SOAK selesai: ", days_done, " hari, tahun ", Clock.year, ", musim ", Clock.season, ", uang ", Inventory.gold)
	SaveSystem.delete_save()
	get_tree().quit()


func fishing_active(main: Node) -> bool:
	return main.get_node("Fishing").state != Fishing.State.IDLE


func _drive_menu(menu: Control) -> void:
	for i in 6:
		if menu.mode == menu.Mode.NONE:
			return
		if menu.entries.size() > 0:
			menu.cursor = randi() % menu.entries.size()
			menu._activate(menu.entries[menu.cursor])
		if menu.mode == menu.Mode.DIALOG and menu.page < menu.pages.size() - 1:
			menu._confirm()
	if menu.mode != menu.Mode.NONE:
		menu.close()
