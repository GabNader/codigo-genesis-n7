class_name Director
extends RefCounted
## Diretor de IA (GDD §16): máquina de estados que avalia o desempenho do jogador
## a cada turno e decide se o ambiente fica mais hostil.
##
## IDLE → AVALIACAO → (HOSTIL | PADRAO) → ATUALIZACAO → IDLE
## Limiar de bateria por quadrante: quanto mais longe do Elevador, mais energia é
## "esperada"; acima dele, o Diretor gera anomalias à frente do N-7.

enum State { IDLE, AVALIACAO, HOSTIL, PADRAO, ATUALIZACAO }

const BASE_THRESHOLD := 45.0
const THRESHOLD_PER_HEX := 5.0
const HOSTILE_ANOMALIES := 2
const HOSTILE_MIN_DIST := 2
const HOSTILE_MAX_DIST := 4

var state: State = State.IDLE
var last_decision: State = State.PADRAO
var history: Array = []


static func threshold(distance_to_elevator: int) -> float:
	return BASE_THRESHOLD + THRESHOLD_PER_HEX * distance_to_elevator


static func state_name(s: State) -> String:
	return State.keys()[s]


func evaluate(battery: float, distance_to_elevator: int) -> State:
	state = State.AVALIACAO
	var decision := State.HOSTIL if battery >= threshold(distance_to_elevator) else State.PADRAO
	last_decision = decision
	history.append(decision)
	state = decision
	return decision


## Chamado depois que o ambiente e a interface foram atualizados.
func finish_cycle() -> void:
	state = State.ATUALIZACAO
	state = State.IDLE
