extends GutTest

const GameStateScript = preload("res://GameState.gd")

var state


func before_each() -> void:
	state = autofree(GameStateScript.new())
	state.reset_state()


func test_reset_state_comeca_com_recursos_cheios() -> void:
	assert_eq(state.current_round, 1)
	assert_eq(state.battery, 100.0)
	assert_eq(state.integrity, 100.0)
	assert_eq(state.load_weight, 0.0)


func test_add_battery_nao_passa_de_100() -> void:
	state.add_battery(25.0)
	assert_eq(state.battery, 100.0)


func test_consume_battery_soma_metade_da_carga_ao_custo() -> void:
	state.load_weight = 10.0
	state.consume_battery(20.0)
	assert_eq(state.battery, 75.0)


func test_apply_damage_zera_integridade_e_emite_game_over() -> void:
	watch_signals(state)
	state.apply_damage(150.0)
	assert_eq(state.integrity, 0.0)
	assert_signal_emitted(state, "game_over")
