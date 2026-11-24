extends GutTest
## Partidas inteiras jogadas pelo piloto automático: garantem que o loop
## Escanear → Analisar → Deslocar → Coletar sempre termina num desfecho válido.

const GameStateScript = preload("res://scripts/autoload/GameState.gd")
const Autopilot = preload("res://tests/support/autopilot.gd")


func _play(seed_value: int) -> Dictionary:
	var state = autofree(GameStateScript.new())
	state.new_run(seed_value)
	var pilot = Autopilot.new(state)
	return pilot.play(80)


func test_partidas_terminam_em_final_ou_game_over() -> void:
	for s in 15:
		var result := _play(1000 + s)
		assert_false(result.is_empty(), "semente %d terminou" % (1000 + s))
		assert_has(["ending", "game_over"], result.get("kind", ""))


func test_jogo_e_vencivel() -> void:
	var endings := 0
	for s in 15:
		if _play(2000 + s).get("kind", "") == "ending":
			endings += 1
	assert_gt(endings, 0, "o piloto automático deve alcançar o Elevador em parte das partidas")
