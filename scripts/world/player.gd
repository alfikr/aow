class_name Player
extends Node2D
## Pemain: gerak per tile, alat, stamina, dan interaksi.

enum Tool { HOE, WATER, SEED }

const TOOL_NAMES := ["Cangkul", "Penyiram", "Benih"]
const MOVE_TIME := 0.14
const STAMINA_MAX := 100.0
const SPAWN := Layout.HOUSE_DOOR + Vector2i(0, 1)

@onready var farm: Farm = $"../Farm"

var save_key := "player"
var cell := Vector2i(12, 14)
var facing := Vector2i(0, -1)
var tool := Tool.HOE
var selected_crop := 0
var stamina := STAMINA_MAX
var water := Inventory.WATER_CAPACITY[0]
var move_cd := 0.0


func _ready() -> void:
	add_to_group("saveable")
	add_to_group("player")
	position = Vector2(cell * Layout.TILE)
	Events.day_started.connect(_on_day_started)
	Events.game_loaded.connect(func(): position = Vector2(cell * Layout.TILE))


func crop_id() -> String:
	return Data.crop_ids()[selected_crop]


func front() -> Vector2i:
	return cell + facing


func say(text: String) -> void:
	Events.message.emit(text)


func spend_stamina(cost: float) -> bool:
	if stamina < cost:
		say("Kamu terlalu lelah. Tidurlah di rumah (E di pintu).")
		return false
	stamina -= cost
	return true


func walkable(c: Vector2i) -> bool:
	return not Layout.is_solid(c) and not farm.blocks(c)


func _process(delta: float) -> void:
	move_cd = maxf(0.0, move_cd - delta)
	if move_cd <= 0.0 and not Events.menu_open:
		var dir := Vector2i(
			int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left")),
			int(Input.is_action_pressed("move_down")) - int(Input.is_action_pressed("move_up")))
		if dir.x != 0:
			dir.y = 0
		if dir != Vector2i.ZERO:
			facing = dir
			if walkable(cell + dir):
				cell += dir
			move_cd = MOVE_TIME
	position = position.move_toward(Vector2(cell * Layout.TILE), Layout.TILE * delta / MOVE_TIME)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if Events.menu_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: tool = Tool.HOE
			KEY_2: tool = Tool.WATER
			KEY_3: tool = Tool.SEED
			KEY_Q:
				selected_crop = (selected_crop + 1) % Data.crop_ids().size()
				tool = Tool.SEED
	if event.is_action_pressed("use_tool"):
		use_tool()
	elif event.is_action_pressed("interact"):
		interact()


func use_tool() -> void:
	var c := front()
	if tool == Tool.WATER and Layout.POND.has_point(c):
		refill()
		return
	match tool:
		Tool.HOE:
			if farm.has_tile(c):
				if farm.crop_at(c) == "" and spend_stamina(2 * Inventory.stamina_mult("hoe")):
					farm.untill(c)
			elif Layout.FIELD.has_point(c) and spend_stamina(4 * Inventory.stamina_mult("hoe")):
				farm.till(c)
		Tool.WATER:
			if not farm.has_tile(c) or farm.is_watered(c):
				return
			if water <= 0:
				say("Air habis. Isi ulang di kolam.")
			elif spend_stamina(2 * Inventory.stamina_mult("water")):
				farm.water(c)
				water -= 1
		Tool.SEED:
			if not farm.has_tile(c) or farm.crop_at(c) != "":
				return
			var id := crop_id()
			if not Data.grows_in(id, Clock.season):
				say("%s tidak bisa ditanam di musim %s." % [Data.crop_name(id), Clock.SEASON_NAMES[Clock.season]])
			elif Inventory.count(Inventory.seed_id(id)) <= 0:
				say("Benih %s habis. Beli di toko (E)." % Data.crop_name(id))
			elif spend_stamina(1):
				Inventory.remove(Inventory.seed_id(id))
				farm.plant(c, id)


func interact() -> void:
	var c := front()
	if c == Layout.HOUSE_DOOR:
		Clock.end_day(false)
	elif c == Layout.BIN:
		if Inventory.ship_crops() > 0:
			say("Hasil panen dimasukkan. Dibayar saat kamu tidur.")
		else:
			say("Kamu tidak membawa hasil panen.")
	elif c == Layout.SHOP:
		Events.open_shop.emit()
	elif Layout.POND.has_point(c):
		refill()
	elif farm.crop_at(c) != "":
		harvest(c)


func refill() -> void:
	water = Inventory.water_max()
	say("Penyiram terisi penuh.")


func harvest(c: Vector2i) -> void:
	if not farm.is_ripe(c):
		var id := farm.crop_at(c)
		say("%s belum matang (%d/%d hari)." % [Data.crop_name(id), farm.tiles[c].age, Data.growth_days(id)])
		return
	var id := farm.harvest(c)
	Inventory.add(Inventory.crop_id(id))
	var regrow := Data.regrow_days(id)
	if regrow > 0:
		say("Panen %s! Berbuah lagi dalam %d hari." % [Data.crop_name(id), regrow])
	else:
		say("Panen %s! Masukkan ke kotak pengiriman (E)." % Data.crop_name(id))


func _on_day_started(passed_out: bool) -> void:
	stamina = 60.0 if passed_out else STAMINA_MAX
	cell = SPAWN
	position = Vector2(cell * Layout.TILE)
	facing = Vector2i(0, -1)


func _draw() -> void:
	# garis tepi tile di depan (digambar relatif terhadap posisi pemain)
	var f := front()
	if Layout.in_map(f):
		draw_rect(Rect2(Vector2(f - cell) * Layout.TILE, Vector2.ONE * Layout.TILE),
			Color(1, 1, 1, 0.9), false, 2.0)
	draw_rect(Rect2(Vector2(6, 4), Vector2(20, 26)), Color(0.2, 0.35, 0.8))
	draw_circle(Vector2(16, 8), 7, Color(0.95, 0.8, 0.65))
	draw_circle(Vector2(16, 16) + Vector2(facing) * 4, 2, Color.BLACK)


func save_data() -> Dictionary:
	return {"x": cell.x, "y": cell.y, "fx": facing.x, "fy": facing.y, "stamina": stamina,
		"water": water, "tool": int(tool), "crop": selected_crop}


func load_data(d: Dictionary) -> void:
	cell = Vector2i(int(d.get("x", cell.x)), int(d.get("y", cell.y)))
	facing = Vector2i(int(d.get("fx", 0)), int(d.get("fy", -1)))
	stamina = float(d.get("stamina", STAMINA_MAX))
	water = clampi(int(d.get("water", Inventory.water_max())), 0, Inventory.water_max())
	tool = int(d.get("tool", 0)) as Tool
	selected_crop = clampi(int(d.get("crop", 0)), 0, Data.crop_ids().size() - 1)
	position = Vector2(cell * Layout.TILE)
