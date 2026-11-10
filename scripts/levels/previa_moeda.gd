extends Node2D

# --- REFERENCIAS A NODES ---
@onready var moeda: Moeda = $Moeda
@onready var mira: Mira = $Mira
@onready var camera: CameraPartida = $CameraPartida
@onready var centro: Marker2D = $Campo/Marcadores/Centro


# --- INICIALIZACAO E LOOP DE FISICA/PROCESSAMENTO ---
func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.035, 0.045, 0.06))
	moeda.reposicionar(centro.global_position)
	camera.reposicionar()
	mira.definir_habilitada(true)


# --- AUXILIARES / SETTERS ---
func _on_lancamento_solicitado(impulso: Vector2) -> void:
	if moeda.lancar(impulso):
		mira.definir_habilitada(false)


func _on_moeda_parou() -> void:
	mira.definir_habilitada(true)
