extends SceneTree
## Grava clipes de gameplay real para o trailer com o Movie Maker do Godot.
## Cada clipe encena um momento do jogo (mesma semente, ações com tempo marcado).
##
## Uso (um clipe por execução):
##   godot --path . --write-movie <saida.avi> --fixed-fps 30 \
##         -s res://tools/trailer/gravar_clipes.gd -- <clipe> [pasta_de_prints]
## Clipes: despertar, lidar, rota, subestacao, natureza, arte, trindade, final, alarme
## O Movie Maker grava no tamanho de viewport do projeto (1280×720). Para 1920×1080,
## crie um override.cfg temporário na raiz (ver docs/trailer/roteiro.md).
## Com [pasta_de_prints], salva um PNG a cada 2 s para conferir o clipe sem abrir o vídeo.
##
## Este script não referencia classes que dependem de autoloads (Tutorial, MapOverlay,
## InventoryPanel): roda antes de os autoloads existirem e acessa tudo por nome.

const SEED := 21
const ZOOM := 0.2
const DURATION := {
	"despertar": 9.5, "lidar": 5.0, "rota": 8.0, "subestacao": 8.0,
	"natureza": 14.0, "arte": 16.0, "trindade": 16.0, "final": 9.0,
	"alarme": 5.0,
}

var clip := "despertar"
var gs: Node
var main: Node
var t := 0.0
var _started := false
var _scheduled := false
var _actions: Array = []   ## [tempo, Callable], executadas em ordem
var _tutorial_before := true
var _snap_dir := ""
var _next_snap := 1.0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		clip = args[0]
	if args.size() > 1:
		_snap_dir = args[1]
	if not DURATION.has(clip):
		push_error("Clipe desconhecido: %s" % clip)
		quit(1)
		return
	_tutorial_before = Settings.tutorial_enabled()
	Settings.set_tutorial_enabled(clip == "despertar")


func _process(delta: float) -> bool:
	if not _started:
		_started = true
		gs = root.get_node("/root/GameState")
		gs.new_run(SEED)
		_prepare()
		change_scene_to_file("res://scenes/Main.tscn")
		return false
	# Só espera a cena tática uma vez: no clipe final o jogo troca para a tela de desfecho.
	if not _scheduled:
		main = current_scene
		if main == null or not main.has_node("N7Player"):
			return false
		main.get_node("N7Player/Camera2D").zoom = Vector2(ZOOM, ZOOM)
		# O mouse real sobre a janela não interfere: as ações vêm só deste roteiro.
		main.get_node("N7Player").set_process_unhandled_input(false)
		_schedule()
		_scheduled = true
		return false
	t += delta
	while not _actions.is_empty() and t >= _actions[0][0]:
		var action: Callable = _actions.pop_front()[1]
		action.call()
	if _snap_dir != "" and t >= _next_snap:
		root.get_viewport().get_texture().get_image().save_png("%s/%s_%02d.png" % [_snap_dir, clip, int(_next_snap)])
		_next_snap += 2.0
	if t >= DURATION[clip]:
		Settings.set_tutorial_enabled(_tutorial_before)
		return true
	return false


## Estado antes de abrir a cena: posição do N-7 e itens na mochila.
func _prepare() -> void:
	match clip:
		"subestacao":
			_teleport_next_to(_find_terrain("subestacao"))
		"natureza":
			_teleport_next_to(_find_poi("core_nature"))
		"arte":
			_teleport_next_to(_find_poi("core_art"))
		"trindade":
			gs.inventory.place("nucleo_natureza", Vector2i.ZERO)
			_teleport_next_to(_find_poi("core_art"))
		"final":
			gs.inventory.place("nucleo_natureza", Vector2i.ZERO)
			gs.inventory.place("nucleo_arte", Vector2i(3, 0))
			_teleport_next_to(gs.elevator_cell)
	if clip != "despertar" and clip != "lidar" and clip != "rota":
		gs.pulse_lidar()
		gs.battery = 82.0
		# Biomas já visitados: o visor fica livre para a memória e a Trindade.
		gs.flags["visited_biomes"] = {"industrial": true, "eco": true, "degrad": true, "nodes": true}
	if clip == "alarme":
		# Um pulso do LiDAR (-5%) cruza o limite de 15% e dispara o alarme.
		gs.battery = 16.0


func _schedule() -> void:
	match clip:
		"despertar":
			_at(6.0, func(): _tutorial().call("_go_lidar"))
			_at(7.5, func(): gs.lidar_pulsed.emit())
		"lidar":
			_at(1.0, func(): gs.lidar_pulsed.emit())
		"rota":
			_at(0.6, func(): gs.lidar_pulsed.emit())
			_at(2.2, func(): _click(_cell_toward(gs.elevator_cell, 4)))
			_at(4.2, func(): gs.move_confirmed.emit())
		"subestacao":
			_at(1.0, func(): _click(_find_terrain("subestacao")))
			_at(2.2, func(): gs.move_confirmed.emit())
			_at(5.5, func(): _hud().call("_choose", 1))
		"natureza":
			_at(1.0, func(): _click(_find_poi("core_nature")))
			_at(2.2, func(): gs.move_confirmed.emit())
			_at(5.2, func(): _hud().call("_choose", 0))
			_at(6.8, func(): _place_in_backpack(Vector2i(0, 0)))
		"arte":
			_at(1.0, func(): _click(_find_poi("core_art")))
			_at(2.2, func(): gs.move_confirmed.emit())
			_at(5.2, func(): _hud().call("_choose", 0))
			_at(6.8, func(): _place_in_backpack(Vector2i(0, 0)))
		"trindade":
			_at(1.0, func(): _click(_find_poi("core_art")))
			_at(2.2, func(): gs.move_confirmed.emit())
			_at(5.0, func(): _hud().call("_choose", 0))
			_at(6.4, func(): _place_in_backpack(Vector2i(3, 0)))
			_at(11.0, func(): _click(gs.elevator_cell))
		"alarme":
			_at(1.0, func(): gs.lidar_pulsed.emit())
		"final":
			_at(1.0, func(): _click(gs.elevator_cell))
			_at(2.2, func(): gs.move_confirmed.emit())
			_at(5.0, func(): _hud().call("_choose", 0))


func _at(time: float, action: Callable) -> void:
	_actions.append([time, action])


func _hud() -> Node:
	return main.get_node("UiHud")


func _tutorial() -> Node:
	for child in _hud().get_children():
		if child.has_method("_go_lidar"):
			return child
	return null


func _click(cell: Vector2i) -> void:
	main.get_node("MapOverlay").call("set_hover", cell)
	main.get_node("N7Player").call("_on_cell_clicked", cell)


## Encaixa a peça pendente como o jogador faria: clique na grade da mochila.
func _place_in_backpack(origin: Vector2i) -> void:
	var panel: Node = _hud().get("_inventory")
	panel.call("_on_grid_click", origin, MOUSE_BUTTON_LEFT)


func _find_poi(kind: String) -> Vector2i:
	for cell in gs.map_pois:
		if gs.map_pois[cell]["type"] == kind:
			return cell
	return gs.elevator_cell


func _find_terrain(kind: String) -> Vector2i:
	var best: Vector2i = gs.spawn_cell
	var best_d := 9999
	for cell in gs.map_terrain:
		if gs.map_terrain[cell] == kind and Hex.distance(cell, gs.spawn_cell) < best_d:
			best_d = Hex.distance(cell, gs.spawn_cell)
			best = cell
	return best


## Posiciona o N-7 num vizinho estável do alvo, voltado para o centro do domo.
func _teleport_next_to(target: Vector2i) -> void:
	var best: Vector2i = gs.player_cell
	var best_d := 9999
	for n in Hex.neighbors(target):
		if gs.in_map(n) and gs.map_terrain[n] == "normal" and not gs.map_pois.has(n):
			var d := Hex.distance(n, gs.spawn_cell)
			if d < best_d:
				best_d = d
				best = n
	gs.player_cell = best
	gs._reveal_around(best)


func _cell_toward(goal: Vector2i, max_steps: int) -> Vector2i:
	var best: Vector2i = gs.player_cell
	for cell in gs.revealed:
		if not gs.can_route_through(cell) or cell == gs.player_cell:
			continue
		var path: Array = gs.plan_route(gs.player_cell, cell)
		if path.is_empty() or path.size() > max_steps:
			continue
		if Hex.distance(cell, goal) < Hex.distance(best, goal):
			best = cell
	return best
