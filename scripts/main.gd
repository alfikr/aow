extends Node2D
## Harvest Moon: Back to Nature (fan remake) - prototipe pertanian dasar.
## Semua gambar digambar lewat kode (_draw), jadi belum butuh aset.

const TILE := 32
const COLS := 30
const ROWS := 16
const HUD_H := 64

const FIELD := Rect2i(10, 3, 16, 10)   # area yang boleh dicangkul
const HOUSE := Rect2i(1, 1, 5, 3)
const HOUSE_DOOR := Vector2i(3, 4)
const BIN := Vector2i(8, 2)
const SHOP := Vector2i(8, 6)
const POND := Rect2i(27, 2, 2, 3)

const DAY_START := 6 * 60
const DAY_END := 24 * 60
const MINUTES_PER_SEC := 10.0
const MOVE_TIME := 0.14

enum Tool { HOE, WATER, SEED }
const TOOL_NAMES := ["Cangkul", "Penyiram", "Benih"]

# nama: [hari tumbuh, harga benih, harga jual, warna]
const CROPS := {
	"Lobak": [4, 20, 60, Color(0.95, 0.95, 0.85)],
	"Kentang": [6, 30, 90, Color(0.75, 0.6, 0.35)],
	"Tomat": [8, 40, 130, Color(0.9, 0.2, 0.15)],
}

var crop_names: Array = CROPS.keys()
var selected_crop := 0
var tool := Tool.HOE

var player := Vector2i(12, 14)
var facing := Vector2i(0, -1)
var draw_pos := Vector2(12, 14)
var move_cd := 0.0

var tiles := {}          # Vector2i -> {tilled, watered, crop, age}
var seeds := {"Lobak": 5, "Kentang": 0, "Tomat": 0}
var bin_items := {}      # nama -> jumlah
var held := {}           # hasil panen yang dibawa

var gold := 300
var stamina := 100.0
var water := 20
const WATER_MAX := 20

var day := 1
var minutes := float(DAY_START)
var message := "Selamat datang di peternakan! WASD/panah jalan, Spasi pakai alat."
var message_t := 6.0


func _ready() -> void:
	randomize()


func _process(delta: float) -> void:
	message_t = max(0.0, message_t - delta)
	minutes += MINUTES_PER_SEC * delta
	if minutes >= DAY_END:
		pass_out()
	move_cd = max(0.0, move_cd - delta)
	if move_cd <= 0.0:
		var dir := Vector2i(
			int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left")),
			int(Input.is_action_pressed("move_down")) - int(Input.is_action_pressed("move_up")))
		if dir.x != 0:
			dir.y = 0
		if dir != Vector2i.ZERO:
			facing = dir
			var target := player + dir
			if walkable(target):
				player = target
			move_cd = MOVE_TIME
	draw_pos = draw_pos.move_toward(Vector2(player), delta / MOVE_TIME)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: tool = Tool.HOE
			KEY_2: tool = Tool.WATER
			KEY_3: tool = Tool.SEED
			KEY_Q:
				selected_crop = (selected_crop + 1) % crop_names.size()
				tool = Tool.SEED
	if event.is_action_pressed("use_tool"):
		use_tool()
	elif event.is_action_pressed("interact"):
		interact()


# ---------------------------------------------------------------- dunia

func in_map(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < COLS and c.y < ROWS


func walkable(c: Vector2i) -> bool:
	if not in_map(c):
		return false
	if HOUSE.has_point(c) or POND.has_point(c):
		return false
	if c == BIN or c == SHOP:
		return false
	var t = tiles.get(c)
	if t != null and t.crop != "":
		return false
	return true


func front() -> Vector2i:
	return player + facing


func say(text: String) -> void:
	message = text
	message_t = 4.0


func spend_stamina(cost: float) -> bool:
	if stamina < cost:
		say("Kamu terlalu lelah. Tidurlah di rumah (E di pintu).")
		return false
	stamina -= cost
	return true


# ------------------------------------------------------------ aksi pemain

func use_tool() -> void:
	var c := front()
	if not FIELD.has_point(c):
		if tool == Tool.WATER and POND.has_point(c):
			water = WATER_MAX
			say("Penyiram terisi penuh.")
		return
	var t = tiles.get(c)
	match tool:
		Tool.HOE:
			if t == null and spend_stamina(4):
				tiles[c] = {"tilled": true, "watered": false, "crop": "", "age": 0}
			elif t != null and t.crop == "" and spend_stamina(2):
				tiles.erase(c)  # ratakan lagi
		Tool.WATER:
			if t == null or not t.tilled:
				return
			if water <= 0:
				say("Air habis. Isi ulang di kolam.")
			elif not t.watered and spend_stamina(2):
				t.watered = true
				water -= 1
		Tool.SEED:
			var crop: String = crop_names[selected_crop]
			if t == null or t.crop != "":
				return
			if seeds[crop] <= 0:
				say("Benih %s habis. Beli di toko (E)." % crop)
			elif spend_stamina(1):
				seeds[crop] -= 1
				t.crop = crop
				t.age = 0


func interact() -> void:
	var c := front()
	if c == HOUSE_DOOR or player == HOUSE_DOOR:
		sleep()
	elif c == BIN:
		ship_all()
	elif c == SHOP:
		buy_seed()
	elif POND.has_point(c):
		water = WATER_MAX
		say("Penyiram terisi penuh.")
	else:
		var t = tiles.get(c)
		if t != null and t.crop != "":
			harvest(c, t)


func harvest(c: Vector2i, t: Dictionary) -> void:
	var crop: String = t.crop
	if t.age < CROPS[crop][0]:
		say("%s belum matang (%d/%d hari)." % [crop, t.age, CROPS[crop][0]])
		return
	held[crop] = held.get(crop, 0) + 1
	t.crop = ""
	t.age = 0
	say("Panen %s! Masukkan ke kotak pengiriman (E)." % crop)


func ship_all() -> void:
	if held.is_empty():
		say("Kamu tidak membawa hasil panen.")
		return
	for k in held:
		bin_items[k] = bin_items.get(k, 0) + held[k]
	held.clear()
	say("Hasil panen dimasukkan. Dibayar saat kamu tidur.")


func buy_seed() -> void:
	var crop: String = crop_names[selected_crop]
	var price: int = CROPS[crop][1]
	if gold < price:
		say("Uang tidak cukup untuk benih %s (%dG)." % [crop, price])
		return
	gold -= price
	seeds[crop] += 1
	say("Beli benih %s (-%dG)." % [crop, price])


# --------------------------------------------------------------- waktu

func sleep() -> void:
	new_day(false)


func pass_out() -> void:
	new_day(true)


func new_day(passed_out: bool) -> void:
	var earned := 0
	for k in bin_items:
		earned += bin_items[k] * int(CROPS[k][2])
	bin_items.clear()
	gold += earned
	for c in tiles:
		var t: Dictionary = tiles[c]
		if t.crop != "" and t.watered:
			t.age += 1
		t.watered = false
	day += 1
	minutes = DAY_START
	stamina = 60.0 if passed_out else 100.0
	player = HOUSE_DOOR + Vector2i(0, 1)
	draw_pos = Vector2(player)
	say("Hari %d. Pendapatan kemarin: %dG." % [day, earned])


# ----------------------------------------------------------- gambar

func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(0, 0, COLS * TILE, ROWS * TILE), Color(0.35, 0.65, 0.3))

	# ladang
	draw_rect(Rect2(FIELD.position * TILE, FIELD.size * TILE), Color(0.3, 0.58, 0.27))
	for c in tiles:
		draw_tile(c, tiles[c], font)

	# rumah, kotak pengiriman, toko, kolam
	draw_rect(Rect2(HOUSE.position * TILE, HOUSE.size * TILE), Color(0.7, 0.45, 0.3))
	draw_rect(Rect2(HOUSE.position * TILE, Vector2(HOUSE.size.x * TILE, TILE)), Color(0.55, 0.2, 0.15))
	draw_rect(Rect2(Vector2(HOUSE_DOOR.x, HOUSE_DOOR.y - 1) * TILE, Vector2(TILE, TILE)), Color(0.35, 0.2, 0.1))
	draw_rect(Rect2(Vector2(BIN) * TILE, Vector2(TILE, TILE)), Color(0.6, 0.45, 0.2))
	draw_string(font, Vector2(BIN) * TILE + Vector2(4, 22), "Kirim", HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
	draw_rect(Rect2(Vector2(SHOP) * TILE, Vector2(TILE, TILE)), Color(0.85, 0.7, 0.2))
	draw_string(font, Vector2(SHOP) * TILE + Vector2(2, 22), "Toko", HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
	draw_rect(Rect2(POND.position * TILE, POND.size * TILE), Color(0.2, 0.45, 0.85))

	# pemain + penanda tile di depan
	var f := front()
	if in_map(f):
		draw_rect(Rect2(Vector2(f) * TILE, Vector2(TILE, TILE)), Color(1, 1, 1, 0.9), false, 2.0)
	var p := draw_pos * TILE
	draw_rect(Rect2(p + Vector2(6, 4), Vector2(20, 26)), Color(0.2, 0.35, 0.8))
	draw_circle(p + Vector2(16, 8), 7, Color(0.95, 0.8, 0.65))
	draw_circle(p + Vector2(16, 16) + Vector2(facing) * 4, 2, Color.BLACK)

	# malam
	var dark := clampf((minutes - 18 * 60) / (6 * 60), 0.0, 0.55)
	draw_rect(Rect2(0, 0, COLS * TILE, ROWS * TILE), Color(0.05, 0.05, 0.25, dark))

	draw_hud(font)


func draw_tile(c: Vector2i, t: Dictionary, font: Font) -> void:
	var r := Rect2(Vector2(c) * TILE, Vector2(TILE, TILE))
	draw_rect(r, Color(0.35, 0.22, 0.12) if t.watered else Color(0.5, 0.33, 0.18))
	draw_rect(r, Color(0, 0, 0, 0.2), false, 1.0)
	if t.crop == "":
		return
	var info: Array = CROPS[t.crop]
	var ripe: bool = t.age >= info[0]
	var growth := clampf(float(t.age) / float(info[0]), 0.0, 1.0)
	var center := r.position + Vector2(16, 20)
	draw_line(center, center + Vector2(0, -6 - 10 * growth), Color(0.15, 0.55, 0.15), 3.0)
	if ripe:
		draw_circle(center + Vector2(0, -2), 8, info[3])
	else:
		draw_circle(center + Vector2(0, -8 * growth - 6), 3 + 2 * growth, Color(0.3, 0.75, 0.3))


func draw_hud(font: Font) -> void:
	var y := ROWS * TILE
	draw_rect(Rect2(0, y, COLS * TILE, HUD_H), Color(0.12, 0.1, 0.08))
	var h := int(minutes) / 60
	var m := int(minutes) % 60
	var crop_name: String = crop_names[selected_crop]
	var line1 := "Musim Semi, Hari %d   %02d:%02d   Uang: %dG" % [day, h, m, gold]
	var line2 := "Alat: [1]%s [2]%s(air %d) [3]%s:%s x%d (Q ganti)   Stamina: %d" % [
		TOOL_NAMES[0], TOOL_NAMES[1], water, TOOL_NAMES[2], crop_name, seeds[crop_name], int(stamina)]
	draw_string(font, Vector2(10, y + 20), line1, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	draw_string(font, Vector2(10, y + 40), line2, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 0.9, 0.6))
	var carry := "Dibawa: "
	for k in held:
		carry += "%s x%d  " % [k, held[k]]
	draw_string(font, Vector2(10, y + 58), carry + "   Alat aktif: " + TOOL_NAMES[tool],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.8, 0.9, 1))
	if message_t > 0.0:
		draw_string(font, Vector2(10, 22), message, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
