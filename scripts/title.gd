extends Control
## Menu judul: Lanjutkan / Game Baru / Pengaturan / Bantuan / Keluar.

const MAIN_SCENE := "res://scenes/main.tscn"

@onready var menu: Control = $Menu

var entries: Array = []
var cursor := 0


func _ready() -> void:
	menu.allow_pause = false
	menu.closed.connect(queue_redraw)
	Audio.auto_music = false
	Audio.set_track("music_day")
	_build()


func _exit_tree() -> void:
	Audio.auto_music = true


func _build() -> void:
	entries = []
	if SaveSystem.has_save():
		entries.append({"label": "Lanjutkan", "kind": "continue"})
	entries.append({"label": "Game Baru", "kind": "new"})
	entries.append({"label": "Pengaturan", "kind": "settings"})
	entries.append({"label": "Bantuan", "kind": "help"})
	entries.append({"label": "Keluar", "kind": "quit"})
	cursor = 0
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if menu.mode != menu.Mode.NONE or not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_UP, KEY_W:
			cursor = maxi(cursor - 1, 0)
			Events.sfx.emit("select")
		KEY_DOWN, KEY_S:
			cursor = mini(cursor + 1, entries.size() - 1)
			Events.sfx.emit("select")
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_activate(entries[cursor].kind)
	queue_redraw()


func _activate(kind: String) -> void:
	match kind:
		"continue":
			get_tree().change_scene_to_file(MAIN_SCENE)
		"new":
			SaveSystem.delete_save()
			Inventory.reset()
			Progress.reset()
			Clock.load_data({})
			get_tree().change_scene_to_file(MAIN_SCENE)
		"settings":
			menu.open(menu.Mode.SETTINGS)
		"help":
			menu.open(menu.Mode.HELP)
		"quit":
			get_tree().quit()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h * 0.62), Color(0.55, 0.78, 0.95))
	draw_rect(Rect2(0, h * 0.62, w, h * 0.38), Color(0.35, 0.65, 0.3))
	draw_circle(Vector2(w * 0.82, h * 0.2), 46, Color(1, 0.92, 0.55))
	draw_colored_polygon(PackedVector2Array([Vector2(0, h * 0.62), Vector2(w * 0.22, h * 0.42), Vector2(w * 0.5, h * 0.62)]), Color(0.45, 0.62, 0.5))
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.35, h * 0.62), Vector2(w * 0.65, h * 0.38), Vector2(w, h * 0.62)]), Color(0.38, 0.55, 0.45))
	for i in 7:
		draw_rect(Rect2(60 + i * 128, h * 0.78 + (i % 2) * 14, 90, 10), Color(0.5, 0.33, 0.18))
	draw_rect(Rect2(w * 0.08, h * 0.5, 120, 80), Color(0.72, 0.46, 0.3))
	draw_rect(Rect2(w * 0.08, h * 0.5, 120, 24), Color(0.55, 0.2, 0.15))

	draw_string(font, Vector2(0, 110), "Lembah Panen", HORIZONTAL_ALIGNMENT_CENTER, w, 56, Color(0.2, 0.15, 0.08))
	draw_string(font, Vector2(0, 112), "Lembah Panen", HORIZONTAL_ALIGNMENT_CENTER, w, 56, Color(1, 0.95, 0.75))
	draw_string(font, Vector2(0, 144), "terinspirasi dari Harvest Moon: Back to Nature (proyek penggemar)", HORIZONTAL_ALIGNMENT_CENTER, w, 14, Color(0.15, 0.15, 0.2))

	if menu.mode != menu.Mode.NONE:
		return
	var y := h * 0.36
	for i in entries.size():
		var selected := i == cursor
		if selected:
			draw_rect(Rect2(w * 0.5 - 150, y - 24, 300, 36), Color(0.4, 0.3, 0.15, 0.9))
		draw_string(font, Vector2(0, y), entries[i].label, HORIZONTAL_ALIGNMENT_CENTER, w, 24,
			Color.WHITE if selected else Color(0.15, 0.12, 0.08))
		y += 42
	draw_string(font, Vector2(0, h - 14), "W/S pilih   Enter konfirmasi", HORIZONTAL_ALIGNMENT_CENTER, w, 13, Color(1, 1, 1, 0.9))
