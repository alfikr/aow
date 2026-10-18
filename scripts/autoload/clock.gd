extends Node
## Waktu, kalender, dan cuaca.

const DAY_START := 6 * 60
const DAY_END := 24 * 60
const MINUTES_PER_SEC := 10.0
const DAYS_PER_SEASON := 30
const SEASON_NAMES := ["Semi", "Panas", "Gugur", "Dingin"]
const WEATHER_NAMES := ["Cerah", "Hujan", "Salju"]

enum Weather { SUNNY, RAINY, SNOW }

var minutes := float(DAY_START)
var day := 1
var season := 0
var year := 1
var weather := Weather.SUNNY
var paused := false


func _process(delta: float) -> void:
	if paused:
		return
	minutes += MINUTES_PER_SEC * delta
	if minutes >= DAY_END:
		end_day(true)


func end_day(passed_out: bool) -> void:
	Events.day_ended.emit(passed_out)
	day += 1
	if day > DAYS_PER_SEASON:
		day = 1
		season = (season + 1) % SEASON_NAMES.size()
		if season == 0:
			year += 1
		Events.season_changed.emit(season)
	minutes = float(DAY_START)
	_roll_weather()
	Events.day_started.emit(passed_out)


func _roll_weather() -> void:
	var r := randf()
	if season == 3:
		weather = Weather.SNOW if r < 0.3 else Weather.SUNNY
	else:
		weather = Weather.RAINY if r < 0.2 else Weather.SUNNY


func festival() -> Dictionary:
	return Data.festivals.get("%d-%d" % [season, day], {})


func time_text() -> String:
	return "%02d:%02d" % [int(minutes) / 60, int(minutes) % 60]


func date_text() -> String:
	return "%s, Hari %d (Tahun %d)" % [SEASON_NAMES[season], day, year]


func save_data() -> Dictionary:
	return {"minutes": minutes, "day": day, "season": season, "year": year, "weather": int(weather)}


func load_data(d: Dictionary) -> void:
	minutes = float(d.get("minutes", DAY_START))
	day = int(d.get("day", 1))
	season = int(d.get("season", 0))
	year = int(d.get("year", 1))
	weather = int(d.get("weather", 0)) as Weather
