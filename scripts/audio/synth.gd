class_name Synth
extends Node
## Sintetizador procedural (GDD §15): ambiência por bioma e trechos musicais gerados em
## tempo real, sem arquivos de áudio. Dois canais: ambiente (contínuo, com crossfade
## entre biomas) e voz (fila de notas para memórias, alarmes e a Trindade).

const RATE := 22050.0
const WRAP := 1000.0                 ## segundos; múltiplo do período de todas as senoides
const CROSSFADE := 1.5               ## segundos para trocar de ambiência
const BIOMES := ["industrial", "eco", "degrad", "nodes"]

var target_biome := ""
var _gains := {"industrial": 0.0, "eco": 0.0, "degrad": 0.0, "nodes": 0.0}
var _amb: AudioStreamGeneratorPlayback
var _voice: AudioStreamGeneratorPlayback
var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _wind := 0.0
var _water := 0.0
var _drop_t := -1.0
var _drop_freq := 1200.0
var _drop_phase := 0.0
var _queue: Array = []
var _note: Array = []
var _note_t := 0.0
var _note_phase := 0.0


func _ready() -> void:
	_amb = _make_channel(-16.0)
	_voice = _make_channel(-8.0)


func _make_channel(volume_db: float) -> AudioStreamGeneratorPlayback:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = RATE
	gen.buffer_length = 0.25
	var player := AudioStreamPlayer.new()
	player.stream = gen
	player.volume_db = volume_db
	add_child(player)
	player.play()
	return player.get_stream_playback() as AudioStreamGeneratorPlayback


func set_biome(biome: String) -> void:
	target_biome = biome if biome in BIOMES else ""


## Fila de notas: [freq, duração] ou [freq_inicial, freq_final, duração]; freq 0 = pausa.
func play_notes(notes: Array, volume := 0.5) -> void:
	for n in notes:
		if n.size() == 2:
			_queue.append([n[0], n[0], n[1], volume])
		else:
			_queue.append([n[0], n[1], n[2], volume])


func is_playing_voice() -> bool:
	return not _note.is_empty() or not _queue.is_empty()


func play_alarm() -> void:
	play_notes([[880.0, 0.12], [0.0, 0.05], [660.0, 0.12], [0.0, 0.1], [880.0, 0.12], [0.0, 0.05], [660.0, 0.12]], 0.45)


func _process(delta: float) -> void:
	var step := delta / CROSSFADE
	for b in BIOMES:
		_gains[b] = move_toward(_gains[b], 1.0 if b == target_biome else 0.0, step)
	if _amb:
		_fill_ambient(_amb.get_frames_available())
	if _voice:
		_fill_voice(_voice.get_frames_available())


func _fill_ambient(frames: int) -> void:
	var g_ind: float = _gains["industrial"]
	var g_eco: float = _gains["eco"]
	var g_deg: float = _gains["degrad"]
	var g_nod: float = _gains["nodes"]
	var dt := 1.0 / RATE
	for i in frames:
		_t = fmod(_t + dt, WRAP)
		var s := 0.0
		if g_ind > 0.001:
			# Zumbido elétrico: 60 Hz e harmônicos com tremolo lento.
			var hum := 0.3 * sin(TAU * 60.0 * _t) + 0.15 * sin(TAU * 120.0 * _t) + 0.07 * sin(TAU * 180.0 * _t)
			s += g_ind * hum * (0.8 + 0.2 * sin(TAU * 0.3 * _t))
		if g_deg > 0.001:
			# Vento: ruído filtrado com corte e volume oscilando devagar.
			var coef := 0.02 + 0.015 * sin(TAU * 0.07 * _t)
			_wind += (_rng.randf_range(-1.0, 1.0) - _wind) * coef
			s += g_deg * _wind * 2.6 * (0.55 + 0.45 * sin(TAU * 0.11 * _t))
		if g_eco > 0.001:
			# Água: correnteza (ruído filtrado) e gotas aleatórias.
			_water += (_rng.randf_range(-1.0, 1.0) - _water) * 0.09
			s += g_eco * _water * 0.55
			if _drop_t < 0.0 and _rng.randf() < 1.0 / (RATE * 0.4):
				_drop_t = 0.0
				_drop_freq = _rng.randf_range(900.0, 1700.0)
			if _drop_t >= 0.0:
				_drop_phase = fmod(_drop_phase + TAU * _drop_freq * (1.0 + _drop_t * 6.0) * dt, TAU)
				s += g_eco * 0.3 * exp(-_drop_t * 28.0) * sin(_drop_phase)
				_drop_t += dt
				if _drop_t > 0.25:
					_drop_t = -1.0
		if g_nod > 0.001:
			# Nódulos: drone harmônico com batimento lento.
			s += g_nod * 0.1 * (sin(TAU * 220.0 * _t) + sin(TAU * 221.5 * _t) + 0.5 * sin(TAU * 330.0 * _t))
		_amb.push_frame(Vector2(s, s))


func _fill_voice(frames: int) -> void:
	var dt := 1.0 / RATE
	for i in frames:
		if _note.is_empty():
			if _queue.is_empty():
				_voice.push_frame(Vector2.ZERO)
				continue
			_note = _queue.pop_front()
			_note_t = 0.0
		var dur: float = _note[2]
		var k := _note_t / dur
		var f: float = lerpf(_note[0], _note[1], k)
		var s := 0.0
		if f > 0.0:
			_note_phase = fmod(_note_phase + TAU * f * dt, TAU)
			var env := minf(1.0, _note_t / 0.01) * pow(1.0 - k, 0.6)
			s = (sin(_note_phase) + 0.3 * sin(2.0 * _note_phase)) * env * float(_note[3])
		_voice.push_frame(Vector2(s, s))
		_note_t += dt
		if _note_t >= dur:
			_note = []
