class_name Lore
extends RefCounted
## Narrativa contada durante a exploração (GDD §11): despertar, chegada a cada bioma,
## memórias recuperadas dos núcleos e o fechamento da Trindade.
## Os trechos musicais usam frequências em Hz e duração em segundos; são tocados pelo
## sintetizador do AudioManager, sem arquivos de áudio externos.

const AWAKENING := [
	"REINICIALIZAÇÃO CONCLUÍDA. Unidade N-7 online.",
	"ALERTA: Domo Esperança em colapso estrutural.",
	"Núcleo da LÓGICA: ATIVO. Natureza: AUSENTE. Arte: AUSENTE.",
	"Missão: resgatar os núcleos da Natureza e da Arte e levar a Trindade ao Elevador Central.",
]

const BIOME_ARRIVAL := {
	"industrial": {
		"title": "Zona Industrial",
		"text": "Máquinas paradas zumbem com o resto de energia que ainda corre nos cabos. Aqui ficam as subestações: o domo ainda pode alimentar quem souber sifonar.",
	},
	"eco": {
		"title": "Setor Eco-Vegetativo",
		"text": "As estufas romperam e a água escorre pelas calhas. Raízes metálicas engoliram os corredores. Em algum lugar aqui dentro, o Jardim Suspenso guarda a Natureza.",
	},
	"degrad": {
		"title": "Zona de Degradação",
		"text": "Vento químico atravessa paredes rachadas. Os sensores falham perto do neon em curto. Escanear antes de andar não é cautela: é sobrevivência.",
	},
	"nodes": {
		"title": "Nódulos de Energia",
		"text": "O caos dá lugar a câmaras limpas e firewalls vermelhos. O Cofre das Memórias pulsa perto do Elevador. Cada travessia aqui cobra pedágio.",
	},
}

## Ode à Alegria (Beethoven, 1824 — domínio público): primeira frase.
const MELODY_ARTE := [
	[329.63, 0.34], [329.63, 0.34], [349.23, 0.34], [392.0, 0.34],
	[392.0, 0.34], [349.23, 0.34], [329.63, 0.34], [293.66, 0.34],
	[261.63, 0.34], [261.63, 0.34], [293.66, 0.34], [329.63, 0.34],
	[329.63, 0.5], [293.66, 0.17], [293.66, 0.7],
]

## Canto de pássaro sintetizado: [frequência inicial, frequência final, duração].
const BIRDSONG := [
	[2600.0, 3400.0, 0.12], [3400.0, 2400.0, 0.10], [0.0, 0.0, 0.08],
	[2800.0, 3600.0, 0.09], [3600.0, 2800.0, 0.09], [0.0, 0.0, 0.25],
	[2200.0, 3000.0, 0.15], [3000.0, 2500.0, 0.12], [2500.0, 3300.0, 0.10],
]

const MEMORIES := {
	"arte": {
		"title": "ARQUIVO RECUPERADO 9/1824",
		"text": "\"Alegria, centelha divina...\" Sinfonia nº 9, Ludwig van Beethoven, 1824. Uma orquestra e um coro cantaram juntos sobre a fraternidade entre todas as pessoas. O servidor guardou só esta frase, mas a melodia ainda está inteira. É isto que o núcleo da Arte preserva: o que a humanidade sentia, e não só o que ela sabia.",
	},
	"natureza": {
		"title": "AMOSTRA GENÉTICA 0417",
		"text": "Sabiá-laranjeira (Turdus rufiventris). Cantava ao amanhecer nas cidades antigas, antes do domo. O núcleo da Natureza guarda o DNA de 41.000 espécies, e a gravação deste canto, que ninguém ouve há trezentos anos.",
	},
}

const TRINITY_COMPLETE := {
	"title": "PROTOCOLO TRINO COMPLETO",
	"text": "Lógica, Natureza e Arte acopladas. Pela primeira vez desde a Queda, os três registros estão no mesmo lugar. O Elevador Central respondeu ao sinal: siga a linha dourada.",
}

## Arpejo da Trindade: Dó–Mi–Sol–Dó.
const TRINITY_CHORD := [[261.63, 0.22], [329.63, 0.22], [392.0, 0.22], [523.25, 0.8]]
