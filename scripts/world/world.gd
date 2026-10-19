class_name World
extends Node2D
## Area yang sedang aktif (didefinisikan di data/areas.json): peternakan,
## desa, interior toko. Menggambar pemandangan dan menjawab pertanyaan
## "bisa dilewati?", "ada apa di tile ini?", dan "apakah ini pintu keluar?".

const SOLID_KINDS := ["building", "sleep", "bin", "water", "shop", "tree", "rock", "kitchen", "tv"]

var save_key := "world"
var area_id := "farm"
var area := {}
var features: Array = []   # {kind, rect: Rect2i, col: Color, raw: Dictionary}
var walk_rect := Rect2i()
var textures := {}   # nama sprite -> Texture2D (atau null bila berkasnya belum ada)


func _ready() -> void:
	add_to_group("saveable")
	add_to_group("world")
	Events.game_loaded.connect(func(): if area_id == "mine": set_area("mine"))
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
	var farm := get_node_or_null("../Farm")
	if farm:
		farm.visible = id == "farm"
	Events.area_changed.emit(id)
	queue_redraw()


func remove_feature(f: Dictionary) -> void:
	features.erase(f)
	queue_redraw()


func is_indoor() -> bool:
	return bool(area.get("indoor", false))


func area_name() -> String:
	return str(area.get("name", area_id))


func in_field(c: Vector2i) -> bool:
	return area_id == "farm" and Layout.FIELD.has_point(c)


func feature_at(c: Vector2i) -> Dictionary:
	for i in range(features.size() - 1, -1, -1):
		if features[i].rect.has_point(c) and features[i].kind != "path" and features[i].kind != "floor":
			return features[i]
	return {}


func exit_at(c: Vector2i) -> Dictionary:
	var f := feature_at(c)
	return f if f.get("kind", "") == "exit" else {}


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


func _draw() -> void:
	var T := Layout.TILE
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(0, 0, Layout.COLS * T, Layout.ROWS * T), Color.html(area.get("ground", "59a64d")))
	if area_id == "farm":
		draw_rect(Rect2(Layout.FIELD.position * T, Layout.FIELD.size * T), Color(0.3, 0.58, 0.27))
	for f in features:
		var r := Rect2(f.rect.position * T, f.rect.size * T)
		var tex := _sprite_for(f)
		if tex != null:
			draw_texture_rect(tex, r, f.raw.has("tile"))
			continue
		match f.kind:
			"tree":
				draw_rect(Rect2(r.position + Vector2(13, 18), Vector2(6, 12)), Color(0.4, 0.26, 0.12))
				draw_circle(r.position + Vector2(16, 14), 13, Color(0.13, 0.42, 0.18))
			"rock":
				draw_rect(r.grow(-2), f.col)
				draw_rect(r.grow(-2), Color(0, 0, 0, 0.25), false, 2.0)
				var ore: String = f.raw.get("ore", "")
				if ore != "":
					var oc: Color = {"tembaga": Color(0.72, 0.45, 0.2), "perak": Color(0.85, 0.85, 0.92), "emas": Color(0.95, 0.8, 0.1)}[ore]
					draw_circle(r.position + Vector2(11, 12), 4, oc)
					draw_circle(r.position + Vector2(20, 19), 3, oc)
			"building":
				draw_rect(r, f.col)
				draw_rect(Rect2(r.position, Vector2(r.size.x, T)), f.col.darkened(0.35))
				_label(font, r.position + Vector2(6, 20), f.raw.get("label", ""))
			_:
				draw_rect(r, f.col)
				if f.kind == "exit" and f.col.a > 0.0:
					draw_rect(r, Color(0, 0, 0, 0.25), false, 2.0)
				_label(font, r.position + Vector2(4, 20), f.raw.get("label", ""))


## Sprite untuk fitur ("sprite": bentang pas rect; "tile": diulang), atau null.
func _sprite_for(f: Dictionary) -> Texture2D:
	var name: String = f.raw.get("sprite", f.raw.get("tile", ""))
	if name == "":
		return null
	if not textures.has(name):
		var path := "res://assets/sprites/%s.png" % name
		textures[name] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return textures[name]


func _label(font: Font, pos: Vector2, text: String) -> void:
	if text != "":
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.95))


func save_data() -> Dictionary:
	return {"area": area_id}


func load_data(d: Dictionary) -> void:
	var id: String = str(d.get("area", "farm"))
	set_area(id if Data.areas.has(id) else "farm")
