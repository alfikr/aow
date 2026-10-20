class_name Dog
extends Node2D
## Anjing yang mengikuti pemain, tertinggal tiga langkah, ke semua area.

const MOVE_TIME := 0.14
const LAG := 2

@onready var player: Player = $"../Player"

var save_key := "dog"
var affection := 0
var petted := false
var cell := Vector2i.ZERO
var trail: Array = []
var last_player_cell := Vector2i(-1, -1)
var snap := true
var face_right := false


func _ready() -> void:
	add_to_group("saveable")
	add_to_group("dog")
	Events.area_changed.connect(func(_id): snap = true)
	Events.day_started.connect(func(_p): petted = false)
	Events.game_loaded.connect(func(): snap = true)


func pet() -> void:
	if petted:
		Events.message.emit("Anjingmu menggoyangkan ekor. (kasih sayang %d)" % affection)
		return
	petted = true
	affection = mini(100, affection + 3)
	Events.message.emit("Guk guk! Kamu mengelus anjingmu. (kasih sayang %d)" % affection)


func _process(delta: float) -> void:
	if snap:
		snap = false
		cell = player.cell
		trail.clear()
		last_player_cell = player.cell
		position = Vector2(cell * Layout.TILE)
	elif player.cell != last_player_cell:
		trail.append(last_player_cell)
		last_player_cell = player.cell
		if trail.size() > LAG:
			var old := cell
			cell = trail.pop_front()
			if cell.x != old.x:
				face_right = cell.x > old.x
	position = position.move_toward(Vector2(cell * Layout.TILE), Layout.TILE * delta / MOVE_TIME)
	queue_redraw()


func _draw() -> void:
	var moving := position.distance_to(Vector2(cell * Layout.TILE)) > 0.5
	var t := Time.get_ticks_msec()
	# diam: ekor bergoyang (bingkai 0/1); jalan: kaki bergantian (bingkai 2/3)
	var frame := 2 + int(t / 130) % 2 if moving else int(t / 450) % 2
	if Sprites.draw_animal(self, "dog", Vector2.ZERO, face_right, frame):
		return
	draw_rect(Rect2(Vector2(5, 14), Vector2(22, 11)), Color(0.55, 0.38, 0.2))
	draw_circle(Vector2(25, 13), 6, Color(0.6, 0.42, 0.24))


func save_data() -> Dictionary:
	return {"affection": affection}


func load_data(d: Dictionary) -> void:
	affection = int(d.get("affection", 0))
