class_name MenuPrincipal
extends Control

# --- CONSTANTES ---
const CAMINHO_TELA_VERSUS: String = "res://scenes/ui/tela_versus.tscn"
const CAMINHO_CREDITOS: String = "res://scenes/ui/creditos.tscn"

# --- EXPORTS ---
@export_range(0.0, 1.0, 0.01) var probabilidade_tigre: float = 0.01

# --- REFERENCIAS A NODES ---
@onready var tigre_moeda: TextureRect = $FundoArte/TigreMoeda
@onready var botao_jogar: Button = $Conteudo/Botoes/BotaoJogar
@onready var botao_creditos: Button = $Conteudo/Botoes/BotaoCreditos
@onready var botao_sair: Button = $Conteudo/Botoes/BotaoSair

# --- ESTADO ---
var transicionando: bool = false


# --- INICIALIZACAO E LOOP DE FISICA/PROCESSAMENTO ---
func _ready() -> void:
	AudioManager.tocar_musica_menu()
	sortear_exibicao_tigre()
	_conectar_foco_mouse_botoes()
	if botao_jogar != null:
		botao_jogar.grab_focus.call_deferred()


# --- DOMINIO PRINCIPAL / PROCESSADORES DE ESTADO ---
func sortear_exibicao_tigre() -> bool:
	var ativo: bool = randf() < probabilidade_tigre
	definir_exibicao_tigre(ativo)
	return ativo


func definir_exibicao_tigre(ativo: bool) -> void:
	if tigre_moeda != null:
		tigre_moeda.visible = ativo


func obter_exibicao_tigre() -> bool:
	return tigre_moeda != null and tigre_moeda.visible


func _transicionar_para(caminho_cena: String) -> void:
	if transicionando:
		return
	transicionando = true
	_definir_botoes_desabilitados(true)
	if not is_inside_tree():
		return
	var erro: Error = get_tree().change_scene_to_file(caminho_cena)
	if erro != OK:
		push_error("Falha ao transicionar para '%s' (erro %d)." % [caminho_cena, erro])
		transicionando = false
		_definir_botoes_desabilitados(false)
		if botao_jogar != null:
			botao_jogar.grab_focus()


# --- AUXILIARES / SETTERS ---
func _definir_botoes_desabilitados(desabilitado: bool) -> void:
	for botao: Button in [botao_jogar, botao_creditos, botao_sair]:
		if botao != null:
			botao.disabled = desabilitado


func _conectar_foco_mouse_botoes() -> void:
	if botao_jogar != null:
		botao_jogar.mouse_entered.connect(_focar_botao_jogar)
		botao_jogar.mouse_exited.connect(_desfocar_botao_jogar)
	if botao_creditos != null:
		botao_creditos.mouse_entered.connect(_focar_botao_creditos)
		botao_creditos.mouse_exited.connect(_desfocar_botao_creditos)
	if botao_sair != null:
		botao_sair.mouse_entered.connect(_focar_botao_sair)
		botao_sair.mouse_exited.connect(_desfocar_botao_sair)


func _focar_botao(botao: Button) -> void:
	if not transicionando and botao != null and not botao.disabled:
		botao.grab_focus()


func _desfocar_botao(botao: Button) -> void:
	if botao != null and botao.has_focus():
		botao.release_focus()


func _focar_botao_jogar() -> void:
	_focar_botao(botao_jogar)


func _desfocar_botao_jogar() -> void:
	_desfocar_botao(botao_jogar)


func _focar_botao_creditos() -> void:
	_focar_botao(botao_creditos)


func _desfocar_botao_creditos() -> void:
	_desfocar_botao(botao_creditos)


func _focar_botao_sair() -> void:
	_focar_botao(botao_sair)


func _desfocar_botao_sair() -> void:
	_desfocar_botao(botao_sair)


func _on_botao_jogar_pressed() -> void:
	_transicionar_para(CAMINHO_TELA_VERSUS)


func _on_botao_creditos_pressed() -> void:
	_transicionar_para(CAMINHO_CREDITOS)


func _on_botao_sair_pressed() -> void:
	if transicionando:
		return
	transicionando = true
	_definir_botoes_desabilitados(true)
	if is_inside_tree():
		get_tree().quit()
