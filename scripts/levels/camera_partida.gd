class_name CameraPartida
extends Camera2D

# --- PARAMETROS CONFIGURAVEIS ---
@export var alvo: Moeda
@export var altura_fixa: float = 160.0


# --- INICIALIZACAO E LOOP DE FISICA/PROCESSAMENTO ---
func _ready() -> void:
	reposicionar()


func _physics_process(_delta: float) -> void:
	if is_instance_valid(alvo):
		global_position = Vector2(clampf(alvo.global_position.x, 320.0, 832.0), altura_fixa)


# --- API PUBLICA ---
func reposicionar() -> void:
	if not is_instance_valid(alvo):
		return
	global_position = Vector2(clampf(alvo.global_position.x, 320.0, 832.0), altura_fixa)
	reset_physics_interpolation()
	reset_smoothing()
	force_update_scroll()
