class_name Gol
extends Area2D

# --- SINAIS ---
signal gol_marcado(equipe_defensora: Prego.Equipe, id_jogada: int)

# --- CONSTANTES ---
const LINHA_ESQUERDA_X: float = 48.0
const LINHA_DIREITA_X: float = 1104.0
const PLANO_CENTRO_ESQUERDO_X: float = LINHA_ESQUERDA_X - Moeda.RAIO
const PLANO_CENTRO_DIREITO_X: float = LINHA_DIREITA_X + Moeda.RAIO
const LIMITE_FUNDO_ESQUERDO_X: float = 8.0 + Moeda.RAIO
const LIMITE_FUNDO_DIREITO_X: float = 1144.0 - Moeda.RAIO
const BOCA_Y_MINIMO: float = 124.0
const BOCA_Y_MAXIMO: float = 196.0
const CENTRO_Y_MINIMO: float = BOCA_Y_MINIMO + Moeda.RAIO
const CENTRO_Y_MAXIMO: float = BOCA_Y_MAXIMO - Moeda.RAIO
const DESLOCAMENTO_MAXIMO_PASSO: float = 200.0
const EPSILON_DIRECAO: float = 0.00001

# --- PARAMETROS CONFIGURAVEIS ---
@export_group("Configuracao")
@export var equipe_defensora: Prego.Equipe = Prego.Equipe.CORINTHIANS
@export var referencia_campo: Node2D
@export_range(0.0, 0.5) var tolerancia: float = 0.01

# --- ESTADO ---
var moeda_monitorada: Moeda
var id_jogada_ativa: int = 0
var contagem_reposicionamento_armada: int = -1
var armado: bool = false
var confirmado: bool = false
var posicao_anterior_local: Vector2 = Vector2.ZERO


# --- INICIALIZACAO E LOOP DE FISICA/PROCESSAMENTO ---
func _physics_process(_delta: float) -> void:
	inspecionar_passo()


# --- DOMINIO PRINCIPAL / PROCESSADORES DE ESTADO ---
func _avaliar_amostra_atual() -> void:
	if not armado or confirmado or moeda_monitorada == null or not is_instance_valid(moeda_monitorada):
		return
	var posicao_atual_local: Vector2 = _converter_para_campo(moeda_monitorada.global_position)
	if moeda_monitorada.contagem_reposicionamento != contagem_reposicionamento_armada:
		contagem_reposicionamento_armada = moeda_monitorada.contagem_reposicionamento
		posicao_anterior_local = posicao_atual_local
		return
	var houve_gol: bool = avaliar_travessia(
		posicao_anterior_local,
		posicao_atual_local,
		equipe_defensora,
		tolerancia
	)
	posicao_anterior_local = posicao_atual_local
	if houve_gol:
		confirmado = true
		armado = false
		gol_marcado.emit(equipe_defensora, id_jogada_ativa)


# --- API PUBLICA ---
func armar(moeda: Moeda, id_jogada: int) -> void:
	if moeda == null or not is_instance_valid(moeda) or id_jogada <= 0:
		desarmar()
		return
	moeda_monitorada = moeda
	id_jogada_ativa = id_jogada
	contagem_reposicionamento_armada = moeda.contagem_reposicionamento
	armado = true
	confirmado = false
	posicao_anterior_local = _converter_para_campo(moeda.global_position)


func desarmar() -> void:
	moeda_monitorada = null
	id_jogada_ativa = 0
	contagem_reposicionamento_armada = -1
	armado = false
	confirmado = false
	posicao_anterior_local = Vector2.ZERO


func inspecionar_passo() -> void:
	_avaliar_amostra_atual()


static func contem_moeda_completa(
	posicao_local: Vector2,
	defensora: Prego.Equipe,
	tol: float = 0.01
) -> bool:
	if not posicao_local.is_finite():
		return false
	var y_valido: bool = (
		posicao_local.y >= CENTRO_Y_MINIMO - tol
		and posicao_local.y <= CENTRO_Y_MAXIMO + tol
	)
	if not y_valido:
		return false
	if defensora == Prego.Equipe.CORINTHIANS:
		return (
			posicao_local.x <= PLANO_CENTRO_ESQUERDO_X + tol
			and posicao_local.x >= LIMITE_FUNDO_ESQUERDO_X - tol
		)
	return (
		posicao_local.x >= PLANO_CENTRO_DIREITO_X - tol
		and posicao_local.x <= LIMITE_FUNDO_DIREITO_X + tol
	)


static func avaliar_travessia(
	anterior: Vector2,
	atual: Vector2,
	defensora: Prego.Equipe,
	tol: float = 0.01
) -> bool:
	if not anterior.is_finite() or not atual.is_finite():
		return false
	if anterior.distance_to(atual) > DESLOCAMENTO_MAXIMO_PASSO:
		return false
	if contem_moeda_completa(atual, defensora, tol):
		return true
	var dx: float = atual.x - anterior.x
	if defensora == Prego.Equipe.CORINTHIANS:
		# Deve vir de fora do plano completo esquerdo (ou da borda com tolerancia) movendo para a esquerda.
		if anterior.x < PLANO_CENTRO_ESQUERDO_X - tol or dx > EPSILON_DIRECAO:
			return false
		if absf(dx) <= EPSILON_DIRECAO:
			return contem_moeda_completa(atual, defensora, tol)
		if atual.x > PLANO_CENTRO_ESQUERDO_X + tol or atual.x < LIMITE_FUNDO_ESQUERDO_X - tol:
			return false
		var plano_x: float = minf(PLANO_CENTRO_ESQUERDO_X, anterior.x)
		var t: float = clampf((plano_x - anterior.x) / dx, 0.0, 1.0)
		var y_cruzamento: float = lerpf(anterior.y, atual.y, t)
		var cruzou_boca: bool = (
			y_cruzamento >= CENTRO_Y_MINIMO - tol
			and y_cruzamento <= CENTRO_Y_MAXIMO + tol
		)
		return cruzou_boca and (
			atual.y >= CENTRO_Y_MINIMO - tol
			and atual.y <= CENTRO_Y_MAXIMO + tol
		)

	# Equipe defensora: FLAMENGO (gol direito).
	if anterior.x > PLANO_CENTRO_DIREITO_X + tol or dx < -EPSILON_DIRECAO:
		return false
	if absf(dx) <= EPSILON_DIRECAO:
		return contem_moeda_completa(atual, defensora, tol)
	if atual.x < PLANO_CENTRO_DIREITO_X - tol or atual.x > LIMITE_FUNDO_DIREITO_X + tol:
		return false
	var plano_direito_x: float = maxf(PLANO_CENTRO_DIREITO_X, anterior.x)
	var t_direito: float = clampf((plano_direito_x - anterior.x) / dx, 0.0, 1.0)
	var y_cruzamento_direito: float = lerpf(anterior.y, atual.y, t_direito)
	var cruzou_boca_direita: bool = (
		y_cruzamento_direito >= CENTRO_Y_MINIMO - tol
		and y_cruzamento_direito <= CENTRO_Y_MAXIMO + tol
	)
	return cruzou_boca_direita and (
		atual.y >= CENTRO_Y_MINIMO - tol
		and atual.y <= CENTRO_Y_MAXIMO + tol
	)


# --- AUXILIARES / SETTERS ---
func _converter_para_campo(posicao_global: Vector2) -> Vector2:
	if referencia_campo != null and is_instance_valid(referencia_campo):
		return referencia_campo.to_local(posicao_global)
	return posicao_global


func _on_body_entered(corpo: Node2D) -> void:
	if corpo == moeda_monitorada:
		_avaliar_amostra_atual()
