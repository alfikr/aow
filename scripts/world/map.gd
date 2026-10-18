extends Node2D
## Pemandangan statis peternakan (placeholder berbentuk kotak).


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var T := Layout.TILE
	draw_rect(Rect2(0, 0, Layout.COLS * T, Layout.ROWS * T), Color(0.35, 0.65, 0.3))
	draw_rect(Rect2(Layout.FIELD.position * T, Layout.FIELD.size * T), Color(0.3, 0.58, 0.27))

	draw_rect(Rect2(Layout.HOUSE.position * T, Layout.HOUSE.size * T), Color(0.7, 0.45, 0.3))
	draw_rect(Rect2(Layout.HOUSE.position * T, Vector2(Layout.HOUSE.size.x * T, T)), Color(0.55, 0.2, 0.15))
	draw_rect(Rect2(Vector2(Layout.HOUSE_DOOR.x, Layout.HOUSE_DOOR.y - 1) * T, Vector2(T, T)), Color(0.35, 0.2, 0.1))
	draw_rect(Rect2(Vector2(Layout.BIN) * T, Vector2(T, T)), Color(0.6, 0.45, 0.2))
	draw_string(font, Vector2(Layout.BIN) * T + Vector2(4, 22), "Kirim", HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
	draw_rect(Rect2(Vector2(Layout.SHOP) * T, Vector2(T, T)), Color(0.85, 0.7, 0.2))
	draw_string(font, Vector2(Layout.SHOP) * T + Vector2(2, 22), "Toko", HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
	draw_rect(Rect2(Layout.POND.position * T, Layout.POND.size * T), Color(0.2, 0.45, 0.85))
