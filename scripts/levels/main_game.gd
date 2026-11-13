class_name MainGame
extends Node2D

# --- ENUMS DE ESTADO ---
enum Estado {
	AGUARDANDO_JOGADA,
	MIRANDO,
	MOEDA_EM_MOVIMENTO,
	GOL_ANIMANDO,
	FIM_DE_PARTIDA,
}
enum EtapaFim { INATIVA, PAUSA, APITO, CONCLUIDA }

# --- SINAIS ---
signal placar_alterado(placar: Vector2i)
signal turno_alterado(equipe: Prego.Equipe)
signal tempo_atualizado(segundos: float)
signal gol_de_ouro_iniciado
signal estado_alterado(estado: Estado)
signal gol_confirmado(equipe_marcadora: Prego.Equipe, placar: Vector2i)
signal partida_encerrada(vencedor: Prego.Equipe, placar: Vector2i, por_gol_de_ouro: bool)

# --- CONSTANTES ---
const POSICAO_PADRAO_CENTRO: Vector2 = Vector2(576.0, 160.0)
const CAMINHO_TELA_FINAL: String = "res://scenes/ui/tela_final.tscn"
const CAMINHO_MENU_PRINCIPAL: String = "res://scenes/ui/menu_principal.tscn"

# --- PARAMETROS CONFIGURAVEIS ---
@export_group("Regras")
@export_range(1.0, 600.0) var duracao_partida: float = 300.0
@export_range(0.05, 5.0) var duracao_apresentacao_gol: float = GolUI.DURACAO_PADRAO
@export_range(0.05, 1.0) var pausa_antes_apito_final: float = 0.25

# --- REFERENCIAS A NODES ---
@onready var campo: Node2D = $Campo
@onready var centro_campo: Marker2D = $Campo/Marcadores/Centro
@onready var moeda: Moeda = $Moeda
@onready var mira: Mira = $Mira
@onready var camera: CameraPartida = $CameraPartida
@onready var cronometro: Timer = $Cronometro
@onready var pausa_gol: Timer = $PausaGol
@onready var pausa_fim: Timer = $PausaFim
@onready var limite_apito_final: Timer = $LimiteApitoFinal
@onready var hub: Hub = $FeedbackRegras/Hub
@onready var gol_ui: GolUI = $FeedbackRegras/GolUI
@onready var rotulo_aviso: Label = $FeedbackRegras/AvisoCentral
@onready var menu_pause: Pause = $FeedbackRegras/Pause

# --- ESTADO ---
var cor_corinthians: Color = Color.WHITE
var cor_flamengo: Color = Color.WHITE
var estado: Estado = Estado.AGUARDANDO_JOGADA
var placar: Vector2i = Vector2i.ZERO
var time_atual: Prego.Equipe = Prego.Equipe.CORINTHIANS
var equipe_sofreu_ultimo_gol: Prego.Equipe = Prego.Equipe.CORINTHIANS
var gol_de_ouro_ativo: bool = false
var tempo_esgotado: bool = false
var partida_ativa: bool = false
var cronometro_pausado_por_gol: bool = false
var semente_configurada: bool = false
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var sensores_gol: Array[Gol] = []
var id_partida: int = 0
var id_jogada_atual: int = 0
var id_jogada_armada: int = 0
var id_jogada_concluida: int = -1
var resolucao_agendada: bool = false
var parada_pendente_id: int = -1
var gol_pendente_id: int = -1
var gol_pendente_defensora: Prego.Equipe = Prego.Equipe.CORINTHIANS
var expiracao_pendente: bool = false
var ultimo_segundo_exibido: int = -1
var ultimo_vencedor: int = -1
var tween_aviso: Tween
var etapa_fim: EtapaFim = EtapaFim.INATIVA
var geracao_fim: int = -1
var player_apito_final: AudioStreamPlayer
var callback_apito_final: Callable


# --- INICIALIZACAO E LOOP DE FISICA/PROCESSAMENTO ---
func _ready() -> void:
	if not semente_configurada:
		rng.randomize()
	_conectar_grupo_sensores(&"sensores_gol", _on_sensor_gol_marcado)
	iniciar_partida()


func _exit_tree() -> void:
	_cancelar_encerramento()


func _unhandled_input(event: InputEvent) -> void:
	if not partida_ativa or estado == Estado.FIM_DE_PARTIDA:
		return
	if event.is_action_pressed(&"pausar", false, true) and not event.is_echo():
		get_viewport().set_input_as_handled()
		definir_pausada(true)


func _physics_process(_delta: float) -> void:
	if not partida_ativa or estado == Estado.FIM_DE_PARTIDA:
		return
	var tempo_restante: float = obter_tempo_restante()
	var segundo_exibido: int = ceili(tempo_restante)
	if segundo_exibido != ultimo_segundo_exibido:
		ultimo_segundo_exibido = segundo_exibido
		tempo_atualizado.emit(tempo_restante)
		_atualizar_feedback_status()


# --- DOMINIO PRINCIPAL / PROCESSADORES DE ESTADO ---
func _agendar_resolucao() -> void:
	if resolucao_agendada or not partida_ativa:
		return
	resolucao_agendada = true
	_resolver_eventos_pendentes.call_deferred(id_partida)


func _resolver_eventos_pendentes(geracao_esperada: int) -> void:
	if geracao_esperada != id_partida:
		return
	resolucao_agendada = false
	if not partida_ativa or estado == Estado.FIM_DE_PARTIDA:
		return

	if estado == Estado.MOEDA_EM_MOVIMENTO and id_jogada_concluida != id_jogada_atual:
		_inspecionar_sensores()

	# 1. Prioridade maxima: gol valido confirmado na jogada ativa.
	if (
		estado == Estado.MOEDA_EM_MOVIMENTO
		and gol_pendente_id == id_jogada_atual
		and id_jogada_concluida != id_jogada_atual
	):
		if expiracao_pendente:
			tempo_esgotado = true
			expiracao_pendente = false
			ultimo_segundo_exibido = 0
			tempo_atualizado.emit(0.0)
		var defensora: Prego.Equipe = gol_pendente_defensora
		gol_pendente_id = -1
		parada_pendente_id = -1
		_confirmar_gol(defensora)
		return

	# 2. Segunda prioridade: expiracao do tempo regolamentar.
	if expiracao_pendente:
		expiracao_pendente = false
		tempo_esgotado = true
		ultimo_segundo_exibido = 0
		tempo_atualizado.emit(0.0)
		if estado == Estado.AGUARDANDO_JOGADA or estado == Estado.MIRANDO:
			mira.definir_habilitada(false)
			_avaliar_pos_tempo_esgotado()
			return
		if estado == Estado.MOEDA_EM_MOVIMENTO and parada_pendente_id == id_jogada_atual:
			parada_pendente_id = -1
			id_jogada_concluida = id_jogada_atual
			_desarmar_sensores()
			_avaliar_pos_tempo_esgotado()
			return
		_atualizar_feedback_status()

	# 3. Terceira prioridade: parada normal da moeda ao fim da jogada.
	if (
		estado == Estado.MOEDA_EM_MOVIMENTO
		and parada_pendente_id == id_jogada_atual
		and id_jogada_concluida != id_jogada_atual
	):
		parada_pendente_id = -1
		id_jogada_concluida = id_jogada_atual
		_desarmar_sensores()
		if not gol_de_ouro_ativo and (tempo_esgotado or _relogio_regulamentar_esgotado()):
			tempo_esgotado = true
			ultimo_segundo_exibido = 0
			tempo_atualizado.emit(0.0)
			_avaliar_pos_tempo_esgotado()
			return
		time_atual = _equipe_adversaria(time_atual)
		_habilitar_turno(time_atual, true)


func _confirmar_gol(equipe_defensora: Prego.Equipe) -> void:
	id_jogada_concluida = id_jogada_atual
	equipe_sofreu_ultimo_gol = equipe_defensora
	_definir_estado(Estado.GOL_ANIMANDO)
	mira.definir_habilitada(false)
	_desarmar_sensores()

	if not gol_de_ouro_ativo:
		if tempo_esgotado or cronometro.is_stopped() or cronometro.time_left <= 0.0:
			tempo_esgotado = true
			cronometro_pausado_por_gol = false
			cronometro.stop()
		else:
			cronometro.paused = true
			cronometro_pausado_por_gol = true

	moeda.interromper_movimento()
	moeda.visible = false

	var equipe_marcadora: Prego.Equipe = _equipe_adversaria(equipe_defensora)
	if equipe_marcadora == Prego.Equipe.CORINTHIANS:
		placar.x += 1
	else:
		placar.y += 1

	placar_alterado.emit(placar)
	gol_confirmado.emit(equipe_marcadora, placar)
	AudioManager.tocar_gol()
	_exibir_aviso_gol(equipe_marcadora)
	_atualizar_feedback_status()
	pausa_gol.paused = false
	pausa_gol.start(duracao_apresentacao_gol)


func _avaliar_pos_tempo_esgotado() -> void:
	cronometro_pausado_por_gol = false
	cronometro.paused = false
	cronometro.stop()
	if placar.x != placar.y:
		_encerrar_partida(_obter_vencedor_atual(), false)
		return
	_iniciar_gol_de_ouro()


func _iniciar_gol_de_ouro() -> void:
	gol_de_ouro_ativo = true
	tempo_esgotado = true
	cronometro_pausado_por_gol = false
	cronometro.paused = false
	cronometro.stop()
	ultimo_segundo_exibido = 0
	tempo_atualizado.emit(0.0)
	_desarmar_sensores()
	moeda.definir_gol_de_ouro(true)
	moeda.visible = true
	_posicionar_moeda_no_centro()
	time_atual = _sortear_equipe()
	gol_de_ouro_iniciado.emit()
	_exibir_aviso_temporario("GOL DE OURO! Sorteio: %s" % _nome_equipe(time_atual))
	_habilitar_turno(time_atual, true)
	AudioManager.tocar_gol_de_ouro()


func _encerrar_partida(vencedor: Prego.Equipe, por_gol_de_ouro: bool) -> void:
	if estado == Estado.FIM_DE_PARTIDA:
		return
	ultimo_vencedor = int(vencedor)
	_desarmar_sensores()
	pausa_gol.stop()
	cronometro_pausado_por_gol = false
	cronometro.paused = false
	cronometro.stop()
	mira.definir_habilitada(false)
	moeda.interromper_movimento()
	_definir_estado(Estado.FIM_DE_PARTIDA)
	_exibir_aviso_fim(vencedor, por_gol_de_ouro)
	_atualizar_feedback_status()
	var chave_vencedor: StringName = _obter_chave_brasao_equipe(vencedor)
	TelaFinal.definir_resultado(vencedor, placar, por_gol_de_ouro, chave_vencedor)
	geracao_fim = id_partida
	etapa_fim = EtapaFim.PAUSA
	pausa_fim.start(pausa_antes_apito_final + AudioManager.obter_tempo_comemoracao_restante())
	partida_encerrada.emit(vencedor, placar, por_gol_de_ouro)


func _obter_chave_brasao_equipe(equipe: Prego.Equipe) -> StringName:
	if hub != null:
		return hub.chave_time_esquerdo if equipe == Prego.Equipe.CORINTHIANS else hub.chave_time_direito
	return (
		DadosTimes.time_esquerdo_selecionado
		if equipe == Prego.Equipe.CORINTHIANS
		else DadosTimes.time_direito_selecionado
	)


func _ir_para_tela_final(geracao_esperada: int) -> void:
	if geracao_esperada != id_partida or estado != Estado.FIM_DE_PARTIDA or not is_inside_tree():
		return
	if not partida_ativa or etapa_fim != EtapaFim.CONCLUIDA or get_tree().current_scene != self:
		return
	var erro: Error = get_tree().change_scene_to_file(CAMINHO_TELA_FINAL)
	if erro != OK:
		push_error("Falha ao abrir tela de resultado (erro %d)." % erro)


func _on_pausa_fim_timeout() -> void:
	if geracao_fim != id_partida or estado != Estado.FIM_DE_PARTIDA or etapa_fim != EtapaFim.PAUSA:
		return
	pausa_fim.stop()
	etapa_fim = EtapaFim.APITO
	player_apito_final = AudioManager.tocar_fim_partida()
	if not is_instance_valid(player_apito_final):
		_concluir_apito_final(geracao_fim)
		return
	callback_apito_final = _concluir_apito_final.bind(geracao_fim)
	player_apito_final.finished.connect(callback_apito_final, CONNECT_ONE_SHOT)
	var duracao: float = player_apito_final.stream.get_length()
	limite_apito_final.start(clampf(duracao + 1.0, 1.0, 11.0))


func _on_limite_apito_final_timeout() -> void:
	if etapa_fim != EtapaFim.APITO or geracao_fim != id_partida:
		return
	if is_instance_valid(player_apito_final):
		player_apito_final.stop()
	_concluir_apito_final(geracao_fim)


func _concluir_apito_final(geracao_esperada: int) -> void:
	if geracao_esperada != id_partida or geracao_esperada != geracao_fim:
		return
	if estado != Estado.FIM_DE_PARTIDA or etapa_fim != EtapaFim.APITO:
		return
	limite_apito_final.stop()
	_desconectar_apito_final()
	etapa_fim = EtapaFim.CONCLUIDA
	_ir_para_tela_final.call_deferred(geracao_esperada)


func _cancelar_encerramento() -> void:
	if pausa_fim != null:
		pausa_fim.stop()
	if limite_apito_final != null:
		limite_apito_final.stop()
	if is_instance_valid(player_apito_final):
		player_apito_final.stop()
	_desconectar_apito_final()
	geracao_fim = -1
	etapa_fim = EtapaFim.INATIVA


func _desconectar_apito_final() -> void:
	if is_instance_valid(player_apito_final) and callback_apito_final.is_valid():
		if player_apito_final.finished.is_connected(callback_apito_final):
			player_apito_final.finished.disconnect(callback_apito_final)
	player_apito_final = null
	callback_apito_final = Callable()


func _habilitar_turno(equipe: Prego.Equipe, emitir_turno: bool) -> void:
	time_atual = equipe
	moeda.cor_posse = _cor_equipe(equipe)
	moeda.queue_redraw()
	_definir_estado(Estado.AGUARDANDO_JOGADA)
	mira.definir_habilitada(true)
	if emitir_turno:
		turno_alterado.emit(time_atual)
	_atualizar_feedback_status()


# --- API PUBLICA ---
func iniciar_partida() -> void:
	_cancelar_encerramento()
	id_partida += 1
	id_jogada_atual = 0
	id_jogada_armada = 0
	id_jogada_concluida = -1
	resolucao_agendada = false
	parada_pendente_id = -1
	gol_pendente_id = -1
	expiracao_pendente = false
	gol_de_ouro_ativo = false
	tempo_esgotado = false
	cronometro_pausado_por_gol = false
	ultimo_vencedor = -1
	placar = Vector2i.ZERO
	partida_ativa = true
	TelaFinal.limpar_resultado()

	if is_inside_tree():
		get_tree().paused = false
	if menu_pause != null:
		menu_pause.ocultar()
	_aplicar_cores_times_na_partida()

	_cancelar_tween_aviso()
	_ocultar_aviso_central()
	pausa_gol.paused = false
	pausa_gol.stop()
	_desarmar_sensores()

	mira.definir_habilitada(false)
	moeda.definir_gol_de_ouro(false)
	moeda.visible = true
	_posicionar_moeda_no_centro()

	cronometro.paused = false
	cronometro.start(duracao_partida)
	ultimo_segundo_exibido = ceili(duracao_partida)

	time_atual = _sortear_equipe()
	placar_alterado.emit(placar)
	tempo_atualizado.emit(duracao_partida)
	_habilitar_turno(time_atual, true)
	_exibir_aviso_temporario("%s começa!" % _nome_equipe(time_atual), 1.5)
	AudioManager.tocar_inicio_partida()


func reiniciar_partida() -> void:
	iniciar_partida()


func cancelar_partida() -> void:
	_cancelar_encerramento()
	id_partida += 1
	partida_ativa = false
	resolucao_agendada = false
	parada_pendente_id = -1
	gol_pendente_id = -1
	expiracao_pendente = false
	cronometro_pausado_por_gol = false
	if is_inside_tree():
		get_tree().paused = false
	if menu_pause != null:
		menu_pause.ocultar()
	if hub != null:
		hub.definir_brasoes_por_chave(
			DadosTimes.time_esquerdo_selecionado,
			DadosTimes.time_direito_selecionado
		)
	_cancelar_tween_aviso()
	_ocultar_aviso_central()
	pausa_gol.stop()
	cronometro.paused = false
	cronometro.stop()
	_desarmar_sensores()
	mira.definir_habilitada(false)
	moeda.interromper_movimento()
	AudioManager.parar_audio_partida()


func definir_pausada(pausada: bool) -> void:
	if not partida_ativa or (pausada and estado == Estado.FIM_DE_PARTIDA):
		return
	if pausada:
		if estado == Estado.MIRANDO or mira.arrastando:
			mira.cancelar()
		if menu_pause != null:
			menu_pause.exibir()
		if is_inside_tree():
			get_tree().paused = true
	else:
		if is_inside_tree():
			get_tree().paused = false
		cronometro.paused = cronometro_pausado_por_gol
		if menu_pause != null:
			menu_pause.ocultar()


func definir_semente(semente: int) -> void:
	semente_configurada = true
	rng.seed = semente


func obter_placar() -> Vector2i:
	return placar


func obter_tempo_restante() -> float:
	if gol_de_ouro_ativo or tempo_esgotado or cronometro == null:
		return 0.0
	return maxf(cronometro.time_left, 0.0)


func obter_time_atual() -> Prego.Equipe:
	return time_atual


func obter_estado() -> Estado:
	return estado


func esta_em_gol_de_ouro() -> bool:
	return gol_de_ouro_ativo


# --- AUXILIARES / SETTERS ---
func _conectar_grupo_sensores(nome_grupo: StringName, callback: Callable) -> void:
	sensores_gol.clear()
	if not is_inside_tree():
		return
	for no: Node in get_tree().get_nodes_in_group(nome_grupo):
		var sensor: Gol = no as Gol
		if sensor != null and is_ancestor_of(sensor):
			sensores_gol.append(sensor)
			if not sensor.gol_marcado.is_connected(callback):
				sensor.gol_marcado.connect(callback)


func _armar_sensores(id_jogada: int) -> void:
	id_jogada_armada = id_jogada
	for sensor: Gol in sensores_gol:
		if is_instance_valid(sensor):
			sensor.armar(moeda, id_jogada)


func _desarmar_sensores() -> void:
	id_jogada_armada = 0
	for sensor: Gol in sensores_gol:
		if is_instance_valid(sensor):
			sensor.desarmar()


func _inspecionar_sensores() -> void:
	for sensor: Gol in sensores_gol:
		if is_instance_valid(sensor):
			sensor.inspecionar_passo()


func _posicionar_moeda_no_centro() -> void:
	var alvo_centro: Vector2 = POSICAO_PADRAO_CENTRO
	if centro_campo != null:
		alvo_centro = centro_campo.global_position
	moeda.reposicionar(alvo_centro)
	if camera != null:
		camera.reposicionar()


func _definir_estado(novo_estado: Estado) -> void:
	if estado == novo_estado:
		return
	estado = novo_estado
	estado_alterado.emit(estado)
	_atualizar_feedback_status()


func _sortear_equipe() -> Prego.Equipe:
	return Prego.Equipe.CORINTHIANS if rng.randi_range(0, 1) == 0 else Prego.Equipe.FLAMENGO


func _equipe_adversaria(equipe: Prego.Equipe) -> Prego.Equipe:
	if equipe == Prego.Equipe.CORINTHIANS:
		return Prego.Equipe.FLAMENGO
	return Prego.Equipe.CORINTHIANS


func _obter_vencedor_atual() -> Prego.Equipe:
	if placar.x >= placar.y:
		return Prego.Equipe.CORINTHIANS
	return Prego.Equipe.FLAMENGO


func _cor_equipe(equipe: Prego.Equipe) -> Color:
	var chave: StringName = _obter_chave_brasao_equipe(equipe)
	return DadosTimes.obter_cor_time(chave)


func _aplicar_cores_times_na_partida() -> void:
	if hub != null:
		hub.definir_brasoes_por_chave(
			DadosTimes.time_esquerdo_selecionado,
			DadosTimes.time_direito_selecionado
		)
	cor_corinthians = _cor_equipe(Prego.Equipe.CORINTHIANS)
	cor_flamengo = _cor_equipe(Prego.Equipe.FLAMENGO)
	if campo == null:
		return
	var container_pregos: Node = campo.get_node_or_null("Pregos")
	if container_pregos == null:
		return
	for filho: Node in container_pregos.get_children():
		var prego: Prego = filho as Prego
		if prego == null:
			continue
		var cor_lado: Color = (
			cor_corinthians
			if prego.time == Prego.Equipe.CORINTHIANS
			else cor_flamengo
		)
		prego.definir_cor_time(cor_lado)


func _nome_equipe(equipe: Prego.Equipe) -> String:
	return DadosTimes.obter_nome_time(_obter_chave_brasao_equipe(equipe))


func _relogio_regulamentar_esgotado() -> bool:
	if gol_de_ouro_ativo:
		return false
	return tempo_esgotado or expiracao_pendente or cronometro.is_stopped() or cronometro.time_left <= 0.0


func _atualizar_feedback_status() -> void:
	if hub == null:
		return
	hub.definir_gol_de_ouro(gol_de_ouro_ativo)
	hub.atualizar_placar(placar, estado == Estado.GOL_ANIMANDO)
	hub.atualizar_tempo(obter_tempo_restante())
	hub.atualizar_turno(time_atual)


func _exibir_aviso_gol(equipe_marcadora: Prego.Equipe) -> void:
	_cancelar_tween_aviso()
	if rotulo_aviso != null:
		rotulo_aviso.visible = false
	if gol_ui != null:
		gol_ui.exibir_gol(
			equipe_marcadora,
			placar,
			duracao_apresentacao_gol,
			_obter_chave_brasao_equipe(Prego.Equipe.CORINTHIANS),
			_obter_chave_brasao_equipe(Prego.Equipe.FLAMENGO)
		)


func _exibir_aviso_temporario(mensagem: String, duracao: float = 0.6) -> void:
	if gol_ui != null:
		gol_ui.ocultar_gol()
	if rotulo_aviso == null:
		return
	_cancelar_tween_aviso()
	rotulo_aviso.text = mensagem
	rotulo_aviso.modulate = Color.WHITE
	rotulo_aviso.visible = true
	tween_aviso = create_tween()
	tween_aviso.tween_interval(duracao)
	tween_aviso.tween_property(rotulo_aviso, "modulate:a", 0.0, 0.25)
	tween_aviso.tween_callback(_ocultar_aviso_central)


func _exibir_aviso_fim(vencedor: Prego.Equipe, por_gol_de_ouro: bool) -> void:
	if gol_ui != null:
		gol_ui.ocultar_gol()
	if rotulo_aviso == null:
		return
	_cancelar_tween_aviso()
	var sufixo: String = " (GOL DE OURO)" if por_gol_de_ouro else ""
	rotulo_aviso.text = "FIM DE PARTIDA%s\nVencedor: %s (%d x %d)" % [
		sufixo,
		_nome_equipe(vencedor),
		placar.x,
		placar.y,
	]
	rotulo_aviso.modulate = Color(1.0, 1.0, 1.0, 1.0)
	rotulo_aviso.visible = true


func _ocultar_aviso_central() -> void:
	if gol_ui != null:
		gol_ui.ocultar_gol()
	if rotulo_aviso != null:
		rotulo_aviso.visible = false


func _cancelar_tween_aviso() -> void:
	if tween_aviso != null and tween_aviso.is_valid():
		tween_aviso.kill()
	tween_aviso = null


func _on_mira_iniciada() -> void:
	if not partida_ativa or get_tree().paused or resolucao_agendada:
		mira.cancelar()
		return
	if estado != Estado.AGUARDANDO_JOGADA:
		return
	if _relogio_regulamentar_esgotado():
		mira.definir_habilitada(false)
		if not tempo_esgotado and not expiracao_pendente:
			expiracao_pendente = true
			_agendar_resolucao()
		return
	_definir_estado(Estado.MIRANDO)


func _on_mira_cancelada() -> void:
	if not partida_ativa or estado != Estado.MIRANDO:
		return
	if _relogio_regulamentar_esgotado() or resolucao_agendada:
		return
	_definir_estado(Estado.AGUARDANDO_JOGADA)


func _on_lancamento_solicitado(impulso: Vector2) -> void:
	if not partida_ativa or get_tree().paused or resolucao_agendada:
		return
	if estado != Estado.AGUARDANDO_JOGADA and estado != Estado.MIRANDO:
		return
	if _relogio_regulamentar_esgotado():
		mira.definir_habilitada(false)
		if not tempo_esgotado and not expiracao_pendente:
			expiracao_pendente = true
			_agendar_resolucao()
		return

	var id_anterior: int = id_jogada_atual
	var proximo_id: int = id_jogada_atual + 1
	id_jogada_atual = proximo_id
	_armar_sensores(proximo_id)
	var aceito: bool = moeda.lancar(impulso)
	if not aceito:
		_desarmar_sensores()
		id_jogada_atual = id_anterior
		if not _relogio_regulamentar_esgotado():
			_definir_estado(Estado.AGUARDANDO_JOGADA)
			mira.definir_habilitada(true)


func _on_moeda_lancada(_impulso: Vector2) -> void:
	if not partida_ativa:
		return
	if estado != Estado.AGUARDANDO_JOGADA and estado != Estado.MIRANDO:
		return
	if id_jogada_armada != id_jogada_atual or id_jogada_atual <= 0:
		id_jogada_atual += 1
		_armar_sensores(id_jogada_atual)
	_ocultar_aviso_central()
	_definir_estado(Estado.MOEDA_EM_MOVIMENTO)
	mira.definir_habilitada(false)


func _on_moeda_parou() -> void:
	if not partida_ativa or estado != Estado.MOEDA_EM_MOVIMENTO:
		return
	if id_jogada_atual <= 0 or id_jogada_concluida == id_jogada_atual:
		return
	_inspecionar_sensores()
	parada_pendente_id = id_jogada_atual
	_agendar_resolucao()


func _on_sensor_gol_marcado(equipe_defensora: Prego.Equipe, id_jogada: int) -> void:
	if not partida_ativa or estado != Estado.MOEDA_EM_MOVIMENTO:
		return
	if id_jogada != id_jogada_atual or id_jogada_concluida == id_jogada_atual:
		return
	if gol_pendente_id == id_jogada_atual:
		return
	gol_pendente_id = id_jogada_atual
	gol_pendente_defensora = equipe_defensora
	_agendar_resolucao()


func _on_cronometro_timeout() -> void:
	if not partida_ativa or gol_de_ouro_ativo or estado == Estado.FIM_DE_PARTIDA:
		return
	expiracao_pendente = true
	if estado == Estado.AGUARDANDO_JOGADA or estado == Estado.MIRANDO:
		mira.definir_habilitada(false)
	_agendar_resolucao()


func _on_pausa_gol_timeout() -> void:
	if not partida_ativa or estado != Estado.GOL_ANIMANDO:
		return
	_cancelar_tween_aviso()
	_ocultar_aviso_central()

	if gol_de_ouro_ativo:
		_encerrar_partida(_obter_vencedor_atual(), true)
		return
	if tempo_esgotado:
		_avaliar_pos_tempo_esgotado()
		return

	moeda.visible = true
	_posicionar_moeda_no_centro()
	cronometro_pausado_por_gol = false
	cronometro.paused = false
	_habilitar_turno(equipe_sofreu_ultimo_gol, true)
	AudioManager.tocar_apito_reinicio()


func _on_hub_pausa_solicitada() -> void:
	definir_pausada(true)


func _on_pause_continuar_solicitado() -> void:
	definir_pausada(false)


func _on_pause_reinicio_solicitado() -> void:
	reiniciar_partida()


func _on_pause_menu_solicitado() -> void:
	cancelar_partida()
	if is_inside_tree() and get_tree().current_scene == self:
		_transicionar_saida_menu.call_deferred()


func _transicionar_saida_menu() -> void:
	if not is_inside_tree() or get_tree().current_scene != self:
		return
	if ResourceLoader.exists(CAMINHO_MENU_PRINCIPAL):
		var erro_menu: Error = get_tree().change_scene_to_file(CAMINHO_MENU_PRINCIPAL)
		if erro_menu != OK:
			push_error("Falha ao transicionar para '%s' (erro %d)." % [CAMINHO_MENU_PRINCIPAL, erro_menu])
	else:
		get_tree().quit()
