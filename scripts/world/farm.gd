class_name Farm
extends Node2D
## Keadaan ladang. Ada kunci di `tiles` berarti tanahnya sudah dicangkul.
## tiles: Vector2i -> {watered: bool, crop: String, age: int}

var save_key := "farm"
var tiles := {}


func _ready() -> void:
	add_to_group("saveable")
	Events.day_ended.connect(_on_day_ended)
	Events.day_started.connect(_on_day_started)
	Events.season_changed.connect(_on_season_changed)


func has_tile(c: Vector2i) -> bool:
	return tiles.has(c)


func crop_at(c: Vector2i) -> String:
	return tiles[c].crop if tiles.has(c) else ""


func is_watered(c: Vector2i) -> bool:
	return tiles.has(c) and tiles[c].watered


func is_ripe(c: Vector2i) -> bool:
	var crop := crop_at(c)
	return crop != "" and tiles[c].age >= Data.growth_days(crop)


func blocks(c: Vector2i) -> bool:
	return crop_at(c) != ""


func till(c: Vector2i) -> bool:
	if not Layout.FIELD.has_point(c) or tiles.has(c):
		return false
	tiles[c] = {"watered": false, "crop": "", "age": 0}
	queue_redraw()
	return true


func untill(c: Vector2i) -> bool:
	if not tiles.has(c) or tiles[c].crop != "":
		return false
	tiles.erase(c)
	queue_redraw()
	return true


func water(c: Vector2i) -> bool:
	if not tiles.has(c) or tiles[c].watered:
		return false
	tiles[c].watered = true
	queue_redraw()
	return true


func plant(c: Vector2i, crop: String) -> bool:
	if not tiles.has(c) or tiles[c].crop != "":
		return false
	tiles[c].crop = crop
	tiles[c].age = 0
	queue_redraw()
	return true


## Mengembalikan id tanaman yang dipanen, atau "" bila belum matang.
func harvest(c: Vector2i) -> String:
	if not is_ripe(c):
		return ""
	var crop: String = tiles[c].crop
	tiles[c].crop = ""
	tiles[c].age = 0
	queue_redraw()
	return crop


func _on_day_ended(_passed_out: bool) -> void:
	for c in tiles:
		var t: Dictionary = tiles[c]
		if t.crop != "" and t.watered:
			t.age += 1
		t.watered = false
	queue_redraw()


func _on_day_started(_passed_out: bool) -> void:
	if Clock.weather == Clock.Weather.RAINY:
		for c in tiles:
			tiles[c].watered = true
	queue_redraw()


func _on_season_changed(season: int) -> void:
	var withered := 0
	for c in tiles:
		var crop: String = tiles[c].crop
		if crop != "" and not Data.grows_in(crop, season):
			tiles[c].crop = ""
			tiles[c].age = 0
			withered += 1
	if withered > 0:
		Events.message.emit("%d tanaman layu karena pergantian musim." % withered)
	queue_redraw()


func _draw() -> void:
	var T := Layout.TILE
	for c in tiles:
		var t: Dictionary = tiles[c]
		var r := Rect2(Vector2(c) * T, Vector2(T, T))
		draw_rect(r, Color(0.35, 0.22, 0.12) if t.watered else Color(0.5, 0.33, 0.18))
		draw_rect(r, Color(0, 0, 0, 0.2), false, 1.0)
		if t.crop == "":
			continue
		var days := Data.growth_days(t.crop)
		var growth := clampf(float(t.age) / float(days), 0.0, 1.0)
		var center := r.position + Vector2(16, 20)
		draw_line(center, center + Vector2(0, -6 - 10 * growth), Color(0.15, 0.55, 0.15), 3.0)
		if t.age >= days:
			draw_circle(center + Vector2(0, -2), 8, Data.crop_color(t.crop))
		else:
			draw_circle(center + Vector2(0, -8 * growth - 6), 3 + 2 * growth, Color(0.3, 0.75, 0.3))


func save_data() -> Dictionary:
	var out := []
	for c in tiles:
		var t: Dictionary = tiles[c]
		out.append({"x": c.x, "y": c.y, "watered": t.watered, "crop": t.crop, "age": t.age})
	return {"tiles": out}


func load_data(d: Dictionary) -> void:
	tiles.clear()
	for e in d.get("tiles", []):
		tiles[Vector2i(int(e.x), int(e.y))] = {
			"watered": bool(e.watered), "crop": str(e.crop), "age": int(e.age)}
	queue_redraw()
