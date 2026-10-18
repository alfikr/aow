class_name Layout
## Konstanta tata letak peta peternakan.

const TILE := 32
const COLS := 30
const ROWS := 16
const HUD_H := 64

const FIELD := Rect2i(10, 3, 16, 10)
const HOUSE := Rect2i(1, 1, 5, 3)
const HOUSE_DOOR := Vector2i(3, 4)
const BIN := Vector2i(8, 2)
const SHOP := Vector2i(8, 6)
const POND := Rect2i(27, 2, 2, 3)


static func in_map(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < COLS and c.y < ROWS


static func is_solid(c: Vector2i) -> bool:
	return not in_map(c) or HOUSE.has_point(c) or POND.has_point(c) or c == BIN or c == SHOP
