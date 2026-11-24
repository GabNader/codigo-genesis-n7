class_name UiTheme
extends RefCounted
## Estilo diegético compartilhado: painéis escuros, bordas ciano e ferrugem (GDD §12–13).

const CYAN := Color(0.0, 0.9, 0.9)
const CYAN_DIM := Color(0.0, 0.55, 0.6)
const RUST := Color(0.85, 0.45, 0.15)
const TEXT := Color(0.85, 0.88, 0.9)
const MUTED := Color(0.55, 0.6, 0.65)
const GOOD := Color(0.35, 1.0, 0.5)
const WARN := Color(1.0, 0.8, 0.3)
const DANGER := Color(1.0, 0.35, 0.25)
const DIRECTOR := Color(1.0, 0.4, 1.0)


static func panel(border: Color = CYAN_DIM, alpha := 0.9) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.04, 0.05, 0.07, alpha)
	s.set_border_width_all(2)
	s.border_color = border
	s.set_content_margin_all(12)
	return s


static func style_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.1, 0.12, 0.95)
	normal.set_border_width_all(2)
	normal.border_color = CYAN_DIM
	normal.set_content_margin_all(8)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.12, 0.22, 0.24, 1.0)
	hover.border_color = CYAN
	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.06, 0.06, 0.07, 0.9)
	disabled.border_color = Color(0.25, 0.25, 0.28)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", CYAN)
	btn.add_theme_color_override("font_hover_color", Color(0.6, 1, 1))
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.42, 0.45))


static func make_button(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	style_button(btn)
	btn.pressed.connect(callback)
	return btn


static func make_label(text: String, color: Color = TEXT, size := 16) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", size)
	return lbl


static func style_bar(bar: ProgressBar, fill: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.1, 0.12)
	bg.set_border_width_all(1)
	bg.border_color = Color(0.3, 0.3, 0.35)
	var f := StyleBoxFlat.new()
	f.bg_color = fill
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", f)
	bar.custom_minimum_size = Vector2(0, 16)
	bar.show_percentage = false
