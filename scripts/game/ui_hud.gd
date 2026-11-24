extends CanvasLayer
## HUD diegética do N-7 (GDD §12): sistemas vitais, Protocolo Trino, fórmula de custo
## em tempo real, terminal de logs, prévia da rota, eventos e mochila.

const LOG_LINES := 14
const LOG_COLORS := {
	"info": UiTheme.TEXT, "good": UiTheme.GOOD, "warn": UiTheme.WARN,
	"danger": UiTheme.DANGER, "director": UiTheme.DIRECTOR,
}
const STATUS_NAMES := {
	"acid_rain": "Chuva ácida (+2 dano/passo)",
	"spores": "Esporos corrosivos (-5/turno)",
	"em_storm": "Tempestade EM (LiDAR instável)",
	"harmonic": "Frequência Harmônica (peso ÷2)",
}

var _round_label: Label
var _battery_label: Label
var _battery_bar: ProgressBar
var _integrity_label: Label
var _integrity_bar: ProgressBar
var _load_label: Label
var _formula_label: Label
var _status_label: Label
var _objective_label: Label
var _trinity: Array = []
var _log: RichTextLabel
var _log_lines: Array = []
var _route_label: Label
var _hover_label: Label
var _alert_label: Label
var _lidar_btn: Button
var _confirm_btn: Button
var _event_layer: ColorRect
var _event_title: Label
var _event_text: Label
var _event_buttons: VBoxContainer
var _inventory: InventoryPanel
var _pause_layer: ColorRect
var _route_summary: Dictionary = {}
var _route_length := 0


func _ready() -> void:
	_build_status_panel()
	_build_log_panel()
	_build_action_bar()
	_build_hover_and_alert()
	_build_event_modal()
	_build_inventory()
	_build_pause()

	GameState.resources_updated.connect(_on_resources_updated)
	GameState.round_advanced.connect(func(_r): _on_resources_updated())
	GameState.choice_event_triggered.connect(_on_event)
	GameState.system_alert.connect(_on_alert)
	GameState.log_message.connect(_on_log)
	GameState.item_offered.connect(_on_item_offered)
	GameState.route_previewed.connect(_on_route_previewed)
	GameState.run_finished.connect(_on_run_finished)
	_on_log("Clique num hexágono visível para traçar a rota. LiDAR revela o raio 3.", "info")
	_on_resources_updated()


# --- Construção -------------------------------------------------------------------

func _build_status_panel() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.panel())
	panel.position = Vector2(16, 16)
	panel.custom_minimum_size = Vector2(320, 0)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	box.add_child(UiTheme.make_label("SISTEMAS N-7 :: ATIVO", UiTheme.CYAN, 18))
	_round_label = UiTheme.make_label("", UiTheme.MUTED)
	box.add_child(_round_label)
	_battery_label = UiTheme.make_label("")
	box.add_child(_battery_label)
	_battery_bar = ProgressBar.new()
	UiTheme.style_bar(_battery_bar, Color(0.0, 0.8, 0.85))
	box.add_child(_battery_bar)
	_integrity_label = UiTheme.make_label("")
	box.add_child(_integrity_label)
	_integrity_bar = ProgressBar.new()
	UiTheme.style_bar(_integrity_bar, UiTheme.RUST)
	box.add_child(_integrity_bar)
	_load_label = UiTheme.make_label("")
	box.add_child(_load_label)
	_formula_label = UiTheme.make_label("", UiTheme.WARN)
	box.add_child(_formula_label)
	_status_label = UiTheme.make_label("", UiTheme.DIRECTOR)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status_label)
	box.add_child(UiTheme.make_label("PROTOCOLO TRINO", UiTheme.CYAN, 16))
	var trinity := HBoxContainer.new()
	trinity.add_theme_constant_override("separation", 10)
	box.add_child(trinity)
	for spec in [["Lógica", Color(0.3, 0.5, 1.0)], ["Natureza", Color(0.25, 0.9, 0.35)], ["Arte", Color(0.75, 0.3, 0.95)]]:
		var icon := TrinityIcon.new()
		icon.core_name = spec[0]
		icon.core_color = spec[1]
		trinity.add_child(icon)
		_trinity.append(icon)
	_objective_label = UiTheme.make_label("", UiTheme.MUTED)
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_objective_label)


func _build_log_panel() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.panel())
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -416
	panel.offset_right = -16
	panel.offset_top = 16
	panel.offset_bottom = 330
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	var title := UiTheme.make_label("TERMINAL LOGS", UiTheme.CYAN, 16)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(UiTheme.make_button("MENU [Esc]", _toggle_pause))
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.add_theme_font_size_override("normal_font_size", 14)
	box.add_child(_log)


func _build_action_bar() -> void:
	var bar := VBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar.offset_left = -360
	bar.offset_right = 360
	bar.offset_top = -100
	bar.offset_bottom = -16
	bar.alignment = BoxContainer.ALIGNMENT_END
	add_child(bar)
	_route_label = UiTheme.make_label("", UiTheme.TEXT)
	_route_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var route_bg := PanelContainer.new()
	route_bg.add_theme_stylebox_override("panel", UiTheme.panel(UiTheme.CYAN_DIM, 0.8))
	route_bg.add_child(_route_label)
	bar.add_child(route_bg)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	bar.add_child(buttons)
	_lidar_btn = UiTheme.make_button("PULSAR LiDAR  (-%.0f%%)" % Economy.LIDAR_COST, func(): GameState.lidar_pulsed.emit())
	buttons.add_child(_lidar_btn)
	buttons.add_child(UiTheme.make_button("MOCHILA", func(): _inventory.open_manage()))
	buttons.add_child(UiTheme.make_button("LIMPAR ROTA", func(): GameState.route_clear_requested.emit()))
	_confirm_btn = UiTheme.make_button("CONFIRMAR MOVIMENTO", func(): GameState.move_confirmed.emit())
	buttons.add_child(_confirm_btn)


func _build_hover_and_alert() -> void:
	_hover_label = UiTheme.make_label("", UiTheme.TEXT, 15)
	_hover_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_hover_label.offset_left = -260
	_hover_label.offset_right = 260
	_hover_label.offset_top = 16
	_hover_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hover_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hover_label.add_theme_constant_override("outline_size", 4)
	_hover_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_hover_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hover_label)
	_alert_label = UiTheme.make_label("", UiTheme.DANGER, 26)
	_alert_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_alert_label.offset_left = -320
	_alert_label.offset_right = 320
	_alert_label.offset_top = 90
	_alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_alert_label.add_theme_constant_override("outline_size", 6)
	_alert_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_alert_label.modulate.a = 0.0
	_alert_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_alert_label)


func _build_event_modal() -> void:
	_event_layer = _make_dim_layer()
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.panel(UiTheme.RUST, 0.97))
	panel.custom_minimum_size = Vector2(640, 0)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_event_layer.add_child(center)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	_event_title = UiTheme.make_label("", UiTheme.CYAN, 22)
	_event_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_event_title)
	_event_text = UiTheme.make_label("", UiTheme.TEXT)
	_event_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_event_text.custom_minimum_size = Vector2(600, 0)
	box.add_child(_event_text)
	_event_buttons = VBoxContainer.new()
	_event_buttons.add_theme_constant_override("separation", 6)
	box.add_child(_event_buttons)


func _build_inventory() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_inventory = InventoryPanel.new()
	center.add_child(_inventory)


func _build_pause() -> void:
	_pause_layer = _make_dim_layer()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_layer.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.panel(UiTheme.CYAN, 0.97))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(UiTheme.make_label("PROTOCOLO EM PAUSA", UiTheme.CYAN, 22))
	box.add_child(UiTheme.make_label("Semente do domo: %d" % GameState.run_seed, UiTheme.MUTED))
	box.add_child(UiTheme.make_button("CONTINUAR", _toggle_pause))
	box.add_child(UiTheme.make_button("ABANDONAR E VOLTAR AO MENU", func():
		GameState.ui_blocking = false
		get_tree().change_scene_to_file("res://scenes/UI_Menu.tscn")))


func _make_dim_layer() -> ColorRect:
	var layer := ColorRect.new()
	layer.color = Color(0, 0, 0, 0.65)
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.visible = false
	add_child(layer)
	return layer


# --- Atualização -----------------------------------------------------------------

func _on_resources_updated() -> void:
	if _battery_bar == null:
		return
	_round_label.text = "Rodada %d   |   Setor %s" % [GameState.current_round, Terrain.biome_name(GameState.biome_at(GameState.player_cell))]
	_battery_label.text = "BATERIA  %.1f%%" % GameState.battery
	_battery_bar.value = GameState.battery
	_battery_label.add_theme_color_override("font_color", UiTheme.DANGER if GameState.battery < AudioManager.LOW_POWER_BATTERY else UiTheme.TEXT)
	_integrity_label.text = "INTEGRIDADE  %.0f%%" % GameState.integrity
	_integrity_bar.value = GameState.integrity
	var load_now := GameState.load_kg()
	var modifier := Economy.weight_modifier(load_now, GameState.is_harmonic())
	_load_label.text = "CARGA ÚTIL  %.0f kg   (mochila %d/%d)" % [load_now, GameState.inventory.used_slots(), GameState.inventory.capacity()]
	_formula_label.text = "Custo/hex = %.1f × (1 + %.0f/%.0f%s) = %.1f%%" % [
		Economy.BASE_STEP_COST, load_now, Economy.WEIGHT_REFERENCE,
		" ÷ 2" if GameState.is_harmonic() else "", Economy.BASE_STEP_COST * (1.0 + modifier)]
	var statuses := []
	for s in GameState.statuses:
		statuses.append("%s: %d" % [STATUS_NAMES.get(s, s), GameState.statuses[s]])
	for t in GameState.temp_loads:
		statuses.append("Sucata magnética +%.0f kg: %d" % [t["kg"], t["turns"]])
	_status_label.text = "\n".join(statuses)
	_status_label.visible = not statuses.is_empty()
	_trinity[0].active = true
	_trinity[1].active = GameState.core_nature
	_trinity[2].active = GameState.core_art
	for icon in _trinity:
		icon.queue_redraw()
	var dist := GameState.distance_to_elevator()
	var goal := "Objetivo: reunir a Trindade e chegar ao Elevador Central (%d hex)." % dist
	if GameState.core_nature and GameState.core_art:
		goal = "Trindade completa! Leve-a ao Elevador Central (%d hex)." % dist
	goal += "\nPedágio de ativação da Ascensão: %.0f%% de bateria." % Economy.ELEVATOR_TOLL
	if GameState.collapsed_radius > 0:
		goal += "\nDomo colapsado até o anel %d." % GameState.collapsed_radius
	_objective_label.text = goal
	_lidar_btn.disabled = GameState.battery < Economy.LIDAR_COST
	_update_route_label()


func _process(_delta: float) -> void:
	if get_parent() and get_parent().has_node("MapOverlay"):
		var cell: Vector2i = get_parent().get_node("MapOverlay").hover_cell
		_hover_label.text = GameState.describe_cell(cell)


func _on_route_previewed(length: int, summary: Dictionary) -> void:
	_route_length = length
	_route_summary = summary
	_update_route_label()


func _update_route_label() -> void:
	if _route_length == 0 or _route_summary.is_empty():
		_route_label.text = "Rota: nenhuma   |   Custo por passo agora: %.1f%%" % GameState.current_step_cost()
		_route_label.add_theme_color_override("font_color", UiTheme.MUTED)
		_confirm_btn.disabled = true
		return
	var text := "Rota: %d/%d hex   |   Bateria: -%.1f%%" % [_route_length, Economy.MAX_ROUTE_LENGTH, _route_summary["battery"]]
	if _route_summary["integrity"] > 0.0:
		text += "   |   Integridade prevista: -%.0f" % _route_summary["integrity"]
	var ok: bool = _route_summary["affordable"]
	if not ok:
		text += "   |   BATERIA INSUFICIENTE"
	_route_label.text = text
	_route_label.add_theme_color_override("font_color", UiTheme.TEXT if ok else UiTheme.DANGER)
	_confirm_btn.disabled = not ok


func _on_log(text: String, kind: String) -> void:
	var color: Color = LOG_COLORS.get(kind, UiTheme.TEXT)
	_log_lines.append("[color=#%s]> %s[/color]" % [color.to_html(false), text])
	while _log_lines.size() > LOG_LINES:
		_log_lines.pop_front()
	if _log:
		_log.text = "\n".join(_log_lines)


func _on_alert(msg: String) -> void:
	_alert_label.text = msg
	var tween := create_tween()
	tween.tween_property(_alert_label, "modulate:a", 1.0, 0.15)
	tween.tween_interval(1.8)
	tween.tween_property(_alert_label, "modulate:a", 0.0, 0.5)


func _on_event(event: Dictionary) -> void:
	_event_title.text = event["title"]
	_event_text.text = event["description"]
	for child in _event_buttons.get_children():
		child.queue_free()
	var options: Array = event["options"]
	for i in options.size():
		var opt: Dictionary = options[i]
		var btn := UiTheme.make_button(opt["label"], _choose.bind(i))
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.custom_minimum_size = Vector2(600, 0)
		var req: float = opt.get("requires_battery", 0.0)
		if GameState.battery < req:
			btn.disabled = true
			btn.text += "   (bateria insuficiente)"
		var effects: Dictionary = opt.get("effects", {})
		if effects.has("item") and not GameState.inventory.fits_anywhere(effects["item"]):
			btn.text += "   (mochila cheia: será preciso descartar)"
		_event_buttons.add_child(btn)
	_event_layer.visible = true
	GameState.ui_blocking = true
	AudioManager.play_beep()


func _choose(index: int) -> void:
	_event_layer.visible = false
	GameState.ui_blocking = false
	AudioManager.play_beep()
	GameState.choose_option(index)


func _on_item_offered(item_id: String) -> void:
	_inventory.open_place(item_id)


func _on_run_finished(result: Dictionary) -> void:
	_event_layer.visible = false
	_inventory.visible = false
	if result["kind"] == "ending":
		_on_alert("ASCENSÃO INICIADA")
	else:
		_on_alert("PROTOCOLO ENCERRADO")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _inventory.visible:
			_inventory._close()
		elif not _event_layer.visible:
			_toggle_pause()


func _toggle_pause() -> void:
	if _event_layer.visible or _inventory.visible:
		return
	_pause_layer.visible = not _pause_layer.visible
	GameState.ui_blocking = _pause_layer.visible


class TrinityIcon extends Control:
	var core_name := ""
	var core_color := Color.WHITE
	var active := false

	func _init() -> void:
		custom_minimum_size = Vector2(86, 58)

	func _draw() -> void:
		var c := Vector2(size.x * 0.5, 20)
		if active:
			draw_circle(c, 17.0, Color(core_color, 0.3))
			draw_circle(c, 12.0, core_color)
		else:
			draw_arc(c, 12.0, 0, TAU, 24, Color(0.4, 0.42, 0.45), 2.0)
			draw_string(get_theme_default_font(), c + Vector2(-5, 6), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.5, 0.5, 0.55))
		var font := get_theme_default_font()
		draw_string(font, Vector2(0, 52), core_name, HORIZONTAL_ALIGNMENT_CENTER, size.x, 14, core_color if active else Color(0.5, 0.5, 0.55))
