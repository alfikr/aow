extends Node
## Uang, barang yang dibawa, dan isi kotak pengiriman.
## ID barang: "seed:<tanaman>" dan "crop:<tanaman>".

const START_GOLD := 300
const TOOL_KEYS := ["hoe", "water"]
const TOOL_LABELS := {"hoe": "Cangkul", "water": "Penyiram"}
const LEVEL_NAMES := ["Dasar", "Tembaga", "Perak"]
const UPGRADE_COST := [0, 500, 1500]
const STAMINA_MULT := [1.0, 0.75, 0.5]
const WATER_CAPACITY := [20, 40, 60]

var gold := 0
var items := {}
var bin := {}
var last_earned := 0
var tool_levels := {"hoe": 0, "water": 0}


func _ready() -> void:
	reset()
	Events.day_ended.connect(_on_day_ended)


func reset() -> void:
	gold = START_GOLD
	items = {"seed:lobak": 5}
	bin = {}
	last_earned = 0
	tool_levels = {"hoe": 0, "water": 0}


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


func tool_level(key: String) -> int:
	return int(tool_levels[key])


func stamina_mult(key: String) -> float:
	return STAMINA_MULT[tool_level(key)]


func water_max() -> int:
	return WATER_CAPACITY[tool_level("water")]


func can_upgrade(key: String) -> bool:
	return tool_level(key) < LEVEL_NAMES.size() - 1


## Biaya upgrade ke level berikutnya, atau -1 bila sudah maksimal.
func next_upgrade_cost(key: String) -> int:
	return UPGRADE_COST[tool_level(key) + 1] if can_upgrade(key) else -1


func upgrade(key: String) -> bool:
	if not can_upgrade(key) or not spend(next_upgrade_cost(key)):
		return false
	tool_levels[key] = tool_level(key) + 1
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
	var bonus := 1.0 + float(Clock.festival().get("sell_bonus", 0.0))
	for id in bin:
		total += roundi(int(bin[id]) * Data.sell_price(str(id).trim_prefix("crop:")) * bonus)
	bin.clear()
	last_earned = total
	gold += total


func save_data() -> Dictionary:
	return {"gold": gold, "items": items, "bin": bin, "last_earned": last_earned,
		"tools": tool_levels}


func load_data(d: Dictionary) -> void:
	gold = int(d.get("gold", START_GOLD))
	items = _ints(d.get("items", {}))
	bin = _ints(d.get("bin", {}))
	last_earned = int(d.get("last_earned", 0))
	tool_levels = _ints(d.get("tools", {"hoe": 0, "water": 0}))


func _ints(src: Dictionary) -> Dictionary:
	var out := {}
	for k in src:
		out[k] = int(src[k])
	return out
