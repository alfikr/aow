class_name Fishing
extends Node2D
## Memancing: lempar kail (Spasi) -> tunggu -> saat "!" muncul tekan Spasi lagi.

enum State { IDLE, WAIT, BITE }

const BITE_WINDOW := 0.9
const STAMINA_COST := 3.0

var state := State.IDLE
var timer := 0.0
var place := ""
var target := Vector2i.ZERO


func _player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


func cast(at_place: String, at_cell: Vector2i) -> void:
	if state != State.IDLE:
		return
	if not _player().spend_stamina(STAMINA_COST):
		return
	place = at_place
	target = at_cell
	state = State.WAIT
	timer = randf_range(1.2, 3.2)
	Events.message.emit("Kamu melempar kail...")


func cancel() -> void:
	if state != State.IDLE:
		state = State.IDLE
		queue_redraw()


func reel() -> void:
	if state == State.BITE:
		state = State.IDLE
		_catch()
	elif state == State.WAIT:
		state = State.IDLE
		Events.message.emit("Terlalu cepat! Ikan kabur.")
	queue_redraw()


## Ikan yang mungkin muncul di tempat dan musim tertentu, berbobot kelangkaan.
func candidates(at_place: String, season: int) -> Array:
	var out := []
	for id in Data.fish:
		var f: Dictionary = Data.fish[id]
		var in_season := false
		for s in f.seasons:
			if int(s) == season:
				in_season = true
		if in_season and f.places.has(at_place):
			out.append(id)
	return out


func pick_fish(at_place: String, season: int) -> String:
	var pool := candidates(at_place, season)
	if pool.is_empty():
		return ""
	var total := 0
	for id in pool:
		total += int(Data.fish[id].weight)
	var r := randi() % total
	for id in pool:
		r -= int(Data.fish[id].weight)
		if r < 0:
			return id
	return pool[0]


func _catch() -> void:
	var id := pick_fish(place, Clock.season)
	if id == "":
		Events.message.emit("Tidak ada ikan yang menggigit.")
		return
	Inventory.add("fish:" + id)
	Progress.bump("fish")
	Events.message.emit("Dapat %s! (dijual %dG)" % [Data.fish[id].name, int(Data.fish[id].sell)])


func _process(delta: float) -> void:
	if state == State.WAIT:
		timer -= delta
		if timer <= 0.0:
			state = State.BITE
			timer = BITE_WINDOW
			Events.message.emit("Ada ikan! Tekan Spasi!")
	elif state == State.BITE:
		timer -= delta
		if timer <= 0.0:
			state = State.IDLE
			Events.message.emit("Ikan lolos...")
	if state != State.IDLE or visible:
		queue_redraw()


func _draw() -> void:
	if state == State.IDLE:
		return
	var p := _player()
	var from := p.position + Vector2(16, 14)
	var to := Vector2(target) * Layout.TILE + Vector2(16, 16)
	draw_line(from, to, Color(1, 1, 1, 0.9), 1.5)
	draw_circle(to, 4, Color(0.95, 0.2, 0.2) if state == State.WAIT else Color(1, 0.9, 0.2))
	if state == State.BITE:
		draw_string(ThemeDB.fallback_font, p.position + Vector2(10, -6), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1, 0.9, 0.2))
