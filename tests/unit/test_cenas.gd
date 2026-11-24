extends GutTest
## Fumaça das cenas: a cena tática monta grid, névoa, jogador e HUD sem erros.


func test_cena_principal_monta_e_responde_ao_lidar() -> void:
	GameState.new_run(7)
	var main: Node = add_child_autofree(load("res://scenes/Main.tscn").instantiate())
	await wait_frames(2)
	assert_not_null(main.get_node("MapOverlay"))
	var fog: TileMapLayer = main.get_node("FogIndustrial")
	assert_eq(fog.get_cell_source_id(GameState.player_cell), -1, "célula do N-7 sem névoa")
	GameState.lidar_pulsed.emit()
	assert_eq(GameState.battery, 95.0)


func test_menu_e_tela_final_carregam() -> void:
	var menu: Node = add_child_autofree(load("res://scenes/UI_Menu.tscn").instantiate())
	await wait_frames(1)
	assert_gt(menu.get_child_count(), 0)
	GameState.new_run(3)
	GameState.apply_effects({"ascend": true})
	var ending: Node = add_child_autofree(load("res://scenes/Ending.tscn").instantiate())
	await wait_frames(1)
	assert_gt(ending.get_child_count(), 0)
	GameState.new_run(3)
