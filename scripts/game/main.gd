extends Node2D
## Cena tática: monta o HexGrid a partir do GameState, aplica a névoa de dados por
## bioma e liga o jogador, a camada de dados do mapa e a HUD.

const BIOME_LAYER := {
	"industrial": "IndustrialGrid", "eco": "EcoGrid", "degrad": "DegradGrid",
	"nodes": "ElevatorGrid", "elevator": "ElevatorGrid",
}
const FOG_LAYER := {
	"industrial": "FogIndustrial", "eco": "FogEco", "degrad": "FogDegrad",
	"nodes": "FogElevator", "elevator": "FogElevator",
}
const FOG_COLORS := {
	"FogIndustrial": Color(0.1, 0.1, 0.1, 1.0),
	"FogEco": Color(0.05, 0.15, 0.05, 1.0),
	"FogDegrad": Color(0.15, 0.05, 0.2, 1.0),
	"FogElevator": Color(0.2, 0.15, 0.05, 1.0),
}

@onready var overlay: MapOverlay = $MapOverlay
@onready var player: Node2D = $N7Player
@onready var base_grid: TileMapLayer = $IndustrialGrid


func _ready() -> void:
	if GameState.map_terrain.is_empty() or GameState.run_over:
		GameState.new_run()
	setup_background()
	setup_fog()
	build_tiles()
	overlay.grid = base_grid
	player.setup(base_grid, overlay)
	GameState.map_changed.connect(_on_map_changed)
	GameState.run_finished.connect(_on_run_finished)
	_on_map_changed()
	AudioManager.set_ambience_active(true)
	tree_exiting.connect(func(): AudioManager.set_ambience_active(false))


func setup_background() -> void:
	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -1
	var bg_tex := TextureRect.new()
	bg_tex.texture = load("res://assets/bg-genesis.png")
	bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_tex.modulate = Color(0.55, 0.6, 0.7)
	bg_layer.add_child(bg_tex)
	add_child(bg_layer)


func setup_fog() -> void:
	var shader := load("res://shaders/fog_shader.gdshader")
	var noise := FastNoiseLite.new()
	noise.frequency = 0.02
	var noise_tex := NoiseTexture2D.new()
	noise_tex.noise = noise
	noise_tex.seamless = true
	for fog_name in FOG_COLORS:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("fog_color", FOG_COLORS[fog_name])
		mat.set_shader_parameter("noise_texture", noise_tex)
		var fog: TileMapLayer = get_node(fog_name)
		fog.material = mat
		fog.z_index = 20


func build_tiles() -> void:
	for layer in BIOME_LAYER.values() + FOG_LAYER.values():
		(get_node(layer) as TileMapLayer).clear()
	for cell in GameState.map_biomes:
		var biome: String = GameState.map_biomes[cell]
		(get_node(BIOME_LAYER[biome]) as TileMapLayer).set_cell(cell, 0, Vector2i.ZERO)
		(get_node(FOG_LAYER[biome]) as TileMapLayer).set_cell(cell, 0, Vector2i.ZERO)


func _on_map_changed() -> void:
	for cell in GameState.revealed:
		var biome: String = GameState.map_biomes.get(cell, "")
		if biome != "":
			(get_node(FOG_LAYER[biome]) as TileMapLayer).erase_cell(cell)
	# Anéis colapsados viram vazio: o fundo do domo aparece pelo buraco.
	if GameState.collapsed_radius > 0:
		for cell in GameState.map_biomes:
			if Hex.distance(cell, GameState.elevator_cell) >= GameState.collapsed_radius and cell != GameState.player_cell:
				(get_node(BIOME_LAYER[GameState.map_biomes[cell]]) as TileMapLayer).erase_cell(cell)
	overlay.queue_redraw()


func _on_run_finished(_result: Dictionary) -> void:
	await get_tree().create_timer(2.5).timeout
	get_tree().change_scene_to_file("res://scenes/Ending.tscn")
