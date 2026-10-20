class_name Farm
extends Node2D
## Keadaan ladang. Ada kunci di `tiles` berarti tanahnya sudah dicangkul.
## tiles: Vector2i -> {watered: bool, crop: String, age: int}

const STARTER := Rect2i(10, 10, 4, 3)     # petak awal yang bersih dari batu
const SEALED_CELL := Vector2i(27, 5)       # batu raksasa penutup jalan rahasia
const MAX_ROCKS := 26
const STRIKE_DAMAGE := {"big": [1, 2, 4], "sealed": [0, 2, 4]}   # per level cangkul

var save_key := "farm"
var tiles := {}
## rocks: [{cell: Vector2i, size: 1|2, kind: "small"|"big"|"sealed", hp: int}]
var rocks: Array = []


func _ready() -> void:
	add_to_group("saveable")
	Events.day_ended.connect(_on_day_ended)
	Events.day_started.connect(_on_day_started)
	Events.season_changed.connect(_on_season_changed)
	scatter_rocks(4242)


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
	return crop_at(c) != "" or rock_index_at(c) >= 0


# ------------------------------------------------------------------ batu

func rock_index_at(c: Vector2i) -> int:
	for i in rocks.size():
		var r: Dictionary = rocks[i]
		if Rect2i(r.cell, Vector2i(r.size, r.size)).has_point(c):
			return i
	return -1


func _free_for(c: Vector2i, size: int, avoid_starter: bool) -> bool:
	var area := Rect2i(c, Vector2i(size, size))
	if not Layout.FIELD.encloses(area):
		return false
	if avoid_starter and STARTER.intersects(area):
		return false
	for x in size:
		for y in size:
			var cc := c + Vector2i(x, y)
			if tiles.has(cc) or rock_index_at(cc) >= 0:
				return false
	return true


## Taburan awal batu: 3 batu besar + 12 batu kecil, dan batu raksasa penutup jalan rahasia.
func scatter_rocks(seed_val: int) -> void:
	rocks.clear()
	if not Progress.flag("secret_open"):
		rocks.append({"cell": SEALED_CELL, "size": 2, "kind": "sealed", "hp": 4})
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var placed := 0
	var attempts := 0
	while placed < 3 and attempts < 300:
		attempts += 1
		var c := Vector2i(rng.randi_range(Layout.FIELD.position.x, Layout.FIELD.end.x - 2),
			rng.randi_range(Layout.FIELD.position.y, Layout.FIELD.end.y - 2))
		if _free_for(c, 2, true):
			rocks.append({"cell": c, "size": 2, "kind": "big", "hp": 4})
			placed += 1
	placed = 0
	attempts = 0
	while placed < 12 and attempts < 600:
		attempts += 1
		var c := Vector2i(rng.randi_range(Layout.FIELD.position.x, Layout.FIELD.end.x - 1),
			rng.randi_range(Layout.FIELD.position.y, Layout.FIELD.end.y - 1))
		if _free_for(c, 1, true):
			rocks.append({"cell": c, "size": 1, "kind": "small", "hp": 1})
			placed += 1
	queue_redraw()


## Batu kecil baru muncul di ladang yang kosong dari waktu ke waktu.
func spawn_daily_rock(force := false) -> bool:
	if rocks.size() >= MAX_ROCKS:
		return false
	if not force and randf() > (0.15 if Clock.season == 3 else 0.35):
		return false
	for i in 60:
		var c := Vector2i(randi_range(Layout.FIELD.position.x, Layout.FIELD.end.x - 1),
			randi_range(Layout.FIELD.position.y, Layout.FIELD.end.y - 1))
		if _free_for(c, 1, false):
			rocks.append({"cell": c, "size": 1, "kind": "small", "hp": 1})
			queue_redraw()
			return true
	return false


## Kerusakan satu pukulan cangkul pada batu di tile c (0 = tak berefek, mis. batu raksasa).
func strike_damage(c: Vector2i, level: int) -> int:
	var i := rock_index_at(c)
	if i < 0:
		return 0
	var kind: String = rocks[i].kind
	return 99 if kind == "small" else int(STRIKE_DAMAGE[kind][clampi(level, 0, 2)])


func strike(c: Vector2i, level: int) -> Dictionary:
	var i := rock_index_at(c)
	if i < 0:
		return {"done": false, "msg": ""}
	var r: Dictionary = rocks[i]
	var dmg := strike_damage(c, level)
	if dmg == 0:
		return {"done": false, "msg": "Cangkulmu terlalu lemah untuk batu raksasa ini. (butuh Cangkul Tembaga)"}
	r.hp -= dmg
	if r.hp > 0:
		return {"done": false, "msg": "Batu retak... (sisa %d)" % r.hp}
	rocks.remove_at(i)
	queue_redraw()
	match r.kind:
		"small":
			var n := randi_range(1, 2)
			Inventory.add("stone", n)
			return {"done": true, "msg": "Batu kecil hancur. Mendapat %d Batu." % n}
		"big":
			var n := randi_range(3, 5)
			Inventory.add("stone", n)
			var extra := ""
			if randf() < 0.4:
				var ore_n := randi_range(1, 2)
				Inventory.add("ore:tembaga", ore_n)
				extra = " dan %d Bijih Tembaga" % ore_n
			if randf() < 0.1:
				Inventory.add("ore:perak")
				extra += " + 1 Bijih Perak"
			return {"done": true, "msg": "Batu besar hancur! Mendapat %d Batu%s." % [n, extra]}
	Inventory.add("stone", 6)
	Progress.set_flag("secret_open")
	Events.story.emit("Batu raksasa runtuh! Sebuah jalan setapak terbuka di tepi timur kebun...")
	return {"done": true, "msg": "Batu raksasa hancur berkeping-keping!"}


func till(c: Vector2i) -> bool:
	if not Layout.FIELD.has_point(c) or tiles.has(c) or rock_index_at(c) >= 0:
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
	var regrow := Data.regrow_days(crop)
	if regrow > 0:
		tiles[c].age = Data.growth_days(crop) - regrow
	else:
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
	spawn_daily_rock()
	if Clock.weather == Clock.Weather.RAINY:
		for c in tiles:
			tiles[c].watered = true
	if Progress.blessing:
		Progress.blessing = false
		var grown := 0
		for c in tiles:
			var t: Dictionary = tiles[c]
			t.watered = true
			if t.crop != "" and t.age < Data.growth_days(t.crop):
				t.age += 1
				grown += 1
		Events.story.emit("Berkah Dewi Panen! Tanamanmu disiram dan tumbuh lebih cepat (%d tanaman)." % grown)
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


## Tahap pertumbuhan untuk sprite: 0 benih, 1 tunas, 2 tumbuh, 3 siap panen.
func growth_stage(crop: String, age: int) -> int:
	var days := Data.growth_days(crop)
	if age >= days:
		return 3
	var ratio := float(age) / float(days)
	return 0 if ratio < 0.25 else (1 if ratio < 0.6 else 2)


func _draw_rocks() -> void:
	var T := Layout.TILE
	for r in rocks:
		var p := Vector2(r.cell) * T
		var sheet := "rock_small" if r.kind == "small" else ("boulder_sealed" if r.kind == "sealed" else "boulder")
		var tex := Sprites.tex(sheet)
		var size: Vector2 = Vector2(T, T) * float(r.size)
		if tex != null:
			draw_texture_rect(tex, Rect2(p, size), false)
		else:
			draw_rect(Rect2(p, size).grow(-3), Color(0.55, 0.55, 0.6))


func _draw() -> void:
	var T := Layout.TILE
	_draw_rocks()
	var soil := Sprites.tex("soil")
	for c in tiles:
		var t: Dictionary = tiles[c]
		var r := Rect2(Vector2(c) * T, Vector2(T, T))
		if soil != null:
			draw_texture_rect_region(soil, r, Rect2((1 if t.watered else 0) * T, 0, T, T))
		else:
			draw_rect(r, Color(0.35, 0.22, 0.12) if t.watered else Color(0.5, 0.33, 0.18))
			draw_rect(r, Color(0, 0, 0, 0.2), false, 1.0)
		if t.crop == "":
			continue
		var days := Data.growth_days(t.crop)
		var tex := Sprites.tex("crop_" + t.crop)
		if tex != null:
			var stage := growth_stage(t.crop, t.age)
			draw_texture_rect_region(tex, Rect2(r.position + Vector2(0, T - 48), Vector2(T, 48)),
				Rect2(stage * T, 0, T, 48))
			continue
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
	var rock_out := []
	for r in rocks:
		rock_out.append({"x": r.cell.x, "y": r.cell.y, "size": r.size, "kind": r.kind, "hp": r.hp})
	return {"tiles": out, "rocks": rock_out}


func load_data(d: Dictionary) -> void:
	tiles.clear()
	if d.has("rocks"):
		rocks.clear()
		for e in d.rocks:
			rocks.append({"cell": Vector2i(int(e.x), int(e.y)), "size": int(e.size), "kind": str(e.kind), "hp": int(e.hp)})
	else:
		scatter_rocks(4242)
	for e in d.get("tiles", []):
		tiles[Vector2i(int(e.x), int(e.y))] = {
			"watered": bool(e.watered), "crop": str(e.crop), "age": int(e.age)}
	queue_redraw()
