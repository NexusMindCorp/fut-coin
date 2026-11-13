@tool
class_name Prego
extends StaticBody2D

# --- ENUMS DE ESTADO ---
enum Equipe { CORINTHIANS, FLAMENGO }

# --- CONSTANTES ---
const SHADER_COR_TIME: Shader = preload("res://assets/shaders/prego_cor_time.gdshader")

# --- PARAMETROS CONFIGURAVEIS ---
@export var time: Equipe = Equipe.CORINTHIANS:
	set(valor):
		time = valor
		if not cor_customizada:
			cor_time = DadosTimes.obter_cor_time(&"corinthians") if time == Equipe.CORINTHIANS else DadosTimes.obter_cor_time(&"flamengo")
		_atualizar_visual()
@export var cor_time: Color = DadosTimes.obter_cor_time(&"corinthians"):
	set(valor):
		cor_time = valor
		_aplicar_cor_material()

# --- REFERENCIAS A NODES ---
@onready var animacao: AnimatedSprite2D = $Animacao

# --- ESTADO ---
var cor_customizada: bool = false
var material_cor: ShaderMaterial


# --- INICIALIZACAO E LOOP DE FISICA/PROCESSAMENTO ---
func _ready() -> void:
	if not cor_customizada:
		cor_time = DadosTimes.obter_cor_time(&"corinthians") if time == Equipe.CORINTHIANS else DadosTimes.obter_cor_time(&"flamengo")
	_garantir_material_cor()
	_atualizar_visual()


# --- API PUBLICA ---
func definir_cor_time(nova_cor: Color) -> void:
	cor_customizada = true
	cor_time = nova_cor


func reagir_ao_impacto() -> void:
	if not is_node_ready():
		return
	animacao.play(_nome_animacao("impacto"))
	animacao.set_frame_and_progress(0, 0.0)


# --- AUXILIARES / SETTERS ---
func _garantir_material_cor() -> void:
	if animacao == null:
		return
	if material_cor == null:
		material_cor = ShaderMaterial.new()
		material_cor.shader = SHADER_COR_TIME
	animacao.material = material_cor
	_aplicar_cor_material()


func _aplicar_cor_material() -> void:
	if not is_node_ready() or animacao == null:
		return
	if material_cor == null:
		_garantir_material_cor()
		return
	material_cor.set_shader_parameter(&"cor_time", cor_time)


func _atualizar_visual() -> void:
	if not is_node_ready() or animacao == null:
		return
	_aplicar_cor_material()
	animacao.play(_nome_animacao("repouso"))


func _nome_animacao(acao: String) -> StringName:
	return StringName("%s_prata" % acao)


func _on_animacao_animation_finished() -> void:
	_atualizar_visual()
