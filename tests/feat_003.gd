extends SceneTree

# --- CONSTANTES ---
const PREVIA: PackedScene = preload("res://scenes/levels/previa_moeda.tscn")

# --- ESTADO ---
var falhas: int = 0
var verificacoes: int = 0
var paradas: int = 0
var lancamentos: int = 0
var previa: Node2D
var moeda: Moeda
var mira: Mira


# --- INICIALIZACAO E LOOP DE FISICA/PROCESSAMENTO ---
func _initialize() -> void:
	_executar.call_deferred()


# --- DOMINIO PRINCIPAL ---
func _executar() -> void:
	previa = PREVIA.instantiate() as Node2D
	root.add_child(previa)
	moeda = previa.get_node("Moeda") as Moeda
	mira = previa.get_node("Mira") as Mira
	moeda.parou.connect(_on_parou)
	moeda.lancada.connect(_on_lancada)
	await _quadros(3)
	_verificar(paradas == 0 and moeda.esta_parada(), "Repouso inicial sem sinal")
	_testar_matematica()
	await _testar_contatos()
	await _testar_movimento()
	await _testar_sleep()
	await _testar_entrada()
	await _testar_trajetorias()
	await _testar_camera()
	await _testar_selecao_borda()
	previa.queue_free()
	await process_frame
	var resultado: String = "FEAT-003: %d verificacoes; %d falhas" % [verificacoes, falhas]
	var arquivo: FileAccess = FileAccess.open("res://.godot/feat003-testes.txt", FileAccess.WRITE)
	arquivo.store_string(resultado + "\n")
	arquivo.close()
	if falhas > 0:
		push_error(resultado)
	quit(0 if falhas == 0 else 1)


func _testar_matematica() -> void:
	for indice: int in range(16):
		var direcao: Vector2 = Vector2.RIGHT.rotated(TAU * float(indice) / 16.0)
		_verificar(Mira.calcular_impulso(direcao * 14.0, 14.0, 96.0, 700.0).is_zero_approx(), "Zona morta")
		_verificar(Mira.calcular_impulso(direcao * 62.0, 14.0, 96.0, 700.0).is_equal_approx(-direcao * 350.0), "Metade da forca e sentido")
		_verificar(Mira.calcular_impulso(direcao * 500.0, 14.0, 96.0, 700.0).is_equal_approx(-direcao * 700.0), "Saturacao")
	_verificar(not moeda.lancar(Vector2.ZERO), "Rejeita impulso zero")
	_verificar(not moeda.lancar(Vector2(INF, 0)), "Rejeita infinito")


func _testar_contatos() -> void:
	var posicoes: Array[Vector2] = [Vector2(576, 46), Vector2(576, 274), Vector2(62, 80), Vector2(1090, 80), Vector2(22, 160), Vector2(1130, 160), Vector2(28, 138), Vector2(28, 182)]
	var saidas: Array[Vector2] = [Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT, Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP]
	for indice: int in range(posicoes.size()):
		await _posicionar(posicoes[indice])
		_verificar(moeda.lancar(-saidas[indice] * moeda.impulso_maximo), "Contato permite tiro contra parede %d" % indice)
		var retornou: bool = false
		for quadro: int in range(6):
			await _quadros(1)
			retornou = retornou or moeda.linear_velocity.dot(saidas[indice]) > 0.0
		_verificar(retornou, "Ricochete retorna ao campo %d" % indice)
	await _posicionar(Vector2(62, 46))
	_verificar(moeda.lancar(Vector2(-1, -1).normalized() * moeda.impulso_maximo), "Canto permite tiro contra paredes")
	await _quadros(12)
	_verificar(moeda.linear_velocity.x > 0.0 and moeda.linear_velocity.y > 0.0, "Canto devolve moeda ao campo")


func _testar_movimento() -> void:
	await _posicionar(Vector2(576, 160))
	var anteriores: int = paradas
	_verificar(moeda.lancar(Vector2(250, 0)), "Lanca parado")
	_verificar(not moeda.lancar(Vector2(250, 0)), "Bloqueia lancamento duplo")
	await _quadros(3)
	_verificar(moeda.global_position.x > 576.0, "Impulso move moeda")
	_verificar(not mira.habilitada or not moeda.esta_parada(), "Movimento bloqueia nova mira")
	await _aguardar_parada()
	_verificar(paradas == anteriores + 1 and moeda.esta_parada(), "Uma parada ao terminar")
	await _quadros(30)
	_verificar(paradas == anteriores + 1, "Parada nao se repete")
	_verificar(mira.habilitada, "Previa libera mira")
	mira.arrastando = true
	mira._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_verificar(not mira.arrastando, "Perda de foco cancela")
	mira.arrastando = true
	mira.definir_habilitada(false)
	_verificar(not mira.arrastando and not moeda.lancar(Vector2.RIGHT * 100), "Bloqueio externo cancela e impede tiro")
	mira.definir_habilitada(true)
	_verificar(moeda.lancar(Vector2.RIGHT * 100), "Novo tiro apos repouso")
	moeda.reposicionar(Vector2(576, 160))
	await _quadros(3)
	_verificar(paradas == anteriores + 1 and moeda.esta_parada(), "Reposicionar cancela sem concluir tiro")


func _testar_sleep() -> void:
	await _posicionar(Vector2(576, 160))
	var anteriores: int = paradas
	moeda.lancar(Vector2.RIGHT * 100)
	await _quadros(3)
	moeda.sleeping = true
	await _aguardar_parada()
	_verificar(paradas == anteriores + 1 and moeda.esta_parada(), "Sleep nao trava parada")
	await _posicionar(Vector2(576, 160))
	moeda.lancar(Vector2.RIGHT * 1.0)
	await _quadros(5)
	_verificar(not moeda.tempo_parada.is_stopped(), "Inicia espera abaixo do limiar")
	moeda.apply_central_impulse(Vector2.RIGHT * 100)
	await _quadros(3)
	_verificar(moeda.tempo_parada.is_stopped() and moeda.em_movimento, "Aceleracao reinicia espera")
	await _aguardar_parada()


func _testar_trajetorias() -> void:
	# Alta velocidade e passagem estreita real pelos dois goleiros, sem sensores de gol.
	var inicios: Array[Vector2] = [Vector2(120, 139), Vector2(1032, 139), Vector2(120, 181), Vector2(1032, 181), Vector2(576, 80), Vector2(576, 240), Vector2(104, 160)]
	var impulsos: Array[Vector2] = [Vector2(-800, 0), Vector2(800, 0), Vector2(-800, 0), Vector2(800, 0), Vector2(0, -800), Vector2(0, 800), Vector2(800, 0)]
	for angulo: int in range(16):
		inicios.append(Vector2(576, 160))
		impulsos.append(Vector2.RIGHT.rotated(TAU * float(angulo) / 16.0) * 800.0)
	for indice: int in range(inicios.size()):
		await _posicionar(inicios[indice])
		_verificar(moeda.lancar(impulsos[indice]), "Trajetoria inicia %d" % indice)
		var entrou_rede: bool = false
		for quadro: int in range(360):
			await physics_frame
			var posicao: Vector2 = moeda.global_position
			# Solver discreto pode sobrepor bordas por um tick; centro nao atravessa a face solida.
			_verificar(posicao.x >= 8.0 and posicao.x <= 1144.0 and posicao.y >= 32.0 and posicao.y <= 288.0, "Sem tunelamento %d quadro %d posicao %s" % [indice, quadro, posicao])
			_verificar(moeda.linear_velocity.length() <= moeda.velocidade_maxima + 0.1, "Velocidade limitada")
			if indice < 4 and (posicao.x < 34.0 or posicao.x > 1118.0):
				entrou_rede = true
			if moeda.esta_parada():
				break
		if indice < 4:
			_verificar(entrou_rede, "Passagem do goleiro %d" % indice)
		_verificar(moeda.esta_parada(), "Trajetoria termina %d" % indice)


func _testar_camera() -> void:
	var camera: CameraPartida = previa.get_node("CameraPartida") as CameraPartida
	for indice: int in range(3):
		var posicao: Vector2 = [Vector2(120, 160), Vector2(576, 160), Vector2(1032, 160)][indice]
		await _posicionar(posicao)
		camera.reposicionar()
		await _quadros(3)
		var esperado: Vector2 = Vector2(clampf(posicao.x, 320, 832), 160)
		_verificar(camera.get_screen_center_position().is_equal_approx(esperado), "Camera trava e sincroniza %d" % indice)


func _testar_entrada() -> void:
	# Integra apenas eventos/estado; nao testa pixels, layout ou animacoes.
	await _posicionar(Vector2(576, 160))
	var camera: CameraPartida = previa.get_node("CameraPartida") as CameraPartida
	camera.reposicionar()
	await _quadros(2)
	_enviar_mouse(Vector2(576, 160), true)
	_verificar(mira.arrastando, "Clique na moeda inicia mira")
	_enviar_mouse(Vector2(466, 160))
	await _quadros(2)
	_verificar(mira.impulso_atual.is_equal_approx(Vector2(moeda.impulso_maximo, 0)), "Arrasto global escolhe direcao oposta")
	var anteriores: int = lancamentos
	_enviar_mouse(Vector2(466, 160), false, true)
	_verificar(lancamentos == anteriores + 1 and not mira.habilitada, "Soltura coordena tiro e bloqueia mira")
	await _posicionar(Vector2(576, 160))
	_enviar_mouse(Vector2(550, 160), true)
	_verificar(not mira.arrastando, "Clique fora nao inicia")
	_enviar_mouse(Vector2(550, 160), false, true)
	_enviar_mouse(Vector2(576, 160), true)
	_enviar_mouse(Vector2(576, 160), false, true)
	_verificar(lancamentos == anteriores + 1, "Soltura sem arrasto nao lanca")
	await _posicionar(Vector2(576, 46))
	camera.reposicionar()
	_enviar_mouse(Vector2(576, 46), true)
	_enviar_mouse(Vector2(576, 156))
	await _quadros(2)
	_verificar(mira.impulso_atual.y < 0.0, "Mira aponta contra parede superior")
	_enviar_mouse(Vector2(576, 156), false, true)
	_verificar(lancamentos == anteriores + 2 and not moeda.esta_parada(), "Soltura junto a parede lanca")


func _enviar_mouse(posicao_global: Vector2, pressionar: bool = false, soltar: bool = false) -> void:
	var posicao_tela: Vector2 = root.get_canvas_transform() * posicao_global
	var movimento: InputEventMouseMotion = InputEventMouseMotion.new()
	movimento.position = posicao_tela
	movimento.global_position = posicao_tela
	root.push_input(movimento, true)
	if pressionar or soltar:
		var botao: InputEventMouseButton = InputEventMouseButton.new()
		botao.button_index = MOUSE_BUTTON_LEFT
		botao.position = posicao_tela
		botao.global_position = posicao_tela
		botao.pressed = pressionar
		root.push_input(botao, true)


func _testar_selecao_borda() -> void:
	var camera: CameraPartida = previa.get_node("CameraPartida") as CameraPartida
	for centro: Vector2 in [Vector2(120, 160), Vector2(576, 160), Vector2(1032, 160)]:
		await _posicionar(centro)
		camera.reposicionar()
		for indice: int in range(8):
			var borda: Vector2 = centro + Vector2.RIGHT.rotated(TAU * float(indice) / 8.0) * 15.9
			_enviar_mouse(borda, true)
			_verificar(mira.arrastando, "Borda selecionavel em %s direcao %d" % [centro, indice])
			mira.cancelar()
			_enviar_mouse(borda, false, true)
		_enviar_mouse(centro + Vector2(17, 0), true)
		_verificar(not mira.arrastando, "Fora da margem continua rejeitado")
		_enviar_mouse(centro + Vector2(17, 0), false, true)
	# Selecao durante smoothing residual, com transformacao real do canvas.
	moeda.reposicionar(Vector2(576, 160))
	mira.definir_habilitada(true)
	await _quadros(2)
	_enviar_mouse(moeda.global_position, true)
	_verificar(mira.arrastando, "Centro selecionavel durante suavizacao")
	mira.cancelar()
	_enviar_mouse(moeda.global_position, false, true)


# --- AUXILIARES / SETTERS ---
func _posicionar(posicao: Vector2) -> void:
	moeda.reposicionar(posicao)
	mira.definir_habilitada(true)
	await _quadros(3)


func _aguardar_parada() -> void:
	for quadro: int in range(420):
		await physics_frame
		if moeda.esta_parada():
			return
	_verificar(false, "Parada dentro de sete segundos")


func _quadros(quantidade: int) -> void:
	for indice: int in range(quantidade):
		await physics_frame


func _verificar(condicao: bool, descricao: String) -> void:
	verificacoes += 1
	if not condicao:
		falhas += 1
		push_error(descricao)


func _on_parou() -> void:
	paradas += 1


func _on_lancada(_impulso: Vector2) -> void:
	lancamentos += 1
