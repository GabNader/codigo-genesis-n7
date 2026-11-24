class_name EventDB
extends RefCounted
## Banco de eventos narrativos e sistêmicos (GDD §16 — tabelas de eventos).
##
## Cada opção tem `effects`, aplicados por GameState.apply_effects:
##   battery / integrity (delta), item (peça para a mochila), load_temp [kg, turnos],
##   status {nome: turnos}, reveal (raio), flag, chance + success/fail, ascend.
## `requires_battery` desabilita a opção; `consume` remove o evento do mapa.

const POOLS := {
	"global": ["pilar_sal", "mana_sintetico"],
	"industrial": ["fruto_silicio", "sucata_magnetica", "automato_caido"],
	"eco": ["esporos_corrosivos", "estufa_intacta"],
	"degrad": ["chuva_acida", "capsula_reparo"],
	"nodes": ["sentinela_defeituosa", "celula_reserva"],
}

const EVENTS := {
	"pilar_sal": {
		"title": "Pilar de Sal",
		"description": "Uma leitura automática de dados corrompidos congelou a articulação do N-7 numa crosta branca e rígida. O peso do passado atrasa a máquina.",
		"options": [
			{"label": "Romper a crosta  (-10 Integridade)", "effects": {"integrity": -10.0}, "consume": true},
		],
	},
	"mana_sintetico": {
		"title": "Maná Sintético",
		"description": "Um antigo drone colapsou do teto, espalhando células de energia intactas sobre a terra árida. Há provisões para hoje.",
		"options": [
			{"label": "Recolher a dádiva  (+25% Bateria)", "effects": {"battery": 25.0}, "consume": true},
		],
	},
	"fruto_silicio": {
		"title": "O Fruto de Silício",
		"description": "Um terminal solitário exibe dados puros sobre a Queda da humanidade. Consumi-los inicia um expurgo doloroso no sistema local, e o conhecimento pesa.",
		"options": [
			{"label": "Baixar os dados  (peça 2×1, +10 kg | -15 Integridade)", "effects": {"item": "dados_queda", "integrity": -15.0}, "consume": true},
			{"label": "Abster-se  (seguir sem saber)", "effects": {}, "consume": true},
		],
	},
	"sucata_magnetica": {
		"title": "Sucata Magnética",
		"description": "Um campo magnético residual gruda detritos de ferro no chassi. O N-7 pode carregá-los ou gastar energia para desmagnetizar.",
		"options": [
			{"label": "Aceitar o peso  (+5 kg por 3 turnos)", "effects": {"load_temp": [5.0, 3]}, "consume": true},
			{"label": "Desmagnetizar  (-8% Bateria)", "effects": {"battery": -8.0}, "requires_battery": 8.0, "consume": true},
		],
	},
	"automato_caido": {
		"title": "Autômato Caído",
		"description": "Uma unidade gêmea jaz desativada entre cabos rompidos. Sua memória ainda guarda um mapa do setor, e seu compartimento, um kit de reparo.",
		"options": [
			{"label": "Minerar o mapa  (-10% Bateria | revela raio 5)", "effects": {"battery": -10.0, "reveal": 5}, "requires_battery": 10.0, "consume": true},
			{"label": "Extrair o kit  (-10% Bateria | kit de reparo)", "effects": {"battery": -10.0, "item": "kit_reparo"}, "requires_battery": 10.0, "consume": true},
			{"label": "Seguir em frente", "effects": {}, "consume": true},
		],
	},
	"esporos_corrosivos": {
		"title": "Esporos Corrosivos",
		"description": "Uma nuvem de esporos metálicos se prende às juntas. Eles corroem o chassi a cada turno até serem queimados.",
		"options": [
			{"label": "Atravessar a nuvem  (-5 Integridade por turno, 3 turnos)", "effects": {"status": {"spores": 3}}, "consume": true},
			{"label": "Queimar os esporos  (-10% Bateria)", "effects": {"battery": -10.0}, "requires_battery": 10.0, "consume": true},
		],
	},
	"estufa_intacta": {
		"title": "Estufa Intacta",
		"description": "Uma estufa hidropônica ainda pulsa. Bactérias eletrogênicas carregaram uma célula de bateria orgânica.",
		"options": [
			{"label": "Acoplar a célula  (peça 1×1, +2 kg)", "effects": {"item": "celula_bateria"}, "consume": true},
			{"label": "Deixar para a natureza", "effects": {}, "consume": true},
		],
	},
	"chuva_acida": {
		"title": "Chuva Ácida",
		"description": "Uma precipitação química severa começa a cair sobre o setor. Cada movimento desgasta o chassi.",
		"options": [
			{"label": "Seguir sob a chuva  (+2 de dano por passo, 5 turnos)", "effects": {"status": {"acid_rain": 5}}, "consume": true},
		],
	},
	"capsula_reparo": {
		"title": "Cápsula de Manutenção",
		"description": "Uma cápsula de manutenção selada resistiu à degradação. Dentro, um kit de reparo intacto.",
		"options": [
			{"label": "Acoplar o kit  (peça 2×1, +3 kg)", "effects": {"item": "kit_reparo"}, "consume": true},
			{"label": "Deixar", "effects": {}, "consume": true},
		],
	},
	"sentinela_defeituosa": {
		"title": "Sentinela Defeituosa",
		"description": "Um antigo robô de segurança barra o caminho, piscando em vermelho. Sua bateria está exposta.",
		"options": [
			{"label": "Roubar a bateria  (70%: +30% Bateria | 30%: -25 Integridade)", "effects": {"chance": 0.7, "success": {"battery": 30.0}, "fail": {"integrity": -25.0}}, "consume": true},
			{"label": "Recuar em silêncio", "effects": {}, "consume": true},
		],
	},
	"celula_reserva": {
		"title": "Célula de Reserva",
		"description": "Um soquete de manutenção guarda uma célula de bateria carregada.",
		"options": [
			{"label": "Acoplar a célula  (peça 1×1, +2 kg)", "effects": {"item": "celula_bateria"}, "consume": true},
			{"label": "Deixar", "effects": {}, "consume": true},
		],
	},
}


static func pick_for_biome(biome: String, rng: RandomNumberGenerator) -> Dictionary:
	var pool: Array = POOLS["global"] + POOLS.get(biome, [])
	var id: String = pool[rng.randi_range(0, pool.size() - 1)]
	return build(id)


static func build(id: String) -> Dictionary:
	var event: Dictionary = EVENTS[id].duplicate(true)
	event["id"] = id
	return event


static func core_nature() -> Dictionary:
	return {
		"id": "jardim_suspenso",
		"title": "O Jardim Suspenso — Núcleo da Natureza",
		"description": "Uma câmara criogênica abriga o DNA de espécies extintas. Estabilizar o núcleo exige desviar energia vital do N-7.",
		"options": [
			{"label": "Extrair a Natureza  (peça 3×2, +15 kg | -30% Bateria)", "effects": {"item": "nucleo_natureza", "battery": -30.0}, "requires_battery": 30.0, "consume": true},
			{"label": "Abster-se por ora  (voltar depois)", "effects": {}, "consume": false},
		],
	}


static func core_art() -> Dictionary:
	return {
		"id": "cofre_memorias",
		"title": "O Cofre das Memórias — Núcleo da Arte",
		"description": "Servidores ecoam sinfonias distorcidas. A beleza do passado humano exige um sacrifício físico da máquina para ser carregada.",
		"options": [
			{"label": "Extrair a Arte  (peça 2×3, +15 kg | -25 Integridade)", "effects": {"item": "nucleo_arte", "integrity": -25.0}, "consume": true},
			{"label": "Abster-se por ora  (voltar depois)", "effects": {}, "consume": false},
		],
	}


static func item_cache(item_id: String) -> Dictionary:
	var item := ItemDB.get_item(item_id)
	return {
		"id": "cache_" + item_id,
		"title": "Compartimento Selado",
		"description": "O LiDAR marcou um compartimento intacto. Dentro: %s. %s" % [item["name"], item["description"]],
		"options": [
			{"label": "Acoplar à mochila  (+%.0f kg)" % item["weight"], "effects": {"item": item_id}, "consume": true},
			{"label": "Deixar", "effects": {}, "consume": false},
		],
	}


## Subestação com estabilidade visível: o jogador compara valores esperados.
static func substation(stability: float) -> Dictionary:
	var pct := roundi(stability * 100.0)
	var ev := Economy.expected_value(stability, 35.0, 0.0)
	return {
		"id": "subestacao",
		"title": "Subestação Elétrica — estabilidade %d%%" % pct,
		"description": "O terminal ainda converte calor residual em energia, mas está corrompido. Forçar o sifonamento pode causar um curto-circuito.\nGanho esperado do sifonamento máximo: %d%% × 35 = %.1f%% de bateria." % [pct, ev],
		"options": [
			{"label": "Sifonar ao máximo  (%d%%: +35%% Bateria | %d%%: -20 Integridade)" % [pct, 100 - pct], "effects": {"chance": stability, "success": {"battery": 35.0}, "fail": {"integrity": -20.0}}, "consume": true},
			{"label": "Sifonamento seguro  (+12% Bateria garantido)", "effects": {"battery": 12.0}, "consume": true},
			{"label": "Deixar para depois", "effects": {}, "consume": false},
		],
	}


static func nodule() -> Dictionary:
	return {
		"id": "sobrecarga_total",
		"title": "Sobrecarga Total — Nódulo Puro",
		"description": "Um reservatório de energia pura vibra no limite. O N-7 pode absorver tudo, mas o calor vai derreter parte do chassi.",
		"options": [
			{"label": "Absorver carga máxima  (+100% Bateria | -40 Integridade)", "effects": {"battery": 100.0, "integrity": -40.0}, "consume": true},
			{"label": "Absorção controlada  (+20% Bateria)", "effects": {"battery": 20.0}, "consume": true},
			{"label": "Deixar para depois", "effects": {}, "consume": false},
		],
	}


static func elevator(has_nature: bool, has_art: bool, battery: float) -> Dictionary:
	var status := "Protocolo Trino:\n  Lógica — integrada\n  Natureza — %s\n  Arte — %s" % [
		"acoplada" if has_nature else "ausente",
		"acoplada" if has_art else "ausente",
	]
	var warn := ""
	if battery < Economy.ELEVATOR_TOLL:
		warn = "\n\nBateria abaixo do pedágio de ativação (%.0f%%)." % Economy.ELEVATOR_TOLL
	return {
		"id": "elevador",
		"title": "Elevador Central de Ascensão",
		"description": "A coluna de luz aguarda. O que N-7 levar agora definirá o recomeço da civilização.\n\n" + status + warn,
		"options": [
			{"label": "Iniciar a Ascensão  (-%.0f%% Bateria)" % Economy.ELEVATOR_TOLL, "effects": {"battery": -Economy.ELEVATOR_TOLL, "ascend": true}, "requires_battery": Economy.ELEVATOR_TOLL, "consume": false},
			{"label": "Continuar explorando", "effects": {}, "consume": false},
		],
	}
