class_name InventoryPanel
extends PanelContainer
## Mochila de carga (GDD §6 e §17 Fase 5): grade 5×4 em que o jogador encaixa as
## peças com o mouse. Modo "place": acoplar a peça recebida (clique esquerdo posiciona,
## direito gira se a peça permitir). Modo "manage": selecionar, usar ou descartar.

signal closed

const CELL := 58

var mode := "manage"
var placing_id := ""
var placing_shape: Array = []
var selected_uid := 0

var _grid_view: GridView
var _title: Label
var _info: Label
var _weight: Label
var _use_btn: Button
var _discard_btn: Button
var _rotate_btn: Button
var _close_btn: Button


func _ready() -> void:
	add_theme_stylebox_override("panel", UiTheme.panel(UiTheme.RUST, 0.97))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	_title = UiTheme.make_label("MOCHILA DE CARGA", UiTheme.CYAN, 20)
	box.add_child(_title)
	_weight = UiTheme.make_label("", UiTheme.TEXT)
	box.add_child(_weight)
	var center := CenterContainer.new()
	box.add_child(center)
	_grid_view = GridView.new()
	_grid_view.panel = self
	_grid_view.custom_minimum_size = Vector2(InventoryGrid.WIDTH * CELL, InventoryGrid.HEIGHT * CELL)
	center.add_child(_grid_view)
	_info = UiTheme.make_label("", UiTheme.MUTED)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size = Vector2(420, 60)
	box.add_child(_info)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(buttons)
	_rotate_btn = UiTheme.make_button("GIRAR", _rotate)
	_use_btn = UiTheme.make_button("USAR", _use_selected)
	_discard_btn = UiTheme.make_button("DESCARTAR", _discard_selected)
	_close_btn = UiTheme.make_button("FECHAR", _close)
	for b in [_rotate_btn, _use_btn, _discard_btn, _close_btn]:
		buttons.add_child(b)
	GameState.inventory_changed.connect(_refresh)
	visible = false


func open_manage() -> void:
	mode = "manage"
	placing_id = ""
	selected_uid = 0
	_open()


func open_place(item_id: String) -> void:
	mode = "place"
	placing_id = item_id
	placing_shape = ItemDB.shape(item_id)
	selected_uid = 0
	_open()


func _open() -> void:
	visible = true
	GameState.ui_blocking = true
	_refresh()


func _close() -> void:
	if mode == "place":
		GameState.cancel_pending_item()
	visible = false
	GameState.ui_blocking = false
	closed.emit()


func _refresh() -> void:
	var inv := GameState.inventory
	_weight.text = "Carga útil: %.0f kg   |   Espaço: %d/%d   |   Custo por passo: %.1f%%" % [GameState.load_kg(), inv.used_slots(), inv.capacity(), GameState.current_step_cost()]
	if mode == "place":
		var item := ItemDB.get_item(placing_id)
		_title.text = "ACOPLAR: " + item["name"].to_upper()
		var text := "%s (%.0f kg). Clique na grade para posicionar." % [item["description"], item["weight"]]
		text += " Clique direito ou GIRAR para rotacionar." if item["rotatable"] else " Núcleos têm formato fixo e não giram."
		if not inv.fits_anywhere(placing_id):
			text += "\nSem espaço contíguo: selecione um item e descarte-o."
		_info.text = text
		_close_btn.text = "CANCELAR"
		_rotate_btn.visible = item["rotatable"]
	else:
		_title.text = "MOCHILA DE CARGA"
		_info.text = "Selecione uma peça para usar ou descartar. Menos carga, menor o modificador de peso."
		_close_btn.text = "FECHAR"
		_rotate_btn.visible = false
	if selected_uid != 0 and inv.items.has(selected_uid):
		var sel := ItemDB.get_item(inv.items[selected_uid]["id"])
		_info.text = "%s — %.0f kg. %s" % [sel["name"], sel["weight"], sel["description"]]
		_use_btn.visible = not sel["use"].is_empty()
		_discard_btn.visible = sel["discardable"]
	else:
		selected_uid = 0
		_use_btn.visible = false
		_discard_btn.visible = false
	_grid_view.queue_redraw()


func _rotate() -> void:
	if mode == "place" and ItemDB.get_item(placing_id)["rotatable"]:
		placing_shape = InventoryGrid.rotated(placing_shape)
		_grid_view.queue_redraw()


func _use_selected() -> void:
	if selected_uid != 0:
		GameState.use_item(selected_uid)
		selected_uid = 0
		_refresh()


func _discard_selected() -> void:
	if selected_uid != 0:
		GameState.discard_item(selected_uid)
		selected_uid = 0
		_refresh()


func _on_grid_click(cell: Vector2i, button: int) -> void:
	if button == MOUSE_BUTTON_RIGHT:
		_rotate()
		return
	var uid := GameState.inventory.uid_at(cell)
	if uid != 0:
		selected_uid = uid
		_refresh()
		return
	if mode == "place":
		if GameState.place_pending_item(cell, placing_shape):
			AudioManager.play_success()
			mode = "manage"
			visible = false
			GameState.ui_blocking = false
			closed.emit()
		else:
			AudioManager.play_error()
			_info.text = "Colisão espacial: a peça não cabe nessa posição."


class GridView extends Control:
	var panel: InventoryPanel
	var hover := Vector2i(-1, -1)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			var cell := _cell_at(event.position)
			if cell != hover:
				hover = cell
				queue_redraw()
		elif event is InputEventMouseButton and event.pressed:
			var cell := _cell_at(event.position)
			if cell.x >= 0:
				panel._on_grid_click(cell, event.button_index)
			accept_event()

	func _cell_at(pos: Vector2) -> Vector2i:
		var c := Vector2i(floori(pos.x / InventoryPanel.CELL), floori(pos.y / InventoryPanel.CELL))
		if c.x < 0 or c.y < 0 or c.x >= InventoryGrid.WIDTH or c.y >= InventoryGrid.HEIGHT:
			return Vector2i(-1, -1)
		return c

	func _draw() -> void:
		var inv := GameState.inventory
		var s := float(InventoryPanel.CELL)
		for y in InventoryGrid.HEIGHT:
			for x in InventoryGrid.WIDTH:
				var r := Rect2(Vector2(x, y) * s + Vector2(2, 2), Vector2(s - 4, s - 4))
				draw_rect(r, Color(0.08, 0.1, 0.12))
				draw_rect(r, Color(0.2, 0.3, 0.32), false, 1.0)
		for uid in inv.items:
			var item: Dictionary = inv.items[uid]
			var color: Color = ItemDB.get_item(item["id"])["color"]
			for p in item["shape"]:
				var cell: Vector2i = item["origin"] + p
				var r := Rect2(Vector2(cell) * s + Vector2(3, 3), Vector2(s - 6, s - 6))
				draw_rect(r, color)
				if uid == panel.selected_uid:
					draw_rect(r, Color.WHITE, false, 3.0)
		if panel.mode == "place" and hover.x >= 0:
			var ok := inv.can_place(panel.placing_shape, hover)
			var ghost: Color = ItemDB.get_item(panel.placing_id)["color"]
			ghost.a = 0.55
			if not ok:
				ghost = Color(1, 0.2, 0.2, 0.5)
			for p in panel.placing_shape:
				var cell: Vector2i = hover + p
				if cell.x < InventoryGrid.WIDTH and cell.y < InventoryGrid.HEIGHT:
					draw_rect(Rect2(Vector2(cell) * s + Vector2(3, 3), Vector2(s - 6, s - 6)), ghost)
