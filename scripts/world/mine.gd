class_name Mine
extends Node
## Tambang 10 lantai. Tata letak dibangkitkan dari seed (hari, lantai) sehingga
## konsisten dalam satu hari; batu yang sudah dipecahkan dicatat di `broken`.

const MAX_FLOOR := 10
const STAMINA_COST := 3.0
const SPAWN := Vector2i(14, 12)

var save_key := "mine"
var floor_n := 1
var broken := {}   # "lantai:x,y" -> true (reset tiap hari)
var damage := {}   # batu besar: "lantai:x,y" -> kerusakan terkumpul (reset tiap hari)
const BIG_HP := 3
const BIG_DAMAGE := [1, 2, 3]   # per level cangkul


func _ready() -> void:
	add_to_group("saveable")
	add_to_group("mine")
	Events.day_started.connect(func(_p):
		broken.clear()
		damage.clear())


func _ore_for_floor(rng: RandomNumberGenerator) -> String:
	var r := rng.randf()
	if floor_n <= 3:
		return "tembaga"
	if floor_n <= 6:
		return "perak" if r < 0.7 else "tembaga"
	return "emas" if r < 0.5 else "perak"


func _key(c: Vector2i) -> String:
	return "%d:%d,%d" % [floor_n, c.x, c.y]


## Membangun definisi area "mine" untuk lantai saat ini.
func generate() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([Clock.total_days(), floor_n])
	var shade := Color(0.2, 0.2, 0.24).darkened(0.05 * (floor_n - 1))
	var feats: Array = [{"kind": "floor", "rect": [2, 2, 26, 12], "color": shade.to_html(false), "tile": "floor_cave"}]
	var stairs := Vector2i(rng.randi_range(4, 25), rng.randi_range(3, 6))
	# batu besar 2x2 (tata letak dari seed terpisah agar konsisten sepanjang hari)
	var taken := {}
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = hash([Clock.total_days(), floor_n, 77])
	for i in 3:
		var bx := rng_b.randi_range(4, 24)
		var by := rng_b.randi_range(3, 10)
		var ore_b := _ore_for_floor(rng_b) if rng_b.randf() < 0.7 else ""
		var cells := [Vector2i(bx, by), Vector2i(bx + 1, by), Vector2i(bx, by + 1), Vector2i(bx + 1, by + 1)]
		var ok := true
		for cc in cells:
			if cc == stairs or taken.has(cc) or (cc.y >= 11 and cc.x >= 12 and cc.x <= 17):
				ok = false
		if not ok:
			continue
		for cc in cells:
			taken[cc] = true
		if not broken.has(_key(Vector2i(bx, by))):
			feats.append({"kind": "rock", "rect": [bx, by, 2, 2], "color": "7d7d85", "ore": ore_b, "big": true,
				"sprite": "boulder_" + ore_b if ore_b != "" else "boulder"})
	for x in range(3, 27):
		for y in range(3, 13):
			var c := Vector2i(x, y)
			var roll := rng.randf()
			var ore := ""
			if rng.randf() < 0.3:
				ore = _ore_for_floor(rng)
			if c == stairs or (y >= 11 and x >= 12 and x <= 17) or taken.has(c):
				continue
			if roll < 0.2 and not broken.has(_key(c)):
				feats.append({"kind": "rock", "rect": [x, y, 1, 1], "color": "7d7d85", "ore": ore,
					"sprite": "rock_" + (ore if ore != "" else "plain")})
	if floor_n < MAX_FLOOR:
		feats.append({"kind": "exit", "rect": [stairs.x, stairs.y, 1, 1], "color": "111118", "label": "Turun",
			"to": "mine", "spawn": [SPAWN.x, SPAWN.y], "floor": floor_n + 1, "sprite": "stairs_down"})
	else:
		feats.append({"kind": "building", "rect": [stairs.x, stairs.y, 1, 1], "color": "e6c200", "label": "Dasar"})
	if floor_n == 1:
		feats.append({"kind": "exit", "rect": [14, 13, 2, 1], "color": "5a3a1a", "label": "Keluar",
			"to": "village", "spawn": [21, 2]})
	else:
		feats.append({"kind": "exit", "rect": [14, 13, 2, 1], "color": "5a3a1a", "label": "Naik",
			"to": "mine", "spawn": [SPAWN.x, SPAWN.y], "floor": floor_n - 1})
	return {"name": "Tambang lantai %d" % floor_n, "indoor": true, "ground": "1c1c22",
		"walkable": [2, 2, 26, 12], "features": feats}


## Pukul batu: batu kecil langsung pecah, batu besar perlu beberapa pukulan (lebih sedikit dengan cangkul lebih kuat).
func strike(f: Dictionary, level: int) -> Dictionary:
	if not f.raw.get("big", false):
		return {"done": true, "msg": break_rock(f)}
	var c: Vector2i = f.rect.position
	var k := _key(c)
	damage[k] = int(damage.get(k, 0)) + int(BIG_DAMAGE[clampi(level, 0, 2)])
	if int(damage[k]) < BIG_HP:
		return {"done": false, "msg": "Batu besar retak... (%d/%d)" % [damage[k], BIG_HP]}
	damage.erase(k)
	broken[k] = true
	Progress.best("mine_floor", floor_n)
	var ore: String = f.raw.get("ore", "")
	if ore != "":
		var n := randi_range(2, 4)
		Inventory.add("ore:" + ore, n)
		return {"done": true, "msg": "Batu besar hancur! Mendapat %d %s." % [n, Data.item_name("ore:" + ore)]}
	var stones := randi_range(4, 6)
	Inventory.add("stone", stones)
	return {"done": true, "msg": "Batu besar hancur! Mendapat %d Batu." % stones}


## Pecahkan satu batu; mengembalikan pesan hasilnya.
func break_rock(f: Dictionary) -> String:
	var c: Vector2i = f.rect.position
	broken[_key(c)] = true
	Progress.best("mine_floor", floor_n)
	var ore: String = f.raw.get("ore", "")
	if ore != "":
		Inventory.add("ore:" + ore)
		return "Mendapat %s!" % Data.item_name("ore:" + ore)
	if randf() < 0.75:
		Inventory.add("stone")
		return "Mendapat Batu."
	return "Batu hancur."


func save_data() -> Dictionary:
	return {"floor": floor_n, "broken": broken.keys()}


func load_data(d: Dictionary) -> void:
	floor_n = clampi(int(d.get("floor", 1)), 1, MAX_FLOOR)
	broken.clear()
	for k in d.get("broken", []):
		broken[str(k)] = true
