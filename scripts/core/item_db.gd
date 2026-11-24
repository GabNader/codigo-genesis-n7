class_name ItemDB
extends RefCounted
## Catálogo de peças da mochila (GDD §6 — Subsistema de Inventário).
## Formatos em blocos; núcleos têm formato fixo e não giram (diagrama do Protocolo Trino).

const ITEMS := {
	"nucleo_natureza": {
		"name": "Núcleo da Natureza",
		"shape": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
		"weight": 15.0,
		"rotatable": false,
		"discardable": false,
		"color": Color(0.25, 0.85, 0.35),
		"use": {},
		"description": "DNA de espécies extintas. Equilíbrio, vida e sustentação ambiental.",
	},
	"nucleo_arte": {
		"name": "Núcleo da Arte",
		"shape": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)],
		"weight": 15.0,
		"rotatable": false,
		"discardable": false,
		"color": Color(0.7, 0.3, 0.95),
		"use": {},
		"description": "Sinfonias, pinturas e poemas comprimidos. Criatividade e expressão humana.",
	},
	"dados_queda": {
		"name": "Dados da Queda",
		"shape": [Vector2i(0, 0), Vector2i(1, 0)],
		"weight": 10.0,
		"rotatable": true,
		"discardable": true,
		"color": Color(0.95, 0.35, 0.3),
		"use": {},
		"description": "O registro de como a humanidade caiu. Pesado de carregar.",
	},
	"celula_bateria": {
		"name": "Célula de bateria",
		"shape": [Vector2i(0, 0)],
		"weight": 2.0,
		"rotatable": true,
		"discardable": true,
		"color": Color(0.2, 0.85, 0.9),
		"use": {"battery": 20.0},
		"description": "Usar: +20% Bateria.",
	},
	"kit_reparo": {
		"name": "Kit de reparo",
		"shape": [Vector2i(0, 0), Vector2i(1, 0)],
		"weight": 3.0,
		"rotatable": true,
		"discardable": true,
		"color": Color(0.95, 0.6, 0.2),
		"use": {"integrity": 25.0},
		"description": "Usar: +25 Integridade.",
	},
}


static func has(id: String) -> bool:
	return ITEMS.has(id)


static func get_item(id: String) -> Dictionary:
	return ITEMS[id]


static func shape(id: String) -> Array:
	return ITEMS[id]["shape"].duplicate()


static func weight(id: String) -> float:
	return ITEMS[id]["weight"]


static func display_name(id: String) -> String:
	return ITEMS[id]["name"]
