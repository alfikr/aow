class_name Overhead
extends Node2D
## Menggambar bagian atas benda tinggi (tajuk pohon, kepala lampu) DI ATAS
## karakter, sehingga pemain yang lewat di belakang pohon tertutup tajuknya.

@onready var world: World = $"../World"


func _ready() -> void:
	Events.area_changed.connect(func(_id): queue_redraw())
	Events.game_loaded.connect(queue_redraw)
	Events.season_changed.connect(func(_s): queue_redraw())


func _draw() -> void:
	var T := Layout.TILE
	for f in world.draw_list:
		if not f.raw.get("overhead", false):
			continue
		var tex := Sprites.tex_season(str(f.raw.get("sprite", "")))
		if tex == null:
			continue
		var d := world.sprite_dest(f, tex)
		var h := d.size.y - T            # semua di atas tile dasar
		if h <= 0.0:
			continue
		draw_texture_rect_region(tex, Rect2(d.position, Vector2(d.size.x, h)), Rect2(0, 0, d.size.x, h))
