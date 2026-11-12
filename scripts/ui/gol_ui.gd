class_name GolUI
extends Control

# --- CONSTANTES ---
const DURACAO_PADRAO: float = 2.2

# --- REFERENCIAS A NODES ---
@onready var painel_central: Control = $PainelCentral
@onready var brasao_equipe: Sprite2D = $PainelCentral/BrasaoEquipe
@onready var rotulo_titulo: Label = $PainelCentral/TituloGol
@onready var rotulo_detalhe: Label = $PainelCentral/DetalheGol
@onready var rotulo_time: Label = $PainelCentral/NomeTime
@onready var faixa_destaque: ColorRect = $PainelCentral/FaixaDestaque

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
func exibir_gol(
	equipe_marcadora: Prego.Equipe,
	placar: Vector2i,
	duracao: float = DURACAO_PADRAO,
	chave_esquerda: StringName = &"",
	chave_direita: StringName = &""
) -> void:
	_cancelar_tween()
	animando = true
	visible = true

	var eh_esquerda: bool = equipe_marcadora == Prego.Equipe.CORINTHIANS
	var chave_esq: StringName = (
		chave_esquerda
		if chave_esquerda != &""
		else DadosTimes.time_esquerdo_selecionado
	)
	var chave_dir: StringName = (
		chave_direita
		if chave_direita != &""
		else DadosTimes.time_direito_selecionado
	)
	var chave_marcadora: StringName = chave_esq if eh_esquerda else chave_dir
	var nome_time: String = DadosTimes.obter_nome_time(chave_marcadora)
	var sigla_esq: String = DadosTimes.obter_sigla_time(chave_esq)
	var sigla_dir: String = DadosTimes.obter_sigla_time(chave_dir)
	var cor_destaque: Color = DadosTimes.obter_cor_time(chave_marcadora).lightened(0.22)

	if brasao_equipe != null:
		brasao_equipe.texture = DadosTimes.obter_textura_time(chave_marcadora)
	if rotulo_titulo != null:
		rotulo_titulo.text = "GOOOL!"
		rotulo_titulo.modulate = Color.WHITE
	if rotulo_detalhe != null:
		rotulo_detalhe.text = "%s %d x %d %s" % [
			sigla_esq,
			placar.x,
			placar.y,
			sigla_dir,
		]
		rotulo_detalhe.modulate = Color.WHITE
	if rotulo_time != null:
		rotulo_time.text = nome_time
		rotulo_time.modulate = cor_destaque.lightened(0.35)
	if faixa_destaque != null:
		faixa_destaque.color = cor_destaque

	if painel_central != null:
		painel_central.pivot_offset = painel_central.size * 0.5
		painel_central.scale = Vector2(0.85, 0.85)
		painel_central.modulate = Color(1.0, 1.0, 1.0, 0.0)

		var tempo_total: float = maxf(duracao, 0.01)
		var tempo_entrada: float = minf(tempo_total * 0.18, 0.22)
		var tempo_acomodacao: float = minf(tempo_total * 0.12, 0.12)
		var tempo_saida: float = minf(tempo_total * 0.18, 0.18)
		var tempo_leitura: float = tempo_total - tempo_entrada - tempo_acomodacao - tempo_saida
		tween_gol = create_tween()
		tween_gol.tween_property(
			painel_central,
			"scale",
			Vector2(1.04, 1.04),
			tempo_entrada
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween_gol.parallel().tween_property(painel_central, "modulate:a", 1.0, tempo_entrada)
		tween_gol.tween_property(
			painel_central,
			"scale",
			Vector2.ONE,
			tempo_acomodacao
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween_gol.tween_interval(tempo_leitura)
		tween_gol.tween_property(painel_central, "modulate:a", 0.0, tempo_saida)


func ocultar_gol() -> void:
	_cancelar_tween()
	animando = false
	visible = false
	if painel_central != null:
		painel_central.scale = Vector2.ONE
		painel_central.modulate = Color(1.0, 1.0, 1.0, 1.0)


# --- AUXILIARES / SETTERS ---
func _carregar_dados_padrao_teste() -> void:
	exibir_gol(Prego.Equipe.CORINTHIANS, Vector2i(1, 0))
	AudioManager.tocar_inicio_partida()
	AudioManager.tocar_gol()


func _cancelar_tween() -> void:
	if tween_gol != null and tween_gol.is_valid():
		tween_gol.kill()
	tween_gol = null
