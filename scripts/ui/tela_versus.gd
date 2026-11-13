class_name TelaVersus
extends Control

# --- CONSTANTES ---
const CAMINHO_PARTIDA: String = "res://scenes/levels/main_game.tscn"
const CAMINHO_MENU_PRINCIPAL: String = "res://scenes/ui/menu_principal.tscn"
const ESCALA_BRASAO_PADRAO: Vector2 = Vector2(2.0, 2.0)
const ESCALA_BRASAO_PULSO: Vector2 = Vector2(2.22, 2.22)

# --- REFERENCIAS A NODES ---
@onready var rotulo_jogador_esquerdo: Label = $Conteudo/MolduraEsquerda/RotuloJogadorEsquerdo
@onready var brasao_esquerdo: Sprite2D = $Conteudo/MolduraEsquerda/BrasaoEsquerdo
@onready var nome_time_esquerdo: Label = $Conteudo/MolduraEsquerda/NomeTimeEsquerdo
@onready var botao_anterior_esquerdo: Button = $Conteudo/MolduraEsquerda/BotaoAnteriorEsquerdo
@onready var botao_proximo_esquerdo: Button = $Conteudo/MolduraEsquerda/BotaoProximoEsquerdo
@onready var rotulo_jogador_direito: Label = $Conteudo/MolduraDireita/RotuloJogadorDireito
@onready var brasao_direito: Sprite2D = $Conteudo/MolduraDireita/BrasaoDireito
@onready var nome_time_direito: Label = $Conteudo/MolduraDireita/NomeTimeDireito
@onready var botao_anterior_direito: Button = $Conteudo/MolduraDireita/BotaoAnteriorDireito
@onready var botao_proximo_direito: Button = $Conteudo/MolduraDireita/BotaoProximoDireito
@onready var botao_comecar: Button = $Conteudo/BotoesAcao/BotaoComecar
@onready var botao_voltar: Button = $Conteudo/BotoesAcao/BotaoVoltar

# --- ESTADO ---
var chave_esquerda_atual: StringName = &"corinthians"
var chave_direita_atual: StringName = &"flamengo"
var transicionando: bool = false
var tween_brasao_esquerdo: Tween
var tween_brasao_direito: Tween


# --- INICIALIZACAO E LOOP DE FISICA/PROCESSAMENTO ---
func _ready() -> void:
	AudioManager.tocar_musica_menu()
	_conectar_foco_mouse_botoes()
	carregar_selecao_atual()
	if botao_comecar != null:
		botao_comecar.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if transicionando or not visible:
		return
	if event.is_action_pressed(&"pausar", false, true) and not event.is_echo():
		get_viewport().set_input_as_handled()
		_on_botao_voltar_pressed()


# --- DOMINIO PRINCIPAL / PROCESSADORES DE ESTADO ---
func _atualizar_exibicao_times() -> void:
	var cor_esquerda: Color = DadosTimes.obter_cor_time(chave_esquerda_atual).lightened(0.22)
	var cor_direita: Color = DadosTimes.obter_cor_time(chave_direita_atual).lightened(0.22)
	if brasao_esquerdo != null:
		brasao_esquerdo.texture = DadosTimes.obter_textura_time(chave_esquerda_atual)
	if nome_time_esquerdo != null:
		nome_time_esquerdo.text = DadosTimes.obter_nome_time(chave_esquerda_atual)
		nome_time_esquerdo.add_theme_color_override(&"font_color", cor_esquerda)
	if rotulo_jogador_esquerdo != null:
		rotulo_jogador_esquerdo.add_theme_color_override(&"font_color", cor_esquerda)
	if brasao_direito != null:
		brasao_direito.texture = DadosTimes.obter_textura_time(chave_direita_atual)
	if nome_time_direito != null:
		nome_time_direito.text = DadosTimes.obter_nome_time(chave_direita_atual)
		nome_time_direito.add_theme_color_override(&"font_color", cor_direita)
	if rotulo_jogador_direito != null:
		rotulo_jogador_direito.add_theme_color_override(&"font_color", cor_direita)


func _animar_troca_brasao(alvo: Sprite2D, eh_esquerdo: bool) -> void:
	if alvo == null:
		return
	if eh_esquerdo:
		if tween_brasao_esquerdo != null and tween_brasao_esquerdo.is_valid():
			tween_brasao_esquerdo.kill()
		alvo.scale = ESCALA_BRASAO_PULSO
		tween_brasao_esquerdo = create_tween()
		tween_brasao_esquerdo.tween_property(
			alvo,
			"scale",
			ESCALA_BRASAO_PADRAO,
			0.14
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		if tween_brasao_direito != null and tween_brasao_direito.is_valid():
			tween_brasao_direito.kill()
		alvo.scale = ESCALA_BRASAO_PULSO
		tween_brasao_direito = create_tween()
		tween_brasao_direito.tween_property(
			alvo,
			"scale",
			ESCALA_BRASAO_PADRAO,
			0.14
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _transicionar_para(caminho_cena: String) -> void:
	if transicionando:
		return
	transicionando = true
	_definir_botoes_desabilitados(true)
	if is_inside_tree():
		get_tree().paused = false
		var erro: Error = get_tree().change_scene_to_file(caminho_cena)
		if erro != OK:
			push_error("Falha ao transicionar para '%s' (erro %d)." % [caminho_cena, erro])
			transicionando = false
			_definir_botoes_desabilitados(false)
			if botao_comecar != null:
				botao_comecar.grab_focus()


# --- API PUBLICA ---
func carregar_selecao_atual() -> void:
	DadosTimes.definir_times_selecionados(DadosTimes.time_esquerdo_selecionado, DadosTimes.time_direito_selecionado)
	chave_esquerda_atual = DadosTimes.time_esquerdo_selecionado
	chave_direita_atual = DadosTimes.time_direito_selecionado
	_atualizar_exibicao_times()


func selecionar_time_esquerdo(chave_time: StringName) -> void:
	_selecionar_time(chave_time, true)


func selecionar_time_direito(chave_time: StringName) -> void:
	_selecionar_time(chave_time, false)


func alternar_time_esquerdo(passo: int) -> void:
	_alternar_time(passo, true)


func alternar_time_direito(passo: int) -> void:
	_alternar_time(passo, false)


func confirmar_e_iniciar_partida() -> void:
	if transicionando:
		return
	DadosTimes.definir_times_selecionados(chave_esquerda_atual, chave_direita_atual)
	if is_inside_tree() and get_tree().current_scene == self:
		_transicionar_para(CAMINHO_PARTIDA)


# --- AUXILIARES / SETTERS ---
func _selecionar_time(chave_time: StringName, lado_esquerdo: bool) -> void:
	if not DadosTimes.possui_time(chave_time):
		return
	var outra_chave: StringName = chave_direita_atual if lado_esquerdo else chave_esquerda_atual
	if outra_chave == chave_time:
		outra_chave = DadosTimes.obter_proximo_time_disponivel(outra_chave, 1, chave_time)
	chave_esquerda_atual = chave_time if lado_esquerdo else outra_chave
	chave_direita_atual = outra_chave if lado_esquerdo else chave_time
	DadosTimes.definir_times_selecionados(chave_esquerda_atual, chave_direita_atual)
	_atualizar_exibicao_times()
	_animar_troca_brasao(brasao_esquerdo if lado_esquerdo else brasao_direito, lado_esquerdo)


func _alternar_time(passo: int, lado_esquerdo: bool) -> void:
	if transicionando:
		return
	var chave_atual: StringName = chave_esquerda_atual if lado_esquerdo else chave_direita_atual
	var outra_chave: StringName = chave_direita_atual if lado_esquerdo else chave_esquerda_atual
	_selecionar_time(DadosTimes.obter_proximo_time_disponivel(chave_atual, passo, outra_chave), lado_esquerdo)


func _definir_botoes_desabilitados(desabilitado: bool) -> void:
	var botoes: Array[Button] = [
		botao_anterior_esquerdo,
		botao_proximo_esquerdo,
		botao_anterior_direito,
		botao_proximo_direito,
		botao_comecar,
		botao_voltar,
	]
	for botao: Button in botoes:
		if botao != null:
			botao.disabled = desabilitado


func _conectar_foco_mouse_botoes() -> void:
	var botoes: Array[Button] = [
		botao_anterior_esquerdo, botao_proximo_esquerdo,
		botao_anterior_direito, botao_proximo_direito,
		botao_comecar, botao_voltar,
	]
	for botao: Button in botoes:
		if botao == null:
			continue
		var ao_entrar: Callable = _on_botao_mouse_entered.bind(botao)
		if not botao.mouse_entered.is_connected(ao_entrar):
			botao.mouse_entered.connect(ao_entrar)


func _on_botao_mouse_entered(botao: Button) -> void:
	if transicionando or botao == null or botao.disabled:
		return
	if not botao.has_focus():
		botao.grab_focus()


func _on_botao_anterior_esquerdo_pressed() -> void:
	alternar_time_esquerdo(-1)


func _on_botao_proximo_esquerdo_pressed() -> void:
	alternar_time_esquerdo(1)


func _on_botao_anterior_direito_pressed() -> void:
	alternar_time_direito(-1)


func _on_botao_proximo_direito_pressed() -> void:
	alternar_time_direito(1)


func _on_botao_comecar_pressed() -> void:
	confirmar_e_iniciar_partida()


func _on_botao_voltar_pressed() -> void:
	if transicionando:
		return
	if is_inside_tree() and get_tree().current_scene == self:
		if ResourceLoader.exists(CAMINHO_MENU_PRINCIPAL):
			_transicionar_para(CAMINHO_MENU_PRINCIPAL)
		else:
			get_tree().quit()
