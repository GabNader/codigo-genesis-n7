extends Node

# Criação de dois canais separados na memória
var sfx_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer

func _ready() -> void:
	# Inicializa o canal de Efeitos Sonoros (Bip)
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	
	# Inicializa o canal de Música de Fundo (Trilha)
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	
	# Dispara a trilha sonora assim que o jogo abrir
	play_music()

func play_beep() -> void:
	# Caminho atualizado para .mp3
	var beep_stream = load("res://assets/audio/beep.mp3")
	if beep_stream:
		sfx_player.stream = beep_stream
		sfx_player.play()
	else:
		push_warning("Arquivo beep.mp3 não encontrado no sistema.")

func play_music() -> void:
	# Caminho para a trilha melancólica
	var music_stream = load("res://assets/audio/trilha.mp3")
	if music_stream:
		if music_stream is AudioStreamMP3 or music_stream is AudioStreamOggVorbis:
			music_stream.loop = true
			
		bgm_player.stream = music_stream
		bgm_player.play()
	else:
		push_warning("Arquivo trilha.mp3 não encontrado no sistema.")
