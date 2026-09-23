extends Node2D

@export var hex_grid: TileMapLayer
var fog_grids: Array = []
var current_cell: Vector2i = Vector2i(0, 6)
var selected_cell: Vector2i = Vector2i(0, 0)
var has_selection: bool = false

@onready var selection_highlight: Sprite2D = $SelectionHighlight
@onready var tread_sound: AudioStreamPlayer = $TreadSound
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
# Dicionário de referências visuais dos marcadores
var event_markers_visuals: Dictionary = {}

func _ready() -> void:
	GameState.move_confirmed.connect(_on_move_confirmed)
	GameState.lidar_pulsed.connect(_on_lidar_pulsed)
	
	if hex_grid:
		global_position = hex_grid.map_to_local(current_cell)
		
	selection_highlight.visible = false
	
	for fg in fog_grids:
		fg.erase_cell(current_cell)

# Planta os eventos e a missão principal no mapa
func generate_random_events() -> void:
	var all_cells = hex_grid.get_used_cells()
	var industrial_cells = []
	for cell in all_cells:
		if GameState.map_biomes.get(cell) == "industrial" and cell != current_cell:
			industrial_cells.append(cell)
	industrial_cells.shuffle()
	
	# Planta os núcleos principais (garantidos no mapa)
	if industrial_cells.size() >= 2:
		GameState.map_events[industrial_cells[0]] = "core_nature"
		GameState.map_events[industrial_cells[1]] = "core_art"
	
	# Planta os eventos aleatórios em quase todos os hexágonos disponíveis
	for i in range(2, industrial_cells.size()):
		var rand_event = randi() % 3
		if rand_event == 0:
			GameState.map_events[industrial_cells[i]] = "hazard"
		elif rand_event == 1:
			GameState.map_events[industrial_cells[i]] = "bonus"
		else:
			GameState.map_events[industrial_cells[i]] = "choice"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked_pos = get_global_mouse_position()
		if hex_grid:
			var target_cell = hex_grid.local_to_map(clicked_pos)
			if GameState.map_biomes.has(target_cell):
				var has_fog = false
				for fg in fog_grids:
					if fg.get_cell_source_id(target_cell) != -1:
						has_fog = true
						break
				if not has_fog:
					select_cell(target_cell)
				else:
					print("Sistema: Área desconhecida. Utilize o LiDAR primeiro.")

func select_cell(cell: Vector2i) -> void:
	if cell == current_cell:
		has_selection = false
		selection_highlight.visible = false
		return
		
	var valid_neighbors = hex_grid.get_surrounding_cells(current_cell)
	
	if cell in valid_neighbors:
		if GameState.map_biomes.has(cell) and GameState.map_biomes[cell] != "industrial":
			GameState.system_alert.emit("Acesso Negado: Bioma bloqueado nesta demo.")
			return
			
		selected_cell = cell
		has_selection = true
		selection_highlight.global_position = hex_grid.map_to_local(cell)
		selection_highlight.visible = true
	else:
		print("Erro: Setor fora do alcance motor.")

func _on_move_confirmed() -> void:
	if not has_selection: return
		
	var battery_cost: float = 2.0
	
	if GameState.battery >= battery_cost:
		GameState.consume_battery(battery_cost)
		
		# Move o robô para o novo hexágono
		current_cell = selected_cell
		move_to_cell_animated(current_cell)
		
		has_selection = false
		selection_highlight.visible = false
		
		# Checa se pisou em algum evento
		check_and_trigger_event(current_cell)
		
		GameState.advance_round()
	else:
		print("Falha Crítica: Energia Insuficiente.")

# GATILHO UNIFICADO: Chama qualquer evento para o Modal e limpa do chão
func check_and_trigger_event(cell: Vector2i) -> void:
	if GameState.map_events.has(cell):
		var event_type = GameState.map_events[cell]
		
		# Chama o evento dinâmico
		GameState.trigger_specific_event(event_type) 
			
		# Remove do mapa e apaga o holograma
		GameState.map_events.erase(cell)
		if event_markers_visuals.has(cell):
			event_markers_visuals[cell].queue_free()
			event_markers_visuals.erase(cell)

func _on_lidar_pulsed() -> void:
	var lidar_cost: float = 5.0 
	
	if GameState.battery >= lidar_cost:
		GameState.consume_battery(lidar_cost)
		
		var neighbors = hex_grid.get_surrounding_cells(current_cell)
		
		for fg in fog_grids:
			fg.erase_cell(current_cell)
			for neighbor in neighbors:
				fg.erase_cell(neighbor)
				
		for neighbor in neighbors:
			if GameState.map_biomes.has(neighbor) and GameState.map_events.has(neighbor):
				reveal_event_marker(neighbor)
				
		var lidar_effect = LidarEffect.new()
		add_child(lidar_effect)
		var tween = create_tween()
		tween.tween_property(lidar_effect, "radius", 500.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(lidar_effect, "modulate:a", 0.0, 0.5)
		tween.tween_callback(lidar_effect.queue_free)
	else:
		print("LiDAR Falhou: Bateria insuficiente.")

# ARQUITETURA VISUAL: Cores separadas para cada tipo de evento
func reveal_event_marker(cell: Vector2i) -> void:
	if event_markers_visuals.has(cell): return 
	
	var marker = Sprite2D.new()
	marker.texture = load("res://icon.svg") 
	marker.scale = Vector2(0.4, 0.4) 
	
	if GameState.map_events[cell] == "hazard":
		marker.modulate = Color(1, 0, 0, 1.0) # Vermelho
	elif GameState.map_events[cell] == "bonus":
		marker.modulate = Color(0, 1, 0, 1.0) # Verde
	elif GameState.map_events[cell] == "choice":
		marker.modulate = Color(1, 1, 0, 1.0) # Amarelo
	elif GameState.map_events[cell] == "core_nature":
		marker.modulate = Color(0, 1, 0.5, 1.0) # Verde Água
	elif GameState.map_events[cell] == "core_art":
		marker.modulate = Color(1, 0, 1, 1.0) # Magenta Brilhante
		
	marker.position = hex_grid.map_to_local(cell)
	hex_grid.add_child(marker)
	event_markers_visuals[cell] = marker

func move_to_cell_animated(cell: Vector2i) -> void:
	if not hex_grid: return
	
	var target_pos = hex_grid.map_to_local(cell)
	var tween = create_tween()
	
	# 1. ACELERA O MOTOR E TOCA O SOM
	animated_sprite.speed_scale = 3.0 # Toca o idle 3x mais rápido (parece motor acelerando)
	tread_sound.play(0.4)
	
	# 2. DESLIZA O ROBÔ ATÉ O HEXÁGONO
	# TRANS_LINEAR faz ele deslizar num ritmo constante (como uma esteira)
	tween.tween_property(self, "global_position", target_pos, 0.4).set_trans(Tween.TRANS_LINEAR)
	
	# 3. ESPERA CHEGAR NO DESTINO
	await tween.finished
	
	# 4. DESLIGA O SOM E DESACELERA O MOTOR
	tread_sound.stop()
	animated_sprite.speed_scale = 1.0 # Volta o idle para a velocidade normal

class LidarEffect extends Node2D:
	var radius: float = 0.0
	
	func _process(_delta: float) -> void:
		queue_redraw()
		
	func _draw() -> void:
		draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color(0.0, 1.0, 1.0, 1.0), 8.0, true)
