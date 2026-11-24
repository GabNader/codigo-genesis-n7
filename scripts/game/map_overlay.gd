class_name MapOverlay
extends Node2D
## Camada de dados sobre o HexGrid: desenha só o que os sensores do N-7 conhecem
## (terreno escaneado, pontos de interesse, leituras instáveis), a rota planejada
## com o custo acumulado e o hexágono sob o mouse (UI diegética, GDD §12).

const HALF_W := 346.0
const HALF_H := 314.0
const FONT_SIZE := 72
const NO_CELL := Vector2i(9999, 9999)

const CYAN := Color(0.0, 0.95, 0.95)
const DANGER := Color(1.0, 0.3, 0.15)
const GOLD := Color(1.0, 0.85, 0.3)

var grid: TileMapLayer
var route: Array = []
var route_summary: Dictionary = {}
var hover_cell: Vector2i = NO_CELL
var font: Font


func _ready() -> void:
	font = load("res://assets/PixelOperator.ttf")
	z_index = 10


func cell_center(cell: Vector2i) -> Vector2:
	return grid.map_to_local(cell)


func hex_points(center: Vector2, scale_factor := 1.0) -> PackedVector2Array:
	var w := HALF_W * scale_factor
	var h := HALF_H * scale_factor
	return PackedVector2Array([
		center + Vector2(w, 0), center + Vector2(w * 0.5, h), center + Vector2(-w * 0.5, h),
		center + Vector2(-w, 0), center + Vector2(-w * 0.5, -h), center + Vector2(w * 0.5, -h),
	])


func set_route(new_route: Array, summary: Dictionary) -> void:
	route = new_route
	route_summary = summary
	queue_redraw()


func set_hover(cell: Vector2i) -> void:
	if cell != hover_cell:
		hover_cell = cell
		queue_redraw()


func _draw() -> void:
	if grid == null:
		return
	for cell in GameState.revealed:
		if not GameState.scanned.has(cell) and GameState.terrain_at(cell) != Terrain.ELEVADOR:
			_text(cell_center(cell) + Vector2(0, 24), "?", Color(0.7, 0.75, 0.8, 0.35), FONT_SIZE)
	for cell in GameState.scanned:
		var info: Dictionary = GameState.scanned[cell]
		var c := cell_center(cell)
		_draw_terrain(info["terrain"], c, cell)
		if info["poi"] and GameState.map_pois.has(cell):
			_draw_poi(GameState.map_pois[cell], c)
		if info["uncertain"]:
			draw_polyline(_closed(hex_points(c, 0.86)), Color(1, 0.3, 1, 0.75), 10.0)
			_text(c + Vector2(HALF_W * 0.45, -HALF_H * 0.45), "~", Color(1, 0.4, 1), FONT_SIZE)
	for cell in GameState.fake_pois:
		_draw_bolt(cell_center(cell), GOLD)
	for cell in GameState.electrified:
		_draw_zigzag(cell_center(cell))
	_draw_route()
	if hover_cell != NO_CELL and GameState.in_map(hover_cell):
		draw_polyline(_closed(hex_points(cell_center(hover_cell), 0.95)), Color(1, 1, 1, 0.85), 14.0)


func _draw_terrain(terrain: String, c: Vector2, cell: Vector2i) -> void:
	match terrain:
		Terrain.FENDA:
			draw_colored_polygon(hex_points(c, 0.93), Color(0.01, 0.01, 0.03, 0.93))
			draw_polyline(PackedVector2Array([c + Vector2(-200, -120), c + Vector2(-60, -20), c + Vector2(-110, 60), c + Vector2(40, 110), c + Vector2(190, 40)]), Color(0.9, 0.2, 0.1, 0.8), 14.0)
		Terrain.VAZAMENTO:
			draw_circle(c, 130.0, Color(1.0, 0.35, 0.05, 0.45))
			draw_circle(c, 70.0, Color(1.0, 0.75, 0.2, 0.85))
			_text(c + Vector2(0, 205), "-20", DANGER, FONT_SIZE)
		Terrain.INTERFERENCIA:
			for i in 3:
				draw_arc(c, 70.0 + i * 55.0, -PI * 0.8, -PI * 0.2, 16, Color(1, 0.3, 1, 0.85), 14.0)
				draw_arc(c, 70.0 + i * 55.0, PI * 0.2, PI * 0.8, 16, Color(1, 0.3, 1, 0.85), 14.0)
		Terrain.SUBESTACAO:
			_draw_bolt(c, GOLD)
			if GameState.substation_stability.has(cell):
				_text(c + Vector2(0, 215), "%d%%" % roundi(GameState.substation_stability[cell] * 100), GOLD, FONT_SIZE)
		Terrain.NODULO:
			draw_circle(c, 170.0, Color(0.2, 0.9, 1.0, 0.25))
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -150), c + Vector2(110, 0), c + Vector2(0, 150), c + Vector2(-110, 0)]), Color(0.4, 1, 1, 0.9))
		Terrain.OASIS:
			draw_rect(Rect2(c - Vector2(35, 120), Vector2(70, 240)), Color(0.3, 1, 0.4, 0.85))
			draw_rect(Rect2(c - Vector2(120, 35), Vector2(240, 70)), Color(0.3, 1, 0.4, 0.85))
		Terrain.FIREWALL:
			for i in 3:
				draw_line(c + Vector2(-230, -110 + i * 110), c + Vector2(230, -110 + i * 110), Color(1, 0.15, 0.2, 0.85), 22.0)
			_text(c + Vector2(0, 250), "-15", DANGER, FONT_SIZE)
		Terrain.RAIZES:
			for i in 3:
				var y := -100.0 + i * 100.0
				var pts := PackedVector2Array()
				for k in 9:
					pts.append(c + Vector2(-220 + k * 55, y + sin(k * 1.3 + i) * 35))
				draw_polyline(pts, Color(0.35, 0.8, 0.3, 0.9), 16.0)
			_text(c + Vector2(0, 250), "x3", Color(0.5, 1, 0.4), FONT_SIZE)
		Terrain.ELEVADOR:
			draw_circle(c, 220.0, Color(1, 0.9, 0.5, 0.2))
			draw_rect(Rect2(c - Vector2(55, 230), Vector2(110, 400)), Color(0.95, 0.97, 1.0, 0.95))
			draw_rect(Rect2(c - Vector2(20, 230), Vector2(40, 400)), Color(0.4, 0.9, 1.0, 0.95))
			_text(c + Vector2(0, 260), "ELEVADOR", GOLD, FONT_SIZE)


func _draw_poi(poi: Dictionary, c: Vector2) -> void:
	match poi["type"]:
		"core_nature":
			draw_circle(c, 165.0, Color(0.2, 1, 0.4, 0.25))
			draw_circle(c, 105.0, Color(0.25, 0.85, 0.35, 0.95))
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -75), c + Vector2(55, 0), c + Vector2(0, 75), c + Vector2(-55, 0)]), Color(0.85, 1, 0.85))
		"core_art":
			draw_circle(c, 165.0, Color(0.8, 0.3, 1, 0.25))
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -130), c + Vector2(110, 0), c + Vector2(0, 130), c + Vector2(-110, 0)]), Color(0.7, 0.3, 0.95, 0.95))
			draw_circle(c, 40.0, Color(1, 0.85, 1))
		"item":
			draw_rect(Rect2(c - Vector2(85, 85), Vector2(170, 170)), Color(0.1, 0.8, 0.9, 0.85))
			_text(c + Vector2(0, 30), "+", Color(0.02, 0.1, 0.12), 140)
		"event":
			draw_circle(c, 105.0, Color(1, 0.85, 0.2, 0.9))
			_text(c + Vector2(0, 45), "?", Color(0.15, 0.1, 0.0), 140)


func _draw_route() -> void:
	if route.is_empty():
		return
	var ok: bool = route_summary.get("affordable", true)
	var color := CYAN if ok else DANGER
	var pts := PackedVector2Array([cell_center(GameState.player_cell)])
	for cell in route:
		pts.append(cell_center(cell))
	draw_polyline(pts, Color(color, 0.85), 26.0)
	var cumulative: Array = route_summary.get("cumulative", [])
	for i in route.size():
		var p := cell_center(route[i])
		draw_circle(p, 42.0, color)
		if i < cumulative.size():
			_text(p + Vector2(0, -70), "-%.1f" % cumulative[i], color, FONT_SIZE)


func _draw_bolt(c: Vector2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(30, -170), c + Vector2(-90, 20), c + Vector2(-5, 20),
		c + Vector2(-35, 170), c + Vector2(90, -30), c + Vector2(5, -30),
	]), color)


func _draw_zigzag(c: Vector2) -> void:
	var pts := PackedVector2Array()
	for k in 7:
		pts.append(c + Vector2(-210 + k * 70, -40 if k % 2 == 0 else 40))
	draw_polyline(pts, Color(1, 1, 0.2, 0.95), 18.0)
	_text(c + Vector2(0, 150), "+15", Color(1, 1, 0.3), FONT_SIZE)


func _text(pos: Vector2, text: String, color: Color, size: int) -> void:
	var width := 600.0
	draw_string_outline(font, pos - Vector2(width * 0.5, 0), text, HORIZONTAL_ALIGNMENT_CENTER, width, size, 14, Color(0, 0, 0, 0.85))
	draw_string(font, pos - Vector2(width * 0.5, 0), text, HORIZONTAL_ALIGNMENT_CENTER, width, size, color)


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var out := points.duplicate()
	out.append(points[0])
	return out
