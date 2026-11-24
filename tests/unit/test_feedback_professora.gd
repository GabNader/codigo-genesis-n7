extends GutTest
## Feedback da professora (issue #4): o jogador pode confiar no que lê, o primeiro
## turno ensina, a história aparece na exploração e a Trindade tem resposta.

const GameStateScript = preload("res://scripts/autoload/GameState.gd")

var state


func before_each() -> void:
	state = autofree(GameStateScript.new())
	state.new_run(42)
	state.statuses.clear()


func _all_options() -> Array:
	var events := []
	for id in EventDB.EVENTS:
		events.append(EventDB.build(id))
	events += [EventDB.core_nature(), EventDB.core_art(), EventDB.substation(0.65), EventDB.nodule(),
		EventDB.item_cache("kit_reparo"), EventDB.elevator(true, true, 50.0)]
	var options := []
	for e in events:
		options += e["options"]
	return options


func test_rotulos_nao_tem_numeros_escritos_a_mao() -> void:
	var digits := RegEx.create_from_string("[0-9%]")
	for opt in _all_options():
		assert_null(digits.search(opt["label"]), "custo no rótulo deve vir dos efeitos: " + opt["label"])


func test_texto_do_botao_mostra_os_efeitos_reais() -> void:
	var nature: Dictionary = EventDB.core_nature()["options"][0]
	assert_eq(EventDB.option_text(nature), "Extrair a Natureza  (peça 3×2, +15 kg | -30% Bateria)")
	var sentinel: Dictionary = EventDB.build("sentinela_defeituosa")["options"][0]
	assert_eq(EventDB.option_text(sentinel), "Roubar a bateria  (70%: +30% Bateria | 30%: -25 Integridade)")
	assert_eq(EventDB.option_text(EventDB.build("sucata_magnetica")["options"][0]), "Aceitar o peso  (+5 kg por 3 turnos)")


## Regressão do relato: "o núcleo da Natureza anunciava custo de 30 e descontou 45".
func test_extrair_natureza_desconta_exatamente_o_anunciado_mesmo_com_carga() -> void:
	state.inventory.place("dados_queda", Vector2i(0, 3))
	state.apply_effects({"load_temp": [5.0, 3]})
	var before: float = state.battery
	state.active_event = EventDB.core_nature()
	state.active_event["cell"] = state.player_cell
	state.choose_option(0)
	state.place_pending_item(Vector2i.ZERO, ItemDB.shape("nucleo_natureza"))
	assert_almost_eq(before - state.battery, 30.0, 0.001)


func test_previa_da_rota_e_igual_ao_gasto_real() -> void:
	var a: Vector2i = state.player_cell + Vector2i(0, -1)
	var b: Vector2i = a + Vector2i(0, -1)
	var c: Vector2i = b + Vector2i(1, -1)
	state.map_terrain[a] = Terrain.RAIZES
	state.map_terrain[b] = Terrain.FIREWALL
	state.map_terrain[c] = Terrain.NORMAL
	state.inventory.place("nucleo_arte", Vector2i.ZERO)
	for cell in [a, b, c]:
		state.revealed[cell] = true
		state._scan_cell(cell, false, false)
	var preview: float = state.route_summary([a, b, c])["battery"]
	var before: float = state.battery
	var prev: Vector2i = state.player_cell
	for cell in [a, b, c]:
		assert_true(state.enter_cell(prev, cell)["ok"])
		prev = cell
	assert_almost_eq(before - state.battery, preview, 0.001)


func test_chegada_a_um_bioma_conta_a_historia_uma_vez() -> void:
	watch_signals(state)
	state._announce_biome("eco")
	state._announce_biome("eco")
	assert_signal_emit_count(state, "story_beat", 1)
	assert_eq(get_signal_parameters(state, "story_beat")[0], "Setor Eco-Vegetativo")


func test_extrair_arte_recupera_a_memoria_musical() -> void:
	watch_signals(state)
	state.active_event = EventDB.core_art()
	state.active_event["cell"] = state.player_cell
	state.choose_option(0)
	state.place_pending_item(Vector2i.ZERO, ItemDB.shape("nucleo_arte"))
	assert_signal_emitted_with_parameters(state, "memory_recovered", ["arte"])
	assert_gt(Lore.MELODY_ARTE.size(), 8)


func test_reunir_os_tres_nucleos_tem_resposta_unica() -> void:
	watch_signals(state)
	state.inventory.place("nucleo_natureza", Vector2i.ZERO)
	state.active_event = EventDB.core_art()
	state.active_event["cell"] = state.player_cell
	state.choose_option(0)
	state.place_pending_item(Vector2i(3, 0), ItemDB.shape("nucleo_arte"))
	assert_signal_emit_count(state, "trinity_completed", 1)


func test_lidar_avisa_quando_termina() -> void:
	watch_signals(state)
	state.pulse_lidar()
	assert_signal_emitted(state, "lidar_done")


func test_sintetizador_toca_notas_sem_arquivos() -> void:
	var synth: Synth = add_child_autofree(Synth.new())
	synth.set_biome("industrial")
	synth.play_notes(Lore.TRINITY_CHORD)
	assert_true(synth.is_playing_voice())
	await wait_frames(3)
	assert_eq(synth.target_biome, "industrial")


func test_tutorial_avanca_com_as_acoes_reais() -> void:
	GameState.new_run(7)
	var main: Node = add_child_autofree(load("res://scenes/Main.tscn").instantiate())
	await wait_frames(2)
	for child in main.get_node("UiHud").get_children():
		if child is Tutorial:
			child.queue_free()
	var tutorial := Tutorial.new()
	main.get_node("UiHud").add_child(tutorial)
	var lidar := Button.new()
	var confirm := Button.new()
	autofree(lidar)
	autofree(confirm)
	tutorial.start(lidar, confirm, main.get_node("MapOverlay"))
	assert_eq(tutorial.step, Tutorial.Step.AWAKE)
	assert_true(GameState.ui_blocking, "o despertar segura o jogo")
	tutorial._go_lidar()
	assert_eq(tutorial.step, Tutorial.Step.LIDAR)
	GameState.pulse_lidar()
	assert_eq(tutorial.step, Tutorial.Step.SELECT)
	assert_ne(main.get_node("MapOverlay").highlight_cell, MapOverlay.NO_CELL, "vizinho destacado")
	var cell: Vector2i = main.get_node("MapOverlay").highlight_cell
	GameState.route_previewed.emit(1, GameState.route_summary([cell]))
	assert_eq(tutorial.step, Tutorial.Step.CONFIRM)
	assert_string_contains(tutorial._tip_text.text, "1.5%")
	GameState.round_advanced.emit(2)
	assert_eq(tutorial.step, Tutorial.Step.GOAL)
	GameState.ui_blocking = false
