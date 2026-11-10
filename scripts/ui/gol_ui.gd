class_name GolUI
extends Control

# --- CONSTANTES ---
const TEXTURA_CORINTHIANS: Texture2D = preload("res://assets/ui/times/corinthians.png")
const TEXTURA_FLAMENGO: Texture2D = preload("res://assets/ui/times/flamengo.png")

# --- REFERENCIAS A NODES ---
@onready var painel_central: Control = $PainelCentral
@onready var brasao_equipe: Sprite2D = $PainelCentral/BrasaoEquipe
@onready var rotulo_titulo: Label = $PainelCentral/TituloGol
@onready var rotulo_detalhe: Label = $PainelCentral/DetalheGol

# --- ESTADO ---
var animando: bool = false
var tween_gol: Tween


# --- INICIALIZACAO E LOOP DE FISICA/PROCESSAMENTO ---
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if get_parent() == get_tree().root:
		_carregar_dados_padrao_teste()
	else:
		ocultar_gol()


# --- API PUBLICA ---
func exibir_gol(equipe_marcadora: Prego.Equipe, placar: Vector2i, duracao: float = 1.2) -> void:
	_cancelar_tween()
	animando = true
	visible = true

	var eh_corinthians: bool = equipe_marcadora == Prego.Equipe.CORINTHIANS
	var nome_time: String = "CORINTHIANS" if eh_corinthians else "FLAMENGO"
	var cor_destaque: Color = (
		Color(0.68, 0.84, 1.0, 1.0)
		if eh_corinthians
		else Color(1.0, 0.36, 0.36, 1.0)
	)

	if brasao_equipe != null:
		brasao_equipe.texture = TEXTURA_CORINTHIANS if eh_corinthians else TEXTURA_FLAMENGO
	if rotulo_titulo != null:
		rotulo_titulo.text = "GOOOL!"
		rotulo_titulo.modulate = Color(1.0, 0.94, 0.32, 1.0)
	if rotulo_detalhe != null:
		rotulo_detalhe.text = "%s  |  COR %d x %d FLA" % [nome_time, placar.x, placar.y]
		rotulo_detalhe.modulate = cor_destaque

	if painel_central != null:
		painel_central.pivot_offset = painel_central.size * 0.5
		painel_central.scale = Vector2(0.55, 0.55)
		painel_central.modulate = Color(1.0, 1.0, 1.0, 0.0)

		var tempo_entrada: float = clampf(duracao * 0.28, 0.06, 0.26)
		var tempo_pulso: float = clampf(duracao * 0.22, 0.05, 0.22)
		tween_gol = create_tween()
		tween_gol.set_parallel(true)
		tween_gol.tween_property(painel_central, "modulate:a", 1.0, tempo_entrada)
		tween_gol.tween_property(
			painel_central,
			"scale",
			Vector2(1.08, 1.08),
			tempo_entrada
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween_gol.chain().tween_property(
			painel_central,
			"scale",
			Vector2.ONE,
			tempo_pulso
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func ocultar_gol() -> void:
	_cancelar_tween()
	animando = false
	visible = false
	if painel_central != null:
		painel_central.scale = Vector2.ONE
		painel_central.modulate = Color(1.0, 1.0, 1.0, 1.0)


# --- AUXILIARES / SETTERS ---
func _carregar_dados_padrao_teste() -> void:
	exibir_gol(Prego.Equipe.CORINTHIANS, Vector2i(1, 0), 1.2)


func _cancelar_tween() -> void:
	if tween_gol != null and tween_gol.is_valid():
		tween_gol.kill()
	tween_gol = null
