extends Node
## Validasi data game secara statis:
##   godot --headless --path . res://tests/validate.tscn

var problems := 0


func bad(msg: String) -> void:
	problems += 1
	print("  MASALAH ", msg)


func rect_of(a: Array) -> Rect2i:
	return Rect2i(int(a[0]), int(a[1]), int(a[2]), int(a[3]))


func solid_at(area_id: String, c: Vector2i) -> bool:
	var area: Dictionary = Data.areas[area_id]
	if not rect_of(area.walkable).has_point(c):
		return true
	var feats: Array = area.features
	for i in range(feats.size() - 1, -1, -1):   # fitur paling atas menentukan (sama seperti World)
		var f: Dictionary = feats[i]
		if f.kind != "path" and f.kind != "floor" and rect_of(f.rect).has_point(c):
			return World.SOLID_KINDS.has(f.kind)
	return false


func _ready() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	var npcs: Npcs = main.get_node("Npcs")

	# --- area, pintu, spawn
	for id in Data.areas:
		if id == "mine":
			continue
		var area: Dictionary = Data.areas[id]
		for f in area.features:
			if f.kind != "exit":
				continue
			if not Data.areas.has(f.to):
				bad("%s: pintu menuju area tidak ada (%s)" % [id, f.to])
				continue
			var sp := Vector2i(int(f.spawn[0]), int(f.spawn[1]))
			if f.to != "mine" and solid_at(f.to, sp):
				bad("%s -> %s: titik spawn %s tidak bisa dilewati" % [id, f.to, sp])
			if f.to != "mine":
				for g in Data.areas[f.to].features:
					if g.kind == "exit" and rect_of(g.rect).has_point(sp):
						bad("%s -> %s: spawn %s berada di atas pintu" % [id, f.to, sp])
			var r := rect_of(f.rect)
			for x in r.size.x:
				for y in r.size.y:
					if solid_at(id, r.position + Vector2i(x, y)):
						bad("%s: pintu '%s' berada di tile yang solid/di luar area" % [id, f.get("label", "")])
	for id in ["village", "farm", "lane"]:
		for f in Data.areas[id].features:
			if f.kind == "exit" and f.to != "mine":
				var back := false
				for g in Data.areas[f.to].features:
					if g.kind == "exit" and g.to == id:
						back = true
				if not back:
					bad("%s -> %s: tidak ada pintu kembali" % [id, f.to])

	# --- jadwal NPC
	var occupied := {}
	for id in Data.npcs:
		var entries: Array = Data.npcs[id].schedule
		for e in entries + (Data.spouse_schedule if true else []):
			if not Data.areas.has(e.area):
				bad("%s: area jadwal tidak ada (%s)" % [id, e.area])
				continue
			var c := Vector2i(int(e.cell[0]), int(e.cell[1]))
			if solid_at(e.area, c):
				bad("%s: sel jadwal %s di %s tidak bisa dilewati" % [id, c, e.area])
			for g in Data.areas[e.area].features:
				if g.kind == "exit" and rect_of(g.rect).has_point(c):
					bad("%s: sel jadwal %s di %s berada di atas pintu" % [id, c, e.area])
		for wd in 7:
			for rainy in [false, true]:
				for m in range(360, 1440, 10):
					var matched := false
					for e in entries:
						if rainy == bool(e.get("rain", false)) or (not rainy and not e.get("rain", false)) or rainy:
							if npcs._matches(e, float(m), wd):
								matched = true
					if not matched:
						bad("%s: jadwal kosong hari %d jam %02d:%02d (hujan=%s)" % [id, wd, m / 60, m % 60, rainy])
						break
				for m in range(360, 1440, 10):
					var t := npcs.schedule_target(id, float(m), wd, rainy)
					var key := "%d|%s|%d|%s|%s" % [wd, rainy, m, t.area, t.cell]
					if occupied.has(key) and occupied[key] != id:
						bad("%s dan %s berdiri di sel yang sama: %s" % [id, occupied[key], key])
					occupied[key] = id

	# --- barang, resep, ikan
	for rid in Data.recipes:
		for ing in Data.recipes[rid].ingredients:
			var known: bool = Data.item_sell_price(ing) > 0 or ing.begins_with("crop:") or ing.begins_with("prod:") or ing.begins_with("fish:")
			if not known:
				bad("resep %s: bahan tidak dikenal (%s)" % [rid, ing])
			if ing.begins_with("crop:") and not Data.crops.has(ing.substr(5)):
				bad("resep %s: tanaman tidak ada (%s)" % [rid, ing])
			if ing.begins_with("prod:") and not Data.products.has(ing.substr(5)):
				bad("resep %s: produk tidak ada (%s)" % [rid, ing])
			if ing.begins_with("fish:") and not Data.fish.has(ing.substr(5)):
				bad("resep %s: ikan tidak ada (%s)" % [rid, ing])
	for nid in Data.npcs:
		for ev in Data.npcs[nid].get("events", []):
			var r: Dictionary = ev.get("reward", {})
			if r.has("recipe") and not Data.recipes.has(r.recipe):
				bad("%s: event memberi resep yang tidak ada (%s)" % [nid, r.recipe])
		for taste in ["loves", "likes", "hates"]:
			for item in Data.npcs[nid][taste]:
				var ok := Data.items.has(item) or Data.recipes.has(item.substr(5)) or Data.crops.has(item.substr(5)) \
					or Data.products.has(item.substr(5)) or Data.fish.has(item.substr(5))
				if not ok:
					bad("%s: selera %s tidak dikenal (%s)" % [nid, taste, item])
	for fid in Data.fish:
		if Data.fish[fid].places.is_empty() or Data.fish[fid].seasons.is_empty():
			bad("ikan %s tanpa tempat/musim" % fid)
	for season in 4:
		for place in ["pond", "beach"]:
			if main.get_node("Fishing").candidates(place, season).is_empty():
				bad("tidak ada ikan di %s musim %d" % [place, season])
	for cid in Data.crops:
		if Data.crops[cid].seasons.is_empty():
			bad("tanaman %s tanpa musim" % cid)

	print("HASIL: ", "LULUS" if problems == 0 else "%d MASALAH" % problems)
	get_tree().quit(problems)
