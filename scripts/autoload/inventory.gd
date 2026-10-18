extends Node
## Uang, barang yang dibawa, dan isi kotak pengiriman.
## ID barang: "seed:<tanaman>" dan "crop:<tanaman>".

const START_GOLD := 300

var gold := 0
var items := {}
var bin := {}
var last_earned := 0


func _ready() -> void:
	reset()
	Events.day_ended.connect(_on_day_ended)


func reset() -> void:
	gold = START_GOLD
	items = {"seed:lobak": 5}
	bin = {}
	last_earned = 0


func seed_id(crop: String) -> String:
	return "seed:" + crop


func crop_id(crop: String) -> String:
	return "crop:" + crop


func count(id: String) -> int:
	return int(items.get(id, 0))


func add(id: String, n := 1) -> void:
	items[id] = count(id) + n


func remove(id: String, n := 1) -> bool:
	if count(id) < n:
		return false
	items[id] = count(id) - n
	if items[id] == 0:
		items.erase(id)
	return true


func spend(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	return true


## Pindahkan semua hasil panen yang dibawa ke kotak pengiriman.
func ship_crops() -> int:
	var moved := 0
	for id in items.keys():
		if str(id).begins_with("crop:"):
			bin[id] = int(bin.get(id, 0)) + items[id]
			moved += items[id]
			items.erase(id)
	return moved


func _on_day_ended(_passed_out: bool) -> void:
	var total := 0
	for id in bin:
		total += int(bin[id]) * Data.sell_price(str(id).trim_prefix("crop:"))
	bin.clear()
	last_earned = total
	gold += total


func save_data() -> Dictionary:
	return {"gold": gold, "items": items, "bin": bin, "last_earned": last_earned}


func load_data(d: Dictionary) -> void:
	gold = int(d.get("gold", START_GOLD))
	items = _ints(d.get("items", {}))
	bin = _ints(d.get("bin", {}))
	last_earned = int(d.get("last_earned", 0))


func _ints(src: Dictionary) -> Dictionary:
	var out := {}
	for k in src:
		out[k] = int(src[k])
	return out
