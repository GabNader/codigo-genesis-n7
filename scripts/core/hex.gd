class_name Hex
extends RefCounted
## Matemática do grid hexagonal em coordenadas axiais (q, r).
## Geometria Analítica do GDD §2: distância, vizinhança e busca de caminhos (A*).

const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1),
]


static func distance(a: Vector2i, b: Vector2i) -> int:
	var dq := a.x - b.x
	var dr := a.y - b.y
	return (absi(dq) + absi(dq + dr) + absi(dr)) / 2


static func neighbors(cell: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in DIRECTIONS:
		out.append(cell + d)
	return out


static func cells_in_radius(center: Vector2i, radius: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for q in range(-radius, radius + 1):
		for r in range(maxi(-radius, -q - radius), mini(radius, -q + radius) + 1):
			out.append(center + Vector2i(q, r))
	return out


static func ring(center: Vector2i, radius: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for cell in cells_in_radius(center, radius):
		if distance(cell, center) == radius:
			out.append(cell)
	return out


## A* de start até goal. `passable(cell) -> bool` e `step_cost(from, to) -> float`.
## Devolve o caminho sem a célula inicial e com o destino; vazio se não houver rota.
static func find_path(start: Vector2i, goal: Vector2i, passable: Callable, step_cost: Callable) -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	if start == goal or not passable.call(goal):
		return empty
	var open: Array[Vector2i] = [start]
	var came_from: Dictionary = {}
	var g: Dictionary = {start: 0.0}
	var f: Dictionary = {start: float(distance(start, goal))}
	while not open.is_empty():
		var best_i := 0
		for i in range(1, open.size()):
			if f[open[i]] < f[open[best_i]]:
				best_i = i
		var current: Vector2i = open[best_i]
		if current == goal:
			var path: Array[Vector2i] = [current]
			while came_from.has(current):
				current = came_from[current]
				if current != start:
					path.push_front(current)
			return path
		open.remove_at(best_i)
		for n in neighbors(current):
			if not passable.call(n):
				continue
			var tentative: float = g[current] + float(step_cost.call(current, n))
			if tentative < g.get(n, INF):
				came_from[n] = current
				g[n] = tentative
				f[n] = tentative + distance(n, goal)
				if not open.has(n):
					open.append(n)
	return empty


## Células alcançáveis a partir de start (busca em largura).
static func reachable(start: Vector2i, passable: Callable) -> Dictionary:
	var seen: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		for n in neighbors(current):
			if not seen.has(n) and passable.call(n):
				seen[n] = true
				queue.append(n)
	return seen
