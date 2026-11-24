extends Control
## Tela de desfecho: um dos 5 finais do Elevador ou o Game Over, com o relatório da
## partida (o histórico como insumo de auditoria, GDD §10.3).

const TONE_COLORS := {
	"true": Color(1.0, 0.88, 0.4), "ambiguous": Color(0.95, 0.5, 0.4),
	"medium": Color(0.5, 0.9, 1.0), "bad": Color(0.6, 0.62, 0.66),
}


func _ready() -> void:
	var result: Dictionary = GameState.last_result
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.05)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var title_text := "PROTOCOLO ENCERRADO"
	var subtitle_text := "Game Over"
	var body: String = result.get("reason", "O ciclo recomeça do zero.")
	var color := UiTheme.DANGER
	if result.get("kind", "") == "ending":
		var info := Endings.info(result["id"])
		title_text = info["title"]
		subtitle_text = info["subtitle"]
		body = info["text"]
		color = TONE_COLORS.get(info["tone"], UiTheme.CYAN)
	panel.add_theme_stylebox_override("panel", UiTheme.panel(color, 0.95))

	var title := UiTheme.make_label(title_text, color, 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var subtitle := UiTheme.make_label(subtitle_text, UiTheme.MUTED, 20)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)
	var text := UiTheme.make_label(body, UiTheme.TEXT, 18)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(680, 0)
	box.add_child(text)

	if not result.is_empty():
		var s: Dictionary = result["stats"]
		var report := "RELATÓRIO DA PARTIDA  (semente %d)\nTurnos: %d   |   Hexágonos percorridos: %d   |   Pulsos LiDAR: %d\nBateria gasta: %.1f%%   |   Bateria recuperada: %.1f%%   |   Dano sofrido: %.0f\nCarga final: %.0f kg   |   Bateria final: %.1f%%   |   Integridade final: %.0f%%" % [
			result["seed"], result["round"], s["hexes"], s["lidar"],
			s["battery_spent"], s["battery_gained"], s["damage"],
			result["load"], result["battery"], result["integrity"]]
		var report_label := UiTheme.make_label(report, UiTheme.CYAN_DIM, 15)
		box.add_child(report_label)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	box.add_child(buttons)
	buttons.add_child(UiTheme.make_button("NOVA PARTIDA", func():
		GameState.new_run()
		get_tree().change_scene_to_file("res://scenes/Main.tscn")))
	buttons.add_child(UiTheme.make_button("MENU INICIAL", func(): get_tree().change_scene_to_file("res://scenes/UI_Menu.tscn")))
