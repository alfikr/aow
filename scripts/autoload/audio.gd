extends Node
## Efek suara dan musik. Berkas dimuat bila ada; bila belum diimpor,
## game tetap berjalan tanpa suara.

const DIR := "res://assets/audio/"
const SFX_NAMES := ["hoe", "water", "plant", "harvest", "coin", "blip", "select", "error", "splash", "mine", "cook", "door"]
const TRACKS := ["music_day", "music_night", "music_indoor"]
const POOL := 6

var sfx := {}
var players: Array = []
var music: AudioStreamPlayer
var current := ""
var ambient: AudioStreamPlayer
var ambient_current := ""
var auto_music := true
var check_t := 0.0


func _ready() -> void:
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, "Master")
	for name in SFX_NAMES:
		var s := _load(name)
		if s:
			sfx[name] = s
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		players.append(p)
	music = AudioStreamPlayer.new()
	music.bus = "Music"
	add_child(music)
	ambient = AudioStreamPlayer.new()
	ambient.bus = "SFX"
	ambient.volume_db = -9.0
	add_child(ambient)
	Events.sfx.connect(play)
	Settings.apply()


func _exit_tree() -> void:
	# lepaskan referensi aliran agar tidak ada peringatan resource saat keluar
	music.stop()
	music.stream = null
	ambient.stop()
	ambient.stream = null
	for p in players:
		p.stop()
		p.stream = null
	sfx.clear()


func _load(name: String) -> AudioStream:
	var path := DIR + name + ".wav"
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	return null


func play(name: String) -> void:
	if not sfx.has(name):
		return
	for p in players:
		if not p.playing:
			p.stream = sfx[name]
			p.play()
			return


func set_track(track: String) -> void:
	if track == current:
		return
	current = track
	var s := _load(track)
	if s == null:
		music.stop()
		return
	if s is AudioStreamWAV:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = s.data.size() / 2   # 16-bit mono
	music.stream = s
	music.play()


func set_ambient(name: String) -> void:
	if name == ambient_current:
		return
	ambient_current = name
	var s := _load(name) if name != "" else null
	if s == null:
		ambient.stop()
		return
	if s is AudioStreamWAV:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = s.data.size() / 2
	ambient.stream = s
	ambient.play()


## Suara latar menurut cuaca: hujan terdengar di luar ruangan.
func choose_ambient() -> String:
	var world := get_tree().get_first_node_in_group("world") as World
	if world == null or world.is_indoor():
		return ""
	return "ambient_rain" if Clock.weather == Clock.Weather.RAINY else ""


func choose_track() -> String:
	var world := get_tree().get_first_node_in_group("world") as World
	if world == null:
		return "music_day"
	var forced := str(world.area.get("music", ""))
	if forced != "":
		return forced
	if world.is_indoor():
		return "music_indoor"
	return "music_night" if Clock.minutes >= 18 * 60 else "music_day"


func _process(delta: float) -> void:
	check_t += delta
	if auto_music and check_t >= 1.0:
		check_t = 0.0
		set_track(choose_track())
		set_ambient(choose_ambient())
