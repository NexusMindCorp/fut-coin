class_name DadosTimes
extends RefCounted

# --- CONSTANTES ---
const ORDEM_TIMES: Array[StringName] = [
	&"corinthians",
	&"flamengo",
	&"atletico_mineiro",
	&"botafogo",
	&"cruzeiro",
	&"fluminense",
	&"palmeiras",
	&"sao_paulo",
	&"vasco",
]
const CATALOGO: Dictionary[StringName, Dictionary] = {
	&"corinthians": {
		&"nome": "CORINTHIANS",
		&"sigla": "COR",
		&"brasao": preload("res://assets/ui/times/corinthians.png"),
		&"brasao_hud": preload("res://assets/ui/times/hud/corinthians.png"),
		&"cor": Color(0.55, 0.72, 0.92, 1.0),
	},
	&"flamengo": {
		&"nome": "FLAMENGO",
		&"sigla": "FLA",
		&"brasao": preload("res://assets/ui/times/flamengo.png"),
		&"brasao_hud": preload("res://assets/ui/times/hud/flamengo.png"),
		&"cor": Color(0.92533237, 0.049644113, 0.000000962615, 1.0),
	},
	&"atletico_mineiro": {
		&"nome": "ATLÉTICO-MG",
		&"sigla": "CAM",
		&"brasao": preload("res://assets/ui/times/atletico_mineiro.png"),
		&"brasao_hud": preload("res://assets/ui/times/hud/atletico_mineiro.png"),
		&"cor": Color(0.95, 0.78, 0.22, 1.0),
	},
	&"botafogo": {
		&"nome": "BOTAFOGO",
		&"sigla": "BOT",
		&"brasao": preload("res://assets/ui/times/botafogo.png"),
		&"brasao_hud": preload("res://assets/ui/times/hud/botafogo.png"),
		&"cor": Color(0.78, 0.82, 0.88, 1.0),
	},
	&"cruzeiro": {
		&"nome": "CRUZEIRO",
		&"sigla": "CRU",
		&"brasao": preload("res://assets/ui/times/cruzeiro.png"),
		&"brasao_hud": preload("res://assets/ui/times/hud/cruzeiro.png"),
		&"cor": Color(0.18, 0.52, 0.98, 1.0),
	},
	&"fluminense": {
		&"nome": "FLUMINENSE",
		&"sigla": "FLU",
		&"brasao": preload("res://assets/ui/times/fluminense.png"),
		&"brasao_hud": preload("res://assets/ui/times/hud/fluminense.png"),
		&"cor": Color(0.7254902, 0.07058824, 0.3254902, 1.0),
	},
	&"palmeiras": {
		&"nome": "PALMEIRAS",
		&"sigla": "PAL",
		&"brasao": preload("res://assets/ui/times/palmeiras.png"),
		&"brasao_hud": preload("res://assets/ui/times/hud/palmeiras.png"),
		&"cor": Color(0.18, 0.80, 0.36, 1.0),
	},
	&"sao_paulo": {
		&"nome": "SÃO PAULO",
		&"sigla": "SAO",
		&"brasao": preload("res://assets/ui/times/sao_paulo.png"),
		&"brasao_hud": preload("res://assets/ui/times/hud/sao_paulo.png"),
		&"cor": Color(0.98, 0.38, 0.20, 1.0),
	},
	&"vasco": {
		&"nome": "VASCO",
		&"sigla": "VAS",
		&"brasao": preload("res://assets/ui/times/vasco.png"),
		&"brasao_hud": preload("res://assets/ui/times/hud/vasco.png"),
		&"cor": Color(0.22, 0.82, 0.78, 1.0),
	},
}

# --- ESTADO ---
static var time_esquerdo_selecionado: StringName = &"corinthians"
static var time_direito_selecionado: StringName = &"flamengo"
static var cores_personalizadas: Dictionary[StringName, Color] = {}


# --- API PUBLICA ---
static func possui_time(chave_time: StringName) -> bool:
	return CATALOGO.has(chave_time)


static func obter_textura_time(chave_time: StringName) -> Texture2D:
	return _obter_dados_clube(chave_time)[&"brasao"] as Texture2D


static func obter_textura_time_hud(chave_time: StringName) -> Texture2D:
	return _obter_dados_clube(chave_time)[&"brasao_hud"] as Texture2D


static func obter_nome_time(chave_time: StringName) -> String:
	return str(_obter_dados_clube(chave_time)[&"nome"])


static func obter_sigla_time(chave_time: StringName) -> String:
	return str(_obter_dados_clube(chave_time)[&"sigla"])


static func obter_cor_time(chave_time: StringName) -> Color:
	if cores_personalizadas.has(chave_time):
		return cores_personalizadas[chave_time]
	return _obter_dados_clube(chave_time)[&"cor"] as Color


static func definir_cor_time(chave_time: StringName, nova_cor: Color) -> void:
	if not possui_time(chave_time):
		return
	if not (is_finite(nova_cor.r) and is_finite(nova_cor.g) and is_finite(nova_cor.b) and is_finite(nova_cor.a)):
		return
	cores_personalizadas[chave_time] = nova_cor


static func definir_times_selecionados(chave_esquerda: StringName, chave_direita: StringName) -> void:
	var esq_valida: StringName = (
		chave_esquerda
		if possui_time(chave_esquerda)
		else &"corinthians"
	)
	var dir_valida: StringName = (
		chave_direita
		if possui_time(chave_direita)
		else &"flamengo"
	)
	if dir_valida == esq_valida:
		dir_valida = obter_proximo_time_disponivel(dir_valida, 1, esq_valida)
	time_esquerdo_selecionado = esq_valida
	time_direito_selecionado = dir_valida


static func restaurar_times_padrao() -> void:
	time_esquerdo_selecionado = &"corinthians"
	time_direito_selecionado = &"flamengo"
	cores_personalizadas.clear()


static func obter_proximo_time_disponivel(
	chave_atual: StringName,
	passo: int,
	chave_bloqueada: StringName = &""
) -> StringName:
	var total: int = ORDEM_TIMES.size()
	if total == 0:
		return &"corinthians"
	var indice_atual: int = ORDEM_TIMES.find(chave_atual)
	if indice_atual < 0:
		indice_atual = 0
	var direcao: int = 1 if passo >= 0 else -1
	for tentativa: int in range(1, total + 1):
		var candidato_idx: int = posmod(indice_atual + direcao * tentativa, total)
		var candidato: StringName = ORDEM_TIMES[candidato_idx]
		if candidato != chave_bloqueada or total <= 1:
			return candidato
	return ORDEM_TIMES[indice_atual]


# --- AUXILIARES / SETTERS ---
static func _obter_dados_clube(chave_time: StringName) -> Dictionary:
	return CATALOGO[chave_time] if possui_time(chave_time) else CATALOGO[&"corinthians"]
