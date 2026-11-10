class_name AudioMoeda
extends Node

# --- CONSTANTES ---
const BUS_SFX: StringName = &"SFX"
const COOLDOWN_IMPACTO_MS: int = 45
const DURACAO_MAXIMA_IMPACTO: float = 0.97
const VELOCIDADE_MINIMA_IMPACTO: float = 20.0
const VELOCIDADE_REFERENCIA_IMPACTO: float = 420.0
const CAMINHO_SFX_CHUTE_PADRAO: String = "res://assets/sounds/sfx/chute_coin.mp3"
const CAMINHO_SFX_IMPACTO_PREGO_PADRAO: String = "res://assets/sounds/sfx/impacto_prego.mp3"

# --- PARAMETROS CONFIGURAVEIS ---
@export var sfx_chute: AudioStream = null
@export var sfx_impacto_prego: AudioStream = null
@export var sfx_impacto_parede: AudioStream = null
@export var sfx_deslize_mesa: AudioStream = null
@export_range(0.05, 5.0) var duracao_maxima_impacto: float = DURACAO_MAXIMA_IMPACTO

# --- ESTADO ---
var moeda: Moeda
var player_chute: AudioStreamPlayer
var player_impacto: AudioStreamPlayer
var player_deslize: AudioStreamPlayer
var ultimo_impacto_ms: int = -1000
var ultima_contagem_reposicionamento: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


# --- INICIALIZACAO E LOOP DE FISICA/PROCESSAMENTO ---
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	rng.randomize()
	if sfx_chute == null:
		sfx_chute = load(CAMINHO_SFX_CHUTE_PADRAO) as AudioStream
	if sfx_impacto_prego == null:
		sfx_impacto_prego = load(CAMINHO_SFX_IMPACTO_PREGO_PADRAO) as AudioStream
	_criar_players()
	moeda = get_parent() as Moeda
	if moeda != null:
		ultima_contagem_reposicionamento = moeda.contagem_reposicionamento
		if not moeda.lancada.is_connected(_on_moeda_lancada):
			moeda.lancada.connect(_on_moeda_lancada)
		if not moeda.parou.is_connected(_on_moeda_parou):
			moeda.parou.connect(_on_moeda_parou)
		if not moeda.body_entered.is_connected(_on_moeda_body_entered):
			moeda.body_entered.connect(_on_moeda_body_entered)


func _exit_tree() -> void:
	parar_todos_sons()
	for player: AudioStreamPlayer in [player_chute, player_impacto, player_deslize]:
		if player != null:
			player.stream = null
	sfx_chute = null
	sfx_impacto_prego = null
	sfx_impacto_parede = null
	sfx_deslize_mesa = null


func _process(_delta: float) -> void:
	_verificar_corte_impacto_e_reposicionamento()


func _physics_process(_delta: float) -> void:
	_verificar_corte_impacto_e_reposicionamento()
	if player_deslize == null or sfx_deslize_mesa == null or moeda == null:
		return
	if not moeda.visible or not moeda.em_movimento:
		if player_deslize.playing:
			player_deslize.stop()
		return
	var velocidade: float = moeda.linear_velocity.length()
	if velocidade < VELOCIDADE_MINIMA_IMPACTO:
		if player_deslize.playing:
			player_deslize.stop()
		return
	var proporcao: float = clampf(velocidade / VELOCIDADE_REFERENCIA_IMPACTO, 0.08, 1.0)
	player_deslize.volume_db = linear_to_db(proporcao * 0.45)
	player_deslize.pitch_scale = lerpf(0.85, 1.15, proporcao)
	if not player_deslize.playing:
		player_deslize.stream = sfx_deslize_mesa
		if DisplayServer.get_name() != "headless":
			player_deslize.play(0.0)


# --- API PUBLICA ---
func parar_todos_sons() -> void:
	for player: AudioStreamPlayer in [player_chute, player_impacto, player_deslize]:
		if player != null and player.playing:
			player.stop()


# --- AUXILIARES / SETTERS ---
func _verificar_corte_impacto_e_reposicionamento() -> void:
	if moeda != null and moeda.contagem_reposicionamento != ultima_contagem_reposicionamento:
		ultima_contagem_reposicionamento = moeda.contagem_reposicionamento
		parar_todos_sons()
		return
	if player_impacto != null and player_impacto.playing:
		if player_impacto.get_playback_position() >= duracao_maxima_impacto:
			player_impacto.stop()


func _criar_players() -> void:
	player_chute = AudioStreamPlayer.new()
	player_chute.name = "PlayerChute"
	player_chute.bus = BUS_SFX
	add_child(player_chute)

	player_impacto = AudioStreamPlayer.new()
	player_impacto.name = "PlayerImpacto"
	player_impacto.bus = BUS_SFX
	add_child(player_impacto)

	player_deslize = AudioStreamPlayer.new()
	player_deslize.name = "PlayerDeslize"
	player_deslize.bus = BUS_SFX
	add_child(player_deslize)


func _on_moeda_lancada(impulso: Vector2) -> void:
	if player_chute == null or sfx_chute == null or moeda == null:
		return
	var proporcao: float = clampf(impulso.length() / maxf(moeda.impulso_maximo, 1.0), 0.25, 1.0)
	player_chute.stop()
	player_chute.stream = sfx_chute
	player_chute.volume_db = linear_to_db(proporcao)
	player_chute.pitch_scale = rng.randf_range(0.95, 1.05)
	if DisplayServer.get_name() != "headless":
		player_chute.play(0.0)


func _on_moeda_parou() -> void:
	if player_deslize != null and player_deslize.playing:
		player_deslize.stop()


func _on_moeda_body_entered(corpo: Node) -> void:
	if moeda == null or player_impacto == null:
		return
	var agora_ms: int = Time.get_ticks_msec()
	if agora_ms - ultimo_impacto_ms < COOLDOWN_IMPACTO_MS:
		return
	var velocidade: float = moeda.linear_velocity.length()
	if velocidade < VELOCIDADE_MINIMA_IMPACTO:
		return
	var stream_escolhido: AudioStream = null
	if corpo is Prego:
		stream_escolhido = sfx_impacto_prego
	else:
		stream_escolhido = sfx_impacto_parede
	if stream_escolhido == null:
		return
	ultimo_impacto_ms = agora_ms
	var proporcao: float = clampf(velocidade / VELOCIDADE_REFERENCIA_IMPACTO, 0.2, 1.0)
	player_impacto.stop()
	player_impacto.stream = stream_escolhido
	player_impacto.volume_db = linear_to_db(proporcao)
	player_impacto.pitch_scale = rng.randf_range(0.93, 1.07)
	if DisplayServer.get_name() != "headless":
		player_impacto.play(0.0)
