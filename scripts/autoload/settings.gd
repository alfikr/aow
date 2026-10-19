extends Node
## Pengaturan pemain (volume, layar penuh), disimpan di user://settings.cfg.

const PATH := "user://settings.cfg"
const BUSES := {"master": "Master", "music": "Music", "sfx": "SFX"}

var volumes := {"master": 8, "music": 6, "sfx": 8}   # 0-10
var fullscreen := false


func _ready() -> void:
	load_settings()
	apply()


func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	for k in volumes:
		volumes[k] = clampi(int(cf.get_value("audio", k, volumes[k])), 0, 10)
	fullscreen = bool(cf.get_value("video", "fullscreen", false))


func save_settings() -> void:
	var cf := ConfigFile.new()
	for k in volumes:
		cf.set_value("audio", k, volumes[k])
	cf.set_value("video", "fullscreen", fullscreen)
	cf.save(PATH)


func adjust(key: String, delta: int) -> void:
	volumes[key] = clampi(volumes[key] + delta, 0, 10)
	apply()
	save_settings()


func toggle_fullscreen() -> void:
	fullscreen = not fullscreen
	apply()
	save_settings()


func apply() -> void:
	for k in BUSES:
		var idx := AudioServer.get_bus_index(BUSES[k])
		if idx >= 0:
			var v: int = volumes[k]
			AudioServer.set_bus_volume_db(idx, -80.0 if v == 0 else linear_to_db(v / 10.0))
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		toggle_fullscreen()
