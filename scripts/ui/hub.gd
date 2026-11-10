class_name Hub
extends Node2D

# --- SINAIS ---
signal pausa_solicitada

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
const BRASOES_TIMES: Dictionary = {
	&"atletico_mineiro": preload("res://assets/ui/times/atletico_mineiro.png"),
	&"botafogo": preload("res://assets/ui/times/botafogo.png"),
	&"corinthians": preload("res://assets/ui/times/corinthians.png"),
	&"cruzeiro": preload("res://assets/ui/times/cruzeiro.png"),
	&"flamengo": preload("res://assets/ui/times/flamengo.png"),
	&"fluminense": preload("res://assets/ui/times/fluminense.png"),
	&"palmeiras": preload("res://assets/ui/times/palmeiras.png"),
	&"sao_paulo": preload("res://assets/ui/times/sao_paulo.png"),
	&"vasco": preload("res://assets/ui/times/vasco.png"),
}
const NOMES_TIMES: Dictionary = {
	&"atletico_mineiro": "ATLÉTICO-MG",
	&"botafogo": "BOTAFOGO",
	&"corinthians": "CORINTHIANS",
	&"cruzeiro": "CRUZEIRO",
	&"flamengo": "FLAMENGO",
	&"fluminense": "FLUMINENSE",
	&"palmeiras": "PALMEIRAS",
	&"sao_paulo": "SÃO PAULO",
	&"vasco": "VASCO",
}
const SIGLAS_TIMES: Dictionary = {
	&"atletico_mineiro": "CAM",
	&"botafogo": "BOT",
	&"corinthians": "COR",
	&"cruzeiro": "CRU",
	&"flamengo": "FLA",
	&"fluminense": "FLU",
	&"palmeiras": "PAL",
	&"sao_paulo": "SAO",
	&"vasco": "VAS",
}
const CORES_PADRAO_TIMES: Dictionary = {
	&"corinthians": Color(0.55, 0.72, 0.92, 1.0),
	&"flamengo": Color(0.92, 0.24, 0.24, 1.0),
	&"atletico_mineiro": Color(0.95, 0.78, 0.22, 1.0),
	&"botafogo": Color(0.78, 0.82, 0.88, 1.0),
	&"cruzeiro": Color(0.18, 0.52, 0.98, 1.0),
	&"fluminense": Color(0.72, 0.18, 0.32, 1.0),
	&"palmeiras": Color(0.18, 0.80, 0.36, 1.0),
	&"sao_paulo": Color(0.98, 0.38, 0.20, 1.0),
	&"vasco": Color(0.22, 0.82, 0.78, 1.0),
}

# --- PARAMETROS CONFIGURAVEIS ---
@export_group("Cores dos Times (Sprite -> Cor)")
@export var sprites_times: Array[Texture2D] = [
	preload("res://assets/ui/times/corinthians.png"),
	preload("res://assets/ui/times/flamengo.png"),
	preload("res://assets/ui/times/atletico_mineiro.png"),
	preload("res://assets/ui/times/botafogo.png"),
	preload("res://assets/ui/times/cruzeiro.png"),
	preload("res://assets/ui/times/fluminense.png"),
	preload("res://assets/ui/times/palmeiras.png"),
	preload("res://assets/ui/times/sao_paulo.png"),
	preload("res://assets/ui/times/vasco.png"),
]
@export var cores_times: Array[Color] = [
	Color(0.55, 0.72, 0.92, 1.0),
	Color(0.92, 0.24, 0.24, 1.0),
	Color(0.95, 0.78, 0.22, 1.0),
	Color(0.78, 0.82, 0.88, 1.0),
	Color(0.18, 0.52, 0.98, 1.0),
	Color(0.72, 0.18, 0.32, 1.0),
	Color(0.18, 0.80, 0.36, 1.0),
	Color(0.98, 0.38, 0.20, 1.0),
	Color(0.22, 0.82, 0.78, 1.0),
]

# --- REFERENCIAS A NODES ---
@onready var brazao_esquerdo: Sprite2D = $Brazoes/Brazao1
@onready var brazao_direito: Sprite2D = $Brazoes/Brazao2
@onready var rotulo_p1: Label = $Control/p1
@onready var rotulo_p2: Label = $Control/p2
@onready var rotulo_timer: Label = $Control/timer
@onready var botao_pausar: Button = $Control/BotaoPausar

# --- ESTADO ---
static var time_esquerdo_selecionado: StringName = &"corinthians"
static var time_direito_selecionado: StringName = &"flamengo"
static var cores_customizadas_por_chave: Dictionary = {}

var placar_atual: Vector2i = Vector2i.ZERO
var tempo_atual: float = 180.0
var turno_atual: Prego.Equipe = Prego.Equipe.CORINTHIANS
var gol_de_ouro_ativo: bool = false
var chave_time_esquerdo: StringName = &"corinthians"
var chave_time_direito: StringName = &"flamengo"
var tween_placar: Tween


# --- INICIALIZACAO E LOOP DE FISICA/PROCESSAMENTO ---
func _ready() -> void:
	sincronizar_lista_cores_sprites(sprites_times, cores_times)
	definir_brasoes_por_chave(time_esquerdo_selecionado, time_direito_selecionado)
	if get_parent() == get_tree().root:
		_carregar_dados_padrao_teste()
	else:
		_sincronizar_exibicao()


# --- API PUBLICA ---
static func formatar_tempo(segundos: float) -> String:
	if not is_finite(segundos):
		return "00:00"
	var total_segundos: int = maxi(ceili(segundos), 0)
	var minutos: int = total_segundos / 60
	var resto_segundos: int = total_segundos % 60
	return "%02d:%02d" % [minutos, resto_segundos]


static func obter_textura_time(chave_time: StringName) -> Texture2D:
	if BRASOES_TIMES.has(chave_time):
		return BRASOES_TIMES[chave_time] as Texture2D
	return BRASOES_TIMES[&"corinthians"] as Texture2D


static func obter_chave_por_sprite(sprite: Texture2D) -> StringName:
	if sprite == null:
		return &""
	for chave: StringName in BRASOES_TIMES.keys():
		var tex: Texture2D = BRASOES_TIMES[chave] as Texture2D
		if tex == sprite or (tex != null and tex.resource_path == sprite.resource_path):
			return chave
	return &""


static func obter_cor_time(chave_time: StringName) -> Color:
	if cores_customizadas_por_chave.has(chave_time):
		return cores_customizadas_por_chave[chave_time] as Color
	if CORES_PADRAO_TIMES.has(chave_time):
		return CORES_PADRAO_TIMES[chave_time] as Color
	return CORES_PADRAO_TIMES[&"corinthians"] as Color


static func obter_cor_por_sprite(sprite: Texture2D) -> Color:
	var chave: StringName = obter_chave_por_sprite(sprite)
	return obter_cor_time(chave)


static func definir_cor_time(chave_time: StringName, nova_cor: Color) -> void:
	if BRASOES_TIMES.has(chave_time):
		cores_customizadas_por_chave[chave_time] = nova_cor


static func sincronizar_lista_cores_sprites(
	lista_sprites: Array[Texture2D],
	lista_cores: Array[Color]
) -> void:
	var limite: int = mini(lista_sprites.size(), lista_cores.size())
	for indice: int in range(limite):
		var chave: StringName = obter_chave_por_sprite(lista_sprites[indice])
		if chave != &"":
			cores_customizadas_por_chave[chave] = lista_cores[indice]


static func obter_nome_time(chave_time: StringName) -> String:
	if NOMES_TIMES.has(chave_time):
		return str(NOMES_TIMES[chave_time])
	return "CORINTHIANS"


static func obter_sigla_time(chave_time: StringName) -> String:
	if SIGLAS_TIMES.has(chave_time):
		return str(SIGLAS_TIMES[chave_time])
	return "COR"


static func definir_times_selecionados(chave_esquerda: StringName, chave_direita: StringName) -> void:
	var esq_valida: StringName = (
		chave_esquerda
		if BRASOES_TIMES.has(chave_esquerda)
		else &"corinthians"
	)
	var dir_valida: StringName = (
		chave_direita
		if BRASOES_TIMES.has(chave_direita)
		else &"flamengo"
	)
	if dir_valida == esq_valida:
		dir_valida = obter_proximo_time_disponivel(dir_valida, 1, esq_valida)
	time_esquerdo_selecionado = esq_valida
	time_direito_selecionado = dir_valida


static func restaurar_times_padrao() -> void:
	time_esquerdo_selecionado = &"corinthians"
	time_direito_selecionado = &"flamengo"
	cores_customizadas_por_chave.clear()


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


func definir_brasoes_por_chave(chave_esquerda: StringName, chave_direita: StringName) -> void:
	if BRASOES_TIMES.has(chave_esquerda):
		chave_time_esquerdo = chave_esquerda
	if BRASOES_TIMES.has(chave_direita):
		chave_time_direito = chave_direita
	definir_times_selecionados(chave_time_esquerdo, chave_time_direito)
	chave_time_esquerdo = time_esquerdo_selecionado
	chave_time_direito = time_direito_selecionado
	if brazao_esquerdo != null:
		brazao_esquerdo.texture = obter_textura_time(chave_time_esquerdo)
	if brazao_direito != null:
		brazao_direito.texture = obter_textura_time(chave_time_direito)
	atualizar_turno(turno_atual)


func definir_brasoes_equipes(equipe_esquerda: Prego.Equipe, equipe_direita: Prego.Equipe) -> void:
	var esq: StringName = &"corinthians" if equipe_esquerda == Prego.Equipe.CORINTHIANS else &"flamengo"
	var dir: StringName = &"flamengo" if equipe_direita == Prego.Equipe.FLAMENGO else &"corinthians"
	definir_brasoes_por_chave(esq, dir)


func atualizar_placar(novo_placar: Vector2i, animar: bool = false) -> void:
	var mudou_esquerda: bool = novo_placar.x != placar_atual.x
	var mudou_direita: bool = novo_placar.y != placar_atual.y
	placar_atual = novo_placar
	if rotulo_p1 != null:
		rotulo_p1.text = str(placar_atual.x)
	if rotulo_p2 != null:
		rotulo_p2.text = str(placar_atual.y)
	if animar:
		if mudou_esquerda and rotulo_p1 != null:
			_animar_rotulo_placar(rotulo_p1)
		elif mudou_direita and rotulo_p2 != null:
			_animar_rotulo_placar(rotulo_p2)


func atualizar_tempo(segundos: float) -> void:
	tempo_atual = maxf(segundos, 0.0)
	if rotulo_timer == null:
		return
	if gol_de_ouro_ativo:
		rotulo_timer.text = "OURO"
	else:
		rotulo_timer.text = formatar_tempo(tempo_atual)


func atualizar_turno(equipe: Prego.Equipe) -> void:
	turno_atual = equipe
	var vez_esquerda: bool = turno_atual == Prego.Equipe.CORINTHIANS
	var cor_esquerda: Color = obter_cor_time(chave_time_esquerdo).lightened(0.22)
	var cor_direita: Color = obter_cor_time(chave_time_direito).lightened(0.22)
	if brazao_esquerdo != null:
		brazao_esquerdo.modulate = (
			Color(1.0, 1.0, 1.0, 1.0)
			if vez_esquerda
			else Color(0.55, 0.55, 0.6, 0.85)
		)
	if brazao_direito != null:
		brazao_direito.modulate = (
			Color(1.0, 1.0, 1.0, 1.0)
			if not vez_esquerda
			else Color(0.55, 0.55, 0.6, 0.85)
		)
	if rotulo_p1 != null:
		rotulo_p1.modulate = (
			cor_esquerda
			if vez_esquerda
			else Color(1.0, 1.0, 1.0, 0.85)
		)
	if rotulo_p2 != null:
		rotulo_p2.modulate = (
			cor_direita
			if not vez_esquerda
			else Color(1.0, 1.0, 1.0, 0.85)
		)


func definir_gol_de_ouro(ativo: bool) -> void:
	gol_de_ouro_ativo = ativo
	if rotulo_timer != null:
		rotulo_timer.modulate = (
			Color(1.0, 0.88, 0.25, 1.0)
			if gol_de_ouro_ativo
			else Color(1.0, 1.0, 1.0, 1.0)
		)
	atualizar_tempo(tempo_atual)


# --- AUXILIARES / SETTERS ---
func _sincronizar_exibicao() -> void:
	atualizar_placar(placar_atual, false)
	definir_gol_de_ouro(gol_de_ouro_ativo)
	atualizar_turno(turno_atual)


func _carregar_dados_padrao_teste() -> void:
	placar_atual = Vector2i.ZERO
	tempo_atual = 180.0
	turno_atual = Prego.Equipe.CORINTHIANS
	gol_de_ouro_ativo = false
	_sincronizar_exibicao()


func _animar_rotulo_placar(alvo: Label) -> void:
	if tween_placar != null and tween_placar.is_valid():
		tween_placar.kill()
	alvo.pivot_offset = alvo.size * 0.5
	alvo.scale = Vector2(1.35, 1.35)
	tween_placar = create_tween()
	tween_placar.tween_property(alvo, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_botao_pausar_pressed() -> void:
	pausa_solicitada.emit()
