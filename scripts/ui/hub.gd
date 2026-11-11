class_name Hub
extends Node2D

# --- SINAIS ---
signal pausa_solicitada

# --- REFERENCIAS A NODES ---
@onready var brazao_esquerdo: Sprite2D = $Brazoes/Brazao1
@onready var brazao_direito: Sprite2D = $Brazoes/Brazao2
@onready var rotulo_p1: Label = $Control/p1
@onready var rotulo_p2: Label = $Control/p2
@onready var rotulo_timer: Label = $Control/timer
@onready var botao_pausar: Button = $Control/BotaoPausar

# --- ESTADO ---
var placar_atual: Vector2i = Vector2i.ZERO
var tempo_atual: float = 180.0
var turno_atual: Prego.Equipe = Prego.Equipe.CORINTHIANS
var gol_de_ouro_ativo: bool = false
var chave_time_esquerdo: StringName = &"corinthians"
var chave_time_direito: StringName = &"flamengo"
var tween_placar: Tween


# --- INICIALIZACAO E LOOP DE FISICA/PROCESSAMENTO ---
func _ready() -> void:
	definir_brasoes_por_chave(DadosTimes.time_esquerdo_selecionado, DadosTimes.time_direito_selecionado)
	if get_parent() == get_tree().root:
		_carregar_dados_padrao_teste()
	else:
		_sincronizar_exibicao()


# --- API PUBLICA ---
static func formatar_tempo(segundos: float) -> String:
	if not is_finite(segundos):
		return "00:00"
	var total_segundos: int = maxi(ceili(segundos), 0)
	var minutos: int = floori(total_segundos / 60.0)
	var resto_segundos: int = total_segundos % 60
	return "%02d:%02d" % [minutos, resto_segundos]


func definir_brasoes_por_chave(chave_esquerda: StringName, chave_direita: StringName) -> void:
	if DadosTimes.possui_time(chave_esquerda):
		chave_time_esquerdo = chave_esquerda
	if DadosTimes.possui_time(chave_direita):
		chave_time_direito = chave_direita
	if brazao_esquerdo != null:
		brazao_esquerdo.texture = DadosTimes.obter_textura_time(chave_time_esquerdo)
	if brazao_direito != null:
		brazao_direito.texture = DadosTimes.obter_textura_time(chave_time_direito)
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
	var cor_esquerda: Color = DadosTimes.obter_cor_time(chave_time_esquerdo).lightened(0.22)
	var cor_direita: Color = DadosTimes.obter_cor_time(chave_time_direito).lightened(0.22)
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
