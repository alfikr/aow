class_name World
extends Node2D
## Area yang sedang aktif (didefinisikan di data/areas.json): peternakan,
## desa, interior toko. Menggambar pemandangan dan menjawab pertanyaan
## "bisa dilewati?", "ada apa di tile ini?", dan "apakah ini pintu keluar?".

const SOLID_KINDS := ["building", "sleep", "bin", "water", "shop", "tree", "rock", "kitchen", "tv", "prop", "fence", "shrine", "chest"]
## Fitur yang tidak ikut menentukan "ada apa di tile ini" (hanya gambar).
const VISUAL_KINDS := ["path", "floor", "overlay"]
## Fitur datar yang digambar lebih dulu (di bawah benda tinggi).
const FLAT_KINDS := ["path", "floor", "overlay", "pier", "exit"]

var save_key := "world"
var area_id := "farm"
var area := {}
var features: Array = []   # {kind, rect: Rect2i, col: Color, raw: Dictionary}
var walk_rect := Rect2i()
var draw_list: Array = []   # urutan menggambar: benda datar dulu, lalu benda tinggi menurut baris
var has_water_anim := false
var water_phase := 0


func _ready() -> void:
	add_to_group("saveable")
	add_to_group("world")
	Events.game_loaded.connect(func():
		if area_id == "mine":
			set_area("mine")
		queue_redraw())
	Events.season_changed.connect(func(_s): queue_redraw())
	Events.world_changed.connect(queue_redraw)
	set_area(area_id)


func set_area(id: String) -> void:
	area_id = id
	if id == "mine":
		var mine := get_tree().get_first_node_in_group("mine") as Mine
		Data.areas["mine"] = mine.generate()
	area = Data.areas[id]
	var w = area.walkable
	walk_rect = Rect2i(int(w[0]), int(w[1]), int(w[2]), int(w[3]))
	features = []
	for f in area.features:
		var r = f.rect
		features.append({
			"kind": f.kind, "raw": f,
			"rect": Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3])),
			"col": Color.html(f.get("color", "888888"))})
	_rebuild_draw_list()
	var farm := get_node_or_null("../Farm")
	if farm:
		farm.visible = id == "farm"
	Events.area_changed.emit(id)
	queue_redraw()


func _is_flat(f: Dictionary) -> bool:
	return FLAT_KINDS.has(f.kind) or (f.kind == "water" and f.raw.get("tile", "") == "water")


func _rebuild_draw_list() -> void:
	var flat: Array = []
	var tall: Array = []
	has_water_anim = false
	for f in features:
		if f.kind == "water" and f.raw.get("tile", "") == "water":
			has_water_anim = true
		(flat if _is_flat(f) else tall).append(f)
	tall.sort_custom(func(a, b): return a.rect.end.y < b.rect.end.y)   # stabil: yang lebih bawah di depan
	draw_list = flat + tall


func remove_feature(f: Dictionary) -> void:
	features.erase(f)
	draw_list.erase(f)
	queue_redraw()


func _process(_delta: float) -> void:
	if has_water_anim:
		var ph := int(Time.get_ticks_msec() / 700)
		if ph != water_phase:
			water_phase = ph
			queue_redraw()


func is_indoor() -> bool:
	return bool(area.get("indoor", false))


func area_name() -> String:
	return str(area.get("name", area_id))


func in_field(c: Vector2i) -> bool:
	return area_id == "farm" and Layout.FIELD.has_point(c)


func feature_at(c: Vector2i) -> Dictionary:
	for i in range(features.size() - 1, -1, -1):
		if features[i].rect.has_point(c) and not VISUAL_KINDS.has(features[i].kind):
			return features[i]
	return {}


func exit_at(c: Vector2i) -> Dictionary:
	var f := feature_at(c)
	if f.get("kind", "") != "exit":
		return {}
	if f.raw.has("requires_flag") and not Progress.flag(str(f.raw.requires_flag)):
		return {}       # jalan rahasia belum terbuka
	return f


## Alasan pintu tidak bisa dimasuki sekarang ("" bila boleh).
func closed_reason(c: Vector2i) -> String:
	var e := exit_at(c)
	if e.is_empty() or not e.raw.has("hours"):
		return ""
	var from: int = int(e.raw.hours[0])
	var to: int = int(e.raw.hours[1])
	if Clock.minutes >= from and Clock.minutes < to:
		return ""
	return "%s tutup. Buka %02d:%02d-%02d:%02d." % [
		e.raw.get("name", "Tempat ini"), from / 60, from % 60, to / 60, to % 60]


func walkable(c: Vector2i) -> bool:
	if not walk_rect.has_point(c):
		return false
	var f := feature_at(c)
	return not SOLID_KINDS.has(f.get("kind", ""))


## Kotak tujuan sprite: "native" = ukuran asli, rata tengah-bawah rect; selain itu dibentang pas rect.
func sprite_dest(f: Dictionary, tex: Texture2D) -> Rect2:
	var r := Rect2(f.rect.position * Layout.TILE, f.rect.size * Layout.TILE)
	if not f.raw.get("native", false):
		return r
	var sz := tex.get_size()
	return Rect2(Vector2(r.position.x + (r.size.x - sz.x) / 2.0, r.end.y - sz.y), sz)


## Pusat cahaya lampu (untuk efek malam) pada area aktif.
func light_points() -> Array:
	var out := []
	for f in features:
		if f.raw.get("light", false):
			var tex := Sprites.tex(str(f.raw.get("sprite", "")))
			if tex != null:
				var d := sprite_dest(f, tex)
				out.append(d.position + Vector2(d.size.x / 2.0, 14.0))
	return out


func _draw() -> void:
	var T := Layout.TILE
	var font := ThemeDB.fallback_font
	var full := Rect2(0, 0, Layout.COLS * T, Layout.ROWS * T)
	var ground_name := str(area.get("ground_tile", ""))
	var ground_tex := Sprites.tex(ground_name) if ground_name == "grass_forest" else Sprites.tex_season(ground_name)
	if ground_tex != null:
		draw_texture_rect(ground_tex, full, true)
	else:
		draw_rect(full, Color.html(area.get("ground", "59a64d")))
	if area_id == "farm":
		var field := Rect2(Layout.FIELD.position * T, Layout.FIELD.size * T)
		var field_tex := Sprites.tex_season("grass_field")
		if field_tex != null:
			draw_texture_rect(field_tex, field, true)
		else:
			draw_rect(field, Color(0.3, 0.58, 0.27))
	for f in draw_list:
		_draw_feature(f, font)


func _draw_feature(f: Dictionary, font: Font) -> void:
	var T := Layout.TILE
	var r := Rect2(f.rect.position * T, f.rect.size * T)
	var raw: Dictionary = f.raw
	# hiasan musiman; bunga hanya di musim semi dan panas
	if raw.has("season") and int(raw.season) != Clock.season:
		return
	if raw.has("requires_flag") and not Progress.flag(str(raw.requires_flag)):
		return
	if f.kind == "forage" and Progress.forage_taken.has("%d,%d" % [f.rect.position.x, f.rect.position.y]):
		return
	if f.kind == "overlay" and str(raw.get("sprite", "")).begins_with("flowers") and Clock.season >= 2:
		return
	if f.kind == "water" and raw.get("tile", "") == "water" and Sprites.tex("water") != null:
		_draw_water(r, bool(raw.get("season_fixed", false)))
		return
	var name: String = raw.get("sprite", raw.get("tile", ""))
	if raw.has("flag") and raw.has("sprite_done") and Progress.flag(str(raw.flag)):
		name = str(raw.sprite_done)          # mis. peti yang sudah dibuka
	var fixed: bool = raw.get("season_fixed", false)
	var tex := (Sprites.tex(name) if fixed else Sprites.tex_season(name)) if name != "" else null
	if tex != null:
		if raw.has("tile"):
			draw_texture_rect(tex, r, true)
			if f.kind == "path":
				_draw_path_edges(f, r)
		else:
			draw_texture_rect(tex, sprite_dest(f, tex), false)
			if raw.has("sign"):
				var d := sprite_dest(f, tex)
				draw_string(font, d.position + Vector2(2, 17), str(raw.sign), HORIZONTAL_ALIGNMENT_CENTER, 44,
					10 if str(raw.sign).length() <= 5 else 8,
					Color(0.28, 0.16, 0.08))
		return
	match f.kind:
		"tree":
			draw_rect(Rect2(r.position + Vector2(13, 18), Vector2(6, 12)), Color(0.4, 0.26, 0.12))
			draw_circle(r.position + Vector2(16, 14), 13, Color(0.13, 0.42, 0.18))
		"rock":
			draw_rect(r.grow(-2), f.col)
			draw_rect(r.grow(-2), Color(0, 0, 0, 0.25), false, 2.0)
			var ore: String = raw.get("ore", "")
			if ore != "":
				var oc: Color = {"tembaga": Color(0.72, 0.45, 0.2), "perak": Color(0.85, 0.85, 0.92), "emas": Color(0.95, 0.8, 0.1)}[ore]
				draw_circle(r.position + Vector2(11, 12), 4, oc)
				draw_circle(r.position + Vector2(20, 19), 3, oc)
		"building":
			draw_rect(r, f.col)
			draw_rect(Rect2(r.position, Vector2(r.size.x, T)), f.col.darkened(0.35))
			_label(font, r.position + Vector2(6, 20), raw.get("label", ""))
		"overlay":
			pass
		_:
			draw_rect(r, f.col)
			if f.kind == "exit" and f.col.a > 0.0:
				draw_rect(r, Color(0, 0, 0, 0.25), false, 2.0)
			_label(font, r.position + Vector2(4, 20), raw.get("label", ""))


## Air dua bingkai yang bergantian per tile + busa tipis di tepi.
func _draw_water(r: Rect2, fixed := false) -> void:
	var T := Layout.TILE
	var tex := Sprites.tex("water") if fixed else Sprites.tex_season("water")
	for x in int(r.size.x / T):
		for y in int(r.size.y / T):
			var frame := (water_phase + x + y) % 2
			draw_texture_rect_region(tex, Rect2(r.position + Vector2(x, y) * T, Vector2(T, T)),
				Rect2(frame * T, 0, T, T))
	draw_rect(r, Color(1, 1, 1, 0.35), false, 3.0)


## Garis tepi tipis pada jalan agar terpisah dari rumput (tidak di tepi peta).
func _draw_path_edges(f: Dictionary, r: Rect2) -> void:
	var T := Layout.TILE
	var col := Color(0.42, 0.3, 0.14, 0.55)
	if f.rect.position.y > 0:
		draw_line(r.position + Vector2(0, 1), Vector2(r.end.x, r.position.y + 1), col, 2.0)
	if f.rect.end.y < Layout.ROWS:
		draw_line(Vector2(r.position.x, r.end.y - 1), r.end - Vector2(0, 1), col, 2.0)
	if f.rect.position.x > 0:
		draw_line(r.position + Vector2(1, 0), Vector2(r.position.x + 1, r.end.y), col, 2.0)
	if f.rect.end.x < Layout.COLS:
		draw_line(Vector2(r.end.x - 1, r.position.y), r.end - Vector2(1, 0), col, 2.0)


func _label(font: Font, pos: Vector2, text: String) -> void:
	if text != "":
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.95))


func save_data() -> Dictionary:
	return {"area": area_id}


func load_data(d: Dictionary) -> void:
	var id: String = str(d.get("area", "farm"))
	set_area(id if Data.areas.has(id) else "farm")
