class_name Pause
extends Control

# --- SINAIS ---
signal continuar_solicitado
signal reinicio_solicitado
signal menu_solicitado

# --- CONSTANTES ---
const CAMINHO_MENU_PRINCIPAL: String = "res://scenes/ui/menu_principal.tscn"

# --- REFERENCIAS A NODES ---
@onready var painel_central: PanelContainer = $PainelPause
@onready var rotulo_titulo: Label = $PainelPause/MargemInterna/Conteudo/TituloPause
@onready var rotulo_subtitulo: Label = $PainelPause/MargemInterna/Conteudo/SubtituloPause
@onready var botao_continuar: Button = $PainelPause/MargemInterna/Conteudo/BotaoContinuar
@onready var botao_reiniciar: Button = $PainelPause/MargemInterna/Conteudo/BotaoReiniciar
@onready var botao_menu: Button = $PainelPause/MargemInterna/Conteudo/BotaoMenu

# --- ESTADO ---
var acao_em_andamento: bool = false
var quadro_abertura: int = -1


# --- INICIALIZACAO E LOOP DE FISICA/PROCESSAMENTO ---
func _ready() -> void:
	_configurar_foco_mouse()
	if get_parent() == get_tree().root:
		process_mode = Node.PROCESS_MODE_ALWAYS
		exibir()
	else:
		process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		ocultar()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or acao_em_andamento:
		return
	if event.is_action_pressed(&"pausar", false, true) and not event.is_echo():
		get_viewport().set_input_as_handled()
		if Engine.get_process_frames() != quadro_abertura:
			_on_botao_continuar_pressed()


# --- API PUBLICA ---
func exibir() -> void:
	quadro_abertura = Engine.get_process_frames()
	acao_em_andamento = false
	_definir_botoes_desabilitados(false)
	_limpar_foco_botoes()
	visible = true


func ocultar() -> void:
	acao_em_andamento = false
	_limpar_foco_botoes()
	visible = false


# --- AUXILIARES / SETTERS ---
func _configurar_foco_mouse() -> void:
	if botao_continuar != null:
		botao_continuar.mouse_entered.connect(_focar_botao_continuar)
		botao_continuar.mouse_exited.connect(_desfocar_botao_continuar)
	if botao_reiniciar != null:
		botao_reiniciar.mouse_entered.connect(_focar_botao_reiniciar)
		botao_reiniciar.mouse_exited.connect(_desfocar_botao_reiniciar)
	if botao_menu != null:
		botao_menu.mouse_entered.connect(_focar_botao_menu)
		botao_menu.mouse_exited.connect(_desfocar_botao_menu)


func _limpar_foco_botoes() -> void:
	for botao: Button in [botao_continuar, botao_reiniciar, botao_menu]:
		if botao != null and botao.has_focus():
			botao.release_focus()


func _on_botao_mouse_entered(botao: Button) -> void:
	if botao != null and not botao.disabled:
		botao.grab_focus()


func _on_botao_mouse_exited(botao: Button) -> void:
	if botao != null and botao.has_focus():
		botao.release_focus()


func _focar_botao_continuar() -> void:
	_on_botao_mouse_entered(botao_continuar)


func _desfocar_botao_continuar() -> void:
	_on_botao_mouse_exited(botao_continuar)


func _focar_botao_reiniciar() -> void:
	_on_botao_mouse_entered(botao_reiniciar)


func _desfocar_botao_reiniciar() -> void:
	_on_botao_mouse_exited(botao_reiniciar)


func _focar_botao_menu() -> void:
	_on_botao_mouse_entered(botao_menu)


func _desfocar_botao_menu() -> void:
	_on_botao_mouse_exited(botao_menu)


func _definir_botoes_desabilitados(desabilitado: bool) -> void:
	if botao_continuar != null:
		botao_continuar.disabled = desabilitado
	if botao_reiniciar != null:
		botao_reiniciar.disabled = desabilitado
	if botao_menu != null:
		botao_menu.disabled = desabilitado


func _on_botao_continuar_pressed() -> void:
	if acao_em_andamento:
		return
	acao_em_andamento = true
	_definir_botoes_desabilitados(true)
	continuar_solicitado.emit()


func _on_botao_reiniciar_pressed() -> void:
	if acao_em_andamento:
		return
	acao_em_andamento = true
	_definir_botoes_desabilitados(true)
	reinicio_solicitado.emit()


func _on_botao_menu_pressed() -> void:
	if acao_em_andamento:
		return
	acao_em_andamento = true
	_definir_botoes_desabilitados(true)
	menu_solicitado.emit()
	if get_parent() == get_tree().root:
		if ResourceLoader.exists(CAMINHO_MENU_PRINCIPAL):
			get_tree().paused = false
			var erro: Error = get_tree().change_scene_to_file(CAMINHO_MENU_PRINCIPAL)
			if erro != OK:
				push_error("Falha ao transicionar para '%s' (erro %d)." % [CAMINHO_MENU_PRINCIPAL, erro])
				acao_em_andamento = false
				_definir_botoes_desabilitados(false)
		else:
			get_tree().quit()
