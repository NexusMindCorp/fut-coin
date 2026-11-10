extends SceneTree

# --- CONSTANTES ---
const CENA_PARTIDA: PackedScene = preload("res://scenes/levels/main_game.tscn")
const CENA_TELA_FINAL: PackedScene = preload("res://scenes/ui/tela_final.tscn")

# --- ESTADO ---
var falhas: int = 0
var verificacoes: int = 0
var detalhes_falhas: PackedStringArray = PackedStringArray()
var partida: MainGame
var moeda: Moeda
var mira: Mira
var gols_confirmados: int = 0
var encerramentos: int = 0
var ultimo_vencedor_sinal: Prego.Equipe = Prego.Equipe.CORINTHIANS
var ultimo_placar_sinal: Vector2i = Vector2i.ZERO
var ultimo_gol_ouro_sinal: bool = false
var inicios_gol_ouro: int = 0


# --- INICIALIZACAO E LOOP DE FISICA/PROCESSAMENTO ---
func _initialize() -> void:
	_executar.call_deferred()


# --- DOMINIO PRINCIPAL / PROCESSADORES DE ESTADO ---
func _executar() -> void:
	partida = CENA_PARTIDA.instantiate() as MainGame
	root.add_child(partida)
	moeda = partida.get_node("Moeda") as Moeda
	mira = partida.get_node("Mira") as Mira
	partida.gol_confirmado.connect(_on_gol_confirmado)
	partida.partida_encerrada.connect(_on_partida_encerrada)
	partida.gol_de_ouro_iniciado.connect(_on_gol_de_ouro_iniciado)
	await _quadros(2)

	_testar_inicializacao_padrao()
	_testar_geometria_sensor_gol()
	await _testar_turnos_cancelamento_e_recusa()
	await _testar_filtros_id_teleporte_e_duplicatas()
	await _testar_gols_normais_e_gol_contra()
	await _testar_expiracao_parado_e_mirando()
	await _testar_expiracao_em_movimento_sem_gol()
	await _testar_expiracao_em_movimento_com_gol()
	await _testar_permutacoes_mesmo_tick()
	await _testar_gol_de_ouro_e_sorteio_independente()
	await _testar_pausa_abandono_e_reinicio()
	await _testar_isolamento_duas_partidas()

	partida.queue_free()
	await process_frame
	var resultado: String = "FEAT-004: %d verificacoes; %d falhas" % [verificacoes, falhas]
	var arquivo: FileAccess = FileAccess.open("res://.godot/feat004-testes.txt", FileAccess.WRITE)
	if arquivo != null:
		arquivo.store_string(resultado + "\n")
		for linha_falha: String in detalhes_falhas:
			arquivo.store_string(" - " + linha_falha + "\n")
		arquivo.close()
	if falhas > 0:
		push_error(resultado)
	quit(0 if falhas == 0 else 1)


func _testar_inicializacao_padrao() -> void:
	_verificar(partida.obter_placar() == Vector2i.ZERO, "Placar inicial 0x0")
	_verificar(moeda.visible and not moeda.dourada, "Moeda prata visivel no inicio")
	_verificar(moeda.animacao.animation == &"repouso", "Animacao inicial repouso prata")
	_verificar(moeda.global_position.is_equal_approx(Vector2(576.0, 160.0)), "Moeda no centro (576, 160)")
	_verificar(partida.obter_tempo_restante() > 175.0 and partida.obter_tempo_restante() <= 180.0, "Cronometro iniciado em 180s")
	_verificar(partida.obter_estado() == MainGame.Estado.AGUARDANDO_JOGADA, "Estado inicial AGUARDANDO_JOGADA")
	_verificar(mira.habilitada and moeda.autorizada, "Mira e moeda autorizadas no primeiro turno")
	var cor_esperada: Color = (
		partida.cor_corinthians
		if partida.obter_time_atual() == Prego.Equipe.CORINTHIANS
		else partida.cor_flamengo
	)
	_verificar(moeda.cor_posse.is_equal_approx(cor_esperada), "Cor de posse inicial corresponde a equipe sorteada")
	_verificar(partida.hub != null and Hub.BRASOES_TIMES.size() == 9, "Hub integrado com os 9 brasoes de assets/ui/times")
	_verificar(Hub.formatar_tempo(180.0) == "03:00" and Hub.formatar_tempo(59.2) == "01:00" and Hub.formatar_tempo(0.0) == "00:00", "Formatacao estatica de tempo do Hub")
	_verificar(partida.gol_ui != null and not partida.gol_ui.visible and not partida.gol_ui.animando, "Cena GolUI oculta e sem animar fora de um gol")


func _testar_geometria_sensor_gol() -> void:
	# Fronteira X=34 (esquerda, Corinthians) e X=1118 (direita, Flamengo) com tolerancia 0.01.
	_verificar(Gol.contem_moeda_completa(Vector2(34.0, 160.0), Prego.Equipe.CORINTHIANS, 0.01), "Centro X=34 dentro do gol esquerdo")
	_verificar(Gol.contem_moeda_completa(Vector2(34.009, 160.0), Prego.Equipe.CORINTHIANS, 0.01), "Centro X=34+eps dentro da tolerancia")
	_verificar(not Gol.contem_moeda_completa(Vector2(34.02, 160.0), Prego.Equipe.CORINTHIANS, 0.01), "Centro X=34.02 fora do gol esquerdo")
	_verificar(Gol.contem_moeda_completa(Vector2(1118.0, 160.0), Prego.Equipe.FLAMENGO, 0.01), "Centro X=1118 dentro do gol direito")
	_verificar(Gol.contem_moeda_completa(Vector2(1117.991, 160.0), Prego.Equipe.FLAMENGO, 0.01), "Centro X=1118-eps dentro da tolerancia")
	_verificar(not Gol.contem_moeda_completa(Vector2(1117.98, 160.0), Prego.Equipe.FLAMENGO, 0.01), "Centro X=1117.98 fora do gol direito")

	# Limites Y=138..182 (boca 124..196 com raio 14).
	_verificar(Gol.contem_moeda_completa(Vector2(30.0, 138.0), Prego.Equipe.CORINTHIANS, 0.01), "Limite superior Y=138 aceito")
	_verificar(Gol.contem_moeda_completa(Vector2(30.0, 182.0), Prego.Equipe.CORINTHIANS, 0.01), "Limite inferior Y=182 aceito")
	_verificar(not Gol.contem_moeda_completa(Vector2(30.0, 137.95), Prego.Equipe.CORINTHIANS, 0.01), "Fora da boca Y=137.95 rejeitado")
	_verificar(not Gol.contem_moeda_completa(Vector2(30.0, 182.05), Prego.Equipe.CORINTHIANS, 0.01), "Fora da boca Y=182.05 rejeitado")

	# Travessia por segmento rapido, saida de rede e teleporte longo.
	_verificar(Gol.avaliar_travessia(Vector2(60.0, 160.0), Vector2(26.0, 160.0), Prego.Equipe.CORINTHIANS, 0.01), "Travessia rapida esquerda confirmada")
	_verificar(Gol.avaliar_travessia(Vector2(1092.0, 160.0), Vector2(1126.0, 160.0), Prego.Equipe.FLAMENGO, 0.01), "Travessia rapida direita confirmada")
	_verificar(not Gol.avaliar_travessia(Vector2(26.0, 160.0), Vector2(56.0, 160.0), Prego.Equipe.CORINTHIANS, 0.01), "Saida da rede esquerda nao pontua")
	_verificar(not Gol.avaliar_travessia(Vector2(1126.0, 160.0), Vector2(1096.0, 160.0), Prego.Equipe.FLAMENGO, 0.01), "Saida da rede direita nao pontua")
	_verificar(not Gol.avaliar_travessia(Vector2(576.0, 160.0), Vector2(28.0, 160.0), Prego.Equipe.CORINTHIANS, 0.01), "Teleporte do centro ao gol rejeitado")
	_verificar(not Gol.avaliar_travessia(Vector2(50.0, 110.0), Vector2(28.0, 110.0), Prego.Equipe.CORINTHIANS, 0.01), "Travessia pela lateral fora da boca rejeitada")
	_verificar(Gol.avaliar_travessia(Vector2(32.0, 137.4), Vector2(26.0, 142.0), Prego.Equipe.CORINTHIANS, 0.01), "Ricochete na trave que entra no gol e confirmado")


func _testar_turnos_cancelamento_e_recusa() -> void:
	partida.duracao_apresentacao_gol = 0.08
	partida.definir_semente(101)
	partida.reiniciar_partida()
	await _quadros(2)

	var time_inicial: Prego.Equipe = partida.obter_time_atual()
	var tempo_antes: float = partida.obter_tempo_restante()

	# Iniciar e cancelar mira nao consome turno nem altera equipe.
	partida._on_mira_iniciada()
	_verificar(partida.obter_estado() == MainGame.Estado.MIRANDO, "Mira iniciada muda para MIRANDO")
	partida._on_mira_cancelada()
	_verificar(partida.obter_estado() == MainGame.Estado.AGUARDANDO_JOGADA, "Cancelamento retorna para AGUARDANDO_JOGADA")
	_verificar(partida.obter_time_atual() == time_inicial, "Cancelamento preserva equipe do turno")

	# Tiro recusado contra a parede superior nao consome turno.
	moeda.reposicionar(Vector2(576.0, 46.0))
	await _quadros(2)
	partida._on_lancamento_solicitado(Vector2(0.0, -200.0))
	_verificar(partida.obter_estado() == MainGame.Estado.AGUARDANDO_JOGADA, "Tiro recusado contra parede mantem AGUARDANDO_JOGADA")
	_verificar(partida.obter_time_atual() == time_inicial and mira.habilitada, "Tiro recusado preserva turno e mira habilitada")
	_verificar(partida.obter_tempo_restante() <= tempo_antes, "Tiro recusado nao reinicia cronometro")

	# 1o tiro valido: deve alternar equipe uma unica vez apos parada.
	moeda.reposicionar(Vector2(576.0, 160.0))
	await _quadros(2)
	partida._on_lancamento_solicitado(Vector2(0.0, -90.0))
	_verificar(partida.obter_estado() == MainGame.Estado.MOEDA_EM_MOVIMENTO, "Tiro valido entra em MOEDA_EM_MOVIMENTO")
	_verificar(not mira.habilitada and not moeda.autorizada, "Mira desabilitada durante movimento")
	await _aguardar_parada_e_resolucao()
	var segundo_time: Prego.Equipe = partida.obter_time_atual()
	_verificar(segundo_time != time_inicial, "Parada sem gol alterna equipe para o adversario")
	_verificar(partida.obter_estado() == MainGame.Estado.AGUARDANDO_JOGADA and mira.habilitada, "Proximo turno habilitado apos parada")

	# 2o tiro valido: retorna posse ao time inicial.
	partida._on_lancamento_solicitado(Vector2(0.0, 90.0))
	await _aguardar_parada_e_resolucao()
	_verificar(partida.obter_time_atual() == time_inicial, "Segundo tiro valido retorna vez ao time inicial")


func _testar_filtros_id_teleporte_e_duplicatas() -> void:
	partida.definir_semente(202)
	partida.reiniciar_partida()
	await _quadros(2)

	var sensor_esquerdo: Gol = partida.get_node("Sensores/GolEsquerdo") as Gol
	var placar_antes: Vector2i = partida.obter_placar()

	# Teleporte via reposicionar enquanto sensor armado nao deve pontuar.
	sensor_esquerdo.armar(moeda, 77)
	moeda.reposicionar(Vector2(28.0, 160.0))
	sensor_esquerdo.inspecionar_passo()
	await _quadros(2)
	_verificar(partida.obter_placar() == placar_antes, "Teleporte via reposicionar nao marca gol")
	sensor_esquerdo.desarmar()
	moeda.reposicionar(Vector2(576.0, 160.0))
	await _quadros(2)

	# Corpo diferente (Prego) no callback body_entered do sensor e ID antigo no juiz sao ignorados.
	var prego_qualquer: Node2D = partida.get_node("Campo/Pregos/GoleiroCorinthians") as Node2D
	partida._on_lancamento_solicitado(Vector2(0.0, -80.0))
	sensor_esquerdo._on_body_entered(prego_qualquer)
	partida._on_sensor_gol_marcado(Prego.Equipe.CORINTHIANS, 9999)
	await _aguardar_parada_e_resolucao()
	_verificar(partida.obter_placar() == Vector2i.ZERO, "Prego e ID de jogada invalido nao alteram placar")


func _testar_gols_normais_e_gol_contra() -> void:
	partida.duracao_apresentacao_gol = 0.1
	partida.definir_semente(303)
	partida.reiniciar_partida()
	await _quadros(2)

	# Forca turno do Corinthians e chuta contra o proprio gol esquerdo (defendido pelo Corinthians).
	partida._habilitar_turno(Prego.Equipe.CORINTHIANS, false)
	moeda.reposicionar(Vector2(82.0, 139.0))
	await _quadros(2)
	var gols_antes: int = gols_confirmados
	partida._on_lancamento_solicitado(Vector2(-550.0, 0.0))
	await _aguardar_estado(MainGame.Estado.GOL_ANIMANDO, 60)

	_verificar(partida.obter_estado() == MainGame.Estado.GOL_ANIMANDO, "Gol contra esquerdo entra em GOL_ANIMANDO")
	_verificar(partida.gol_ui.visible and partida.gol_ui.animando, "Cena GolUI visivel e animando durante GOL_ANIMANDO")
	_verificar(partida.obter_placar() == Vector2i(0, 1), "Gol esquerdo pontua para o Flamengo (gol contra vale)")
	_verificar(gols_confirmados == gols_antes + 1, "Sinal gol_confirmado emitido exatamente uma vez")
	_verificar(not moeda.visible and not mira.habilitada, "Moeda oculta e mira desabilitada durante GOL_ANIMANDO")
	_verificar(partida.cronometro.paused, "Cronometro pausado durante apresentacao de gol")
	var tempo_congelado: float = partida.obter_tempo_restante()
	await _quadros(2)
	_verificar(is_equal_approx(partida.obter_tempo_restante(), tempo_congelado), "Tempo restante preservado enquanto gol anima")

	# Fim da apresentacao: quem sofreu o gol (Corinthians, defensor esquerdo) recebe o turno no centro.
	await _aguardar_estado(MainGame.Estado.AGUARDANDO_JOGADA, 40)
	_verificar(not partida.gol_ui.visible and not partida.gol_ui.animando, "Cena GolUI ocultada ao encerrar apresentacao do gol")
	_verificar(moeda.visible and moeda.global_position.is_equal_approx(Vector2(576.0, 160.0)), "Moeda visivel no centro apos apresentacao")
	_verificar(not partida.cronometro.paused, "Cronometro retomado apos apresentacao")
	_verificar(partida.obter_time_atual() == Prego.Equipe.CORINTHIANS, "Corinthians (sofreu o gol esquerdo) inicia proximo turno")

	# Gol direito (defendido pelo Flamengo): ponto para o Corinthians e posse seguinte para o Flamengo.
	moeda.reposicionar(Vector2(1070.0, 139.0))
	await _quadros(2)
	partida._on_lancamento_solicitado(Vector2(550.0, 0.0))
	await _aguardar_estado(MainGame.Estado.GOL_ANIMANDO, 60)
	_verificar(partida.obter_placar() == Vector2i(1, 1), "Gol direito pontua para o Corinthians (1x1)")
	await _aguardar_estado(MainGame.Estado.AGUARDANDO_JOGADA, 40)
	_verificar(partida.obter_time_atual() == Prego.Equipe.FLAMENGO, "Flamengo (sofreu o gol direito) inicia proximo turno")


func _testar_expiracao_parado_e_mirando() -> void:
	# Expiracao em AGUARDANDO_JOGADA com placar desigual -> encerra imediatamente.
	partida.definir_semente(404)
	partida.reiniciar_partida()
	await _quadros(2)
	partida.placar = Vector2i(2, 0)
	var encerramentos_antes: int = encerramentos
	partida._on_cronometro_timeout()
	await _quadros(2)
	_verificar(partida.obter_estado() == MainGame.Estado.FIM_DE_PARTIDA, "Timeout em AGUARDANDO_JOGADA encerra com placar desigual")
	_verificar(encerramentos == encerramentos_antes + 1 and ultimo_vencedor_sinal == Prego.Equipe.CORINTHIANS and not ultimo_gol_ouro_sinal, "Vencedor Corinthians sem gol de ouro")

	# Expiracao durante MIRANDO com arrasto ativo -> cancela mira e encerra sem conceder tiro.
	partida.reiniciar_partida()
	await _quadros(2)
	partida.placar = Vector2i(1, 3)
	mira.arrastando = true
	partida._on_mira_iniciada()
	_verificar(partida.obter_estado() == MainGame.Estado.MIRANDO, "Em estado MIRANDO antes do timeout")
	partida._on_cronometro_timeout()
	await _quadros(2)
	_verificar(not mira.arrastando and not mira.habilitada, "Timeout cancela arrasto e desabilita mira")
	_verificar(partida.obter_estado() == MainGame.Estado.FIM_DE_PARTIDA and ultimo_vencedor_sinal == Prego.Equipe.FLAMENGO, "Timeout mirando encerra com vitoria do Flamengo")


func _testar_expiracao_em_movimento_sem_gol() -> void:
	# Caso A: Placar desigual em movimento quando o tempo acaba -> espera parar e encerra.
	partida.definir_semente(505)
	partida.reiniciar_partida()
	await _quadros(2)
	partida.placar = Vector2i(0, 1)
	partida._on_lancamento_solicitado(Vector2(0.0, -80.0))
	_verificar(partida.obter_estado() == MainGame.Estado.MOEDA_EM_MOVIMENTO, "Moeda em movimento antes de expirar")
	partida._on_cronometro_timeout()
	await _quadros(1)
	_verificar(partida.obter_estado() == MainGame.Estado.MOEDA_EM_MOVIMENTO, "Partida aguarda fim do movimento apos timeout")
	await _aguardar_estado(MainGame.Estado.FIM_DE_PARTIDA, 180)
	_verificar(partida.obter_estado() == MainGame.Estado.FIM_DE_PARTIDA and ultimo_vencedor_sinal == Prego.Equipe.FLAMENGO, "Encerra apos parada da ultima jogada")

	# Caso B: Empate em movimento quando o tempo acaba -> espera parar e entra no Gol de Ouro.
	partida.reiniciar_partida()
	await _quadros(2)
	partida.placar = Vector2i(1, 1)
	partida._on_lancamento_solicitado(Vector2(0.0, -80.0))
	partida._on_cronometro_timeout()
	await _aguardar_parada_e_resolucao()
	_verificar(partida.esta_em_gol_de_ouro() and partida.obter_estado() == MainGame.Estado.AGUARDANDO_JOGADA, "Empate apos parada ativa Gol de Ouro")


func _testar_expiracao_em_movimento_com_gol() -> void:
	partida.duracao_apresentacao_gol = 0.08
	# Caso A: Estava 0x1, tempo expira durante o chute, mas Corinthians faz gol (empata 1x1) -> vai para Gol de Ouro!
	partida.reiniciar_partida()
	await _quadros(2)
	partida.placar = Vector2i(0, 1)
	moeda.reposicionar(Vector2(1070.0, 139.0))
	await _quadros(2)
	partida._on_lancamento_solicitado(Vector2(550.0, 0.0))
	partida._on_cronometro_timeout()
	await _aguardar_estado(MainGame.Estado.GOL_ANIMANDO, 60)
	_verificar(partida.obter_placar() == Vector2i(1, 1), "Gol apos expiracao em movimento e contabilizado (1x1)")
	await _aguardar_estado(MainGame.Estado.AGUARDANDO_JOGADA, 40)
	_verificar(partida.esta_em_gol_de_ouro(), "Gol de empate no ultimo lance leva ao Gol de Ouro apos apresentacao")

	# Caso B: Estava 1x1, tempo expira durante o chute e Corinthians faz gol (2x1) -> encerra partida com vitoria!
	partida.reiniciar_partida()
	await _quadros(2)
	partida.placar = Vector2i(1, 1)
	moeda.reposicionar(Vector2(1070.0, 139.0))
	await _quadros(2)
	partida._on_lancamento_solicitado(Vector2(550.0, 0.0))
	partida._on_cronometro_timeout()
	await _aguardar_estado(MainGame.Estado.GOL_ANIMANDO, 60)
	await _aguardar_estado(MainGame.Estado.FIM_DE_PARTIDA, 40)
	_verificar(partida.obter_estado() == MainGame.Estado.FIM_DE_PARTIDA and not ultimo_gol_ouro_sinal, "Gol de desempate no ultimo lance encerra partida sem Gol de Ouro")
	_verificar(ultimo_vencedor_sinal == Prego.Equipe.CORINTHIANS and partida.obter_placar() == Vector2i(2, 1), "Vencedor Corinthians 2x1 confirmado")


func _testar_permutacoes_mesmo_tick() -> void:
	partida.duracao_apresentacao_gol = 0.06
	# 6 permutacoes (3!) de [gol, parada, timeout] disparados no mesmo tick fisico.
	var ordens: Array[Array] = [
		["gol", "parada", "timeout"],
		["gol", "timeout", "parada"],
		["parada", "gol", "timeout"],
		["parada", "timeout", "gol"],
		["timeout", "gol", "parada"],
		["timeout", "parada", "gol"],
	]
	for indice: int in range(ordens.size()):
		partida.definir_semente(600 + indice)
		partida.reiniciar_partida()
		await _quadros(2)
		partida._on_lancamento_solicitado(Vector2(0.0, -80.0))
		var id_ativo: int = partida.id_jogada_atual
		var sequencia: Array = ordens[indice]
		for evento: String in sequencia:
			match evento:
				"gol":
					partida._on_sensor_gol_marcado(Prego.Equipe.FLAMENGO, id_ativo)
				"parada":
					partida._on_moeda_parou()
				"timeout":
					partida._on_cronometro_timeout()
		await _quadros(2)
		_verificar(
			partida.obter_estado() == MainGame.Estado.GOL_ANIMANDO and partida.obter_placar() == Vector2i(1, 0),
			"Permutacao %d prioriza gol no mesmo tick" % indice
		)
		await _aguardar_estado(MainGame.Estado.FIM_DE_PARTIDA, 30)
		_verificar(
			partida.obter_estado() == MainGame.Estado.FIM_DE_PARTIDA and ultimo_vencedor_sinal == Prego.Equipe.CORINTHIANS,
			"Permutacao %d encerra apos apresentacao preservando timeout" % indice
		)


func _testar_gol_de_ouro_e_sorteio_independente() -> void:
	partida.duracao_apresentacao_gol = 0.08
	var viu_corinthians: bool = false
	var viu_flamengo: bool = false

	# Verifica em 0x0 que o Gol de Ouro faz novo sorteio independente, ativa moeda dourada e zera relogio.
	for semente: int in range(1, 16):
		partida.definir_semente(semente * 37)
		partida.reiniciar_partida()
		await _quadros(1)
		partida._on_cronometro_timeout()
		await _quadros(2)
		if partida.obter_time_atual() == Prego.Equipe.CORINTHIANS:
			viu_corinthians = true
		else:
			viu_flamengo = true

	_verificar(viu_corinthians and viu_flamengo, "Sorteio independente do Gol de Ouro contempla ambas as equipes")
	_verificar(partida.esta_em_gol_de_ouro() and is_zero_approx(partida.obter_tempo_restante()), "Relogio em zero no Gol de Ouro")
	_verificar(moeda.dourada and moeda.animacao.animation == &"repouso_dourado", "Moeda em repouso_dourado no Gol de Ouro")

	# Chute sem gol no Gol de Ouro NAO reinicia no centro nem encerra: alterna turno e continua ate sair gol.
	var inicios_ouro_antes: int = inicios_gol_ouro
	var time_ouro_1: Prego.Equipe = partida.obter_time_atual()
	partida._on_lancamento_solicitado(Vector2(0.0, -90.0))
	await _aguardar_parada_e_resolucao()
	_verificar(
		partida.esta_em_gol_de_ouro()
		and inicios_gol_ouro == inicios_ouro_antes
		and partida.obter_estado() == MainGame.Estado.AGUARDANDO_JOGADA
		and partida.obter_time_atual() != time_ouro_1
		and not moeda.global_position.is_equal_approx(Vector2(576.0, 160.0))
		and mira.habilitada
		and moeda.esta_parada(),
		"Chute sem gol no Gol de Ouro alterna turno no local e permite novo chute ate sair gol"
	)

	# Primeiro gol no Gol de Ouro encerra a partida apos apresentacao sem liberar nova jogada.
	moeda.reposicionar(Vector2(82.0, 139.0))
	await _quadros(2)
	partida._on_lancamento_solicitado(Vector2(-550.0, 0.0))
	_verificar(moeda.animacao.animation == &"giro_dourado", "Moeda usa animacao giro_dourado ao lancar no Gol de Ouro")
	await _aguardar_estado(MainGame.Estado.GOL_ANIMANDO, 60)
	await _aguardar_estado(MainGame.Estado.FIM_DE_PARTIDA, 40)
	_verificar(
		partida.obter_estado() == MainGame.Estado.FIM_DE_PARTIDA
		and ultimo_gol_ouro_sinal
		and ultimo_vencedor_sinal == Prego.Equipe.FLAMENGO
		and not mira.habilitada,
		"Primeiro gol no Gol de Ouro define vencedor e bloqueia novas cobrancas"
	)
	_verificar(
		TelaFinal.resultado_pendente
		and TelaFinal.vencedor_registrado == Prego.Equipe.FLAMENGO
		and TelaFinal.gol_ouro_registrado
		and TelaFinal.chave_vencedor_registrada == &"flamengo",
		"Fim de partida registra DTO do vencedor na TelaFinal"
	)
	var tela_final: TelaFinal = CENA_TELA_FINAL.instantiate() as TelaFinal
	root.add_child(tela_final)
	await _quadros(2)
	_verificar(
		tela_final != null
		and tela_final.rotulo_vencedor.text == "VENCEDOR"
		and tela_final.sprite_brasao.texture != null
		and tela_final.confete_esquerdo.emitting
		and tela_final.confete_direito.emitting
		and tela_final.confete_central.emitting,
		"TelaFinal instancia trofeu com brasao do vencedor, texto VENCEDOR e estouro de confete"
	)
	tela_final.queue_free()
	await process_frame


func _testar_pausa_abandono_e_reinicio() -> void:
	partida.duracao_apresentacao_gol = 0.12
	partida.definir_semente(707)
	partida.reiniciar_partida()
	await _quadros(2)

	# Pausa durante mira cancela arrasto sem gastar turno e exibe o modal Pause.
	_verificar(partida.menu_pause != null and not partida.menu_pause.visible, "Modal Pause inicia oculto")
	var equipe_turno: Prego.Equipe = partida.obter_time_atual()
	mira.arrastando = true
	partida._on_mira_iniciada()
	partida.hub.pausa_solicitada.emit()
	_verificar(
		paused
		and partida.menu_pause.visible
		and not mira.arrastando
		and partida.obter_estado() == MainGame.Estado.AGUARDANDO_JOGADA,
		"Pausa via Hub cancela mira sem gastar turno e exibe modal Pause"
	)
	partida.menu_pause.botao_continuar.grab_focus()
	partida.menu_pause._on_botao_mouse_entered(partida.menu_pause.botao_reiniciar)
	_verificar(
		not partida.menu_pause.botao_continuar.has_focus()
		and partida.menu_pause.botao_reiniciar.has_focus(),
		"Selecao com mouse move foco/coloracao do Continuar para o botao sob o cursor"
	)
	partida.menu_pause._on_botao_continuar_pressed()
	_verificar(
		not paused
		and not partida.menu_pause.visible
		and partida.obter_time_atual() == equipe_turno,
		"Continuar pelo modal Pause despausa arvore, oculta modal e preserva turno"
	)

	# Pausa durante GOL_ANIMANDO nao retoma cronometro ao despausar.
	moeda.reposicionar(Vector2(1070.0, 139.0))
	await _quadros(2)
	partida._on_lancamento_solicitado(Vector2(550.0, 0.0))
	await _aguardar_estado(MainGame.Estado.GOL_ANIMANDO, 60)
	partida.definir_pausada(true)
	partida.definir_pausada(false)
	_verificar(partida.cronometro.paused, "Despausar arvore durante GOL_ANIMANDO mantem cronometro pausado pelo gol")

	# Reinicio durante GOL_ANIMANDO restaura 0x0, moeda prata e invalida apresentacao anterior.
	partida.reiniciar_partida()
	await _quadros(4)
	_verificar(
		partida.obter_estado() == MainGame.Estado.AGUARDANDO_JOGADA
		and partida.obter_placar() == Vector2i.ZERO
		and not moeda.dourada
		and moeda.visible,
		"Reinicio durante GOL_ANIMANDO restaura estado limpo 0x0"
	)

	# Abandono via botao Sair do Pause durante Gol de Ouro nao emite partida_encerrada.
	partida._on_cronometro_timeout()
	await _quadros(2)
	_verificar(partida.esta_em_gol_de_ouro(), "Em Gol de Ouro antes do abandono")
	var encerramentos_antes: int = encerramentos
	partida.definir_pausada(true)
	_verificar(paused and partida.menu_pause.visible, "Modal Pause abre durante Gol de Ouro")
	partida.menu_pause._on_botao_menu_pressed()
	await _quadros(2)
	_verificar(
		not partida.partida_ativa
		and not paused
		and not partida.menu_pause.visible
		and encerramentos == encerramentos_antes,
		"Abandono via modal Pause encerra sessao sem vencedor ficticio"
	)
	partida.reiniciar_partida()
	await _quadros(2)


func _testar_isolamento_duas_partidas() -> void:
	var segunda_partida: MainGame = CENA_PARTIDA.instantiate() as MainGame
	root.add_child(segunda_partida)
	await _quadros(2)

	partida.reiniciar_partida()
	segunda_partida.reiniciar_partida()
	await _quadros(2)

	# Gol na segunda partida nao pode alterar o placar da primeira partida.
	segunda_partida._on_lancamento_solicitado(Vector2(0.0, -80.0))
	var sensor_segunda: Gol = segunda_partida.get_node("Sensores/GolEsquerdo") as Gol
	sensor_segunda.gol_marcado.emit(Prego.Equipe.CORINTHIANS, segunda_partida.id_jogada_atual)
	await _quadros(2)

	_verificar(partida.obter_placar() == Vector2i.ZERO, "Primeira partida isolada dos sensores da segunda partida")
	_verificar(segunda_partida.obter_placar() == Vector2i(0, 1), "Segunda partida processou apenas seu proprio sensor")

	segunda_partida.queue_free()
	await process_frame


# --- AUXILIARES / SETTERS ---
func _verificar(condicao: bool, descricao: String) -> void:
	verificacoes += 1
	if not condicao:
		falhas += 1
		var info: String = "%s [estado=%d placar=%s tempo=%.2f ouro=%s pos=%s mov=%s hab=%s]" % [
			descricao,
			partida.obter_estado() if partida != null else -1,
			str(partida.obter_placar()) if partida != null else "null",
			partida.obter_tempo_restante() if partida != null else -1.0,
			str(partida.esta_em_gol_de_ouro()) if partida != null else "null",
			str(moeda.global_position) if moeda != null else "null",
			str(moeda.em_movimento) if moeda != null else "null",
			str(mira.habilitada) if mira != null else "null",
		]
		detalhes_falhas.append(info)
		push_error("FALHA [%s]" % info)


func _quadros(quantidade: int) -> void:
	for _indice: int in range(quantidade):
		await physics_frame
		await process_frame


func _aguardar_parada_e_resolucao() -> void:
	for _passo: int in range(180):
		await physics_frame
		await process_frame
		if partida.obter_estado() != MainGame.Estado.MOEDA_EM_MOVIMENTO and not partida.resolucao_agendada:
			break
	await _quadros(2)


func _aguardar_estado(esperado: MainGame.Estado, limite_passos: int) -> void:
	for _passo: int in range(limite_passos):
		if partida.obter_estado() == esperado:
			return
		await physics_frame
		await process_frame


func _on_gol_confirmado(_equipe: Prego.Equipe, _placar: Vector2i) -> void:
	gols_confirmados += 1


func _on_partida_encerrada(vencedor: Prego.Equipe, placar_final: Vector2i, por_gol_de_ouro: bool) -> void:
	encerramentos += 1
	ultimo_vencedor_sinal = vencedor
	ultimo_placar_sinal = placar_final
	ultimo_gol_ouro_sinal = por_gol_de_ouro


func _on_gol_de_ouro_iniciado() -> void:
	inicios_gol_ouro += 1
