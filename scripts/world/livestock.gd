class_name Livestock
extends Node2D
## Hewan ternak (ayam, sapi). Hewan hanya bergerak dan digambar saat pemain
## berada di kandangnya. Tiap hari: diberi pakan -> menghasilkan produk;
## tidak diberi pakan -> kasih sayang turun.
## animals: [{type, name, fed, product, petted, affection, cell: Vector2i}]

const WANDER_INTERVAL := 1.2

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
			animals.append({"type": type, "name": "%s %d" % [Data.animals[type].name, count_of(type) + 1],
				"fed": false, "product": false, "petted": false, "affection": 0, "cell": c})
			queue_redraw()
			return true
	return false


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
	wander_t += delta
	if wander_t < WANDER_INTERVAL:
		return
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
	queue_redraw()


func _draw() -> void:
	var T := Layout.TILE
	for a in animals:
		if area_of(a) != world.area_id:
			continue
		var info: Dictionary = Data.animals[a.type]
		var p := Vector2(a.cell) * T
		var col := Color.html(info.color)
		if a.type == "sapi":
			draw_rect(Rect2(p + Vector2(3, 8), Vector2(26, 16)), col)
			draw_rect(Rect2(p + Vector2(8, 11), Vector2(7, 6)), Color(0.25, 0.2, 0.18))
			draw_rect(Rect2(p + Vector2(24, 6), Vector2(7, 9)), col.darkened(0.15))
		else:
			draw_circle(p + Vector2(16, 20), 9, col)
			draw_circle(p + Vector2(22, 12), 5, col)
			draw_rect(Rect2(p + Vector2(25, 11), Vector2(5, 3)), Color(0.95, 0.65, 0.15))
		if a.product:
			draw_circle(p + Vector2(16, 4), 4, Color(1, 0.9, 0.2))
		elif not a.fed:
			draw_circle(p + Vector2(16, 4), 3, Color(0.85, 0.2, 0.2))


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
		animals.append({"type": str(e.type), "name": str(e.name), "fed": bool(e.fed),
			"product": bool(e.product), "petted": bool(e.petted), "affection": int(e.affection),
			"cell": Vector2i(int(e.x), int(e.y))})
	queue_redraw()
