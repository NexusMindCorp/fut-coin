class_name Sounds
extends Node

# --- CONSTANTES ---
const BUS_UI: StringName = &"UI"
const CAMINHO_SOM_SELECAO_PADRAO: String = "res://assets/sounds/ui/select.mp3"
const CAMINHO_SOM_CONFIRMACAO_PADRAO: String = "res://assets/sounds/ui/click_ok.mp3"

# --- PARAMETROS CONFIGURAVEIS ---
@export var som_selecao: AudioStream = null
@export var som_confirmacao: AudioStream = null

# --- ESTADO ---
var player_selecao: AudioStreamPlayer
var player_confirmacao: AudioStreamPlayer
var ignorar_foco_inicial: bool = true


# --- INICIALIZACAO E LOOP DE FISICA/PROCESSAMENTO ---
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if som_selecao == null:
		som_selecao = load(CAMINHO_SOM_SELECAO_PADRAO) as AudioStream
	if som_confirmacao == null:
		som_confirmacao = load(CAMINHO_SOM_CONFIRMACAO_PADRAO) as AudioStream
	_criar_players()
	var raiz_escopo: Node = get_parent() if get_parent() != null else self
	_conectar_botoes_recursivo(raiz_escopo)
	_liberar_foco_inicial.call_deferred()


func _exit_tree() -> void:
	for player: AudioStreamPlayer in [player_selecao, player_confirmacao]:
		if player != null:
			player.stop()
			player.stream = null
	som_selecao = null
	som_confirmacao = null


# --- API PUBLICA ---
func tocar_selecao() -> void:
	if ignorar_foco_inicial or player_selecao == null or som_selecao == null:
		return
	player_selecao.stream = som_selecao
	if DisplayServer.get_name() != "headless":
		player_selecao.play()


func tocar_confirmacao() -> void:
	if player_confirmacao == null or som_confirmacao == null:
		return
	player_confirmacao.stream = som_confirmacao
	if DisplayServer.get_name() != "headless":
		player_confirmacao.play()


func choice_select() -> void:
	tocar_confirmacao()
	if player_confirmacao != null and player_confirmacao.playing and is_inside_tree():
		await get_tree().create_timer(0.12, true, false, true).timeout


# --- AUXILIARES / SETTERS ---
func _criar_players() -> void:
	player_selecao = AudioStreamPlayer.new()
	player_selecao.name = "PlayerSelecaoUI"
	player_selecao.bus = BUS_UI
	add_child(player_selecao)

	player_confirmacao = AudioStreamPlayer.new()
	player_confirmacao.name = "PlayerConfirmacaoUI"
	player_confirmacao.bus = BUS_UI
	add_child(player_confirmacao)


func _liberar_foco_inicial() -> void:
	ignorar_foco_inicial = false


func _conectar_botoes_recursivo(no: Node) -> void:
	if no is BaseButton:
		var botao: BaseButton = no as BaseButton
		if not botao.mouse_entered.is_connected(_on_botao_selecionado):
			botao.mouse_entered.connect(_on_botao_selecionado)
		if not botao. pressed.is_connected(_on_botao_pressionado):
			botao.pressed.connect(_on_botao_pressionado)
	for filho: Node in no.get_children():
		if filho != self:
			_conectar_botoes_recursivo(filho)


func _on_botao_selecionado() -> void:
	tocar_selecao()


func _on_botao_pressionado() -> void:
	tocar_confirmacao()
