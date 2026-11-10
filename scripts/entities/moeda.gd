class_name Moeda
extends RigidBody2D

# --- SINAIS ---
signal lancada(impulso: Vector2)
signal parou

# --- CONSTANTES ---
const RAIO: float = 14.0

# --- PARAMETROS CONFIGURAVEIS ---
@export_group("Fisica")
@export_range(1.0, 2000.0) var impulso_maximo: float = 700.0
@export_range(1.0, 2000.0) var velocidade_maxima: float = 700.0
@export_range(0.01, 20.0) var limiar_parada: float = 3.0
@export_range(0.05, 1.0) var duracao_parada: float = 0.2
@export_range(0.01, 2.0) var tolerancia_contato: float = 0.5
@export_group("Apresentacao")
@export var cor_posse: Color = Color(0.8, 0.9, 1.0)

# --- REFERENCIAS A NODES ---
@onready var animacao: AnimatedSprite2D = $Animacao
@onready var tempo_parada: Timer = $TempoParada

# --- ESTADO ---
var em_movimento: bool = false
var autorizada: bool = false
var dourada: bool = false
var contagem_reposicionamento: int = 0
var impulso_pendente: Vector2 = Vector2.ZERO
var consulta: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
var forma_consulta: CircleShape2D = CircleShape2D.new()
var pulso: Tween
var intensidade_aura: float = 0.6:
	set(valor):
		intensidade_aura = valor
		queue_redraw()


# --- INICIALIZACAO E LOOP DE FISICA/PROCESSAMENTO ---
func _ready() -> void:
	consulta.shape = forma_consulta
	consulta.collision_mask = 1
	consulta.exclude = [get_rid()]
	_atualizar_animacao()
	pulso = create_tween().set_loops()
	pulso.tween_property(self, "intensidade_aura", 1.0, 0.6)
	pulso.tween_property(self, "intensidade_aura", 0.45, 0.6)


func _physics_process(_delta: float) -> void:
	if not em_movimento or not impulso_pendente.is_zero_approx():
		return
	if not sleeping and linear_velocity.length() >= limiar_parada:
		tempo_parada.stop()
	elif tempo_parada.is_stopped():
		tempo_parada.start(duracao_parada)


func _integrate_forces(estado: PhysicsDirectBodyState2D) -> void:
	if not impulso_pendente.is_zero_approx():
		estado.apply_central_impulse(impulso_pendente)
		impulso_pendente = Vector2.ZERO
	estado.linear_velocity = estado.linear_velocity.limit_length(velocidade_maxima)


func _draw() -> void:
	if not autorizada or em_movimento:
		return
	var cor: Color = cor_posse
	cor.a = intensidade_aura
	draw_arc(Vector2.ZERO, RAIO, 0.0, TAU, 48, cor, 2.0)


# --- API PUBLICA ---
func lancar(impulso: Vector2) -> bool:
	if not impulso.is_finite() or impulso.is_zero_approx() or not autorizada:
		return false
	if not esta_parada() or not pode_lancar(impulso.normalized()):
		return false
	impulso_pendente = impulso.limit_length(impulso_maximo)
	em_movimento = true
	freeze = false
	sleeping = false
	tempo_parada.stop()
	_atualizar_animacao()
	queue_redraw()
	lancada.emit(impulso_pendente)
	return true


func esta_parada() -> bool:
	return not em_movimento and (freeze or linear_velocity.is_zero_approx())


func pode_lancar(direcao: Vector2) -> bool:
	if not direcao.is_finite() or direcao.is_zero_approx() or not is_inside_tree():
		return false
	forma_consulta.radius = RAIO + tolerancia_contato
	consulta.transform = Transform2D(0.0, global_position)
	var pontos: Array[Vector2] = get_world_2d().direct_space_state.collide_shape(consulta, 16)
	for indice: int in range(0, pontos.size(), 2):
		# Ponto na parede menos ponto no circulo: normal para o espaco livre.
		var normal: Vector2 = (pontos[indice + 1] - pontos[indice]).normalized()
		if not direcao_permitida(direcao.normalized(), normal):
			return false
	return true


func definir_autorizada(valor: bool) -> void:
	autorizada = valor
	queue_redraw()


func reposicionar(posicao: Vector2) -> void:
	if not posicao.is_finite():
		return
	contagem_reposicionamento += 1
	_limpar_estado_fisico()
	global_position = posicao
	reset_physics_interpolation()
	_atualizar_animacao()
	queue_redraw()


func interromper_movimento() -> void:
	_limpar_estado_fisico()
	_atualizar_animacao()
	queue_redraw()


func definir_gol_de_ouro(ativo: bool) -> void:
	dourada = ativo
	_atualizar_animacao()


static func direcao_permitida(direcao: Vector2, normal: Vector2) -> bool:
	return direcao.dot(normal) >= -0.001


# --- AUXILIARES / SETTERS ---
func _limpar_estado_fisico() -> void:
	em_movimento = false
	impulso_pendente = Vector2.ZERO
	tempo_parada.stop()
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	freeze = true


func _atualizar_animacao() -> void:
	if animacao == null:
		return
	if em_movimento:
		animacao.play(&"giro_dourado" if dourada else &"giro")
	else:
		animacao.play(&"repouso_dourado" if dourada else &"repouso")


func _on_tempo_parada_timeout() -> void:
	if not em_movimento or (not sleeping and linear_velocity.length() >= limiar_parada):
		return
	_limpar_estado_fisico()
	_atualizar_animacao()
	queue_redraw()
	parou.emit()


func _on_body_entered(corpo: Node) -> void:
	var prego: Prego = corpo as Prego
	if prego != null:
		prego.reagir_ao_impacto()
