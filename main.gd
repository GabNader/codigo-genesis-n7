extends Node2D

@onready var ind_grid = $IndustrialGrid
@onready var eco_grid = $EcoGrid
@onready var degrad_grid = $DegradGrid
@onready var elev_grid = $ElevatorGrid

@onready var ind_fog = $FogIndustrial
@onready var eco_fog = $FogEco
@onready var degrad_fog = $FogDegrad
@onready var elev_fog = $FogElevator

func _ready() -> void:
	GameState.game_over.connect(_on_game_over)
	setup_background()
	setup_fog()
	generate_map()
	$N7Player.generate_random_events()

func setup_background() -> void:
	var bg_layer = CanvasLayer.new()
	bg_layer.layer = -1
	
	var bg_tex = TextureRect.new()
	bg_tex.texture = load("res://assets/bg-genesis.png")
	# Expande a imagem para preencher toda a tela
	bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	bg_layer.add_child(bg_tex)
	add_child(bg_layer)

func setup_fog() -> void:
	var shader = load("res://fog_shader.gdshader")
	var noise = FastNoiseLite.new()
	noise.frequency = 0.02
	var noise_tex = NoiseTexture2D.new()
	noise_tex.noise = noise
	noise_tex.seamless = true
	
	var setup_mat = func(fog_node, color):
		var mat = ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("fog_color", color)
		mat.set_shader_parameter("noise_texture", noise_tex)
		fog_node.material = mat
		
	setup_mat.call(ind_fog, Color(0.1, 0.1, 0.1, 1.0))
	setup_mat.call(eco_fog, Color(0.05, 0.15, 0.05, 1.0))
	setup_mat.call(degrad_fog, Color(0.15, 0.05, 0.2, 1.0))
	setup_mat.call(elev_fog, Color(0.2, 0.15, 0.05, 1.0))
	
	$N7Player.fog_grids = [ind_fog, eco_fog, degrad_fog, elev_fog]

func get_hex_dist(a: Vector2i, b: Vector2i) -> int:
	var q = a.x - b.x
	var r = a.y - b.y
	return (abs(q) + abs(q + r) + abs(r)) / 2

func generate_map() -> void:
	var radius = 7
	var spawn_pos = Vector2i(0, 6)
	
	# Sementes (clusters) para gerar manchas orgânicas
	var ind_seeds = [Vector2i(0, 6), Vector2i(4, -4), Vector2i(-4, 4)]
	var eco_seeds = [Vector2i(-4, 0), Vector2i(3, 3)]
	var deg_seeds = [Vector2i(4, 0), Vector2i(-3, -3)]
	
	for q in range(-radius, radius + 1):
		var r1 = max(-radius, -q - radius)
		var r2 = min(radius, -q + radius)
		for r in range(r1, r2 + 1):
			var cell = Vector2i(q, r)
			var biome = ""
			var target_grid = null
			
			var target_fog = null
			
			if cell == Vector2i(0, 0):
				biome = "elevator"
				target_grid = elev_grid
				target_fog = elev_fog
			elif get_hex_dist(cell, spawn_pos) <= 2:
				biome = "industrial" # Força área ao redor do start segura
				target_grid = ind_grid
				target_fog = ind_fog
			else:
				var min_dist = 9999
				var best_biome = "industrial"
				
				for s in ind_seeds:
					var d = get_hex_dist(cell, s)
					if d < min_dist: min_dist = d; best_biome = "industrial"
				for s in eco_seeds:
					var d = get_hex_dist(cell, s)
					if d < min_dist: min_dist = d; best_biome = "eco"
				for s in deg_seeds:
					var d = get_hex_dist(cell, s)
					if d < min_dist: min_dist = d; best_biome = "degrad"
						
				biome = best_biome
				if biome == "industrial": target_grid = ind_grid; target_fog = ind_fog
				elif biome == "eco": target_grid = eco_grid; target_fog = eco_fog
				elif biome == "degrad": target_grid = degrad_grid; target_fog = degrad_fog
				
			target_grid.set_cell(cell, 0, Vector2i(0, 0))
			target_fog.set_cell(cell, 0, Vector2i(0, 0))
			GameState.map_biomes[cell] = biome

func _on_game_over(reason: String) -> void:
	print("--- PROTOCOLO ENCERRADO ---")
	print("Motivo: ", reason)
	
	# Congela a entrada de dados para evitar cliques extras
	get_tree().root.set_disable_input(true)
	
	# Cria um delay de 2.5 segundos para o jogador ler o log antes de sair
	await get_tree().create_timer(2.5).timeout
	
	# Restaura os controles e retorna ao Menu Inicial
	get_tree().root.set_disable_input(false)
	get_tree().change_scene_to_file("res://UI_Menu.tscn")
