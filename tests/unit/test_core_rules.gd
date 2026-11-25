extends GutTest
## Regras puras: geometria hexagonal, economia, mochila, mapa, Diretor e finais.


func test_distancia_hexagonal_axial() -> void:
	assert_eq(Hex.distance(Vector2i.ZERO, Vector2i(3, -1)), 3)
	assert_eq(Hex.distance(Vector2i(0, 6), Vector2i.ZERO), 6)
	assert_eq(Hex.distance(Vector2i(2, -2), Vector2i(-2, 2)), 4)


func test_vizinhos_estao_a_distancia_1() -> void:
	for n in Hex.neighbors(Vector2i(1, 1)):
		assert_eq(Hex.distance(n, Vector2i(1, 1)), 1)


func test_mapa_de_raio_6_tem_127_hexagonos() -> void:
	assert_eq(Hex.cells_in_radius(Vector2i.ZERO, 6).size(), 127)
	assert_eq(Hex.ring(Vector2i.ZERO, 3).size(), 18)


func test_a_estrela_contorna_bloqueio() -> void:
	var blocked := {Vector2i(0, -1): true, Vector2i(1, -1): true}
	var passable := func(c: Vector2i) -> bool: return Hex.distance(c, Vector2i.ZERO) <= 4 and not blocked.has(c)
	var cost := func(_a: Vector2i, _b: Vector2i) -> float: return 1.0
	var path := Hex.find_path(Vector2i.ZERO, Vector2i(0, -2), passable, cost)
	assert_gt(path.size(), 2)
	assert_eq(path[-1], Vector2i(0, -2))
	for c in path:
		assert_false(blocked.has(c))


func test_a_estrela_sem_caminho_devolve_vazio() -> void:
	var passable := func(c: Vector2i) -> bool: return c == Vector2i.ZERO
	var cost := func(_a: Vector2i, _b: Vector2i) -> float: return 1.0
	assert_eq(Hex.find_path(Vector2i.ZERO, Vector2i(2, 0), passable, cost).size(), 0)


func test_custo_economia_formula_linear() -> void:
	assert_almost_eq(Economy.step_cost(0.0), 1.5, 0.001)
	assert_almost_eq(Economy.step_cost(15.0), 3.0, 0.001)
	assert_almost_eq(Economy.step_cost(30.0), 4.5, 0.001)
	assert_almost_eq(Economy.step_cost(30.0, true), 3.0, 0.001)
	assert_almost_eq(Economy.route_cost(7, 0.0), 10.5, 0.001)


func test_valor_esperado() -> void:
	assert_almost_eq(Economy.expected_value(0.75, 35.0, 0.0), 26.25, 0.001)


func test_mochila_colisao_e_peso() -> void:
	var inv := InventoryGrid.new()
	assert_gt(inv.place("nucleo_natureza", Vector2i.ZERO), 0)
	assert_eq(inv.place("kit_reparo", Vector2i(1, 1)), -1, "colide com o núcleo")
	assert_gt(inv.place("kit_reparo", Vector2i(3, 0)), 0)
	assert_eq(inv.used_slots(), 8)
	assert_almost_eq(inv.total_weight(), 18.0, 0.001)


func test_mochila_nao_aceita_fora_da_grade() -> void:
	var inv := InventoryGrid.new()
	assert_eq(inv.place("nucleo_natureza", Vector2i(3, 0)), -1)
	assert_eq(inv.place("nucleo_arte", Vector2i(0, 2)), -1)


func test_rotacao_de_peca() -> void:
	var shape := InventoryGrid.rotated([Vector2i(0, 0), Vector2i(1, 0)])
	assert_eq(shape, [Vector2i(0, 0), Vector2i(0, 1)])


func test_remover_libera_espaco() -> void:
	var inv := InventoryGrid.new()
	var uid := inv.place("dados_queda", Vector2i.ZERO)
	assert_eq(inv.remove(uid), "dados_queda")
	assert_eq(inv.used_slots(), 0)


func test_os_dois_nucleos_cabem_juntos() -> void:
	var inv := InventoryGrid.new()
	assert_true(inv.place("nucleo_natureza", Vector2i.ZERO) > 0)
	assert_true(inv.fits_anywhere("nucleo_arte"))


func test_todos_os_mapas_tem_solucao() -> void:
	for s in 60:
		var map := MapGenerator.generate(s)
		assert_true(MapGenerator.is_solvable(map), "semente %d" % s)


func test_mapa_posiciona_nucleos_nos_biomas_do_gdd() -> void:
	for s in 20:
		var map := MapGenerator.generate(s)
		assert_eq(Hex.distance(map["core_art"], Vector2i.ZERO), 2, "Arte nos Nódulos")
		assert_eq(map["terrain"][map["elevator"]], Terrain.ELEVADOR)
		assert_eq(map["terrain"][map["spawn"]], Terrain.NORMAL)


func test_diretor_fica_hostil_com_bateria_acima_do_limiar() -> void:
	var d := Director.new()
	assert_eq(Director.threshold(6), 75.0)
	assert_eq(d.evaluate(80.0, 6), Director.State.HOSTIL)
	assert_eq(d.evaluate(60.0, 6), Director.State.PADRAO)
	d.finish_cycle()
	assert_eq(d.state, Director.State.IDLE)


func test_cinco_finais() -> void:
	assert_eq(Endings.evaluate(true, true, false), Endings.GENESIS)
	assert_eq(Endings.evaluate(true, true, true), Endings.PARAISO_PERDIDO)
	assert_eq(Endings.evaluate(true, false, false), Endings.EDEN_SILENCIOSO)
	assert_eq(Endings.evaluate(false, true, true), Endings.MUSEU_CRISTAL)
	assert_eq(Endings.evaluate(false, false, false), Endings.CIVILIZACAO_ESTERIL)
	assert_eq(Endings.DATA.size(), 5)


func test_todo_evento_tem_opcoes_validas() -> void:
	for id in EventDB.EVENTS:
		var event := EventDB.build(id)
		assert_gt(event["options"].size(), 0, id)
		for opt in event["options"]:
			assert_true(opt.has("label"), id)
			if opt["effects"].has("item"):
				assert_true(ItemDB.has(opt["effects"]["item"]), id)


func test_carga_negativa_vale_como_zero() -> void:
	assert_almost_eq(Economy.step_cost(-10.0), Economy.step_cost(0.0), 0.001)
	assert_almost_eq(Economy.weight_modifier(-5.0), 0.0, 0.001)
