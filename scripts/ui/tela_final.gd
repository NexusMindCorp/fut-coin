class_name TelaFinal
extends Control

# --- CONSTANTES ---
const CAMINHO_PARTIDA: String = "res://scenes/levels/main_game.tscn"
const CAMINHO_TELA_VERSUS: String = "res://scenes/ui/tela_versus.tscn"
const CAMINHO_MENU_PRINCIPAL: String = "res://scenes/ui/menu_principal.tscn"
const CORES_FOGOS: Array[Color] = [
	Color(1.0, 0.9, 0.25, 1.0),
	Color(1.0, 0.28, 0.34, 1.0),
	Color(0.28, 0.85, 1.0, 1.0),
	Color(0.35, 1.0, 0.52, 1.0),
	Color(1.0, 0.55, 0.18, 1.0),
	Color(0.92, 0.42, 1.0, 1.0),
]
const POSICOES_FOGOS_ESQUERDA: Array[Vector2] = [
	Vector2(96.0, 88.0),
	Vector2(142.0, 128.0),
	Vector2(78.0, 152.0),
	Vector2(124.0, 72.0),
]
const POSICOES_FOGOS_DIREITA: Array[Vector2] = [
	Vector2(544.0, 88.0),
	Vector2(498.0, 128.0),
	Vector2(562.0, 152.0),
	Vector2(516.0, 72.0),
]
const POSICOES_FOGOS_CENTRO: Array[Vector2] = [
	Vector2(320.0, 74.0),
	Vector2(228.0, 82.0),
	Vector2(412.0, 82.0),
	Vector2(320.0, 110.0),
]

# --- REFERENCIAS A NODES ---
@onready var rotulo_vencedor: Label = $Conteudo/TituloVencedor
@onready var container_trofeu: Control = $Conteudo/AreaTrofeu
@onready var sprite_trofeu: Sprite2D = $Conteudo/AreaTrofeu/TrofeuSprite
@onready var sprite_brasao: Sprite2D = $Conteudo/AreaTrofeu/TrofeuSprite/BrasaoVencedor
@onready var rotulo_equipe_placar: Label = $Conteudo/NomeEquipePlacar
@onready var botao_jogar_novamente: Button = $Conteudo/BotaoJogarNovamente
@onready var botao_trocar_times: Button = $Conteudo/BotaoTrocarTimes
@onready var botao_menu: Button = $Conteudo/BotaoMenu
@onready var fogos_esquerdo: CPUParticles2D = $CamadaFogos/FogosEsquerdo
@onready var fogos_direito: CPUParticles2D = $CamadaFogos/FogosDireito
@onready var fogos_central: CPUParticles2D = $CamadaFogos/FogosCentral
@onready var ciclo_fogos: Timer = $CicloFogos

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
var indice_salva_fogos: int = 0
var tween_entrada: Tween


# --- INICIALIZACAO E LOOP DE FISICA/PROCESSAMENTO ---
func _ready() -> void:
	if not resultado_pendente:
		_carregar_dados_padrao_teste()
	else:
		_consumir_resultado_estatico()

	_atualizar_interface_vencedor()
	_animar_entrada_trofeu_e_fogos()
	_conectar_foco_mouse_botoes()
	AudioManager.tocar_tela_vitoria()
	if botao_jogar_novamente != null:
		botao_jogar_novamente.grab_focus.call_deferred()


# --- DOMINIO PRINCIPAL / PROCESSADORES DE ESTADO ---
func _atualizar_interface_vencedor() -> void:
	var nome_equipe: String = DadosTimes.obter_nome_time(chave_vencedor_atual)
	var sufixo_ouro: String = " — GOL DE OURO!" if por_gol_de_ouro_atual else ""

	if rotulo_vencedor != null:
		rotulo_vencedor.text = "VENCEDOR"
	if sprite_brasao != null:
		sprite_brasao.texture = DadosTimes.obter_textura_time(chave_vencedor_atual)
	if rotulo_equipe_placar != null:
		rotulo_equipe_placar.text = "%s  (%d x %d)%s" % [
			nome_equipe,
			placar_atual.x,
			placar_atual.y,
			sufixo_ouro,
		]
		rotulo_equipe_placar.modulate = DadosTimes.obter_cor_time(chave_vencedor_atual).lightened(0.5)


func _animar_entrada_trofeu_e_fogos() -> void:
	_disparar_salva_fogos()

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


func _disparar_salva_fogos() -> void:
	var idx_pos: int = indice_salva_fogos % POSICOES_FOGOS_ESQUERDA.size()
	var idx_cor_esq: int = (indice_salva_fogos * 2) % CORES_FOGOS.size()
	var idx_cor_dir: int = (indice_salva_fogos * 2 + 1) % CORES_FOGOS.size()
	var idx_cor_cen: int = (indice_salva_fogos * 2 + 3) % CORES_FOGOS.size()
	indice_salva_fogos += 1

	_explodir_emissor_fogo(fogos_esquerdo, POSICOES_FOGOS_ESQUERDA[idx_pos], CORES_FOGOS[idx_cor_esq])
	_explodir_emissor_fogo(fogos_direito, POSICOES_FOGOS_DIREITA[idx_pos], CORES_FOGOS[idx_cor_dir])
	_explodir_emissor_fogo(fogos_central, POSICOES_FOGOS_CENTRO[idx_pos], CORES_FOGOS[idx_cor_cen])


func _explodir_emissor_fogo(emissor: CPUParticles2D, posicao: Vector2, cor_principal: Color) -> void:
	if emissor == null:
		return
	var rampa_vida: Gradient = Gradient.new()
	rampa_vida.offsets = PackedFloat32Array([0.0, 0.18, 0.68, 1.0])
	rampa_vida.colors = PackedColorArray([
		Color(1.0, 1.0, 0.96, 1.0),
		cor_principal,
		cor_principal.lightened(0.18),
		Color(cor_principal.r, cor_principal.g, cor_principal.b, 0.0),
	])
	emissor.position = posicao
	emissor.color_ramp = rampa_vida
	emissor.restart()
	emissor.emitting = true


func _transicionar_para(caminho_cena: String) -> void:
	if transicionando:
		return
	transicionando = true
	if ciclo_fogos != null:
		ciclo_fogos.stop()
	AudioManager.parar_audio_partida()
	if botao_jogar_novamente != null:
		botao_jogar_novamente.disabled = true
	if botao_trocar_times != null:
		botao_trocar_times.disabled = true
	if botao_menu != null:
		botao_menu.disabled = true
	if is_inside_tree():
		get_tree().paused = false
		var erro: Error = get_tree().change_scene_to_file(caminho_cena)
		if erro != OK:
			push_error("Falha ao transicionar para '%s' (erro %d)." % [caminho_cena, erro])
			transicionando = false
			if botao_jogar_novamente != null:
				botao_jogar_novamente.disabled = false
				botao_jogar_novamente.grab_focus()
			if botao_trocar_times != null:
				botao_trocar_times.disabled = false
			if botao_menu != null:
				botao_menu.disabled = false


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
			DadosTimes.time_esquerdo_selecionado
			if vencedor == Prego.Equipe.CORINTHIANS
			else DadosTimes.time_direito_selecionado
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


func _conectar_foco_mouse_botoes() -> void:
	if botao_jogar_novamente != null and not botao_jogar_novamente.mouse_entered.is_connected(_on_mouse_entered_jogar_novamente):
		botao_jogar_novamente.mouse_entered.connect(_on_mouse_entered_jogar_novamente)
	if botao_trocar_times != null and not botao_trocar_times.mouse_entered.is_connected(_on_mouse_entered_trocar_times):
		botao_trocar_times.mouse_entered.connect(_on_mouse_entered_trocar_times)
	if botao_menu != null and not botao_menu.mouse_entered.is_connected(_on_mouse_entered_menu):
		botao_menu.mouse_entered.connect(_on_mouse_entered_menu)


func _on_mouse_entered_menu() -> void:
	if not transicionando and botao_menu != null and not botao_menu.disabled:
		botao_menu.grab_focus()


func _on_mouse_entered_jogar_novamente() -> void:
	if not transicionando and botao_jogar_novamente != null and not botao_jogar_novamente.disabled:
		botao_jogar_novamente.grab_focus()


func _on_mouse_entered_trocar_times() -> void:
	if not transicionando and botao_trocar_times != null and not botao_trocar_times.disabled:
		botao_trocar_times.grab_focus()


func _on_ciclo_fogos_timeout() -> void:
	if not transicionando:
		_disparar_salva_fogos()


func _on_botao_jogar_novamente_pressed() -> void:
	_transicionar_para(CAMINHO_PARTIDA)


func _on_botao_trocar_times_pressed() -> void:
	_transicionar_para(CAMINHO_TELA_VERSUS)


func _on_botao_menu_pressed() -> void:
	_transicionar_para(CAMINHO_MENU_PRINCIPAL)
