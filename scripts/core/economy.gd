class_name Economy
extends RefCounted
## Subsistema de Economia (GDD §6): custos de energia das ações do N-7.
##
## Custo de um passo = CUSTO_BASE × (1 + Modificador de Peso)
## Modificador de Peso = carga útil (kg) ÷ PESO_REFERENCIA
## O custo é linear na carga de propósito: o jogador consegue prever de cabeça
## exatamente quanto vai gastar (Pilar 3 — Satisfação Intelectual).

const BASE_STEP_COST := 1.5        ## % de bateria por hexágono sem carga
const WEIGHT_REFERENCE := 15.0     ## kg que somam +1,0 ao modificador (um macro-núcleo)
const LIDAR_COST := 5.0            ## % fixo por pulso (GDD §5)
const LIDAR_RADIUS := 3            ## níveis de distância revelados (GDD §5)
const FIREWALL_COST := 15.0        ## pedágio fixo para atravessar um firewall físico
const ROOTS_MULTIPLIER := 3.0      ## sair de raízes preensoras triplica o passo
const ELECTRIFIED_COST := 15.0     ## piso eletrificado pelo Curto em Cadeia
const ELEVATOR_TOLL := 10.0        ## energia para ativar a subida no Elevador Central
const MAX_ROUTE_LENGTH := 4        ## alcance motor por turno: hexágonos por movimento confirmado
const MAX_RESOURCE := 100.0


static func weight_modifier(load_kg: float, harmonic := false) -> float:
	var modifier := load_kg / WEIGHT_REFERENCE
	if harmonic:
		modifier *= 0.5
	return modifier


static func step_cost(load_kg: float, harmonic := false) -> float:
	return BASE_STEP_COST * (1.0 + weight_modifier(load_kg, harmonic))


static func route_cost(distance: int, load_kg: float, harmonic := false) -> float:
	return distance * step_cost(load_kg, harmonic)


## Valor esperado de uma aposta: usado nas mensagens de sifonamento (Probabilidade).
static func expected_value(chance: float, gain: float, loss: float) -> float:
	return chance * gain - (1.0 - chance) * loss
