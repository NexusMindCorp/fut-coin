class_name Mira
extends Node2D

# --- SINAIS ---
signal mira_iniciada
signal mira_cancelada
signal lancamento_solicitado(impulso: Vector2)

# --- PARAMETROS CONFIGURAVEIS ---
@export var moeda: Moeda
@export_range(0.0, 6.0) var margem_selecao: float = 2.0
@export_range(1.0, 200.0) var zona_morta: float = 14.0
@export_range(1.0, 300.0) var arrasto_maximo: float = 96.0
@export_range(20.0, 120.0) var comprimento_maximo: float = 80.0

# --- ESTADO ---
var habilitada: bool = false
var arrastando: bool = false
var impulso_atual: Vector2 = Vector2.ZERO
var bloqueada: bool = false
var posicao_mouse_tela: Vector2 = Vector2.ZERO


# --- INICIALIZACAO E LOOP DE FISICA/PROCESSAMENTO ---
func _physics_process(_delta: float) -> void:
	if not arrastando:
		return
	if not habilitada or not moeda.autorizada or not moeda.esta_parada():
		cancelar()
		return
	_atualizar_arrasto()


func _unhandled_input(evento: InputEvent) -> void:
	var evento_mouse: InputEventMouse = evento as InputEventMouse
	if evento_mouse != null:
		posicao_mouse_tela = evento_mouse.position
	if moeda == null:
		return
	if evento.is_action_pressed(&"mira_clique"):
		if not habilitada or not moeda.autorizada or not moeda.esta_parada():
			return
		if _obter_mouse_global().distance_to(moeda.global_position) > Moeda.RAIO + margem_selecao:
			return
		arrastando = true
		_atualizar_arrasto()
		mira_iniciada.emit()
		get_viewport().set_input_as_handled()
	elif evento.is_action_released(&"mira_clique") and arrastando:
		_atualizar_arrasto()
		var valido: bool = habilitada and moeda.autorizada and moeda.esta_parada()
		var impulso: Vector2 = impulso_atual
		valido = valido and not impulso.is_zero_approx() and not bloqueada
		arrastando = false
		impulso_atual = Vector2.ZERO
		queue_redraw()
		if valido:
			lancamento_solicitado.emit(impulso)
		else:
			mira_cancelada.emit()
		get_viewport().set_input_as_handled()


func _notification(notificacao: int) -> void:
	if notificacao == NOTIFICATION_APPLICATION_FOCUS_OUT:
		cancelar()


func _draw() -> void:
	if not arrastando or impulso_atual.is_zero_approx():
		return
	var direcao: Vector2 = impulso_atual.normalized()
	var forca: float = impulso_atual.length() / moeda.impulso_maximo
	var inicio: Vector2 = direcao * 21.0
	var ponta: Vector2 = direcao * (21.0 + comprimento_maximo * forca)
	var lateral: Vector2 = direcao.orthogonal() * 5.0
	var cor: Color = Color(1.0, 0.9, 0.35)
	if forca > 2.0 / 3.0:
		cor = Color(1.0, 0.3, 0.25)
	elif forca > 1.0 / 3.0:
		cor = Color(1.0, 0.6, 0.2)
	if bloqueada:
		cor = Color(0.65, 0.65, 0.65, 0.65)
	draw_line(inicio, ponta, Color(0.04, 0.04, 0.06), 6.0)
	draw_line(inicio, ponta, cor, 3.0)
	draw_colored_polygon(PackedVector2Array([ponta + direcao * 6.0, ponta - direcao * 5.0 + lateral, ponta - direcao * 5.0 - lateral]), cor)
	if bloqueada:
		# Marca pelo lado livre: a ponta pode estar fora da tela junto a parede.
		var centro: Vector2 = -direcao * 25.0
		draw_line(centro - Vector2(4, 4), centro + Vector2(4, 4), Color.BLACK, 5.0)
		draw_line(centro - Vector2(4, -4), centro + Vector2(4, -4), Color.BLACK, 5.0)
		draw_line(centro - Vector2(4, 4), centro + Vector2(4, 4), Color.WHITE, 2.0)
		draw_line(centro - Vector2(4, -4), centro + Vector2(4, -4), Color.WHITE, 2.0)


# --- API PUBLICA ---
func definir_habilitada(valor: bool) -> void:
	habilitada = valor
	if moeda != null:
		moeda.definir_autorizada(valor)
	if not valor:
		cancelar()


func cancelar() -> void:
	var estava_arrastando: bool = arrastando
	arrastando = false
	impulso_atual = Vector2.ZERO
	queue_redraw()
	if estava_arrastando:
		mira_cancelada.emit()


static func calcular_impulso(puxada: Vector2, zona: float, arrasto: float, maximo: float) -> Vector2:
	if not puxada.is_finite() or arrasto <= 0.0 or maximo <= 0.0:
		return Vector2.ZERO
	var proporcao: float = clampf((puxada.length() - zona) / arrasto, 0.0, 1.0)
	return -puxada.normalized() * proporcao * maximo


# --- AUXILIARES / SETTERS ---
func _atualizar_arrasto() -> void:
	global_position = moeda.global_position
	impulso_atual = calcular_impulso(_obter_mouse_global() - moeda.global_position, zona_morta, arrasto_maximo, moeda.impulso_maximo)
	bloqueada = not impulso_atual.is_zero_approx() and not moeda.pode_lancar(impulso_atual.normalized())
	queue_redraw()


func _obter_mouse_global() -> Vector2:
	return get_canvas_transform().affine_inverse() * posicao_mouse_tela
