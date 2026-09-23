extends Control

@onready var start_button: Button = $VBoxContainer/StartButton

func _ready() -> void:
	# Ouve o clique do botão de iniciar
	start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	
	# Reinicia o estado global para garantir que o N-7 inicie zerado
	GameState.reset_state()
	
	# Destrói o Menu e carrega a cena do jogo tático
	get_tree().change_scene_to_file("res://Main.tscn")
