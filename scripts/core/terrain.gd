class_name Terrain
extends RefCounted
## Tipos de terreno do HexGrid e biomas do Domo Esperança (GDD §5, §9 e §10).

const NORMAL := "normal"
const FENDA := "fenda"
const VAZAMENTO := "vazamento"
const INTERFERENCIA := "interferencia"
const SUBESTACAO := "subestacao"
const NODULO := "nodulo"
const OASIS := "oasis"
const FIREWALL := "firewall"
const RAIZES := "raizes"
const ELEVADOR := "elevador"

const LEAK_DAMAGE := 20.0
const GAS_DAMAGE := 20.0
const GAS_CHANCE := 0.2
const OASIS_HEAL := 30.0

const INFO := {
	NORMAL: {"name": "Terreno estável", "effect": "Passo com custo normal."},
	FENDA: {"name": "Fenda estrutural", "effect": "Intransponível."},
	VAZAMENTO: {"name": "Vazamento térmico", "effect": "Entrar: -20 Integridade."},
	INTERFERENCIA: {"name": "Zona de interferência EM", "effect": "Leituras do LiDAR ao redor podem estar erradas (30%)."},
	SUBESTACAO: {"name": "Subestação", "effect": "Pare aqui para sifonar energia."},
	NODULO: {"name": "Nódulo de energia puro", "effect": "Pare aqui: Sobrecarga Total."},
	OASIS: {"name": "Oásis vegetativo", "effect": "Pare aqui: +30 Integridade (uma vez)."},
	FIREWALL: {"name": "Firewall físico", "effect": "Entrar: -15% Bateria fixo."},
	RAIZES: {"name": "Raízes preensoras", "effect": "Sair daqui custa o triplo."},
	ELEVADOR: {"name": "Elevador Central de Ascensão", "effect": "Pare aqui para tentar a Ascensão."},
}

const BIOME_NAMES := {
	"industrial": "Zona Industrial",
	"eco": "Setor Eco-Vegetativo",
	"degrad": "Zona de Degradação",
	"nodes": "Nódulos de Energia",
	"elevator": "Elevador Central",
}


## Estruturas físicas que os sensores passivos (câmera) enxergam sem LiDAR quando
## estão ao lado do N-7. Radiação, interferência e gás só aparecem na varredura.
const VISIBLE_WITHOUT_SCAN := [FENDA, FIREWALL, RAIZES, SUBESTACAO, NODULO, ELEVADOR]


static func visible_without_scan(terrain: String) -> bool:
	return terrain in VISIBLE_WITHOUT_SCAN


static func blocks(terrain: String) -> bool:
	return terrain == FENDA


static func name_of(terrain: String) -> String:
	return INFO.get(terrain, INFO[NORMAL])["name"]


static func effect_of(terrain: String) -> String:
	return INFO.get(terrain, INFO[NORMAL])["effect"]


static func biome_name(biome: String) -> String:
	return BIOME_NAMES.get(biome, biome)
