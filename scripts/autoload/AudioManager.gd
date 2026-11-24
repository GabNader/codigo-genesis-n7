extends Node
## Áudio como feedback ativo dos sistemas (GDD §15).
## - Trilha com filtro passa-baixa abaixo de 15% de bateria (economia de processamento).
## - Alarme próprio ao cruzar 15% e 5% de bateria.
## - Ambiência sintetizada do bioma em que o N-7 está (zumbido, água, vento, drone).
## - Memórias recuperadas tocadas no sintetizador, com a trilha abaixada.

const LOW_POWER_BATTERY := 15.0
const CRITICAL_BATTERY := 5.0
const MUSIC_BUS := "Musica"
const MUSIC_DB := 0.0
const DUCK_DB := -14.0

var sfx_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer
var synth: Synth
var _beep: AudioStream
var _low_power := false
var _music_bus_idx := -1
var _ambience_active := false
var _alarm_level := 0   ## 0 = normal, 1 = abaixo de 15%, 2 = abaixo de 5%


func _ready() -> void:
	_setup_music_bus()
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = MUSIC_BUS
	add_child(bgm_player)
	synth = Synth.new()
	add_child(synth)
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


## Ligado pela cena tática: fora dela não há ambiência nem alarme.
func set_ambience_active(active: bool) -> void:
	_ambience_active = active
	_alarm_level = 0
	if not active:
		synth.set_biome("")
	_on_resources_updated()


func _on_resources_updated() -> void:
	var battery := GameState.battery
	set_low_power(battery < LOW_POWER_BATTERY and not GameState.run_over)
	if not _ambience_active:
		return
	synth.set_biome(GameState.biome_at(GameState.player_cell))
	var level := 0
	if battery < CRITICAL_BATTERY:
		level = 2
	elif battery < LOW_POWER_BATTERY:
		level = 1
	if level > _alarm_level and not GameState.run_over:
		synth.play_alarm()
		GameState.system_alert.emit("BATERIA CRÍTICA: %.0f%%" % battery if level == 2 else "BATERIA BAIXA: %.0f%%" % battery)
	_alarm_level = level


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


## Memória recuperada de um núcleo: abaixa a trilha e toca o trecho no sintetizador.
func play_memory(id: String) -> void:
	var notes: Array = Lore.MELODY_ARTE if id == "arte" else Lore.BIRDSONG
	_duck(true)
	synth.play_notes(notes, 0.55 if id == "arte" else 0.35)
	var total := 0.0
	for n in notes:
		total += n[n.size() - 1]
	get_tree().create_timer(total + 0.5).timeout.connect(_duck.bind(false))


func play_trinity() -> void:
	synth.play_notes(Lore.TRINITY_CHORD, 0.5)


func _duck(enabled: bool) -> void:
	var tween := create_tween()
	tween.tween_property(bgm_player, "volume_db", DUCK_DB if enabled else MUSIC_DB, 0.6)


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
