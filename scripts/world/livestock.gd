class_name Livestock
extends Node2D
## Hewan ternak (ayam, sapi). Hewan hanya bergerak dan digambar saat pemain
## berada di kandangnya. Tiap hari: diberi pakan -> menghasilkan produk;
## tidak diberi pakan -> kasih sayang turun.
## animals: [{type, name, fed, product, petted, affection, cell: Vector2i}]

const WANDER_INTERVAL := 1.2
const WALK_SPEED := 60.0   # px/detik

@onready var world: World = $"../World"

var save_key := "livestock"
var animals: Array = []
var wander_t := 0.0


func _ready() -> void:
	add_to_group("saveable")
	add_to_group("livestock")
	Events.day_ended.connect(_on_day_ended)
	Events.area_changed.connect(func(_id): queue_redraw())


func count_of(type: String) -> int:
	var n := 0
	for a in animals:
		if a.type == type:
			n += 1
	return n


func can_add(type: String) -> bool:
	return count_of(type) < int(Data.animals[type].capacity)


func _slot_cell(type: String, slot: int) -> Vector2i:
	var info: Dictionary = Data.animals[type]
	return Vector2i(int(info.home[0]) + slot * int(info.step), int(info.home[1]))


## Menambah hewan di slot kosong pertama kandangnya. false bila kandang penuh.
func add_animal(type: String) -> bool:
	if not can_add(type):
		return false
	for slot in int(Data.animals[type].capacity):
		var c := _slot_cell(type, slot)
		if animal_at(Data.animals[type].area, c) < 0:
			animals.append(_with_visuals({"type": type, "name": "%s %d" % [Data.animals[type].name, count_of(type) + 1],
				"fed": false, "product": false, "petted": false, "affection": 0, "cell": c}))
			queue_redraw()
			return true
	return false


## Menambah bidang animasi (hanya runtime, tidak disimpan).
func _with_visuals(a: Dictionary) -> Dictionary:
	a["pos"] = Vector2(a.cell * Layout.TILE)
	a["right"] = false
	a["moving"] = false
	a["idle_t"] = 0.0
	a["next_peck"] = randf_range(2.0, 5.0)
	a["peck_t"] = 0.0
	return a


func area_of(a: Dictionary) -> String:
	return str(Data.animals[a.type].area)


func animal_at(area_id: String, c: Vector2i) -> int:
	for i in animals.size():
		if animals[i].cell == c and area_of(animals[i]) == area_id:
			return i
	return -1


## Beri pakan / ambil produk / elus, sesuai keadaan hewan.
func interact(i: int) -> void:
	var a: Dictionary = animals[i]
	if a.product:
		var prod: String = Data.animals[a.type].product
		Inventory.add("prod:" + prod)
		a.product = false
		Events.sfx.emit("harvest")
		Events.message.emit("Mengambil %s dari %s." % [Data.products[prod].name, a.name])
	elif not a.fed:
		if Inventory.remove("feed"):
			a.fed = true
			Events.message.emit("%s makan dengan lahap." % a.name)
		else:
			Events.message.emit("%s lapar, tapi kamu tidak punya pakan. Beli di toko." % a.name)
	elif not a.petted:
		a.petted = true
		a.affection = mini(100, a.affection + 2)
		Events.message.emit("Kamu mengelus %s. (kasih sayang %d)" % [a.name, a.affection])
	else:
		Events.message.emit("%s tampak senang. (kasih sayang %d)" % [a.name, a.affection])
	queue_redraw()


func _on_day_ended(_passed_out: bool) -> void:
	for a in animals:
		if a.fed:
			a.affection = mini(100, a.affection + 4)
			a.product = true
		else:
			a.affection = maxi(0, a.affection - 3)
		a.fed = false
		a.petted = false
	queue_redraw()


func _process(delta: float) -> void:
	var visible_here := false
	for a in animals:
		if area_of(a) != world.area_id:
			continue
		visible_here = true
		var target := Vector2(a.cell * Layout.TILE)
		var d: Vector2 = target - a.pos
		a.moving = d.length() > 0.5
		if a.moving:
			if absf(d.x) > 0.5:
				a.right = d.x > 0.0
			a.pos = a.pos.move_toward(target, WALK_SPEED * delta)
		else:
			a.pos = target
			a.idle_t += delta
			if a.idle_t >= a.next_peck:
				a.idle_t = 0.0
				a.next_peck = randf_range(2.0, 5.0)
				a.peck_t = 0.6
		a.peck_t = maxf(0.0, a.peck_t - delta)
	wander_t += delta
	if wander_t >= WANDER_INTERVAL:
		wander_t = 0.0
		var player := get_tree().get_first_node_in_group("player") as Player
		for a in animals:
			if area_of(a) != world.area_id or randf() > 0.4:
				continue
			var dir: Vector2i = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT].pick_random()
			var target: Vector2i = a.cell + dir
			if world.walkable(target) and animal_at(world.area_id, target) < 0 \
					and not (player != null and player.cell == target):
				a.cell = target
	if visible_here:
		queue_redraw()


## Nomor bingkai animasi untuk hewan (ayam: diam/jalan/mematuk, sapi: diam/jalan A/B/makan).
func _frame_of(a: Dictionary, sheet: String) -> int:
	var t := Time.get_ticks_msec()
	if sheet == "cow":
		if a.moving:
			return 1 + int(t / 260) % 2
		return 3 if a.peck_t > 0.0 else 0
	if a.moving:
		return 1 if int(t / 180) % 2 == 0 else 0
	return 2 if a.peck_t > 0.0 else 0


func _draw() -> void:
	var T := Layout.TILE
	for a in animals:
		if area_of(a) != world.area_id:
			continue
		var info: Dictionary = Data.animals[a.type]
		var sheet: String = info.get("sprite", "")
		var p: Vector2 = a.pos
		if not Sprites.draw_animal(self, sheet, p, a.right, _frame_of(a, sheet)):
			var col := Color.html(info.color)
			if a.type == "sapi":
				draw_rect(Rect2(p + Vector2(3, 8), Vector2(26, 16)), col)
			else:
				draw_circle(p + Vector2(16, 20), 9, col)
		var top := p.y + T - Sprites.animal_height(sheet) - 5.0
		if a.product:
			draw_circle(Vector2(p.x + 16, top), 4, Color(1, 0.9, 0.2))
			draw_arc(Vector2(p.x + 16, top), 4, 0, TAU, 12, Color(0.4, 0.3, 0.0), 1.0)
		elif not a.fed:
			draw_circle(Vector2(p.x + 16, top), 3, Color(0.85, 0.2, 0.2))


func save_data() -> Dictionary:
	var out := []
	for a in animals:
		out.append({"type": a.type, "name": a.name, "fed": a.fed, "product": a.product,
			"petted": a.petted, "affection": a.affection, "x": a.cell.x, "y": a.cell.y})
	return {"animals": out}


func load_data(d: Dictionary) -> void:
	animals.clear()
	for e in d.get("animals", []):
		if not Data.animals.has(str(e.type)):
			continue
		animals.append(_with_visuals({"type": str(e.type), "name": str(e.name), "fed": bool(e.fed),
			"product": bool(e.product), "petted": bool(e.petted), "affection": int(e.affection),
			"cell": Vector2i(int(e.x), int(e.y))}))
	queue_redraw()
