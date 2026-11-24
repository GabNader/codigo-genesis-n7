extends Node2D
## Autômato N-7: seleção de rota com o mouse, execução passo a passo e animações
## de feedback (GDD §5 Movimentação, §14 Animações).
##
## Clique esquerdo em hexágono visível: traça a rota mais barata até ele.
## Clique em hexágono vizinho ao fim da rota: estende a rota à mão (Rota Alfa/Beta).
## Clique em hexágono da rota: corta a rota ali. Clique direito: limpa a rota.
## Roda do mouse: zoom. Botão do meio arrastando: move a câmera.

const STEP_TIME := 0.3
const ZOOM_MIN := 0.1
const ZOOM_MAX := 0.4

var hex_grid: TileMapLayer
var overlay: MapOverlay
var route: Array[Vector2i] = []
var moving := false
var _panning := false

@onready var camera: Camera2D = $Camera2D
@onready var tread_sound: AudioStreamPlayer = $TreadSound
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	GameState.move_confirmed.connect(_on_move_confirmed)
	GameState.lidar_pulsed.connect(_on_lidar_pulsed)
	GameState.route_clear_requested.connect(clear_route)
	GameState.resources_updated.connect(_refresh_route)
	$SelectionHighlight.visible = false
	camera.zoom = Vector2(0.17, 0.17)


func setup(grid: TileMapLayer, map_overlay: MapOverlay) -> void:
	hex_grid = grid
	overlay = map_overlay
	global_position = _cell_to_world(GameState.player_cell)
	camera.reset_smoothing()


func _unhandled_input(event: InputEvent) -> void:
	if hex_grid == null or GameState.run_over:
		return
	if event is InputEventMouseMotion:
		if _panning:
			camera.position -= event.relative / camera.zoom
		else:
			overlay.set_hover(_mouse_cell())
		return
	if not event is InputEventMouseButton:
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		_zoom(1.1)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		_zoom(1.0 / 1.1)
	elif event.button_index == MOUSE_BUTTON_MIDDLE:
		_panning = event.pressed
	elif moving or GameState.ui_blocking or not event.pressed:
		return
	elif event.button_index == MOUSE_BUTTON_LEFT:
		_on_cell_clicked(_mouse_cell())
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		clear_route()


func _on_cell_clicked(cell: Vector2i) -> void:
	if not GameState.in_map(cell):
		return
	if not GameState.revealed.has(cell):
		GameState.system_alert.emit("Área sob névoa de dados. Use o LiDAR.")
		return
	if cell == GameState.player_cell:
		clear_route()
		return
	var idx := route.find(cell)
	if idx >= 0:
		route = route.slice(0, idx + 1)
	elif not GameState.can_route_through(cell):
		GameState.system_alert.emit("Fenda estrutural: intransponível.")
		return
	else:
		var tail: Vector2i = route[-1] if not route.is_empty() else GameState.player_cell
		if Hex.distance(tail, cell) == 1:
			if route.size() >= Economy.MAX_ROUTE_LENGTH:
				GameState.system_alert.emit("Alcance motor: até %d hexágonos por turno." % Economy.MAX_ROUTE_LENGTH)
				return
			route.append(cell)
		else:
			var path := GameState.plan_route(GameState.player_cell, cell)
			if path.is_empty():
				GameState.system_alert.emit("Sem rota conhecida até esse setor.")
				return
			if path.size() > Economy.MAX_ROUTE_LENGTH:
				path = path.slice(0, Economy.MAX_ROUTE_LENGTH)
				GameState.system_alert.emit("Rota cortada no alcance motor: %d hexágonos por turno." % Economy.MAX_ROUTE_LENGTH)
			route = path
	_refresh_route()


func clear_route() -> void:
	route.clear()
	_refresh_route()


func _refresh_route() -> void:
	if overlay == null:
		return
	var summary := GameState.route_summary(route) if not route.is_empty() else {}
	overlay.set_route(route, summary)
	GameState.route_previewed.emit(route.size(), summary)


func _on_move_confirmed() -> void:
	if moving or GameState.run_over or GameState.ui_blocking:
		return
	if route.is_empty():
		GameState.system_alert.emit("Trace uma rota clicando num hexágono visível.")
		return
	var summary := GameState.route_summary(route)
	if not summary["in_range"]:
		GameState.system_alert.emit("Alcance motor: até %d hexágonos por turno." % Economy.MAX_ROUTE_LENGTH)
		return
	if not summary["affordable"]:
		GameState.system_alert.emit("Movimentação bloqueada: rota custa %.1f%%. Reavalie o destino ou reduza a carga." % summary["battery"])
		AudioManager.play_error()
		return
	moving = true
	var steps := route.duplicate()
	route.clear()
	_refresh_route()
	var prev := GameState.player_cell
	animated_sprite.speed_scale = 3.0
	for cell in steps:
		var integrity_before := GameState.integrity
		var result := GameState.enter_cell(prev, cell)
		if not result["ok"]:
			AudioManager.play_error()
			break
		_play_tread()
		await _slide_to(cell)
		if GameState.integrity < integrity_before:
			_flash_damage()
			AudioManager.play_error()
		prev = cell
		if result["stop"]:
			break
	animated_sprite.speed_scale = 1.0
	tread_sound.stop()
	moving = false
	if not GameState.run_over:
		GameState.finish_move()


func _on_lidar_pulsed() -> void:
	if moving or GameState.run_over:
		return
	var cells := GameState.pulse_lidar()
	if cells.is_empty():
		AudioManager.play_error()
		return
	AudioManager.play_beep()
	var effect := LidarEffect.new()
	add_child(effect)
	var tween := create_tween()
	tween.tween_property(effect, "radius", 606.0 * Economy.LIDAR_RADIUS + 300.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, 0.5)
	tween.tween_callback(effect.queue_free)
	_refresh_route()


func _slide_to(cell: Vector2i) -> void:
	var tween := create_tween()
	tween.tween_property(self, "global_position", _cell_to_world(cell), STEP_TIME).set_trans(Tween.TRANS_LINEAR)
	await tween.finished


## Servomotores: o timbre fica mais grave e lento conforme a carga (GDD §15).
func _play_tread() -> void:
	tread_sound.pitch_scale = clampf(1.0 - GameState.load_kg() / 90.0, 0.55, 1.0)
	if not tread_sound.playing:
		tread_sound.play(0.4)


func _flash_damage() -> void:
	var tween := create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1, 0.3, 0.3), 0.08)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.25)


func _zoom(factor: float) -> void:
	var z := clampf(camera.zoom.x * factor, ZOOM_MIN, ZOOM_MAX)
	camera.zoom = Vector2(z, z)


func _mouse_cell() -> Vector2i:
	return hex_grid.local_to_map(hex_grid.to_local(get_global_mouse_position()))


func _cell_to_world(cell: Vector2i) -> Vector2:
	return hex_grid.to_global(hex_grid.map_to_local(cell))


class LidarEffect extends Node2D:
	var radius: float = 0.0

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		draw_arc(Vector2.ZERO, radius, 0, TAU, 96, Color(0.0, 1.0, 1.0, 1.0), 24.0, true)
		draw_arc(Vector2.ZERO, radius * 0.8, 0, TAU, 96, Color(0.0, 1.0, 1.0, 0.4), 10.0, true)
