extends Node2D

# --- CONSTANTES ---
const CENTRO_CAMPO: Vector2 = Vector2(576.0, 160.0)
const VELOCIDADE_INSPECAO: float = 360.0
const LIMITE_ESQUERDO: float = 320.0
const LIMITE_DIREITO: float = 832.0

# --- REFERENCIAS A NODES ---
@onready var camera: Camera2D = $CameraPrevia
@onready var indicacao: Label = $Instrucoes/Indicacao
@onready var pregos: Node2D = $Campo/Pregos

# --- ESTADO ---
var vista_geral: bool = true


# --- INICIALIZACAO E LOOP DE FISICA/PROCESSAMENTO ---
func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.035, 0.045, 0.06, 1.0))
	_atualizar_vista()


func _physics_process(delta: float) -> void:
	if vista_geral:
		return
	var direcao: float = Input.get_axis(&"ui_left", &"ui_right")
	camera.position.x = clampf(
		camera.position.x + direcao * VELOCIDADE_INSPECAO * delta,
		LIMITE_ESQUERDO, LIMITE_DIREITO
	)


func _unhandled_key_input(evento: InputEvent) -> void:
	var tecla: InputEventKey = evento as InputEventKey
	if tecla == null or not tecla.pressed or tecla.echo:
		return
	match tecla.physical_keycode:
		KEY_SPACE:
			vista_geral = not vista_geral
			_atualizar_vista()
			get_viewport().set_input_as_handled()
		KEY_I:
			for filho: Node in pregos.get_children():
				var prego: Prego = filho as Prego
				if prego != null:
					prego.reagir_ao_impacto()
			get_viewport().set_input_as_handled()


# --- AUXILIARES / SETTERS ---
func _atualizar_vista() -> void:
	camera.position = CENTRO_CAMPO
	camera.zoom = Vector2(0.5, 0.5) if vista_geral else Vector2.ONE
	indicacao.text = (
		"VISTA GERAL  |  Espaco: detalhe  |  I: impacto dos pregos"
		if vista_geral else
		"DETALHE  |  Setas: percorrer campo  |  Espaco: geral  |  I: impacto"
	)
