class_name Sprites
## Memuat dan menggambar sprite sheet karakter dan hewan (assets/sprites).
##
## Karakter: sel 32x48, kolom = [diam, langkah A, langkah B],
##           baris = [bawah, kiri, kanan, atas].
## Hewan:    baris 0 = menghadap kiri, baris 1 = menghadap kanan; kolom = bingkai.

const DIR := "res://assets/sprites/"
const CHAR_CELL := Vector2(32, 48)
const ANIMAL_CELLS := {
	"chicken": Vector2(32, 32),
	"cow": Vector2(48, 36),
	"dog": Vector2(36, 28),
}

## Tekstur yang punya variasi per musim: <nama>_summer / _autumn / _winter (musim semi = dasar).
const SEASONAL := ["grass", "grass_field", "tree_oak", "tree_pine", "bush", "path", "water", "fence_h"]
const SEASON_KEYS := ["", "summer", "autumn", "winter"]

static var cache := {}


static func tex(sheet: String) -> Texture2D:
	if not cache.has(sheet):
		var path := DIR + sheet + ".png"
		cache[sheet] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return cache[sheet]


## Tekstur menurut musim berjalan; kembali ke versi dasar bila variasinya belum ada.
static func tex_season(sheet: String) -> Texture2D:
	if Clock.season > 0 and SEASONAL.has(sheet):
		var t := tex("%s_%s" % [sheet, SEASON_KEYS[Clock.season]])
		if t != null:
			return t
	return tex(sheet)


static func char_row(facing: Vector2i) -> int:
	if facing.y > 0:
		return 0
	if facing.x < 0:
		return 1
	if facing.x > 0:
		return 2
	return 3


## Bingkai jalan untuk karakter: 0 = diam, 1/2 = langkah bergantian.
static func walk_frame(moving: bool) -> int:
	return 1 + int(Time.get_ticks_msec() / 150) % 2 if moving else 0


## `at` = pojok kiri-atas tile tempat karakter berdiri; kaki sejajar dasar tile.
static func draw_char(ci: CanvasItem, sheet: String, at: Vector2, facing: Vector2i, frame: int) -> bool:
	var t := tex(sheet)
	if t == null:
		return false
	var dest := Rect2(at + Vector2(0, Layout.TILE - CHAR_CELL.y), CHAR_CELL)
	var src := Rect2(Vector2(frame * CHAR_CELL.x, char_row(facing) * CHAR_CELL.y), CHAR_CELL)
	ci.draw_texture_rect_region(t, dest, src)
	return true


## Hewan diratakan di tengah tile, dasar sprite sejajar dasar tile.
static func draw_animal(ci: CanvasItem, sheet: String, at: Vector2, facing_right: bool, frame: int) -> bool:
	var t := tex(sheet)
	if t == null or not ANIMAL_CELLS.has(sheet):
		return false
	var cell: Vector2 = ANIMAL_CELLS[sheet]
	var dest := Rect2(at + Vector2((Layout.TILE - cell.x) / 2.0, Layout.TILE - cell.y), cell)
	var src := Rect2(Vector2(frame * cell.x, (1 if facing_right else 0) * cell.y), cell)
	ci.draw_texture_rect_region(t, dest, src)
	return true


## Tinggi sprite hewan (untuk menaruh penanda di atas kepala).
static func animal_height(sheet: String) -> float:
	return (ANIMAL_CELLS[sheet] as Vector2).y if ANIMAL_CELLS.has(sheet) else 24.0
