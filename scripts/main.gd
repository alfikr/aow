extends Node2D
## Scene utama: memuat simpanan bila ada, dan menangani tombol simpan/muat.


func _ready() -> void:
	if SaveSystem.load_game():
		Events.message.emit("Game dimuat. %s" % Clock.date_text())
	else:
		Events.message.emit("Selamat datang! WASD jalan, Spasi pakai alat, E interaksi.")


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_F6:
			Events.message.emit("Game disimpan." if SaveSystem.save_game() else "Gagal menyimpan.")
		KEY_F9:
			if not SaveSystem.load_game():
				Events.message.emit("Tidak ada simpanan.")
		KEY_F10:
			SaveSystem.delete_save()
			Inventory.reset()
			Clock.load_data({})
			get_tree().reload_current_scene()
