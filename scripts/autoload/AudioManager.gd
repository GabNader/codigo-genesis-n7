extends Node
## Áudio como feedback ativo dos sistemas (GDD §15).
## A trilha passa por um filtro passa-baixa quando a bateria cai abaixo de 15%,
## simulando a economia de processamento do N-7.

const LOW_POWER_BATTERY := 15.0
const MUSIC_BUS := "Musica"

var sfx_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer
var _beep: AudioStream
var _low_power := false
var _music_bus_idx := -1


func _ready() -> void:
	_setup_music_bus()
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = MUSIC_BUS
	add_child(bgm_player)
	_beep = load("res://assets/audio/beep.mp3")
	GameState.resources_updated.connect(_on_resources_updated)
	play_music()


func _setup_music_bus() -> void:
	_music_bus_idx = AudioServer.get_bus_index(MUSIC_BUS)
	if _music_bus_idx == -1:
		AudioServer.add_bus()
		_music_bus_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_music_bus_idx, MUSIC_BUS)
		AudioServer.set_bus_send(_music_bus_idx, "Master")
		var low_pass := AudioEffectLowPassFilter.new()
		low_pass.cutoff_hz = 600.0
		AudioServer.add_bus_effect(_music_bus_idx, low_pass)
	AudioServer.set_bus_effect_enabled(_music_bus_idx, 0, false)


func _on_resources_updated() -> void:
	set_low_power(GameState.battery < LOW_POWER_BATTERY and not GameState.run_over)


func set_low_power(enabled: bool) -> void:
	if enabled == _low_power:
		return
	_low_power = enabled
	AudioServer.set_bus_effect_enabled(_music_bus_idx, 0, enabled)


func is_low_power() -> bool:
	return _low_power


func play_beep() -> void:
	_play_sfx(1.0)


## Bip de erro crítico: mesmo sonar, muito mais grave (dano, rota bloqueada).
func play_error() -> void:
	_play_sfx(0.45)


func play_success() -> void:
	_play_sfx(1.5)


func _play_sfx(pitch: float) -> void:
	if _beep == null:
		return
	sfx_player.stream = _beep
	sfx_player.pitch_scale = pitch
	sfx_player.play()


func play_music() -> void:
	var music_stream = load("res://assets/audio/trilha.mp3")
	if music_stream == null:
		push_warning("Arquivo trilha.mp3 não encontrado.")
		return
	if music_stream is AudioStreamMP3 or music_stream is AudioStreamOggVorbis:
		music_stream.loop = true
	bgm_player.stream = music_stream
	bgm_player.play()
