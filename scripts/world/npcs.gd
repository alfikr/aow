class_name Npcs
extends Node2D
## Warga desa: jadwal harian, dialog, hadiah, hubungan, dan event hati.
## state[id] = {friend, talked, gifted, seen}; where/goal = posisi runtime.

const STEP_TIME := 0.25
const MAX_FRIEND := 1000
const MARRY_HEARTS := 8
const TASTE_DELTA := {"love": 80, "like": 45, "neutral": 20, "hate": -40}
const DIRS := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const SEASON_KEYS := ["semi", "panas", "gugur", "dingin"]

@onready var world: World = $"../World"

var save_key := "npcs"
var state := {}
var where := {}
var goal := {}
var step_t := 0.0
var vis := {}   # id -> {pos, area, facing, moving} (animasi, runtime)


func _ready() -> void:
	add_to_group("saveable")
	add_to_group("npcs")
	for id in Data.npcs:
		state[id] = _fresh()
	Events.day_started.connect(_on_day_started)
	Events.game_loaded.connect(snap_all)
	snap_all()


func _fresh() -> Dictionary:
	return {"friend": 0, "talked": false, "gifted": false, "seen": []}


func hearts(id: String) -> int:
	return int(state[id].friend) / 100


func npc_name(id: String) -> String:
	return str(Data.npcs[id].name)


# ------------------------------------------------------------- jadwal

func _matches(e: Dictionary, minutes: float, weekday: int) -> bool:
	if minutes < float(e.from) or minutes >= float(e.to):
		return false
	if e.has("days"):
		for d in e.days:
			if int(d) == weekday:
				return true
		return false
	return true


func _target(e: Dictionary) -> Dictionary:
	return {"area": str(e.area), "cell": Vector2i(int(e.cell[0]), int(e.cell[1]))}


## Di mana NPC seharusnya berada pada waktu tertentu.
func schedule_target(id: String, minutes: float, weekday: int, rainy: bool) -> Dictionary:
	var entries: Array = Data.spouse_schedule if Progress.spouse == id else Data.npcs[id].schedule
	if rainy:
		for e in entries:
			if e.get("rain", false) and _matches(e, minutes, weekday):
				return _target(e)
	for e in entries:
		if not e.get("rain", false) and _matches(e, minutes, weekday):
			return _target(e)
	return _target(entries[0])


func current_goal(id: String) -> Dictionary:
	return schedule_target(id, Clock.minutes, Clock.weekday(), Clock.weather != Clock.Weather.SUNNY)


func snap_all() -> void:
	for id in Data.npcs:
		where[id] = current_goal(id)
		goal[id] = where[id]
		vis.erase(id)


func npc_at(area_id: String, c: Vector2i) -> String:
	for id in where:
		if where[id].area == area_id and where[id].cell == c:
			return id
	return ""


# --------------------------------------------------------------- gerak

func _process(delta: float) -> void:
	for id in Data.npcs:
		goal[id] = current_goal(id)
	_animate(delta)
	step_t += delta
	if step_t >= STEP_TIME:
		step_t = 0.0
		for id in Data.npcs:
			_advance(id)
	queue_redraw()


## Geser posisi gambar menuju tile tujuan dan tentukan arah hadap.
func _animate(delta: float) -> void:
	for id in where:
		var w: Dictionary = where[id]
		var target := Vector2(w.cell * Layout.TILE)
		if not vis.has(id) or vis[id].area != w.area:
			vis[id] = {"pos": target, "area": w.area, "moving": false,
				"facing": vis[id].facing if vis.has(id) else Vector2i.DOWN}
			continue
		var v: Dictionary = vis[id]
		var d: Vector2 = target - v.pos
		if d.length() > 0.5:
			v.facing = Vector2i(int(signf(d.x)), 0) if absf(d.x) >= absf(d.y) else Vector2i(0, int(signf(d.y)))
			v.pos = v.pos.move_toward(target, Layout.TILE / STEP_TIME * delta)
			v.moving = true
		else:
			v.pos = target
			v.moving = false


## NPC menoleh ke pemain saat diajak bicara.
func face_towards(id: String, from_cell: Vector2i) -> void:
	if not vis.has(id):
		return
	var d: Vector2i = from_cell - where[id].cell
	vis[id].facing = Vector2i(signi(d.x), 0) if absi(d.x) >= absi(d.y) else Vector2i(0, signi(d.y))


func _advance(id: String) -> void:
	var cur: Dictionary = where[id]
	var g: Dictionary = goal[id]
	if cur.area == g.area and cur.cell == g.cell:
		return
	if cur.area != g.area or world.area_id != cur.area:
		where[id] = g.duplicate()
		return
	var nxt := _next_step(cur.cell, g.cell)
	if nxt == cur.cell:
		where[id] = g.duplicate()   # tak ada jalur: langsung pindah
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if (player != null and player.cell == nxt) or npc_at(cur.area, nxt) != "":
		return                       # terhalang, tunggu
	where[id].cell = nxt


func _next_step(from: Vector2i, to: Vector2i) -> Vector2i:
	var prev := {from: from}
	var queue := [from]
	var qi := 0
	while qi < queue.size():
		var c: Vector2i = queue[qi]
		qi += 1
		if c == to:
			break
		for d in DIRS:
			var n: Vector2i = c + d
			if prev.has(n) or not (world.walkable(n) or n == to):
				continue
			prev[n] = c
			queue.append(n)
	if not prev.has(to) or from == to:
		return from
	var c := to
	while prev[c] != from:
		c = prev[c]
	return c


func _on_day_started(_passed_out: bool) -> void:
	for id in state:
		state[id].talked = false
		state[id].gifted = false
	snap_all()
	for id in Data.npcs:
		var b: Array = Data.npcs[id].birthday
		if int(b[0]) == Clock.season and int(b[1]) == Clock.day:
			Events.story.emit("Hari ini ulang tahun %s! Hadiah akan sangat dihargai." % npc_name(id))


# ---------------------------------------------------------- interaksi

func _pick_line(id: String) -> String:
	var lines: Dictionary = Data.npcs[id].lines
	var pool: Array = []
	pool.append_array(lines.get("default", []))
	pool.append_array(lines.get(SEASON_KEYS[Clock.season], []))
	if Clock.weather != Clock.Weather.SUNNY:
		pool.append_array(lines.get("rain", []))
		pool.append_array(lines.get("rain", []))
	if not Clock.festival().is_empty():
		pool.append_array(lines.get("festival", []))
		pool.append_array(lines.get("festival", []))
	if hearts(id) >= 4:
		pool.append_array(lines.get("h4", []))
	if hearts(id) >= 8:
		pool.append_array(lines.get("h8", []))
	if Progress.spouse == id:
		for i in 4:
			pool.append_array(lines.get("spouse", []))
	return "%s: %s" % [npc_name(id), pool.pick_random()]


## Mengembalikan halaman-halaman teks percakapan.
func talk(id: String) -> Array:
	var st: Dictionary = state[id]
	var first: bool = not st.talked
	st.talked = true
	if first:
		st.friend = mini(MAX_FRIEND, st.friend + 10)
	for ev in Data.npcs[id].get("events", []):
		if not st.seen.has(ev.id) and hearts(id) >= int(ev.hearts):
			st.seen.append(ev.id)
			var pages: Array = ev.lines.duplicate()
			_apply_reward(ev.get("reward", {}))
			return pages
	return [_pick_line(id)]


func _apply_reward(r: Dictionary) -> void:
	if r.has("recipe"):
		Progress.unlock_recipe(str(r.recipe))
	if r.has("gold"):
		Inventory.gold += int(r.gold)
	if r.has("item"):
		Inventory.add(str(r.item), int(r.get("n", 1)))


func taste_of(id: String, item: String) -> String:
	var info: Dictionary = Data.npcs[id]
	if info.loves.has(item):
		return "love"
	if info.likes.has(item):
		return "like"
	if info.hates.has(item):
		return "hate"
	return "neutral"


func is_birthday(id: String) -> bool:
	var b: Array = Data.npcs[id].birthday
	return int(b[0]) == Clock.season and int(b[1]) == Clock.day


func gift(id: String, item: String) -> String:
	var st: Dictionary = state[id]
	var info: Dictionary = Data.npcs[id]
	if Inventory.count(item) <= 0:
		return "Kamu tidak punya barang itu."
	if item == "gift:bulu_biru":
		return _propose(id)
	if st.gifted:
		return "%s sudah menerima hadiah hari ini." % npc_name(id)
	var taste := taste_of(id, item)
	var delta: int = TASTE_DELTA[taste]
	if delta > 0 and is_birthday(id):
		delta *= 4
	Inventory.remove(item)
	st.gifted = true
	st.friend = clampi(st.friend + delta, 0, MAX_FRIEND)
	Progress.bump("gifts")
	var extra := "  (ulang tahun! kasih sayang +%d)" % delta if is_birthday(id) and delta > 0 else ""
	return "%s: %s%s" % [npc_name(id), info.reactions[taste], extra]


func _propose(id: String) -> String:
	var info: Dictionary = Data.npcs[id]
	if not info.get("romance", false):
		return "%s tersenyum canggung. \"Hadiah ini terlalu istimewa untukku.\"" % npc_name(id)
	if Progress.spouse != "" or Progress.fiance != "":
		return "Kamu sudah terikat dengan seseorang."
	if hearts(id) < MARRY_HEARTS:
		return "%s: \"Aku belum cukup mengenalmu... mungkin nanti.\" (butuh %d hati)" % [npc_name(id), MARRY_HEARTS]
	Inventory.remove("gift:bulu_biru")
	Progress.fiance = id
	return "%s menerima Bulu Biru dengan mata berkaca-kaca. \"Ya, aku mau!\" Pernikahan besok pagi!" % npc_name(id)


# -------------------------------------------------------------- gambar

func _draw() -> void:
	var font := ThemeDB.fallback_font
	for id in where:
		if where[id].area != world.area_id or not vis.has(id):
			continue
		var info: Dictionary = Data.npcs[id]
		var v: Dictionary = vis[id]
		var p: Vector2 = v.pos
		if not Sprites.draw_char(self, "char_" + id, p, v.facing, Sprites.walk_frame(v.moving)):
			draw_rect(Rect2(p + Vector2(7, 12), Vector2(18, 18)), Color.html(info.color))
			draw_circle(p + Vector2(16, 9), 7, Color(0.96, 0.82, 0.68))
			draw_rect(Rect2(p + Vector2(9, 1), Vector2(14, 5)), Color.html(info.hair))
		draw_string(font, p + Vector2(-32, -20), info.name, HORIZONTAL_ALIGNMENT_CENTER, 96, 10, Color(1, 1, 1, 0.95))


func save_data() -> Dictionary:
	return {"state": state}


func load_data(d: Dictionary) -> void:
	for id in d.get("state", {}):
		if not state.has(id):
			continue
		var s: Dictionary = d.state[id]
		state[id] = {"friend": int(s.get("friend", 0)), "talked": bool(s.get("talked", false)),
			"gifted": bool(s.get("gifted", false)), "seen": s.get("seen", []).map(func(x): return str(x))}
