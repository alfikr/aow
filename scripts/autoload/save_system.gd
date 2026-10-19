extends Node
## Simpan/muat satu file JSON. Node di grup "saveable" menyediakan
## save_key, save_data(), dan load_data(dict).

var path := "user://save.json"


func _ready() -> void:
	# deferred: biarkan semua penangan day_started selesai dulu
	Events.day_started.connect(func(_p): save_game.call_deferred())


func has_save() -> bool:
	return FileAccess.file_exists(path)


func save_game() -> bool:
	var data := {"version": 1, "clock": Clock.save_data(), "inventory": Inventory.save_data(),
		"progress": Progress.save_data()}
	for n in get_tree().get_nodes_in_group("saveable"):
		data[n.save_key] = n.save_data()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data))
	return true


func load_game() -> bool:
	if not has_save():
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	Clock.load_data(parsed.get("clock", {}))
	Inventory.load_data(parsed.get("inventory", {}))
	Progress.load_data(parsed.get("progress", {}))
	for n in get_tree().get_nodes_in_group("saveable"):
		if parsed.has(n.save_key):
			n.load_data(parsed[n.save_key])
	Events.game_loaded.emit()
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
