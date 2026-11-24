extends GutTest

const GameStateScript = preload("res://scripts/autoload/GameState.gd")

var state


func before_each() -> void:
	state = autofree(GameStateScript.new())
	state.new_run(42)


func test_new_run_comeca_com_recursos_cheios_no_spawn() -> void:
	assert_eq(state.current_round, 1)
	assert_eq(state.battery, 100.0)
	assert_eq(state.integrity, 100.0)
	assert_eq(state.load_kg(), 0.0)
	assert_eq(state.player_cell, Vector2i(0, MapGenerator.DEFAULT_RADIUS))
	assert_true(state.revealed.has(state.player_cell))


func test_mesma_semente_gera_o_mesmo_domo() -> void:
	var other = autofree(GameStateScript.new())
	other.new_run(42)
	assert_eq(other.map_terrain, state.map_terrain)
	assert_eq(other.map_pois.keys(), state.map_pois.keys())


func test_lidar_custa_5_e_escaneia_raio_3() -> void:
	var cells: Array = state.pulse_lidar()
	assert_eq(state.battery, 95.0)
	for c in cells:
		assert_lte(Hex.distance(c, state.player_cell), Economy.LIDAR_RADIUS)
		assert_true(state.scanned.has(c))
	assert_eq(state.stats["lidar"], 1)


func test_lidar_sem_bateria_nao_faz_nada() -> void:
	state.battery = 3.0
	var cells: Array = state.pulse_lidar()
	assert_eq(cells.size(), 0)
	assert_eq(state.battery, 3.0)


func test_custo_do_passo_segue_a_formula_do_gdd() -> void:
	var to: Vector2i = state.player_cell + Vector2i(0, -1)
	state.map_terrain[to] = Terrain.NORMAL
	state.map_terrain[state.player_cell] = Terrain.NORMAL
	assert_almost_eq(state.step_battery_cost(state.player_cell, to), 1.5, 0.001)
	state.inventory.place("nucleo_natureza", Vector2i.ZERO)
	assert_almost_eq(state.step_battery_cost(state.player_cell, to), 3.0, 0.001)


func test_vazamento_tira_20_de_integridade() -> void:
	var to: Vector2i = state.player_cell + Vector2i(0, -1)
	state.map_terrain[to] = Terrain.VAZAMENTO
	state.scanned[to] = {"terrain": Terrain.VAZAMENTO, "poi": false, "uncertain": false}
	state.statuses.clear()
	var res: Dictionary = state.enter_cell(state.player_cell, to)
	assert_true(res["ok"])
	assert_eq(state.integrity, 80.0)
	assert_eq(state.player_cell, to)


func test_firewall_cobra_pedagio_fixo() -> void:
	var to: Vector2i = state.player_cell + Vector2i(0, -1)
	state.map_terrain[to] = Terrain.FIREWALL
	state.enter_cell(state.player_cell, to)
	assert_almost_eq(state.battery, 100.0 - 1.5 - Economy.FIREWALL_COST, 0.001)


func test_sair_de_raizes_custa_o_triplo() -> void:
	var to: Vector2i = state.player_cell + Vector2i(0, -1)
	state.map_terrain[state.player_cell] = Terrain.RAIZES
	assert_almost_eq(state.step_battery_cost(state.player_cell, to), 4.5, 0.001)


func test_fenda_oculta_interrompe_a_rota() -> void:
	var to: Vector2i = state.player_cell + Vector2i(0, -1)
	state.map_terrain[to] = Terrain.FENDA
	var start: Vector2i = state.player_cell
	var res: Dictionary = state.enter_cell(start, to)
	assert_false(res["ok"])
	assert_true(res["stop"])
	assert_eq(state.player_cell, start)
	assert_eq(state.scanned[to]["terrain"], Terrain.FENDA)


func test_fendas_vizinhas_sao_visiveis_sem_lidar() -> void:
	var n: Vector2i = state.player_cell + Vector2i(1, -1)
	state.map_terrain[n] = Terrain.FENDA
	state._reveal_around(state.player_cell)
	assert_eq(state.scanned[n]["terrain"], Terrain.FENDA)


func test_resumo_de_rota_soma_custos_e_marca_falta_de_bateria() -> void:
	var a: Vector2i = state.player_cell + Vector2i(0, -1)
	var b: Vector2i = a + Vector2i(0, -1)
	for c in [a, b]:
		state.map_terrain[c] = Terrain.NORMAL
		state.revealed[c] = true
	var summary: Dictionary = state.route_summary([a, b])
	assert_almost_eq(summary["battery"], 3.0, 0.001)
	assert_true(summary["affordable"])
	state.battery = 2.0
	assert_false(state.route_summary([a, b])["affordable"])


func test_rota_maior_que_o_alcance_motor_fica_fora_de_alcance() -> void:
	var route := []
	for i in Economy.MAX_ROUTE_LENGTH + 1:
		route.append(Vector2i(0, i))
	assert_false(state.route_summary(route)["in_range"])


func test_evento_com_chance_aplica_sucesso_ou_falha() -> void:
	state.rng.seed = 1
	state.apply_effects({"chance": 1.0, "success": {"battery": -10.0}, "fail": {"integrity": -10.0}})
	assert_eq(state.battery, 90.0)
	state.apply_effects({"chance": 0.0, "success": {"battery": -10.0}, "fail": {"integrity": -10.0}})
	assert_eq(state.integrity, 90.0)


func test_bateria_nunca_passa_de_100() -> void:
	state.apply_effects({"battery": 50.0})
	assert_eq(state.battery, 100.0)


func test_extrair_nucleo_acopla_peca_e_aplica_custo() -> void:
	state.active_event = EventDB.core_nature()
	state.active_event["cell"] = state.player_cell
	watch_signals(state)
	state.choose_option(0)
	assert_signal_emitted(state, "item_offered")
	assert_true(state.place_pending_item(Vector2i.ZERO, ItemDB.shape("nucleo_natureza")))
	assert_true(state.core_nature)
	assert_eq(state.battery, 70.0)
	assert_eq(state.load_kg(), 15.0)


func test_cancelar_acoplamento_mantem_o_nucleo_no_mapa() -> void:
	var cell: Vector2i = state.player_cell
	state.map_pois[cell] = {"type": "core_art"}
	state.active_event = EventDB.core_art()
	state.active_event["cell"] = cell
	state.choose_option(0)
	state.cancel_pending_item()
	assert_false(state.core_art)
	assert_true(state.map_pois.has(cell))
	assert_eq(state.integrity, 100.0)


func test_esporos_causam_dano_por_turno() -> void:
	state.statuses = {"spores": 2}
	state.end_turn()
	assert_eq(state.integrity, 95.0)
	assert_eq(state.statuses.get("spores", 0), 1)


func test_carga_temporaria_expira() -> void:
	state.apply_effects({"load_temp": [5.0, 1]})
	assert_eq(state.load_kg(), 5.0)
	state.end_turn()
	assert_eq(state.load_kg(), 0.0)


func test_tempestade_em_quando_bateria_baixa() -> void:
	state.battery = 15.0
	state.end_turn()
	assert_true(state.statuses.has("em_storm"))


func test_colapso_comeca_no_turno_15_pelo_anel_externo() -> void:
	state.current_round = GameState.COLLAPSE_START - 1
	state.player_cell = Vector2i.ZERO + Vector2i(0, 2)
	state.end_turn()
	assert_eq(state.collapsed_radius, MapGenerator.DEFAULT_RADIUS)
	for cell in Hex.ring(Vector2i.ZERO, MapGenerator.DEFAULT_RADIUS):
		assert_eq(state.map_terrain[cell], Terrain.FENDA)


func test_ascensao_gera_final_conforme_os_nucleos() -> void:
	state.inventory.place("nucleo_natureza", Vector2i.ZERO)
	state.inventory.place("nucleo_arte", Vector2i(3, 0))
	watch_signals(state)
	state.apply_effects({"battery": -10.0, "ascend": true})
	assert_true(state.run_over)
	assert_eq(state.last_result["id"], Endings.GENESIS)
	assert_signal_emitted(state, "run_finished")


func test_integridade_zero_e_game_over() -> void:
	watch_signals(state)
	state.apply_effects({"integrity": -150.0})
	assert_true(state.run_over)
	assert_eq(state.last_result["kind"], "game_over")
	assert_signal_emitted(state, "game_over")


func test_diretor_hostil_nao_isola_objetivos() -> void:
	for i in 20:
		state.battery = 100.0
		state._director_spawn_anomalies()
	assert_true(state._objectives_reachable())
