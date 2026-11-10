class_name TelaVersus
extends Control

# --- CONSTANTES ---
const CAMINHO_PARTIDA: String = "res://scenes/levels/main_game.tscn"
const CAMINHO_MENU_PRINCIPAL: String = "res://scenes/ui/menu_principal.tscn"
const ESCALA_BRASAO_PADRAO: Vector2 = Vector2(2.0, 2.0)
const ESCALA_BRASAO_PULSO: Vector2 = Vector2(2.22, 2.22)

# --- PARAMETROS CONFIGURAVEIS ---
@export_group("Cores dos Times (Sprite -> Cor)")
@export var sprites_times: Array[Texture2D] = [
	preload("res://assets/ui/times/corinthians.png"),
	preload("res://assets/ui/times/flamengo.png"),
	preload("res://assets/ui/times/atletico_mineiro.png"),
	preload("res://assets/ui/times/botafogo.png"),
	preload("res://assets/ui/times/cruzeiro.png"),
	preload("res://assets/ui/times/fluminense.png"),
	preload("res://assets/ui/times/palmeiras.png"),
	preload("res://assets/ui/times/sao_paulo.png"),
	preload("res://assets/ui/times/vasco.png"),
]
@export var cores_times: Array[Color] = [
	Color(0.55, 0.72, 0.92, 1.0),
	Color(0.92, 0.24, 0.24, 1.0),
	Color(0.95, 0.78, 0.22, 1.0),
	Color(0.78, 0.82, 0.88, 1.0),
	Color(0.18, 0.52, 0.98, 1.0),
	Color(0.72, 0.18, 0.32, 1.0),
	Color(0.18, 0.80, 0.36, 1.0),
	Color(0.98, 0.38, 0.20, 1.0),
	Color(0.22, 0.82, 0.78, 1.0),
]

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
	Hub.sincronizar_lista_cores_sprites(sprites_times, cores_times)
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
	var cor_esquerda: Color = Hub.obter_cor_time(chave_esquerda_atual).lightened(0.22)
	var cor_direita: Color = Hub.obter_cor_time(chave_direita_atual).lightened(0.22)
	if brasao_esquerdo != null:
		brasao_esquerdo.texture = Hub.obter_textura_time(chave_esquerda_atual)
	if nome_time_esquerdo != null:
		nome_time_esquerdo.text = Hub.obter_nome_time(chave_esquerda_atual)
		nome_time_esquerdo.add_theme_color_override(&"font_color", cor_esquerda)
	if rotulo_jogador_esquerdo != null:
		rotulo_jogador_esquerdo.add_theme_color_override(&"font_color", cor_esquerda)
	if brasao_direito != null:
		brasao_direito.texture = Hub.obter_textura_time(chave_direita_atual)
	if nome_time_direito != null:
		nome_time_direito.text = Hub.obter_nome_time(chave_direita_atual)
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
	Hub.definir_times_selecionados(Hub.time_esquerdo_selecionado, Hub.time_direito_selecionado)
	chave_esquerda_atual = Hub.time_esquerdo_selecionado
	chave_direita_atual = Hub.time_direito_selecionado
	_atualizar_exibicao_times()


func selecionar_time_esquerdo(chave_time: StringName) -> void:
	if not Hub.BRASOES_TIMES.has(chave_time):
		return
	chave_esquerda_atual = chave_time
	if chave_direita_atual == chave_esquerda_atual:
		chave_direita_atual = Hub.obter_proximo_time_disponivel(
			chave_direita_atual,
			1,
			chave_esquerda_atual
		)
	Hub.definir_times_selecionados(chave_esquerda_atual, chave_direita_atual)
	_atualizar_exibicao_times()
	_animar_troca_brasao(brasao_esquerdo, true)


func selecionar_time_direito(chave_time: StringName) -> void:
	if not Hub.BRASOES_TIMES.has(chave_time):
		return
	chave_direita_atual = chave_time
	if chave_esquerda_atual == chave_direita_atual:
		chave_esquerda_atual = Hub.obter_proximo_time_disponivel(
			chave_esquerda_atual,
			1,
			chave_direita_atual
		)
	Hub.definir_times_selecionados(chave_esquerda_atual, chave_direita_atual)
	_atualizar_exibicao_times()
	_animar_troca_brasao(brasao_direito, false)


func alternar_time_esquerdo(passo: int) -> void:
	if transicionando:
		return
	var proximo: StringName = Hub.obter_proximo_time_disponivel(
		chave_esquerda_atual,
		passo,
		chave_direita_atual
	)
	selecionar_time_esquerdo(proximo)


func alternar_time_direito(passo: int) -> void:
	if transicionando:
		return
	var proximo: StringName = Hub.obter_proximo_time_disponivel(
		chave_direita_atual,
		passo,
		chave_esquerda_atual
	)
	selecionar_time_direito(proximo)


func confirmar_e_iniciar_partida() -> void:
	if transicionando:
		return
	Hub.definir_times_selecionados(chave_esquerda_atual, chave_direita_atual)
	if is_inside_tree() and get_tree().current_scene == self:
		_transicionar_para(CAMINHO_PARTIDA)


# --- AUXILIARES / SETTERS ---
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
	if botao_anterior_esquerdo != null and not botao_anterior_esquerdo.mouse_entered.is_connected(_on_mouse_entered_ant_esq):
		botao_anterior_esquerdo.mouse_entered.connect(_on_mouse_entered_ant_esq)
	if botao_proximo_esquerdo != null and not botao_proximo_esquerdo.mouse_entered.is_connected(_on_mouse_entered_prox_esq):
		botao_proximo_esquerdo.mouse_entered.connect(_on_mouse_entered_prox_esq)
	if botao_anterior_direito != null and not botao_anterior_direito.mouse_entered.is_connected(_on_mouse_entered_ant_dir):
		botao_anterior_direito.mouse_entered.connect(_on_mouse_entered_ant_dir)
	if botao_proximo_direito != null and not botao_proximo_direito.mouse_entered.is_connected(_on_mouse_entered_prox_dir):
		botao_proximo_direito.mouse_entered.connect(_on_mouse_entered_prox_dir)
	if botao_comecar != null and not botao_comecar.mouse_entered.is_connected(_on_mouse_entered_comecar):
		botao_comecar.mouse_entered.connect(_on_mouse_entered_comecar)
	if botao_voltar != null and not botao_voltar.mouse_entered.is_connected(_on_mouse_entered_voltar):
		botao_voltar.mouse_entered.connect(_on_mouse_entered_voltar)


func _on_botao_mouse_entered(botao: Button) -> void:
	if transicionando or botao == null or botao.disabled:
		return
	if not botao.has_focus():
		botao.grab_focus()


func _on_mouse_entered_ant_esq() -> void:
	_on_botao_mouse_entered(botao_anterior_esquerdo)


func _on_mouse_entered_prox_esq() -> void:
	_on_botao_mouse_entered(botao_proximo_esquerdo)


func _on_mouse_entered_ant_dir() -> void:
	_on_botao_mouse_entered(botao_anterior_direito)


func _on_mouse_entered_prox_dir() -> void:
	_on_botao_mouse_entered(botao_proximo_direito)


func _on_mouse_entered_comecar() -> void:
	_on_botao_mouse_entered(botao_comecar)


func _on_mouse_entered_voltar() -> void:
	_on_botao_mouse_entered(botao_voltar)


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
