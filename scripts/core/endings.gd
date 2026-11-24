class_name Endings
extends RefCounted
## Os 5 finais do Elevador Central (GDD §8 e §11), definidos pela combinação de dados
## que N-7 entrega na Ascensão. O Game Over não conta como final: é o colapso do protocolo.

const GENESIS := "genesis"
const PARAISO_PERDIDO := "paraiso_perdido"
const EDEN_SILENCIOSO := "eden_silencioso"
const MUSEU_CRISTAL := "museu_cristal"
const CIVILIZACAO_ESTERIL := "civilizacao_esteril"

const DATA := {
	GENESIS: {
		"title": "GÊNESIS",
		"subtitle": "Final Verdadeiro — Lógica + Natureza + Arte",
		"tone": "true",
		"text": "A Trindade de Dados se une no topo do Elevador. A razão encontra a vida e a beleza, e a nova civilização floresce completa: cálculo a serviço do cuidado, e não como fim em si mesmo.",
	},
	PARAISO_PERDIDO: {
		"title": "PARAÍSO PERDIDO",
		"subtitle": "Final Ambíguo — Trindade + Dados da Queda",
		"tone": "ambiguous",
		"text": "A civilização renasce inteira, mas carrega na memória o registro exato de como caiu. Talvez esse conhecimento a proteja. Talvez a tente a repetir o erro.",
	},
	EDEN_SILENCIOSO: {
		"title": "ÉDEN SILENCIOSO",
		"subtitle": "Final Médio — Lógica + Natureza",
		"tone": "medium",
		"text": "Florestas cobrem o domo e a vida volta a respirar. Mas não há canções nem pinturas: um jardim perfeito, sem ninguém que se espante com ele.",
	},
	MUSEU_CRISTAL: {
		"title": "MUSEU DE CRISTAL",
		"subtitle": "Final Médio — Lógica + Arte",
		"tone": "medium",
		"text": "As obras da humanidade sobrevivem intactas em salas frias e estéreis. Há beleza para contemplar, mas nenhuma vida para contemplá-la.",
	},
	CIVILIZACAO_ESTERIL: {
		"title": "CIVILIZAÇÃO ESTÉRIL",
		"subtitle": "Final Ruim — apenas Lógica",
		"tone": "bad",
		"text": "N-7 sobe sozinho com o que sempre teve. O recomeço é exato, eficiente e vazio: uma sociedade de máquinas que sabe calcular tudo, menos o porquê.",
	},
}


static func evaluate(has_nature: bool, has_art: bool, has_fall_data: bool) -> String:
	if has_nature and has_art:
		return PARAISO_PERDIDO if has_fall_data else GENESIS
	if has_nature:
		return EDEN_SILENCIOSO
	if has_art:
		return MUSEU_CRISTAL
	return CIVILIZACAO_ESTERIL


static func info(id: String) -> Dictionary:
	return DATA[id]
