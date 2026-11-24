extends Control
## Menu inicial: iniciar protocolo, instruções (sem quiz: só as regras do domo) e sair.

const HOW_TO := """[b]OBJETIVO[/b]
N-7 carrega a Lógica. Resgate o Núcleo da [color=#5f5]Natureza[/color] (setor eco) e o Núcleo da [color=#c6f]Arte[/color] (Nódulos de Energia, perto do centro) e leve a Trindade ao [color=#fd5]Elevador Central[/color]. O que você entregar define um de 5 finais.

[b]CONTROLES (só mouse)[/b]
• Clique num hexágono visível: traça a rota mais barata. Clique ao lado do fim da rota para estendê-la à mão.
• Clique direito: limpa a rota. Roda: zoom. Botão do meio arrastando: move a câmera.
• CONFIRMAR MOVIMENTO executa a rota inteira e encerra o turno.

[b]ENERGIA[/b]
Custo por hexágono = 1,5 × (1 + Carga ÷ 15). Cada núcleo pesa 15 kg.
LiDAR: -5% e escaneia o raio 3. Sem escanear, vazamentos e bolsões de gás ficam ocultos.

[b]PERIGOS[/b]
Vazamento térmico -20 Integridade • Firewall -15% Bateria • Raízes: sair custa o triplo • Zonas de interferência: leituras ao redor podem estar erradas (30%) • Fendas: intransponíveis.
A partir do turno 15 o domo colapsa de fora para dentro.

[b]ENERGIA EXTRA[/b]
Subestações mostram a estabilidade: compare o ganho esperado do sifonamento arriscado com o seguro."""

var _how_to: PanelContainer


func _ready() -> void:
	var bg := TextureRect.new()
	bg.texture = load("res://assets/wp11936763-cyberpunk-pixel-wallpapers.png")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.45, 0.5, 0.6)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.panel(UiTheme.CYAN_DIM, 0.85))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(box)
	var title := UiTheme.make_label("CÓDIGO GÊNESIS", UiTheme.CYAN, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var subtitle := UiTheme.make_label("O LEGADO DE N-7", UiTheme.RUST, 24)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)
	var tagline := UiTheme.make_label("Lógica, Natureza e Arte. Só a matemática leva a Trindade até o Elevador.", UiTheme.MUTED)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tagline)
	box.add_child(UiTheme.make_button("INICIAR PROTOCOLO", _on_start_pressed))
	box.add_child(UiTheme.make_button("COMO JOGAR", func(): _how_to.visible = not _how_to.visible))
	box.add_child(UiTheme.make_button("SAIR", func(): get_tree().quit()))

	_how_to = PanelContainer.new()
	_how_to.add_theme_stylebox_override("panel", UiTheme.panel(UiTheme.RUST, 0.97))
	_how_to.set_anchors_preset(Control.PRESET_CENTER)
	_how_to.custom_minimum_size = Vector2(760, 560)
	_how_to.offset_left = -380
	_how_to.offset_top = -280
	_how_to.visible = false
	add_child(_how_to)
	var how_box := VBoxContainer.new()
	_how_to.add_child(how_box)
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.text = HOW_TO
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	how_box.add_child(text)
	how_box.add_child(UiTheme.make_button("ENTENDIDO", func(): _how_to.visible = false))


func _on_start_pressed() -> void:
	GameState.new_run()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
