extends Node2D
## Scene utama: memuat simpanan bila ada, dan tombol cepat simpan/muat.


func _ready() -> void:
	if SaveSystem.load_game():
		Events.message.emit("Game dimuat. %s" % Clock.date_text())
	else:
		Events.message.emit("Selamat datang! WASD jalan, Spasi pakai alat, E interaksi, Esc menu.")


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_F6:
			Events.message.emit("Game disimpan." if SaveSystem.save_game() else "Gagal menyimpan.")
		KEY_F9:
			if not SaveSystem.load_game():
				Events.message.emit("Tidak ada simpanan.")
