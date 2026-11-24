class_name InventoryGrid
extends RefCounted
## Mochila de carga em grade 5×4 = 20 slots (GDD §6 — Subsistema de Inventário).
## Verifica colisão espacial das peças e soma o peso enviado ao custo de movimento.

const WIDTH := 5
const HEIGHT := 4
const NO_FIT := Vector2i(-1, -1)

var cells: Dictionary = {}   ## Vector2i -> uid
var items: Dictionary = {}   ## uid -> {"id": String, "origin": Vector2i, "shape": Array}
var _next_uid := 1


static func normalize(shape: Array) -> Array:
	var min_x := 999
	var min_y := 999
	for p in shape:
		min_x = mini(min_x, p.x)
		min_y = mini(min_y, p.y)
	var out := []
	for p in shape:
		out.append(Vector2i(p.x - min_x, p.y - min_y))
	return out


## Gira 90° no sentido horário.
static func rotated(shape: Array) -> Array:
	var out := []
	for p in shape:
		out.append(Vector2i(-p.y, p.x))
	return normalize(out)


func can_place(shape: Array, origin: Vector2i) -> bool:
	for p in shape:
		var c: Vector2i = origin + p
		if c.x < 0 or c.y < 0 or c.x >= WIDTH or c.y >= HEIGHT:
			return false
		if cells.has(c):
			return false
	return true


## Coloca a peça e devolve o uid, ou -1 se houver colisão.
func place(id: String, origin: Vector2i, shape: Array = []) -> int:
	if shape.is_empty():
		shape = ItemDB.shape(id)
	if not can_place(shape, origin):
		return -1
	var uid := _next_uid
	_next_uid += 1
	items[uid] = {"id": id, "origin": origin, "shape": shape}
	for p in shape:
		cells[origin + p] = uid
	return uid


func find_fit(shape: Array) -> Vector2i:
	for y in HEIGHT:
		for x in WIDTH:
			if can_place(shape, Vector2i(x, y)):
				return Vector2i(x, y)
	return NO_FIT


## Procura uma posição considerando as rotações permitidas da peça.
func fits_anywhere(id: String) -> bool:
	var shape := ItemDB.shape(id)
	var turns := 4 if ItemDB.get_item(id)["rotatable"] else 1
	for i in turns:
		if find_fit(shape) != NO_FIT:
			return true
		shape = rotated(shape)
	return false


func remove(uid: int) -> String:
	if not items.has(uid):
		return ""
	var item: Dictionary = items[uid]
	for p in item["shape"]:
		cells.erase(item["origin"] + p)
	items.erase(uid)
	return item["id"]


func uid_at(cell: Vector2i) -> int:
	return cells.get(cell, 0)


func has_item(id: String) -> bool:
	return first_uid(id) != 0


func first_uid(id: String) -> int:
	for uid in items:
		if items[uid]["id"] == id:
			return uid
	return 0


func count(id: String) -> int:
	var n := 0
	for uid in items:
		if items[uid]["id"] == id:
			n += 1
	return n


func total_weight() -> float:
	var total := 0.0
	for uid in items:
		total += ItemDB.weight(items[uid]["id"])
	return total


func used_slots() -> int:
	return cells.size()


func capacity() -> int:
	return WIDTH * HEIGHT
