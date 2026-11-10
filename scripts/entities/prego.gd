@tool
class_name Prego
extends StaticBody2D

# --- ENUMS DE ESTADO ---
enum Equipe { CORINTHIANS, FLAMENGO }

# --- PARAMETROS CONFIGURAVEIS ---
@export var time: Equipe = Equipe.CORINTHIANS:
	set(valor):
		time = valor
		_atualizar_visual()

# --- REFERENCIAS A NODES ---
@onready var animacao: AnimatedSprite2D = $Animacao


# --- INICIALIZACAO E LOOP DE FISICA/PROCESSAMENTO ---
func _ready() -> void:
	_atualizar_visual()


# --- API PUBLICA ---
func reagir_ao_impacto() -> void:
	if not is_node_ready():
		return
	animacao.play(_nome_animacao("impacto"))
	animacao.set_frame_and_progress(0, 0.0)


# --- AUXILIARES / SETTERS ---
func _atualizar_visual() -> void:
	if not is_node_ready():
		return
	animacao.play(_nome_animacao("repouso"))


func _nome_animacao(acao: String) -> StringName:
	var cor: String = "prata" if time == Equipe.CORINTHIANS else "vermelho"
	return StringName("%s_%s" % [acao, cor])


func _on_animacao_animation_finished() -> void:
	_atualizar_visual()
