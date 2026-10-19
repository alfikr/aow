extends Control
## HUD bawah + pesan sementara.

var text := ""
var text_t := 0.0
var queue: Array = []   # cerita yang menunggu giliran tampil


func _ready() -> void:
	Events.message.connect(func(t: String): text = t; text_t = 4.0)
	Events.story.connect(func(t: String): queue.append(t))
	Events.day_started.connect(_on_day_started)


func _on_day_started(_passed_out: bool) -> void:
	var msg := "%s. Pendapatan kemarin: %dG." % [Clock.date_text(), Inventory.last_earned]
	var fest := Clock.festival()
	if not fest.is_empty():
		msg = "%s hari ini! Harga jual +%d%%." % [fest.name, roundi(float(fest.sell_bonus) * 100)]
	text = msg
	text_t = 4.0


func _process(delta: float) -> void:
	text_t = maxf(0.0, text_t - delta)
	if text_t <= 0.0 and not queue.is_empty():
		text = queue.pop_front()
		text_t = 5.0
	queue_redraw()


func _draw() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	var font := ThemeDB.fallback_font
	var y := Layout.ROWS * Layout.TILE
	draw_rect(Rect2(0, y, Layout.COLS * Layout.TILE, Layout.HUD_H), Color(0.12, 0.1, 0.08))

	var crop := player.crop_id()
	var world := get_tree().get_first_node_in_group("world") as World
	var line1 := "%s  %s  %s  [%s]   Uang: %dG" % [
		Clock.date_text(), Clock.time_text(), Clock.WEATHER_NAMES[Clock.weather],
		world.area_name() if world else "", Inventory.gold]
	var line2 := "Alat: [1]Cangkul [2]Penyiram(air %d/%d) [3]Benih:%s x%d (Q ganti)   Stamina: %d" % [
		player.water, Inventory.water_max(), Data.crop_name(crop), Inventory.count(Inventory.seed_id(crop)), int(player.stamina)]
	var carry := "Dibawa: "
	for id in Inventory.items:
		if not str(id).begins_with("seed:"):
			carry += "%s x%d  " % [Data.item_name(str(id)), Inventory.items[id]]
	draw_string(font, Vector2(10, y + 20), line1, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	draw_string(font, Vector2(10, y + 40), line2, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 0.9, 0.6))
	draw_string(font, Vector2(10, y + 58),
		"%s   Alat aktif: %s   [I inventori, F6/F9/F10]" % [carry, Player.TOOL_NAMES[player.tool]],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.8, 0.9, 1))
	if text_t > 0.0:
		draw_rect(Rect2(0, 0, Layout.COLS * Layout.TILE, 30 + 18 * (text.length() / 100)), Color(0, 0, 0, 0.45))
		draw_multiline_string(font, Vector2(10, 22), text, HORIZONTAL_ALIGNMENT_LEFT, 930, 16, -1, Color.WHITE)
