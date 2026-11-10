class_name TelaFinal
extends Control

# --- CONSTANTES ---
const CAMINHO_PARTIDA: String = "res://scenes/levels/main_game.tscn"
const CORES_CONFETE: Array[Color] = [
	Color(1.0, 0.88, 0.22, 1.0),
	Color(0.95, 0.24, 0.28, 1.0),
	Color(0.28, 0.76, 1.0, 1.0),
	Color(0.32, 0.92, 0.48, 1.0),
	Color(0.98, 0.52, 0.18, 1.0),
	Color(0.96, 0.96, 1.0, 1.0),
]

# --- REFERENCIAS A NODES ---
@onready var rotulo_vencedor: Label = $Conteudo/TituloVencedor
@onready var container_trofeu: Control = $Conteudo/AreaTrofeu
@onready var sprite_trofeu: Sprite2D = $Conteudo/AreaTrofeu/TrofeuSprite
@onready var sprite_brasao: Sprite2D = $Conteudo/AreaTrofeu/TrofeuSprite/BrasaoVencedor
@onready var rotulo_equipe_placar: Label = $Conteudo/NomeEquipePlacar
@onready var botao_jogar_novamente: Button = $Conteudo/BotaoJogarNovamente
@onready var confete_esquerdo: CPUParticles2D = $CamadaConfete/ConfeteEsquerdo
@onready var confete_direito: CPUParticles2D = $CamadaConfete/ConfeteDireito
@onready var confete_central: CPUParticles2D = $CamadaConfete/ConfeteCentral

# --- ESTADO ---
static var resultado_pendente: bool = false
static var vencedor_registrado: Prego.Equipe = Prego.Equipe.CORINTHIANS
static var placar_registrado: Vector2i = Vector2i(1, 0)
static var gol_ouro_registrado: bool = false
static var chave_vencedor_registrada: StringName = &"corinthians"

var vencedor_atual: Prego.Equipe = Prego.Equipe.CORINTHIANS
var placar_atual: Vector2i = Vector2i(1, 0)
var por_gol_de_ouro_atual: bool = false
var chave_vencedor_atual: StringName = &"corinthians"
var transicionando: bool = false
var tween_entrada: Tween


# --- INICIALIZACAO E LOOP DE FISICA/PROCESSAMENTO ---
func _ready() -> void:
	if not resultado_pendente:
		_carregar_dados_padrao_teste()
	else:
		_consumir_resultado_estatico()

	_atualizar_interface_vencedor()
	_animar_entrada_trofeu_e_confetes()
	if botao_jogar_novamente != null:
		botao_jogar_novamente.grab_focus.call_deferred()


# --- DOMINIO PRINCIPAL / PROCESSADORES DE ESTADO ---
func _atualizar_interface_vencedor() -> void:
	var eh_corinthians: bool = vencedor_atual == Prego.Equipe.CORINTHIANS
	var nome_equipe: String = "CORINTHIANS" if eh_corinthians else "FLAMENGO"
	var sufixo_ouro: String = " — GOL DE OURO!" if por_gol_de_ouro_atual else ""

	if rotulo_vencedor != null:
		rotulo_vencedor.text = "VENCEDOR"
	if sprite_brasao != null:
		sprite_brasao.texture = Hub.obter_textura_time(chave_vencedor_atual)
	if rotulo_equipe_placar != null:
		rotulo_equipe_placar.text = "%s  (%d x %d)%s" % [
			nome_equipe,
			placar_atual.x,
			placar_atual.y,
			sufixo_ouro,
		]
		rotulo_equipe_placar.modulate = (
			Color(0.72, 0.88, 1.0, 1.0)
			if eh_corinthians
			else Color(1.0, 0.45, 0.45, 1.0)
		)


func _animar_entrada_trofeu_e_confetes() -> void:
	_disparar_estouro_confete()

	if tween_entrada != null and tween_entrada.is_valid():
		tween_entrada.kill()

	if container_trofeu != null:
		container_trofeu.pivot_offset = container_trofeu.size * 0.5
		container_trofeu.scale = Vector2(0.4, 0.4)
		container_trofeu.modulate = Color(1.0, 1.0, 1.0, 0.0)

		tween_entrada = create_tween()
		tween_entrada.set_parallel(true)
		tween_entrada.tween_property(container_trofeu, "modulate:a", 1.0, 0.25)
		tween_entrada.tween_property(
			container_trofeu,
			"scale",
			Vector2(1.08, 1.08),
			0.34
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween_entrada.chain().tween_property(
			container_trofeu,
			"scale",
			Vector2.ONE,
			0.18
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _disparar_estouro_confete() -> void:
	var gradiente: Gradient = Gradient.new()
	gradiente.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
	gradiente.colors = PackedColorArray(CORES_CONFETE)

	for emissor: CPUParticles2D in [confete_esquerdo, confete_direito, confete_central]:
		if emissor != null:
			emissor.color_initial_ramp = gradiente
			emissor.restart()
			emissor.emitting = true


func _transicionar_para(caminho_cena: String) -> void:
	if transicionando:
		return
	transicionando = true
	if botao_jogar_novamente != null:
		botao_jogar_novamente.disabled = true
	if is_inside_tree():
		get_tree().paused = false
		var erro: Error = get_tree().change_scene_to_file(caminho_cena)
		if erro != OK:
			push_error("Falha ao transicionar para '%s' (erro %d)." % [caminho_cena, erro])
			transicionando = false
			if botao_jogar_novamente != null:
				botao_jogar_novamente.disabled = false
				botao_jogar_novamente.grab_focus()


# --- API PUBLICA ---
static func definir_resultado(
	vencedor: Prego.Equipe,
	placar: Vector2i,
	por_gol_de_ouro: bool,
	chave_time: StringName = &""
) -> void:
	vencedor_registrado = vencedor
	placar_registrado = placar
	gol_ouro_registrado = por_gol_de_ouro
	if chave_time != &"":
		chave_vencedor_registrada = chave_time
	else:
		chave_vencedor_registrada = (
			&"corinthians"
			if vencedor == Prego.Equipe.CORINTHIANS
			else &"flamengo"
		)
	resultado_pendente = true


static func limpar_resultado() -> void:
	resultado_pendente = false


# --- AUXILIARES / SETTERS ---
func _consumir_resultado_estatico() -> void:
	vencedor_atual = vencedor_registrado
	placar_atual = placar_registrado
	por_gol_de_ouro_atual = gol_ouro_registrado
	chave_vencedor_atual = chave_vencedor_registrada
	resultado_pendente = false


func _carregar_dados_padrao_teste() -> void:
	vencedor_atual = Prego.Equipe.CORINTHIANS
	placar_atual = Vector2i(2, 1)
	por_gol_de_ouro_atual = false
	chave_vencedor_atual = &"corinthians"


func _on_botao_jogar_novamente_pressed() -> void:
	_transicionar_para(CAMINHO_PARTIDA)
