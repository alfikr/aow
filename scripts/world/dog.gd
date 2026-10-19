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
			cell = trail.pop_front()
	position = position.move_toward(Vector2(cell * Layout.TILE), Layout.TILE * delta / MOVE_TIME)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2(5, 14), Vector2(22, 11)), Color(0.55, 0.38, 0.2))
	draw_circle(Vector2(25, 13), 6, Color(0.6, 0.42, 0.24))
	draw_rect(Rect2(Vector2(5, 22), Vector2(4, 7)), Color(0.45, 0.3, 0.16))
	draw_rect(Rect2(Vector2(22, 22), Vector2(4, 7)), Color(0.45, 0.3, 0.16))


func save_data() -> Dictionary:
	return {"affection": affection}


func load_data(d: Dictionary) -> void:
	affection = int(d.get("affection", 0))
