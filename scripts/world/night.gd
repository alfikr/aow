extends Node2D
## Lapisan gelap malam dan efek cuaca di atas dunia.


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var world := get_tree().get_first_node_in_group("world") as World
	if world != null and world.is_indoor():
		return
	var size := Vector2(Layout.COLS, Layout.ROWS) * Layout.TILE
	var dark := clampf((Clock.minutes - 18 * 60) / (6 * 60), 0.0, 0.55)
	if Clock.weather != Clock.Weather.SUNNY:
		dark = maxf(dark, 0.2)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.05, 0.25, dark))
	# kolam cahaya hangat di bawah tiang lampu saat gelap
	if world != null and dark > 0.1:
		var strength := clampf((dark - 0.1) / 0.3, 0.0, 1.0)
		for p in world.light_points():
			for i in 6:
				draw_circle(p + Vector2(0, 18), 84.0 - i * 13.0, Color(1.0, 0.86, 0.45, 0.05 * strength))
			draw_circle(p, 5.0, Color(1.0, 0.95, 0.7, 0.6 * strength))
