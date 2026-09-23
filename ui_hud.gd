extends CanvasLayer

@onready var round_label: Label = $VBoxContainer/RoundLabel
@onready var battery_bar: ProgressBar = $VBoxContainer/BatteryBar
@onready var integrity_bar: ProgressBar = $VBoxContainer/IntegrityBar
@onready var stats_label: Label = $VBoxContainer/StatsLabel
@onready var confirm_button: Button = $ActionButtons/ConfirmMoveButton
@onready var lidar_button: Button = $ActionButtons/LidarButton

@onready var logic_core: TextureRect = $VBoxContainer/TrinityContainer/LogicCore
@onready var nature_core: TextureRect = $VBoxContainer/TrinityContainer/NatureCore
@onready var art_core: TextureRect = $VBoxContainer/TrinityContainer/ArtCore

@onready var system_alert_text: Label = $SystemAlertText

# REFERÊNCIAS DO MODAL
@onready var event_modal: ColorRect = $EventModal
@onready var event_text: Label = $EventModal/Panel/VBoxContainer/EventText
@onready var btn_a: Button = $EventModal/Panel/VBoxContainer/OptionA
@onready var btn_b: Button = $EventModal/Panel/VBoxContainer/OptionB
@onready var btn_c: Button = $EventModal/Panel/VBoxContainer/OptionC

var current_options: Array = []

func _ready() -> void:
	GameState.resources_updated.connect(_on_resources_updated)
	GameState.round_advanced.connect(_on_round_advanced)
	GameState.choice_event_triggered.connect(_on_choice_event_triggered)
	GameState.system_alert.connect(_on_system_alert)
	var icon_tex = load("res://icon.svg")
	logic_core.texture = icon_tex
	nature_core.texture = icon_tex
	art_core.texture = icon_tex

	confirm_button.pressed.connect(_on_confirm_pressed)
	lidar_button.pressed.connect(_on_lidar_pressed)
	
	setup_styles()
	
	# Conexão fixa para os botões do modal
	btn_a.pressed.connect(_on_btn_a_pressed)
	btn_b.pressed.connect(_on_btn_b_pressed)
	btn_c.pressed.connect(_on_btn_c_pressed)
	
	_on_resources_updated()
	_on_round_advanced(GameState.current_round)

func setup_styles() -> void:
	# Botões
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.12, 0.12, 0.12, 1.0)
	btn_style.border_width_left = 2; btn_style.border_width_right = 2
	btn_style.border_width_top = 2; btn_style.border_width_bottom = 2
	btn_style.border_color = Color(0.0, 0.7, 0.7, 1.0)
	btn_style.corner_radius_top_left = 0
	btn_style.corner_radius_top_right = 0
	btn_style.corner_radius_bottom_left = 0
	btn_style.corner_radius_bottom_right = 0
	
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(0.2, 0.3, 0.3, 1.0)
	btn_hover.border_color = Color(0.0, 1.0, 1.0, 1.0)
	
	for btn in [confirm_button, lidar_button, btn_a, btn_b, btn_c]:
		btn.add_theme_stylebox_override("normal", btn_style)
		btn.add_theme_stylebox_override("hover", btn_hover)
		btn.add_theme_stylebox_override("pressed", btn_hover)
		btn.add_theme_color_override("font_color", Color(0.0, 0.9, 0.9, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(0.0, 1.0, 1.0, 1.0))
		
	# Painel do Modal
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.08, 0.98)
	panel_style.border_width_left = 4; panel_style.border_width_right = 4
	panel_style.border_width_top = 4; panel_style.border_width_bottom = 4
	panel_style.border_color = Color(0.8, 0.4, 0.1, 1.0) # Ferrugem
	$EventModal/Panel.add_theme_stylebox_override("panel", panel_style)
	
	# Barras de Progresso
	var pb_bg = StyleBoxFlat.new()
	pb_bg.bg_color = Color(0.1, 0.1, 0.1, 1.0)
	pb_bg.border_width_left = 1; pb_bg.border_width_right = 1
	pb_bg.border_width_top = 1; pb_bg.border_width_bottom = 1
	pb_bg.border_color = Color(0.3, 0.3, 0.3, 1.0)
	
	var bat_fill = StyleBoxFlat.new()
	bat_fill.bg_color = Color(0.0, 0.8, 0.8, 1.0)
	
	var int_fill = StyleBoxFlat.new()
	int_fill.bg_color = Color(0.8, 0.4, 0.1, 1.0)
	
	battery_bar.add_theme_stylebox_override("background", pb_bg)
	battery_bar.add_theme_stylebox_override("fill", bat_fill)
	
	integrity_bar.add_theme_stylebox_override("background", pb_bg)
	integrity_bar.add_theme_stylebox_override("fill", int_fill)
	
	# Textos
	for lbl in [round_label, stats_label, event_text]:
		lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))

func _on_resources_updated() -> void:
	battery_bar.value = GameState.battery
	integrity_bar.value = GameState.integrity
	stats_label.text = "Carga: " + str(GameState.load_weight) + " / " + str(GameState.max_load) + " kg"
	
	if GameState.core_logic:
		logic_core.modulate = Color(0.18, 0.20, 1.0, 1.0)
	else:
		logic_core.modulate = Color(0.0, 0.0, 0.0, 0.5)
		
	if GameState.core_nature:
		nature_core.modulate = Color(0.21, 1.0, 0.21, 1.0)
	else:
		nature_core.modulate = Color(0.0, 0.0, 0.0, 0.5)
		
	if GameState.core_art:
		art_core.modulate = Color(1.0, 0.18, 0.18, 1.0)
	else:
		art_core.modulate = Color(0.0, 0.0, 0.0, 0.5)

func _on_round_advanced(current_round: int) -> void:
	round_label.text = "Rodada: " + str(current_round)

func _on_confirm_pressed() -> void:
	##AudioManager.play_beep()
	GameState.move_confirmed.emit()

func _on_lidar_pressed() -> void:
	AudioManager.play_beep()
	GameState.lidar_pulsed.emit()

# PREENCHE O MODAL COM O BANCO DE DADOS
func _on_choice_event_triggered(event_data: Dictionary) -> void:
	event_text.text = event_data["title"] + "\n\n" + event_data["description"]
	current_options = event_data["options"]
	
	var buttons = [btn_a, btn_b, btn_c]
	
	for i in range(3):
		if i < current_options.size():
			buttons[i].visible = true
			buttons[i].disabled = false
			var opt = current_options[i]
			buttons[i].text = opt["label"]
			
			if GameState.battery < opt["req_battery"]:
				buttons[i].disabled = true
				buttons[i].text += "\n(Bateria Insuficiente)"
		else:
			buttons[i].visible = false 
			
	event_modal.visible = true

# --- AS FUNÇÕES QUE FALTAVAM ---
func _on_btn_a_pressed() -> void:
	_execute_option(0)

func _on_btn_b_pressed() -> void:
	_execute_option(1)

func _on_btn_c_pressed() -> void:
	_execute_option(2)

func _on_system_alert(msg: String) -> void:
	system_alert_text.text = msg
	var tween = create_tween()
	tween.tween_property(system_alert_text, "modulate:a", 1.0, 0.2)
	tween.tween_interval(2.0)
	tween.tween_property(system_alert_text, "modulate:a", 0.0, 0.5)

func _execute_option(index: int) -> void:
	AudioManager.play_beep()
	GameState.resolve_choice(current_options[index]["action"])
	event_modal.visible = false
