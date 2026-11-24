class_name Tutorial
extends Control
## Primeiro turno guiado: o despertar do N-7 vira o tutorial (feedback da professora).
## DESPERTAR → LiDAR em destaque → hexágono vizinho em destaque → custo explicado antes
## de confirmar → objetivo. Cada etapa avança com a ação real do jogador, sem quiz.

signal finished

enum Step { AWAKE, LIDAR, SELECT, CONFIRM, GOAL, DONE }

var step: Step = Step.AWAKE
var lidar_button: Button
var confirm_button: Button
var overlay: MapOverlay

var _dim: ColorRect
var _awake_panel: PanelContainer
var _awake_text: RichTextLabel
var _tip_panel: PanelContainer
var _tip_text: RichTextLabel
var _tip_ok: Button
var _pulse: Tween
var _pulsing: Control
var _target := MapOverlay.NO_CELL


func start(lidar_btn: Button, confirm_btn: Button, map_overlay: MapOverlay) -> void:
	lidar_button = lidar_btn
	confirm_button = confirm_btn
	overlay = map_overlay
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	GameState.lidar_done.connect(_on_lidar_done)
	GameState.route_previewed.connect(_on_route_previewed)
	GameState.round_advanced.connect(_on_round_advanced)
	_show_awake()


func _build() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.75)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.add_child(center)
	_awake_panel = PanelContainer.new()
	_awake_panel.add_theme_stylebox_override("panel", UiTheme.panel(UiTheme.CYAN, 0.97))
	_awake_panel.custom_minimum_size = Vector2(640, 0)
	center.add_child(_awake_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_awake_panel.add_child(box)
	box.add_child(UiTheme.make_label("VISOR N-7 :: DESPERTAR", UiTheme.CYAN, 22))
	_awake_text = RichTextLabel.new()
	_awake_text.bbcode_enabled = true
	_awake_text.fit_content = true
	_awake_text.custom_minimum_size = Vector2(600, 0)
	box.add_child(_awake_text)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	buttons.add_child(UiTheme.make_button("INICIAR SISTEMAS", _go_lidar))
	buttons.add_child(UiTheme.make_button("PULAR TUTORIAL", _finish))

	_tip_panel = PanelContainer.new()
	_tip_panel.add_theme_stylebox_override("panel", UiTheme.panel(UiTheme.WARN, 0.95))
	_tip_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_tip_panel.offset_left = -330
	_tip_panel.offset_right = 330
	_tip_panel.offset_top = -270
	_tip_panel.offset_bottom = -112
	_tip_panel.visible = false
	add_child(_tip_panel)
	var tip_box := VBoxContainer.new()
	_tip_panel.add_child(tip_box)
	_tip_text = RichTextLabel.new()
	_tip_text.bbcode_enabled = true
	_tip_text.fit_content = true
	_tip_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip_box.add_child(_tip_text)
	var tip_buttons := HBoxContainer.new()
	tip_buttons.alignment = BoxContainer.ALIGNMENT_END
	tip_buttons.add_theme_constant_override("separation", 8)
	tip_box.add_child(tip_buttons)
	_tip_ok = UiTheme.make_button("ENTENDIDO", _finish)
	_tip_ok.visible = false
	tip_buttons.add_child(_tip_ok)
	tip_buttons.add_child(UiTheme.make_button("PULAR TUTORIAL", _finish))


func _show_awake() -> void:
	step = Step.AWAKE
	GameState.ui_blocking = true
	var lines := []
	for line in Lore.AWAKENING:
		lines.append("[color=#8ff]>[/color] " + line)
	_awake_text.text = "\n".join(lines)
	_awake_text.visible_ratio = 0.0
	var tween := create_tween()
	tween.tween_property(_awake_text, "visible_ratio", 1.0, 2.5)
	AudioManager.play_beep()


func _go_lidar() -> void:
	_dim.visible = false
	GameState.ui_blocking = false
	step = Step.LIDAR
	_tip("[b]1/3 · ENXERGAR[/b]\nSeus sensores passivos só veem os hexágonos [b]vizinhos[/b]. Perigos invisíveis (radiação, interferência) continuam ocultos.\nClique em [color=#ffd060]PULSAR LiDAR[/color]: custa [b]5%[/b] de bateria e escaneia 3 hexágonos ao redor.")
	_pulse_control(lidar_button)


func _on_lidar_done(_cells: int) -> void:
	if step != Step.LIDAR:
		return
	step = Step.SELECT
	_target = _pick_neighbor()
	overlay.set_highlight(_target)
	_stop_pulse()
	_tip("[b]2/3 · PLANEJAR[/b]\nO LiDAR marcou o terreno. Agora clique no [color=#ffd060]hexágono destacado[/color] para planejar o primeiro passo.\nNada se move ainda: primeiro você vê quanto vai custar.")


func _on_route_previewed(length: int, summary: Dictionary) -> void:
	if step != Step.SELECT or length == 0:
		return
	step = Step.CONFIRM
	overlay.set_highlight(MapOverlay.NO_CELL)
	var load_now := GameState.load_kg()
	var per_step := Economy.step_cost(load_now)
	_tip("[b]3/3 · CALCULAR[/b]\nEsta rota custa [color=#ffd060][b]%.1f%%[/b][/color] de bateria (%d hex). O número aparece [b]antes[/b] de confirmar, e é exatamente o que será descontado.\nCusto por passo = 1.5 × (1 + carga ÷ 15) = 1.5 × (1 + %.0f ÷ 15) = [b]%.1f%%[/b]. Um núcleo pesa 15 kg: com ele, cada passo custará %.1f%%.\nClique em [color=#ffd060]CONFIRMAR MOVIMENTO[/color]." % [
		summary["battery"], length, load_now, per_step, Economy.step_cost(load_now + Economy.WEIGHT_REFERENCE)])
	_pulse_control(confirm_button)


func _on_round_advanced(_round: int) -> void:
	if step != Step.CONFIRM:
		return
	step = Step.GOAL
	_stop_pulse()
	_tip("[b]PROTOCOLO EM ANDAMENTO[/b]\nVocê é N-7, e carrega a Lógica. Encontre a [color=#5f5]Natureza[/color] no setor verde e a [color=#c6f]Arte[/color] perto do Elevador, e leve as três ao [color=#ffd060]Elevador Central[/color] (a coluna de luz no centro).\nAté 4 hexágonos por turno. Subestações recarregam a bateria. O domo começa a colapsar no turno 15.")
	_tip_ok.visible = true


func _pick_neighbor() -> Vector2i:
	var best := MapOverlay.NO_CELL
	var best_d := 9999
	for n in Hex.neighbors(GameState.player_cell):
		if not GameState.can_route_through(n) or GameState.terrain_at(n, true) != Terrain.NORMAL:
			continue
		var d := Hex.distance(n, GameState.elevator_cell)
		if d < best_d:
			best_d = d
			best = n
	return best


func _tip(text: String) -> void:
	_tip_text.text = text
	_tip_panel.visible = true


func _pulse_control(control: Control) -> void:
	_stop_pulse()
	_pulsing = control
	_pulse = create_tween().set_loops()
	_pulse.tween_property(control, "modulate", Color(1.6, 1.4, 0.4), 0.45)
	_pulse.tween_property(control, "modulate", Color.WHITE, 0.45)


func _stop_pulse() -> void:
	if _pulse:
		_pulse.kill()
	if is_instance_valid(_pulsing):
		_pulsing.modulate = Color.WHITE
	_pulsing = null


func _finish() -> void:
	_stop_pulse()
	if overlay:
		overlay.set_highlight(MapOverlay.NO_CELL)
	GameState.ui_blocking = false
	step = Step.DONE
	Settings.set_tutorial_enabled(false)
	finished.emit()
	queue_free()
