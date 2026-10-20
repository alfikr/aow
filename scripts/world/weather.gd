class_name WeatherFx
extends Node2D
## Partikel cuaca dan musim di area luar ruangan:
## hujan, salju, daun gugur (gugur), kelopak (semi), kunang-kunang (panas, malam).

const AREA := Vector2(Layout.COLS * Layout.TILE, Layout.ROWS * Layout.TILE)
const COUNTS := {"rain": 150, "snow": 100, "leaves": 24, "petals": 18, "fireflies": 18}
const LEAF_COLORS := [Color(0.88, 0.5, 0.12), Color(0.75, 0.25, 0.1), Color(0.94, 0.72, 0.18)]
const PETAL_COLORS := [Color(1.0, 0.75, 0.85), Color(1.0, 0.9, 0.93), Color(0.96, 0.6, 0.78)]

@onready var world: World = $"../World"

var kind := ""
var parts: Array = []
var ripples: Array = []


## Jenis efek yang berlaku (murni, mudah diuji).
static func kind_for(indoor: bool, weather: int, season: int, minutes: float) -> String:
	if indoor:
		return ""
	if weather == Clock.Weather.RAINY:
		return "rain"
	if weather == Clock.Weather.SNOW:
		return "snow"
	match season:
		0: return "petals"
		1: return "fireflies" if minutes >= 19.0 * 60 else ""
		2: return "leaves"
	return ""


func _process(delta: float) -> void:
	var forced := str(world.area.get("fx", ""))      # mis. kunang-kunang abadi di hutan rahasia
	var k := forced if forced != "" else kind_for(world.is_indoor(), Clock.weather, Clock.season, Clock.minutes)
	if k != kind:
		_reset(k)
	if kind == "":
		return
	_update(delta)
	queue_redraw()


func _reset(k: String) -> void:
	kind = k
	parts.clear()
	ripples.clear()
	for i in int(COUNTS.get(k, 0)):
		parts.append(_spawn(k, true))
	queue_redraw()


func _spawn(k: String, anywhere: bool) -> Dictionary:
	var x := randf() * AREA.x
	var y := randf() * AREA.y if anywhere else -8.0
	match k:
		"rain":
			return {"pos": Vector2(x, y), "vel": Vector2(-60, randf_range(480, 620))}
		"snow":
			return {"pos": Vector2(x, y), "vel": Vector2(0, randf_range(24, 52)), "phase": randf() * TAU,
				"size": randi_range(1, 3)}
		"leaves":
			return {"pos": Vector2(x, y), "vel": Vector2(randf_range(-6, 14), randf_range(18, 38)),
				"phase": randf() * TAU, "col": LEAF_COLORS.pick_random()}
		"petals":
			return {"pos": Vector2(x, y), "vel": Vector2(randf_range(8, 20), randf_range(14, 28)),
				"phase": randf() * TAU, "col": PETAL_COLORS.pick_random()}
	# kunang-kunang melayang di sekitar tinggi tanaman
	return {"pos": Vector2(x, randf_range(70, AREA.y - 40)), "vel": Vector2(randf_range(-10, 10), randf_range(-8, 8)),
		"phase": randf() * TAU}


func _update(delta: float) -> void:
	for p in parts:
		p.pos += p.vel * delta
		if p.has("phase"):
			p.phase += delta * (4.0 if kind == "fireflies" else 2.0)
		if kind == "snow" or kind == "leaves" or kind == "petals":
			p.pos.x += sin(p.phase) * 14.0 * delta
		if kind == "fireflies":
			p.vel += Vector2(randf_range(-20, 20), randf_range(-20, 20)) * delta
			p.vel = p.vel.limit_length(16.0)
			p.pos.x = wrapf(p.pos.x, 0.0, AREA.x)
			p.pos.y = clampf(p.pos.y, 60.0, AREA.y - 20.0)
			continue
		if p.pos.y > AREA.y + 8.0 or p.pos.x < -16.0 or p.pos.x > AREA.x + 16.0:
			var fresh := _spawn(kind, false)
			for key in fresh:
				p[key] = fresh[key]
	if kind == "rain":
		if randf() < 6.0 * delta and ripples.size() < 16:
			ripples.append({"pos": Vector2(randf() * AREA.x, randf_range(40, AREA.y)), "age": 0.0})
		for r in ripples:
			r.age += delta
		ripples = ripples.filter(func(r): return r.age < 0.45)


func _draw() -> void:
	match kind:
		"rain":
			for p in parts:
				draw_line(p.pos, p.pos + p.vel.normalized() * 11.0, Color(0.72, 0.82, 1.0, 0.55), 1.0)
			for r in ripples:
				var t: float = r.age / 0.45
				draw_arc(r.pos, 2.0 + 7.0 * t, 0.0, TAU, 14, Color(0.85, 0.92, 1.0, 0.5 * (1.0 - t)), 1.0)
		"snow":
			for p in parts:
				draw_rect(Rect2(p.pos, Vector2.ONE * p.size), Color(1, 1, 1, 0.9))
		"leaves", "petals":
			for p in parts:
				var flutter := 0.5 + 0.5 * sin(p.phase * 1.5)
				draw_rect(Rect2(p.pos, Vector2(3, 1.5 + flutter * 1.5)), p.col)
		"fireflies":
			for p in parts:
				var glow := 0.5 + 0.5 * sin(p.phase)
				draw_circle(p.pos, 7.0, Color(1, 0.95, 0.4, 0.10 * glow))
				draw_circle(p.pos, 2.0, Color(1, 0.98, 0.6, 0.35 + 0.55 * glow))
