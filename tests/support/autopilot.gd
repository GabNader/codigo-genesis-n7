extends RefCounted
## Piloto automático para testes e balanceamento: joga uma partida inteira usando
## só a API pública do GameState (LiDAR, rota, passos, eventos e mochila).
## Estratégia simples e "honesta": só anda por hexágonos revelados.

var gs
var skipped: Dictionary = {}
var _best_dist := 9999
var _stall := 0


func _init(state) -> void:
	gs = state
	gs.item_offered.connect(_on_item_offered)


func play(max_turns := 80) -> Dictionary:
	var guard := 0
	while not gs.run_over and gs.current_round <= max_turns and guard < max_turns * 3:
		guard += 1
		_take_turn()
	return gs.last_result


func objective() -> Vector2i:
	for wanted in ["core_nature", "core_art"]:
		for cell in gs.map_pois:
			if gs.map_pois[cell]["type"] == wanted and not skipped.has(cell):
				return cell
	return gs.elevator_cell


func _take_turn() -> void:
	_use_items()
	var goal := objective()
	# Sem aproximação por 6 turnos: desiste desse objetivo e segue para o próximo.
	var dist: int = Hex.distance(gs.player_cell, goal)
	if dist < _best_dist:
		_best_dist = dist
		_stall = 0
	else:
		_stall += 1
	if _stall >= 6 and goal != gs.elevator_cell:
		skipped[goal] = true
		_best_dist = 9999
		_stall = 0
		goal = objective()
	var unscanned := 0
	for c in Hex.cells_in_radius(gs.player_cell, 2):
		if gs.in_map(c) and not gs.scanned.has(c):
			unscanned += 1
	if unscanned >= 4 and gs.battery > 25.0:
		gs.pulse_lidar()
	var path := _best_path(goal)
	if path.is_empty() and gs.battery >= Economy.LIDAR_COST:
		gs.pulse_lidar()
		path = _best_path(goal)
	if path.is_empty():
		# Não há "passar a vez": anda para qualquer vizinho que a bateria pague.
		for n in Hex.neighbors(gs.player_cell):
			if gs.can_route_through(n) and gs.route_summary([n])["affordable"]:
				path = [n]
				break
	if path.is_empty():
		gs.end_turn()
		return
	var prev: Vector2i = gs.player_cell
	for cell in path:
		var res: Dictionary = gs.enter_cell(prev, cell)
		if not res["ok"] or res["stop"]:
			break
		prev = cell
	if gs.run_over:
		return
	gs.finish_move()
	var safety := 0
	while not gs.active_event.is_empty() and safety < 5:
		safety += 1
		gs.choose_option(_pick_option(gs.active_event))


func _best_path(goal: Vector2i) -> Array:
	var best := Vector2i(9999, 9999)
	var best_d := 9999
	var known := Hex.reachable(gs.player_cell, func(c: Vector2i) -> bool: return gs.can_route_through(c))
	for c in known:
		if c == gs.player_cell:
			continue
		var d := Hex.distance(c, goal)
		if d < best_d:
			best_d = d
			best = c
	if best_d >= Hex.distance(gs.player_cell, goal) and gs.player_cell != goal:
		# Nada mais perto: escolhe um vizinho ainda não visitado para explorar.
		for n in Hex.neighbors(gs.player_cell):
			if gs.can_route_through(n):
				best = n
				break
	if best == Vector2i(9999, 9999):
		return []
	var path: Array = gs.plan_route(gs.player_cell, best)
	if path.size() > Economy.MAX_ROUTE_LENGTH:
		path = path.slice(0, Economy.MAX_ROUTE_LENGTH)
	while not path.is_empty() and not gs.route_summary(path)["affordable"]:
		path.pop_back()
	return path


func _pick_option(event: Dictionary) -> int:
	var options: Array = event["options"]
	if event.get("id", "") == "elevador":
		var ready: bool = gs.core_nature and gs.core_art
		var cores_left: bool = objective() != gs.elevator_cell
		return 0 if (ready or not cores_left) and gs.battery >= Economy.ELEVATOR_TOLL else 1
	for i in options.size():
		var opt: Dictionary = options[i]
		var eff: Dictionary = opt.get("effects", {})
		if gs.battery < opt.get("requires_battery", 0.0):
			continue
		if eff.get("integrity", 0.0) < 0.0 and gs.integrity + eff["integrity"] <= 15.0:
			continue
		if eff.get("item", "") == "dados_queda":
			continue
		if eff.has("chance") and gs.integrity <= 30.0:
			continue
		return i
	return options.size() - 1


func _use_items() -> void:
	for uid in gs.inventory.items.keys():
		var id: String = gs.inventory.items[uid]["id"]
		if id == "celula_bateria" and gs.battery < 30.0:
			gs.use_item(uid)
		elif id == "kit_reparo" and gs.integrity < 45.0:
			gs.use_item(uid)


func _on_item_offered(item_id: String) -> void:
	var shape := ItemDB.shape(item_id)
	var turns := 4 if ItemDB.get_item(item_id)["rotatable"] else 1
	for i in turns:
		var origin: Vector2i = gs.inventory.find_fit(shape)
		if origin != InventoryGrid.NO_FIT:
			gs.place_pending_item(origin, shape)
			return
		shape = InventoryGrid.rotated(shape)
	gs.cancel_pending_item()
