class_name MapGenerator
extends RefCounted
## Geração procedural do Domo Esperança (GDD §10 e §16).
## Biomas por regiões de Voronoi no grid axial, terreno por probabilidades de cada
## bioma e garantia de que núcleos e Elevador sejam alcançáveis (anti-goal: nada de
## derrota por aleatoriedade injusta).

const DEFAULT_RADIUS := 6
const MAX_ATTEMPTS := 30

## Probabilidade de cada terreno por bioma (o restante é terreno estável).
const TERRAIN_TABLE := {
	"industrial": {Terrain.FENDA: 0.10, Terrain.VAZAMENTO: 0.06, Terrain.INTERFERENCIA: 0.04, Terrain.SUBESTACAO: 0.07},
	"eco": {Terrain.FENDA: 0.12, Terrain.RAIZES: 0.14, Terrain.VAZAMENTO: 0.04, Terrain.OASIS: 0.04},
	"degrad": {Terrain.FENDA: 0.10, Terrain.VAZAMENTO: 0.20, Terrain.INTERFERENCIA: 0.10},
	"nodes": {Terrain.FIREWALL: 0.35},
}

## Chance de um hexágono estável conter um evento do bioma.
const EVENT_CHANCE := {"industrial": 0.14, "eco": 0.14, "degrad": 0.12, "nodes": 0.12}
const ITEM_CACHES := ["celula_bateria", "celula_bateria", "kit_reparo"]


static func generate(seed_value: int, radius: int = DEFAULT_RADIUS) -> Dictionary:
	for attempt in MAX_ATTEMPTS:
		var map := _generate_once(seed_value + attempt * 7919, radius)
		if is_solvable(map):
			map["seed"] = seed_value
			return map
	# Último recurso: remove todas as fendas, o que sempre conecta o mapa.
	var fallback := _generate_once(seed_value, radius)
	for cell in fallback["terrain"]:
		if fallback["terrain"][cell] == Terrain.FENDA:
			fallback["terrain"][cell] = Terrain.NORMAL
	fallback["seed"] = seed_value
	return fallback


static func is_solvable(map: Dictionary) -> bool:
	var terrain: Dictionary = map["terrain"]
	var passable := func(c: Vector2i) -> bool:
		return terrain.has(c) and not Terrain.blocks(terrain[c])
	var seen := Hex.reachable(map["spawn"], passable)
	for target in [map["elevator"], map["core_nature"], map["core_art"]]:
		if not seen.has(target):
			return false
	return true


static func _generate_once(seed_value: int, radius: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var center := Vector2i.ZERO
	var spawn := Vector2i(0, radius)
	var cells := Hex.cells_in_radius(center, radius)

	var seeds := {
		"industrial": [spawn, _pick(rng, cells, func(c): return Hex.distance(c, center) >= 4 and Hex.distance(c, spawn) >= 5)],
		"eco": [
			_pick(rng, cells, func(c): return Hex.distance(c, center) in [3, 4, 5] and Hex.distance(c, spawn) >= 5),
			_pick(rng, cells, func(c): return Hex.distance(c, center) in [3, 4, 5] and Hex.distance(c, spawn) >= 4),
		],
		"degrad": [
			_pick(rng, cells, func(c): return Hex.distance(c, center) in [3, 4, 5] and Hex.distance(c, spawn) >= 3),
			_pick(rng, cells, func(c): return Hex.distance(c, center) in [3, 4, 5] and Hex.distance(c, spawn) >= 3),
		],
	}

	var biomes := {}
	var terrain := {}
	for cell in cells:
		var d_center := Hex.distance(cell, center)
		var biome := ""
		if d_center == 0:
			biome = "elevator"
		elif d_center <= 2:
			biome = "nodes"
		elif Hex.distance(cell, spawn) <= 2:
			biome = "industrial"
		else:
			var best := 9999
			for b in ["industrial", "eco", "degrad"]:
				for s in seeds[b]:
					var d := Hex.distance(cell, s)
					if d < best:
						best = d
						biome = b
		biomes[cell] = biome
		terrain[cell] = Terrain.NORMAL

	# Terreno por probabilidade, mantendo a área inicial segura.
	for cell in cells:
		var biome: String = biomes[cell]
		if biome == "elevator":
			terrain[cell] = Terrain.ELEVADOR
			continue
		if Hex.distance(cell, spawn) <= 1:
			continue
		var roll := rng.randf()
		var acc := 0.0
		for t in TERRAIN_TABLE.get(biome, {}):
			acc += TERRAIN_TABLE[biome][t]
			if roll < acc:
				terrain[cell] = t
				break

	# Núcleos: Natureza no setor eco, Arte nos Nódulos de Energia (GDD §10).
	var core_nature: Vector2i = _pick(rng, cells, func(c): return biomes[c] == "eco" and Hex.distance(c, spawn) >= 4)
	if core_nature == InventoryGrid.NO_FIT:
		core_nature = _pick(rng, cells, func(c): return Hex.distance(c, spawn) >= 5 and biomes[c] != "nodes" and biomes[c] != "elevator")
	var core_art: Vector2i = _pick(rng, cells, func(c): return Hex.distance(c, center) == 2)
	var nodule: Vector2i = _pick(rng, cells, func(c): return Hex.distance(c, center) == 1)
	terrain[core_nature] = Terrain.NORMAL
	terrain[core_art] = Terrain.NORMAL
	terrain[nodule] = Terrain.NODULO

	# Garante uma subestação perto do início para a economia base (GDD §10, Zonas Industriais).
	var has_early_station := false
	for cell in cells:
		if terrain[cell] == Terrain.SUBESTACAO and Hex.distance(cell, spawn) <= 4:
			has_early_station = true
	if not has_early_station:
		var station: Vector2i = _pick(rng, cells, func(c): return Hex.distance(c, spawn) in [2, 3, 4] and terrain[c] == Terrain.NORMAL and c != core_nature)
		if station != InventoryGrid.NO_FIT:
			terrain[station] = Terrain.SUBESTACAO

	var pois := {}
	pois[core_nature] = {"type": "core_nature"}
	pois[core_art] = {"type": "core_art"}

	var stability := {}
	for cell in cells:
		if terrain[cell] == Terrain.SUBESTACAO:
			stability[cell] = snappedf(rng.randf_range(0.5, 0.9), 0.05)

	var free := []
	for cell in cells:
		if terrain[cell] == Terrain.NORMAL and not pois.has(cell) and Hex.distance(cell, spawn) >= 2 and biomes[cell] != "elevator":
			free.append(cell)
	_shuffle(rng, free)
	for item_id in ITEM_CACHES:
		if free.is_empty():
			break
		pois[free.pop_back()] = {"type": "item", "item": item_id}
	for cell in free:
		if rng.randf() < EVENT_CHANCE.get(biomes[cell], 0.0):
			pois[cell] = {"type": "event"}

	return {
		"radius": radius,
		"biomes": biomes,
		"terrain": terrain,
		"pois": pois,
		"stability": stability,
		"spawn": spawn,
		"elevator": center,
		"core_nature": core_nature,
		"core_art": core_art,
	}


static func _pick(rng: RandomNumberGenerator, cells: Array, condition: Callable) -> Vector2i:
	var options := []
	for c in cells:
		if condition.call(c):
			options.append(c)
	if options.is_empty():
		return InventoryGrid.NO_FIT
	return options[rng.randi_range(0, options.size() - 1)]


## Embaralhamento determinístico (Array.shuffle usa o RNG global).
static func _shuffle(rng: RandomNumberGenerator, arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
