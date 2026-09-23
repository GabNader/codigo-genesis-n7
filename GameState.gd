extends Node

signal resources_updated
signal round_advanced(current_round: int)
signal game_over(reason: String)
signal move_confirmed
signal lidar_pulsed
signal choice_event_triggered(event_data: Dictionary)
signal system_alert(message: String)

var current_round: int = 1

var battery: float = 100.0
var integrity: float = 100.0
var load_weight: float = 0.0
var max_load: float = 50.0

# Variáveis da Missão Principal (Trindade)
var core_logic: bool = true 
var core_nature: bool = false
var core_art: bool = false

# Dicionário que guarda as coordenadas dos eventos no mapa
var map_events: Dictionary = {} 

# Dicionário que guarda os biomas de cada coordenada
var map_biomes: Dictionary = {}

# --- BANCOS DE DADOS NARRATIVOS ---
var choice_events: Array = [
	{
		"title": "O Fruto de Silício",
		"description": "Um terminal solitário exibe dados puros. Consumi-lo iniciará um expurgo doloroso no sistema local, mas trará conhecimento da Queda.",
		"options": [
			{"label": "[ Baixar Dados ]\n+10kg Carga | -15 Integridade", "action": "lore_apple", "req_battery": 0},
			{"label": "[ Abster-se ]\nSeguir em ignorância", "action": "ignore", "req_battery": 0}
		]
	}
]

var hazard_events: Array = [
	{
		"title": "Pilar de Sal",
		"description": "Uma tentativa automática de ler dados corrompidos congelou a articulação do N-7 em uma crosta branca e rígida. O peso do passado atrasa a máquina.",
		"options": [
			{"label": "[ Romper Crosta ]\n-10% Integridade", "action": "hazard_salt", "req_battery": 0}
		]
	}
]

var bonus_events: Array = [
	{
		"title": "Maná Sintético",
		"description": "Um antigo drone colapsou do teto, espalhando células de energia intactas sobre a terra árida. Há provisões para hoje.",
		"options": [
			{"label": "[ Recolher Dádiva ]\n+25% Bateria", "action": "bonus_manna", "req_battery": 0}
		]
	}
]

var event_nature = {
	"title": "O Jardim Suspenso (Núcleo da Natureza)",
	"description": "Uma câmara criogênica abriga o DNA de espécies extintas. A extração exige que o N-7 desvie energia vital para manter o núcleo estabilizado.",
	"options": [
		{"label": "[ Extrair Natureza ]\n+15kg Carga | -30 Bat", "action": "extract_nature", "req_battery": 30},
		{"label": "[ Abster-se ]\nO peso é grande demais", "action": "ignore", "req_battery": 0}
	]
}

var event_art = {
	"title": "O Cofre das Memórias (Núcleo da Arte)",
	"description": "Servidores ecoam com sinfonias distorcidas. A beleza do passado humano exige um sacrifício físico da máquina para ser carregada.",
	"options": [
		{"label": "[ Extrair Arte ]\n+15kg Carga | -25 Integridade", "action": "extract_art", "req_battery": 0},
		{"label": "[ Abster-se ]\nIgnorar beleza", "action": "ignore", "req_battery": 0}
	]
}

# --- FUNÇÕES DE CONTROLE DE FLUXO ---

func _ready() -> void:
	reset_state()

func reset_state() -> void:
	current_round = 1
	battery = 100.0
	integrity = 100.0
	load_weight = 0.0
	core_logic = true
	core_nature = false
	core_art = false
	map_events.clear()
	map_biomes.clear()
	resources_updated.emit()

func trigger_specific_event(event_type: String) -> void:
	var event_data: Dictionary
	
	if event_type == "core_nature": 
		event_data = event_nature
	elif event_type == "core_art": 
		event_data = event_art
	elif event_type == "hazard": 
		event_data = hazard_events.pick_random()
	elif event_type == "bonus": 
		event_data = bonus_events.pick_random()
	elif event_type == "choice": 
		event_data = choice_events.pick_random()
		
	choice_event_triggered.emit(event_data)

func resolve_choice(action: String) -> void:
	if action == "extract_nature":
		core_nature = true
		load_weight += 15.0
		consume_battery(30.0)
	elif action == "extract_art":
		core_art = true
		load_weight += 15.0
		apply_damage(25.0)
	elif action == "lore_apple":
		load_weight += 10.0
		apply_damage(15.0)
	elif action == "hazard_salt":
		apply_damage(10.0)
	elif action == "bonus_manna":
		add_battery(25.0)
	elif action == "ignore":
		print("Sistema: Ação ignorada. Conservando estado atual.")
		
	resources_updated.emit()

# --- FUNÇÕES DE RECURSOS E MATEMÁTICA ---

func add_battery(amount: float) -> void:
	battery += amount
	if battery > 100.0:
		battery = 100.0
	resources_updated.emit()

func consume_battery(base_amount: float) -> void:
	# Calcula o custo final somando o peso extraído
	var final_cost: float = base_amount + (load_weight * 0.5)
	battery -= final_cost
	if battery <= 0:
		battery = 0
		game_over.emit("Falha Crítica: Bateria esgotada.")
	resources_updated.emit()

func apply_damage(amount: float) -> void:
	integrity -= amount
	if integrity <= 0:
		integrity = 0
		game_over.emit("Falha Crítica: Integridade do chassi comprometida.")
	resources_updated.emit()

func advance_round() -> void:
	current_round += 1
	round_advanced.emit(current_round)
