extends Node
## Data statis game (dibaca dari res://data/*.json).

const CROPS_PATH := "res://data/crops.json"
const ANIMALS_PATH := "res://data/animals.json"
const ITEMS_PATH := "res://data/items.json"
const NPCS_PATH := "res://data/npcs.json"
const AREAS_PATH := "res://data/areas.json"
const FESTIVALS_PATH := "res://data/festivals.json"

var crops := {}
var festivals := {}
var areas := {}
var animals := {}
var products := {}
var items := {}
var npcs := {}
var spouse_schedule: Array = []


func _ready() -> void:
	crops = _load_json(CROPS_PATH)
	festivals = _load_json(FESTIVALS_PATH)
	areas = _load_json(AREAS_PATH)
	items = _load_json(ITEMS_PATH)
	var n := _load_json(NPCS_PATH)
	npcs = n.get("npcs", {})
	spouse_schedule = n.get("spouse_schedule", [])
	var a := _load_json(ANIMALS_PATH)
	animals = a.get("animals", {})
	products = a.get("products", {})


func _load_json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Gagal membaca %s" % path)
		return {}
	return parsed


## Nama tampilan untuk id barang ("crop:x", "prod:x", "seed:x", "feed").
func item_name(id: String) -> String:
	if items.has(id):
		return items[id].name
	if id.begins_with("crop:"):
		return crop_name(id.substr(5))
	if id.begins_with("prod:"):
		return products[id.substr(5)].name
	if id.begins_with("seed:"):
		return "Benih " + crop_name(id.substr(5))
	if id == "feed":
		return "Pakan"
	return id


func item_sell_price(id: String) -> int:
	if items.has(id):
		return int(items[id].sell)
	if id.begins_with("crop:"):
		return sell_price(id.substr(5))
	if id.begins_with("prod:"):
		return int(products[id.substr(5)].sell)
	return 0


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
