extends Node
## Estado global da partida (autoload). Orquestra os subsistemas do GDD §6:
## economia, inventário, conflitos ambientais, progressão e Diretor de IA.
## As regras puras ficam em scripts/core/ para serem testáveis isoladamente.

signal resources_updated
signal round_advanced(current_round: int)
signal game_over(reason: String)
signal move_confirmed
signal lidar_pulsed
signal route_clear_requested
signal route_previewed(length: int, summary: Dictionary)
signal choice_event_triggered(event_data: Dictionary)
signal system_alert(message: String)
signal log_message(text: String, kind: String)
signal map_changed
signal item_offered(item_id: String)
signal inventory_changed
signal run_finished(result: Dictionary)

const START_BATTERY := 100.0
const START_INTEGRITY := 100.0
const ACID_RAIN_START_CHANCE := 0.2
const SPORE_DAMAGE := 5.0
const ACID_DAMAGE := 2.0
const NOISE_CHANCE := 0.3
const FALSE_TOPOGRAPHY_CHANCE := 0.35
const STORM_BATTERY := 20.0
const STORM_TURNS := 3
const STORM_COOLDOWN := 8
const SURGE_BATTERY := 80.0
const SURGE_COOLDOWN := 5
const MIRAGE_INTEGRITY := 30.0
const HARMONIC_LOAD := 15.0
const HARMONIC_TURNS := 3
const COLLAPSE_START := 15
const COLLAPSE_EVERY := 4
const COLLAPSE_MIN_RADIUS := 3
const COLLAPSE_DAMAGE := 25.0
const AUTO_ROUTE_LEAK_PENALTY := 8.0

var rng := RandomNumberGenerator.new()
var run_seed: int = 0
var current_round: int = 1
var battery: float = START_BATTERY
var integrity: float = START_INTEGRITY
var inventory := InventoryGrid.new()
var temp_loads: Array = []       ## [{"kg": float, "turns": int}]
var statuses: Dictionary = {}    ## nome -> turnos restantes
var flags: Dictionary = {}

# Mapa — a verdade do sistema.
var map_radius: int = MapGenerator.DEFAULT_RADIUS
var map_biomes: Dictionary = {}
var map_terrain: Dictionary = {}
var map_pois: Dictionary = {}
var substation_stability: Dictionary = {}
var spawn_cell: Vector2i = Vector2i.ZERO
var elevator_cell: Vector2i = Vector2i.ZERO
var player_cell: Vector2i = Vector2i.ZERO

# Conhecimento do jogador — o que os sensores mostram (pode conter erros).
var revealed: Dictionary = {}    ## sem névoa (visível e caminhável)
var scanned: Dictionary = {}     ## cell -> {"terrain": String, "poi": bool, "uncertain": bool}
var electrified: Dictionary = {} ## piso eletrificado pelo Curto em Cadeia (1 turno)
var fake_pois: Dictionary = {}   ## Miragem de Dados

var director := Director.new()
var collapsed_radius: int = 0    ## anéis com raio >= este valor colapsaram (0 = nenhum)
var stats: Dictionary = {}
var run_over := false
var last_result: Dictionary = {}
var active_event: Dictionary = {}
var pending_item: Dictionary = {}
var ui_blocking := false

# Compatibilidade com a HUD do protótipo.
var core_logic: bool:
	get: return true
var core_nature: bool:
	get: return inventory.has_item("nucleo_natureza")
var core_art: bool:
	get: return inventory.has_item("nucleo_arte")
var load_weight: float:
	get: return load_kg()


func _ready() -> void:
	reset_state()


## Mantido para o menu e os testes: começa uma partida nova com semente aleatória.
func reset_state() -> void:
	new_run()


func new_run(seed_value: int = -1) -> void:
	if seed_value < 0:
		seed_value = randi() % 1000000
	run_seed = seed_value
	rng.seed = seed_value
	current_round = 1
	battery = START_BATTERY
	integrity = START_INTEGRITY
	inventory = InventoryGrid.new()
	temp_loads.clear()
	statuses.clear()
	flags.clear()
	revealed.clear()
	scanned.clear()
	electrified.clear()
	fake_pois.clear()
	director = Director.new()
	collapsed_radius = 0
	run_over = false
	last_result = {}
	active_event = {}
	pending_item = {}
	ui_blocking = false
	stats = {"hexes": 0, "lidar": 0, "battery_spent": 0.0, "battery_gained": 0.0, "damage": 0.0, "events": 0}

	var map := MapGenerator.generate(seed_value, map_radius)
	map_biomes = map["biomes"]
	map_terrain = map["terrain"]
	map_pois = map["pois"]
	substation_stability = map["stability"]
	spawn_cell = map["spawn"]
	elevator_cell = map["elevator"]
	player_cell = spawn_cell

	_reveal_around(player_cell)
	# O Elevador é o farol do domo: sempre visível no mapa.
	revealed[elevator_cell] = true
	scanned[elevator_cell] = {"terrain": Terrain.ELEVADOR, "poi": false, "uncertain": false}

	if rng.randf() < ACID_RAIN_START_CHANCE:
		statuses["acid_rain"] = 5
		_log("Chuva Ácida no domo: +2 de dano por passo durante 5 turnos.", "warn")
	_log("N-7 desperta no setor [%d,%d]. Protocolo de Ascensão carregado. Semente %d." % [player_cell.x, player_cell.y, run_seed], "info")
	_emit_all()


# --- Consultas -----------------------------------------------------------------

func load_kg() -> float:
	var total := inventory.total_weight()
	for t in temp_loads:
		total += t["kg"]
	return total


func is_harmonic() -> bool:
	return statuses.has("harmonic")


func current_step_cost() -> float:
	return Economy.step_cost(load_kg(), is_harmonic())


func biome_at(cell: Vector2i) -> String:
	return map_biomes.get(cell, "")


func in_map(cell: Vector2i) -> bool:
	return map_terrain.has(cell)


## Terreno como o jogador o conhece (use_known) ou como ele realmente é.
func terrain_at(cell: Vector2i, use_known := false) -> String:
	if use_known:
		if scanned.has(cell):
			return scanned[cell]["terrain"]
		return Terrain.NORMAL
	return map_terrain.get(cell, Terrain.FENDA)


func step_battery_cost(from: Vector2i, to: Vector2i, use_known := false) -> float:
	var cost := current_step_cost()
	if terrain_at(from, use_known) == Terrain.RAIZES:
		cost *= Economy.ROOTS_MULTIPLIER
	if terrain_at(to, use_known) == Terrain.FIREWALL:
		cost += Economy.FIREWALL_COST
	if electrified.has(to):
		cost += Economy.ELECTRIFIED_COST
	return cost


func step_integrity_risk(to: Vector2i, use_known := true) -> float:
	var risk := 0.0
	if terrain_at(to, use_known) == Terrain.VAZAMENTO:
		risk += Terrain.LEAK_DAMAGE
	if statuses.has("acid_rain"):
		risk += ACID_DAMAGE
	return risk


func can_route_through(cell: Vector2i) -> bool:
	return in_map(cell) and revealed.has(cell) and not Terrain.blocks(terrain_at(cell, true))


## Rota automática pelo caminho conhecido mais barato (evita perigos já escaneados).
func plan_route(from: Vector2i, target: Vector2i) -> Array[Vector2i]:
	var passable := func(c: Vector2i) -> bool: return can_route_through(c)
	var cost := func(a: Vector2i, b: Vector2i) -> float:
		var c := step_battery_cost(a, b, true)
		if terrain_at(b, true) == Terrain.VAZAMENTO:
			c += AUTO_ROUTE_LEAK_PENALTY
		return c
	return Hex.find_path(from, target, passable, cost)


## Prévia da rota: custo de bateria passo a passo e dano previsto.
func route_summary(route: Array) -> Dictionary:
	var total := 0.0
	var damage := 0.0
	var cumulative: Array = []
	var prev := player_cell
	for cell in route:
		total += step_battery_cost(prev, cell, true)
		damage += step_integrity_risk(cell, true)
		cumulative.append(total)
		prev = cell
	return {
		"distance": route.size(),
		"battery": total,
		"integrity": damage,
		"cumulative": cumulative,
		"affordable": total <= battery + 0.0001,
		"in_range": route.size() <= Economy.MAX_ROUTE_LENGTH,
	}


func describe_cell(cell: Vector2i) -> String:
	if not in_map(cell):
		return ""
	var head := "[%d,%d] %s" % [cell.x, cell.y, Terrain.biome_name(biome_at(cell))]
	if not revealed.has(cell):
		return head + " — névoa de dados (use o LiDAR)"
	if not scanned.has(cell):
		return head + " — não escaneado: perigos desconhecidos"
	var info: Dictionary = scanned[cell]
	var text := head + " — " + Terrain.name_of(info["terrain"])
	var effect := Terrain.effect_of(info["terrain"])
	if info["terrain"] == Terrain.SUBESTACAO and substation_stability.has(cell):
		effect = "Estabilidade %d%%. %s" % [roundi(substation_stability[cell] * 100), effect]
	if effect != "" and info["terrain"] != Terrain.NORMAL:
		text += ": " + effect
	if info["uncertain"]:
		text += "  [leitura instável]"
	if electrified.has(cell):
		text += "  [eletrificado: +15% Bateria]"
	if info["poi"] or fake_pois.has(cell):
		text += "  [ponto de interesse]"
	return text


func distance_to_elevator() -> int:
	return Hex.distance(player_cell, elevator_cell)


# --- Ações do jogador ------------------------------------------------------------

## Varredura LiDAR (GDD §5): -5% de bateria, revela e escaneia o raio 3.
func pulse_lidar() -> Array[Vector2i]:
	var scanned_now: Array[Vector2i] = []
	if run_over:
		return scanned_now
	if battery < Economy.LIDAR_COST:
		system_alert.emit("LiDAR: bateria insuficiente.")
		return scanned_now
	_spend_battery(Economy.LIDAR_COST)
	stats["lidar"] += 1
	var radius := Economy.LIDAR_RADIUS
	var biome := biome_at(player_cell)
	if biome == "degrad" and flags.get("lidar_this_turn", false):
		radius = 1
		_log("Névoa Oxidadora: o pulso repetido dispersou gases densos. Raio reduzido a 1.", "warn")
	flags["lidar_this_turn"] = true
	var storm := statuses.has("em_storm")
	var false_topography := biome == "eco" and rng.randf() < FALSE_TOPOGRAPHY_CHANCE
	if false_topography:
		_log("Folhagem densa refletiu parte do pulso. Confiabilidade da leitura no setor eco: 65%.", "warn")
	var hazards := 0
	for cell in Hex.cells_in_radius(player_cell, radius):
		if not in_map(cell):
			continue
		revealed[cell] = true
		_scan_cell(cell, storm, false_topography)
		scanned_now.append(cell)
		var shown: String = scanned[cell]["terrain"]
		if shown in [Terrain.VAZAMENTO, Terrain.FENDA, Terrain.INTERFERENCIA]:
			hazards += 1
	_log("Pulso LiDAR (-%.0f%%): %d setores escaneados, %d anomalias detectadas." % [Economy.LIDAR_COST, scanned_now.size(), hazards], "info")
	map_changed.emit()
	_check_defeat()
	_emit_all()
	return scanned_now


## Executa um passo da rota. Devolve {"ok": entrou na célula, "stop": interromper a rota}.
func enter_cell(from: Vector2i, to: Vector2i) -> Dictionary:
	if run_over:
		return {"ok": false, "stop": true}
	var real := terrain_at(to)
	if Terrain.blocks(real):
		scanned[to] = {"terrain": real, "poi": false, "uncertain": false}
		revealed[to] = true
		_log("ALERTA: fenda estrutural oculta em [%d,%d]. Rota interrompida." % [to.x, to.y], "danger")
		system_alert.emit("Fenda oculta! Rota interrompida.")
		map_changed.emit()
		return {"ok": false, "stop": true}
	var cost := step_battery_cost(from, to)
	if battery < cost:
		_log("Energia insuficiente para o próximo passo (%.1f%%)." % cost, "danger")
		return {"ok": false, "stop": true}
	_spend_battery(cost)
	stats["hexes"] += 1
	player_cell = to
	if real == Terrain.FIREWALL:
		_log("Firewall físico rompido por força bruta computacional (-%.0f%% fixo)." % Economy.FIREWALL_COST, "warn")
	if electrified.has(to):
		_log("Piso eletrificado! Surto drenou %.0f%% de bateria." % Economy.ELECTRIFIED_COST, "danger")
	if real == Terrain.VAZAMENTO:
		_damage(Terrain.LEAK_DAMAGE, "Vazamento térmico em [%d,%d]" % [to.x, to.y])
	if statuses.has("acid_rain"):
		_damage(ACID_DAMAGE, "Chuva ácida")
	if biome_at(to) == "degrad" and not scanned.has(to) and rng.randf() < Terrain.GAS_CHANCE:
		_damage(Terrain.GAS_DAMAGE, "Bolsão de gás em setor não escaneado")
	_reveal_around(to)
	if biome_at(to) == "nodes" and load_kg() > HARMONIC_LOAD and not flags.get("harmonic_used", false):
		flags["harmonic_used"] = true
		statuses["harmonic"] = HARMONIC_TURNS
		_log("Frequência Harmônica: os núcleos ressoam com o Elevador. Modificador de peso pela metade por %d turnos." % HARMONIC_TURNS, "good")
	map_changed.emit()
	_check_defeat()
	_emit_all()
	return {"ok": true, "stop": run_over}


## Fim do deslocamento: interage com o hexágono e encerra o turno.
func finish_move() -> void:
	if run_over:
		return
	if not _interact_at(player_cell):
		end_turn()


func use_item(uid: int) -> void:
	if not inventory.items.has(uid):
		return
	var id: String = inventory.items[uid]["id"]
	var use: Dictionary = ItemDB.get_item(id)["use"]
	if use.is_empty():
		return
	inventory.remove(uid)
	_log("%s utilizado." % ItemDB.display_name(id), "good")
	apply_effects(use)
	inventory_changed.emit()
	_emit_all()


func discard_item(uid: int) -> void:
	if not inventory.items.has(uid):
		return
	var id: String = inventory.items[uid]["id"]
	if not ItemDB.get_item(id)["discardable"]:
		system_alert.emit("Núcleos acoplados não podem ser descartados.")
		return
	inventory.remove(uid)
	_log("%s descartado (-%.0f kg)." % [ItemDB.display_name(id), ItemDB.weight(id)], "info")
	inventory_changed.emit()
	_emit_all()


# --- Eventos --------------------------------------------------------------------

func choose_option(index: int) -> void:
	if active_event.is_empty():
		return
	var option: Dictionary = active_event["options"][index]
	if battery < option.get("requires_battery", 0.0):
		system_alert.emit("Bateria insuficiente para esta opção.")
		return
	var effects: Dictionary = option.get("effects", {})
	if effects.has("item"):
		pending_item = {"event": active_event, "option": option}
		active_event = {}
		item_offered.emit(effects["item"])
		return
	var event := active_event
	active_event = {}
	_resolve_option(event, option, effects)


## A peça pendente foi encaixada na mochila: aplica o restante dos efeitos.
func place_pending_item(origin: Vector2i, shape: Array) -> bool:
	if pending_item.is_empty():
		return false
	var option: Dictionary = pending_item["option"]
	var effects: Dictionary = option["effects"].duplicate()
	var item_id: String = effects["item"]
	if inventory.place(item_id, origin, shape) < 0:
		return false
	effects.erase("item")
	var event: Dictionary = pending_item["event"]
	pending_item = {}
	_log("%s acoplado à mochila (+%.0f kg). Novo custo por passo: %.1f%%." % [ItemDB.display_name(item_id), ItemDB.weight(item_id), current_step_cost()], "good")
	inventory_changed.emit()
	_resolve_option(event, option, effects)
	return true


func cancel_pending_item() -> void:
	if pending_item.is_empty():
		return
	var event: Dictionary = pending_item["event"]
	pending_item = {}
	_log("Acoplamento cancelado. O item continua no setor.", "info")
	_close_event(event, false)


func _resolve_option(event: Dictionary, option: Dictionary, effects: Dictionary) -> void:
	stats["events"] += 1
	apply_effects(effects)
	_close_event(event, option.get("consume", true))


func _close_event(event: Dictionary, consume: bool) -> void:
	var cell: Vector2i = event.get("cell", player_cell)
	if consume:
		if map_pois.has(cell):
			map_pois.erase(cell)
		if event.get("id", "") in ["subestacao", "sobrecarga_total"]:
			map_terrain[cell] = Terrain.NORMAL
			substation_stability.erase(cell)
		if scanned.has(cell):
			scanned[cell]["poi"] = map_pois.has(cell)
			scanned[cell]["terrain"] = map_terrain[cell]
		map_changed.emit()
	_emit_all()
	if not run_over and event.get("ends_turn", true):
		end_turn()


func apply_effects(effects: Dictionary) -> void:
	if effects.has("chance"):
		var success: bool = rng.randf() < float(effects["chance"])
		_log("Probabilidade de sucesso %d%% → %s." % [roundi(effects["chance"] * 100.0), "SUCESSO" if success else "FALHA"], "good" if success else "danger")
		apply_effects(effects["success"] if success else effects["fail"])
		return
	if effects.has("battery"):
		var delta: float = effects["battery"]
		if delta >= 0.0:
			var before := battery
			battery = minf(Economy.MAX_RESOURCE, battery + delta)
			stats["battery_gained"] += battery - before
			_log("Bateria +%.0f%%." % (battery - before), "good")
		else:
			_spend_battery(-delta)
			_log("Bateria %.0f%%." % delta, "warn")
	if effects.has("integrity"):
		var d: float = effects["integrity"]
		if d >= 0.0:
			var before_i := integrity
			integrity = minf(Economy.MAX_RESOURCE, integrity + d)
			_log("Integridade +%.0f." % (integrity - before_i), "good")
		else:
			_damage(-d, "Evento")
	if effects.has("load_temp"):
		temp_loads.append({"kg": effects["load_temp"][0], "turns": effects["load_temp"][1]})
		_log("Carga temporária +%.0f kg por %d turnos." % [effects["load_temp"][0], effects["load_temp"][1]], "warn")
	if effects.has("status"):
		for s in effects["status"]:
			statuses[s] = maxi(statuses.get(s, 0), effects["status"][s])
	if effects.has("reveal"):
		for cell in Hex.cells_in_radius(player_cell, effects["reveal"]):
			if in_map(cell):
				revealed[cell] = true
				_scan_cell(cell, false, false)
		_log("Mapa do setor transferido: raio %d escaneado." % effects["reveal"], "good")
		map_changed.emit()
	if effects.has("flag"):
		flags[effects["flag"]] = true
	if effects.get("ascend", false):
		_ascend()
		return
	_check_defeat()
	_emit_all()


# --- Turno, Diretor de IA e pressão procedural -------------------------------------

func end_turn() -> void:
	if run_over:
		return
	current_round += 1
	flags["lidar_this_turn"] = false
	electrified.clear()

	for t in temp_loads:
		t["turns"] -= 1
	temp_loads = temp_loads.filter(func(t): return t["turns"] > 0)

	if statuses.has("spores"):
		_damage(SPORE_DAMAGE, "Esporos corrosivos")
	var expired := []
	for s in statuses:
		statuses[s] -= 1
		if statuses[s] <= 0:
			expired.append(s)
	for s in expired:
		statuses.erase(s)

	_run_director()
	_update_collapse()

	if not run_over:
		_check_defeat()
	round_advanced.emit(current_round)
	_emit_all()
	map_changed.emit()


func _run_director() -> void:
	var dist := distance_to_elevator()
	var decision := director.evaluate(battery, dist)
	if decision == Director.State.HOSTIL:
		var changed := _director_spawn_anomalies()
		if changed > 0:
			_log("DIRETOR [GERAR AMBIENTE HOSTIL]: bateria %.0f%% ≥ limiar %.0f%% do quadrante. %d anomalias geradas à frente." % [battery, Director.threshold(dist), changed], "director")
	var turn := current_round
	if battery < STORM_BATTERY and not statuses.has("em_storm") and turn >= flags.get("storm_ready", 0):
		statuses["em_storm"] = STORM_TURNS
		flags["storm_ready"] = turn + STORM_COOLDOWN
		_log("DIRETOR: Tempestade EM! Por %d turnos o LiDAR pode exibir falsos positivos ou ocultar perigos (30%%)." % STORM_TURNS, "director")
	if battery > SURGE_BATTERY and turn >= flags.get("surge_ready", 0):
		if _electrify_floor() > 0:
			flags["surge_ready"] = turn + SURGE_COOLDOWN
			_log("DIRETOR: Curto em Cadeia! Pisos eletrificados por 1 turno (+15% Bateria para entrar). Recalcule a rota.", "director")
	if integrity < MIRAGE_INTEGRITY and not flags.get("mirage_used", false):
		if _spawn_mirage():
			flags["mirage_used"] = true
	director.finish_cycle()


## Converte setores ainda não escaneados à frente em anomalias, sem nunca isolar objetivos.
func _director_spawn_anomalies() -> int:
	var candidates := []
	for cell in Hex.cells_in_radius(player_cell, Director.HOSTILE_MAX_DIST):
		var d := Hex.distance(cell, player_cell)
		if d < Director.HOSTILE_MIN_DIST or not in_map(cell) or scanned.has(cell):
			continue
		if map_terrain[cell] != Terrain.NORMAL or map_pois.has(cell) or biome_at(cell) == "elevator":
			continue
		candidates.append(cell)
	MapGenerator._shuffle(rng, candidates)
	var changed := 0
	for cell in candidates:
		if changed >= Director.HOSTILE_ANOMALIES:
			break
		var options := [Terrain.FENDA, Terrain.VAZAMENTO, Terrain.INTERFERENCIA]
		if biome_at(cell) == "eco":
			options = [Terrain.FENDA, Terrain.RAIZES]
		var t: String = options[rng.randi_range(0, options.size() - 1)]
		map_terrain[cell] = t
		if not _objectives_reachable():
			map_terrain[cell] = Terrain.NORMAL
			continue
		changed += 1
	return changed


func _electrify_floor() -> int:
	var options := []
	for cell in Hex.cells_in_radius(player_cell, 2):
		if cell != player_cell and scanned.has(cell) and map_terrain.get(cell) == Terrain.NORMAL:
			options.append(cell)
	MapGenerator._shuffle(rng, options)
	for i in mini(3, options.size()):
		electrified[options[i]] = true
	return mini(3, options.size())


func _spawn_mirage() -> bool:
	var options := []
	for cell in Hex.cells_in_radius(player_cell, 3):
		if cell != player_cell and scanned.has(cell) and map_terrain.get(cell) == Terrain.NORMAL and not map_pois.has(cell):
			options.append(cell)
	if options.is_empty():
		return false
	var cell: Vector2i = options[rng.randi_range(0, options.size() - 1)]
	fake_pois[cell] = true
	_log("Sensor detecta uma subestação em [%d,%d]... a leitura oscila." % [cell.x, cell.y], "info")
	return true


func _update_collapse() -> void:
	if current_round < COLLAPSE_START - 1:
		return
	var steps_done := 0
	if current_round >= COLLAPSE_START:
		steps_done = (current_round - COLLAPSE_START) / COLLAPSE_EVERY + 1
	var target_radius := maxi(COLLAPSE_MIN_RADIUS, map_radius - steps_done + 1)
	if steps_done > 0 and (collapsed_radius == 0 or target_radius < collapsed_radius):
		var from_radius := map_radius if collapsed_radius == 0 else collapsed_radius - 1
		for r in range(from_radius, target_radius - 1, -1):
			_collapse_ring(r)
		collapsed_radius = target_radius
	var next_turn := COLLAPSE_START + steps_done * COLLAPSE_EVERY
	var next_radius := map_radius - steps_done
	if current_round == COLLAPSE_START - 1 or (current_round == next_turn - 1 and next_radius >= COLLAPSE_MIN_RADIUS):
		var warn_radius := map_radius if current_round == COLLAPSE_START - 1 else next_radius
		_log("ALERTA: o anel %d do domo vai colapsar no próximo turno." % warn_radius, "danger")
		system_alert.emit("Colapso iminente do anel %d!" % warn_radius)


func _collapse_ring(radius: int) -> void:
	var lost := []
	for cell in Hex.ring(elevator_cell, radius):
		if not in_map(cell):
			continue
		if cell == player_cell:
			_damage(COLLAPSE_DAMAGE, "O chão cede sob as esteiras")
			continue
		if map_pois.has(cell):
			var t: String = map_pois[cell]["type"]
			if t in ["core_nature", "core_art"]:
				lost.append("Núcleo da Natureza" if t == "core_nature" else "Núcleo da Arte")
			map_pois.erase(cell)
		map_terrain[cell] = Terrain.FENDA
		substation_stability.erase(cell)
		fake_pois.erase(cell)
		revealed[cell] = true
		scanned[cell] = {"terrain": Terrain.FENDA, "poi": false, "uncertain": false}
	_log("Colapso de Setor: o anel %d desmoronou." % radius, "danger")
	for name in lost:
		_log("%s perdido no colapso." % name, "danger")


func _objectives_reachable() -> bool:
	var passable := func(c: Vector2i) -> bool: return in_map(c) and not Terrain.blocks(map_terrain[c])
	var seen := Hex.reachable(player_cell, passable)
	if not seen.has(elevator_cell):
		return false
	for cell in map_pois:
		if map_pois[cell]["type"] in ["core_nature", "core_art"] and not seen.has(cell):
			return false
	return true


# --- Internos -------------------------------------------------------------------

func _interact_at(cell: Vector2i) -> bool:
	if fake_pois.has(cell):
		fake_pois.erase(cell)
		_log("Miragem de Dados: não há subestação alguma. O deslocamento foi desperdiçado.", "danger")
		system_alert.emit("Miragem de Dados!")
		map_changed.emit()
		return false
	var terrain := terrain_at(cell)
	var event := {}
	if terrain == Terrain.OASIS:
		var before := integrity
		integrity = minf(Economy.MAX_RESOURCE, integrity + Terrain.OASIS_HEAL)
		map_terrain[cell] = Terrain.NORMAL
		if scanned.has(cell):
			scanned[cell]["terrain"] = Terrain.NORMAL
		_log("Oásis vegetativo: radiação purificada. Integridade +%.0f." % (integrity - before), "good")
		map_changed.emit()
		_emit_all()
		return false
	if terrain == Terrain.SUBESTACAO:
		event = EventDB.substation(substation_stability.get(cell, 0.5))
	elif terrain == Terrain.NODULO:
		event = EventDB.nodule()
	elif terrain == Terrain.ELEVADOR:
		event = EventDB.elevator(core_nature, core_art, battery)
	elif map_pois.has(cell):
		var poi: Dictionary = map_pois[cell]
		match poi["type"]:
			"core_nature":
				event = EventDB.core_nature()
			"core_art":
				event = EventDB.core_art()
			"item":
				event = EventDB.item_cache(poi["item"])
			"event":
				if not poi.has("event_id"):
					poi["event_id"] = EventDB.pick_for_biome(biome_at(cell), rng)["id"]
				event = EventDB.build(poi["event_id"])
	if event.is_empty():
		return false
	event["cell"] = cell
	active_event = event
	choice_event_triggered.emit(event)
	return true


## Sensores passivos: a célula atual e as vizinhas saem da névoa. Estruturas físicas
## (fendas, firewalls, raízes, subestações) são vistas a olho nu; vazamentos,
## interferência e gás só aparecem com o LiDAR.
func _reveal_around(cell: Vector2i) -> void:
	for c in [cell] + Hex.neighbors(cell):
		if not in_map(c):
			continue
		revealed[c] = true
		var t: String = map_terrain[c]
		if Terrain.visible_without_scan(t) and (not scanned.has(c) or scanned[c]["terrain"] != t):
			scanned[c] = {"terrain": t, "poi": scanned.get(c, {}).get("poi", false), "uncertain": false}


func _scan_cell(cell: Vector2i, storm: bool, false_topography: bool) -> void:
	var real := terrain_at(cell)
	var shown := real
	var uncertain := false
	var near_interference := false
	for c in Hex.cells_in_radius(cell, 1):
		if map_terrain.get(c, "") == Terrain.INTERFERENCIA:
			near_interference = true
	var alterable := real in [Terrain.NORMAL, Terrain.VAZAMENTO, Terrain.FENDA]
	if (storm or (near_interference and real != Terrain.INTERFERENCIA)) and alterable:
		uncertain = true
		if rng.randf() < NOISE_CHANCE:
			shown = Terrain.NORMAL if real != Terrain.NORMAL else Terrain.VAZAMENTO
	if false_topography and biome_at(cell) == "eco" and real in [Terrain.VAZAMENTO, Terrain.FENDA]:
		if rng.randf() < FALSE_TOPOGRAPHY_CHANCE:
			shown = Terrain.NORMAL
	scanned[cell] = {"terrain": shown, "poi": map_pois.has(cell), "uncertain": uncertain}


func _spend_battery(amount: float) -> void:
	battery = maxf(0.0, battery - amount)
	stats["battery_spent"] += amount


func _damage(amount: float, source: String) -> void:
	integrity = maxf(0.0, integrity - amount)
	stats["damage"] += amount
	_log("%s: -%.0f Integridade." % [source, amount], "danger")
	system_alert.emit("-%.0f Integridade" % amount)


func _can_afford_any_move() -> bool:
	for n in Hex.neighbors(player_cell):
		if in_map(n) and not Terrain.blocks(map_terrain[n]) and battery >= step_battery_cost(player_cell, n):
			return true
	return false


func _check_defeat() -> void:
	if run_over:
		return
	if integrity <= 0.0:
		_finish_game_over("Falha Crítica: integridade do chassi comprometida.")
	elif battery <= 0.0:
		_finish_game_over("Falha Crítica: bateria esgotada.")
	elif _is_isolated() and terrain_at(player_cell) != Terrain.ELEVADOR:
		_finish_game_over("Falha Crítica: N-7 ficou isolado pelo colapso do domo.")
	elif not _can_afford_any_move() and not inventory.has_item("celula_bateria") and not _has_energy_source_here():
		_finish_game_over("Falha Crítica: energia insuficiente para qualquer deslocamento.")


func _is_isolated() -> bool:
	for n in Hex.neighbors(player_cell):
		if in_map(n) and not Terrain.blocks(map_terrain[n]):
			return false
	return true


func _has_energy_source_here() -> bool:
	var t := terrain_at(player_cell)
	if t == Terrain.ELEVADOR:
		return battery >= Economy.ELEVATOR_TOLL
	if t in [Terrain.SUBESTACAO, Terrain.NODULO] or not active_event.is_empty() or not pending_item.is_empty():
		return true
	# Só conta um ponto de interesse que ainda possa render energia.
	var poi: Dictionary = map_pois.get(player_cell, {})
	if poi.get("type", "") == "item":
		return poi["item"] == "celula_bateria"
	return poi.get("type", "") == "event" and not poi.has("event_id")


func _ascend() -> void:
	var ending := Endings.evaluate(core_nature, core_art, inventory.has_item("dados_queda"))
	_log("Ascensão iniciada. Protocolo Trino entregue ao Elevador Central.", "good")
	_finish({"kind": "ending", "id": ending})


func _finish_game_over(reason: String) -> void:
	_log(reason, "danger")
	game_over.emit(reason)
	_finish({"kind": "game_over", "reason": reason})


func _finish(result: Dictionary) -> void:
	run_over = true
	result["stats"] = stats.duplicate()
	result["round"] = current_round
	result["seed"] = run_seed
	result["battery"] = battery
	result["integrity"] = integrity
	result["load"] = load_kg()
	last_result = result
	_emit_all()
	run_finished.emit(result)


func _log(text: String, kind: String = "info") -> void:
	log_message.emit(text, kind)


func _emit_all() -> void:
	resources_updated.emit()
