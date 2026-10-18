extends Node2D
## Lapisan gelap malam dan efek cuaca di atas dunia.


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var size := Vector2(Layout.COLS, Layout.ROWS) * Layout.TILE
	var dark := clampf((Clock.minutes - 18 * 60) / (6 * 60), 0.0, 0.55)
	if Clock.weather != Clock.Weather.SUNNY:
		dark = maxf(dark, 0.2)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.05, 0.25, dark))
