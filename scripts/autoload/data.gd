extends Node
## Data statis game (dibaca dari res://data/*.json).

const CROPS_PATH := "res://data/crops.json"
const FESTIVALS_PATH := "res://data/festivals.json"

var crops := {}
var festivals := {}


func _ready() -> void:
	crops = _load_json(CROPS_PATH)
	festivals = _load_json(FESTIVALS_PATH)


func _load_json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Gagal membaca %s" % path)
		return {}
	return parsed


func crop_ids() -> Array:
	return crops.keys()


func crop_name(id: String) -> String:
	return crops[id].name


func growth_days(id: String) -> int:
	return int(crops[id].days)


## Hari yang dibutuhkan untuk berbuah lagi setelah panen; 0 = sekali panen.
func regrow_days(id: String) -> int:
	return int(crops[id].get("regrow", 0))


func seed_price(id: String) -> int:
	return int(crops[id].seed)


func sell_price(id: String) -> int:
	return int(crops[id].sell)


func crop_color(id: String) -> Color:
	return Color.html(crops[id].color)


func grows_in(id: String, season: int) -> bool:
	return crops[id].seasons.has(float(season)) or crops[id].seasons.has(season)
