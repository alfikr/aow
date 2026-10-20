extends Node
## Progres jangka panjang: pernikahan, resep, statistik, dan ending.

const ENDING_YEAR := 3   # ending muncul saat tahun ke-3 dimulai (setelah 2 tahun)

var spouse := ""
var fiance := ""
var wedding_day := 0
var child := false
var ending_seen := false
var stats := {}
var recipes: Array = []
var flags := {}            # penanda cerita: secret_open, grove_visited, grove_chest, ...
var forage_taken := {}     # "x,y" -> true (tumbuh lagi tiap hari)
var blessing := false      # berkah Dewi Panen untuk besok pagi
var offerings := 0


func _ready() -> void:
	reset()
	Events.day_started.connect(_on_day_started)
	Events.area_changed.connect(_on_area_changed)


func reset() -> void:
	spouse = ""
	fiance = ""
	wedding_day = 0
	child = false
	ending_seen = false
	stats = {"fish": 0, "mine_floor": 0, "dishes": 0, "harvests": 0, "gifts": 0}
	recipes = ["sup_lobak", "telur_goreng"]
	flags = {}
	forage_taken = {}
	blessing = false
	offerings = 0


func flag(name: String) -> bool:
	return bool(flags.get(name, false))


func set_flag(name: String) -> void:
	flags[name] = true
	Events.world_changed.emit()


func _on_area_changed(id: String) -> void:
	if id == "grove" and not flag("grove_visited"):
		flags["grove_visited"] = true
		unlock_recipe("sup_jamur")
		unlock_recipe("teh_herba")
		Events.story.emit("Kamu menemukan Hutan Rahasia! Di sini Dewi Panen bersemayam. (Resep Sup Jamur dan Teh Herba dipelajari.)")


## Persembahan ke patung Dewi Panen: berkah untuk tanaman esok pagi.
func offer(item: String) -> String:
	if blessing:
		return "Dewi Panen sudah menerima persembahanmu hari ini."
	if not Inventory.remove(item):
		return "Kamu tidak punya itu."
	blessing = true
	offerings += 1
	var msg := "Dewi Panen menerima %s dengan senyum. Besok tanamanmu akan diberkahi." % Data.item_name(item)
	if offerings == 10 and not flag("offer_reward"):
		flags["offer_reward"] = true
		Inventory.add("ore:emas", 3)
		msg += " Cahaya hangat menjatuhkan 3 Bijih Emas untukmu!"
	return msg


func bump(stat: String, n := 1) -> void:
	stats[stat] = int(stats.get(stat, 0)) + n


func best(stat: String, value: int) -> void:
	stats[stat] = maxi(int(stats.get(stat, 0)), value)


func knows_recipe(id: String) -> bool:
	return recipes.has(id)


func unlock_recipe(id: String) -> void:
	if not recipes.has(id):
		recipes.append(id)


func _on_day_started(_passed_out: bool) -> void:
	forage_taken.clear()
	if fiance != "":
		spouse = fiance
		fiance = ""
		wedding_day = Clock.total_days()
		Events.story.emit("Hari ini hari pernikahanmu dengan %s! Desa merayakannya bersama." % Data.npcs[spouse].name)
	elif spouse != "" and not child and Clock.total_days() - wedding_day >= 30:
		child = true
		Events.story.emit("Kabar gembira! %s dan kamu menyambut seorang bayi di rumah." % Data.npcs[spouse].name)
	if Clock.year >= ENDING_YEAR and not ending_seen:
		ending_seen = true
		Events.show_ending.emit()


func ending_text(player_stamina_note := "") -> String:
	var lines := ["Dua tahun telah berlalu sejak kamu tiba di peternakan ini.", ""]
	lines.append("Uang: %dG" % Inventory.gold)
	var ls := Engine.get_main_loop().root.get_tree().get_first_node_in_group("livestock") as Livestock
	lines.append("Hewan ternak: %d" % (ls.animals.size() if ls else 0))
	lines.append("Level alat: Cangkul %s, Penyiram %s" % [
		Inventory.LEVEL_NAMES[Inventory.tool_level("hoe")], Inventory.LEVEL_NAMES[Inventory.tool_level("water")]])
	lines.append("Ikan ditangkap: %d   Lantai tambang terdalam: %d   Masakan dibuat: %d" % [
		int(stats.fish), int(stats.mine_floor), int(stats.dishes)])
	lines.append("Pasangan: %s%s" % [Data.npcs[spouse].name if spouse != "" else "belum ada", " (dan seorang anak)" if child else ""])
	var score := Inventory.gold / 100 + int(stats.fish) + int(stats.mine_floor) * 5 + int(stats.dishes) * 2 \
		+ (60 if spouse != "" else 0) + (30 if child else 0) + recipes.size() * 5
	lines.append("")
	lines.append("Skor: %d" % score)
	var rating := "Pendatang baru yang rajin."
	if score >= 400:
		rating = "Legenda Desa! Semua orang mengenang kerja kerasmu."
	elif score >= 200:
		rating = "Petani teladan. Peternakanmu jadi kebanggaan desa."
	elif score >= 100:
		rating = "Warga yang dicintai desa."
	lines.append(rating)
	lines.append("")
	lines.append("Kamu boleh terus bermain. Terima kasih sudah bermain!")
	return "\n".join(lines)


func save_data() -> Dictionary:
	return {"spouse": spouse, "fiance": fiance, "wedding_day": wedding_day, "child": child,
		"ending_seen": ending_seen, "stats": stats, "recipes": recipes, "flags": flags,
		"forage_taken": forage_taken, "blessing": blessing, "offerings": offerings}


func load_data(d: Dictionary) -> void:
	reset()
	spouse = str(d.get("spouse", ""))
	fiance = str(d.get("fiance", ""))
	wedding_day = int(d.get("wedding_day", 0))
	child = bool(d.get("child", false))
	ending_seen = bool(d.get("ending_seen", false))
	for k in d.get("stats", {}):
		stats[k] = int(d.stats[k])
	for k in d.get("flags", {}):
		flags[k] = bool(d.flags[k])
	for k in d.get("forage_taken", {}):
		forage_taken[k] = true
	blessing = bool(d.get("blessing", false))
	offerings = int(d.get("offerings", 0))
	if d.has("recipes"):
		recipes = []
		for r in d.recipes:
			recipes.append(str(r))
