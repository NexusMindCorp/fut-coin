class_name AudioManager
extends Node

# --- CONSTANTES ---
const BUS_MASTER: StringName = &"Master"
const BUS_SFX: StringName = &"SFX"
const BUS_MUSIC: StringName = &"Music"
const BUS_AMBIENTE: StringName = &"Ambiente"
const BUS_UI: StringName = &"UI"

const VOLUME_MUSICA_PADRAO_DB: float = -4.0
const VOLUME_MUSICA_DUCKING_DB: float = -14.0
const VOLUME_MUSICA_PAUSE_DB: float = -12.0

const CAMINHO_MUSICA_PARTIDA_NORMAL: String = "res://assets/sounds/music/jogo_normal_sound.mp3"
const CAMINHO_MUSICA_GOL_DE_OURO: String = "res://assets/sounds/music/bola_ouro_sound.mp3"
const CAMINHO_SFX_INICIO_PARTIDA: String = "res://assets/sounds/sfx/start_sound.mp3"
const CAMINHO_SFX_GOL: String = "res://assets/sounds/sfx/gol_sound.mp3"
const CAMINHO_SFX_VITORIA: String = "res://assets/sounds/sfx/vitoria_sound.mp3"
const CAMINHO_SFX_FOGOS: String = "res://assets/sounds/sfx/fogos_artificios.mp3"

# --- PARAMETROS CONFIGURAVEIS ---
@export_group("Streams Ativos")
@export var musica_partida_normal: AudioStream = null
@export var musica_gol_de_ouro: AudioStream = null
@export var sfx_inicio_partida: AudioStream = null
@export var sfx_gol: AudioStream = null
@export var sfx_vitoria_trofeu: AudioStream = null
@export var sfx_fogos_artificio: AudioStream = null
@export_group("Streams Opcionais Pendentes")
@export var musica_menu: AudioStream = null
@export var som_ambiente_torcida: AudioStream = null
@export var sfx_apito_final: AudioStream = null

# --- ESTADO ---
static var instancia: AudioManager = null

var player_musica: AudioStreamPlayer
var player_ambiente: AudioStreamPlayer
var player_sfx_evento: AudioStreamPlayer
var player_fogos: AudioStreamPlayer
var tween_ducking: Tween
var arvore_estava_pausada: bool = false
var sfx_mutado_antes_pause: bool = false
var ambiente_mutado_antes_pause: bool = false


# --- INICIALIZACAO E LOOP DE FISICA/PROCESSAMENTO ---
func _ready() -> void:
	instancia = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	_garantir_barramentos()
	_carregar_streams_padrao()
	_criar_players()


func _exit_tree() -> void:
	if tween_ducking != null and tween_ducking.is_valid():
		tween_ducking.kill()
	for player: AudioStreamPlayer in [player_musica, player_ambiente, player_sfx_evento, player_fogos]:
		if player != null:
			player.stop()
			player.stream = null
	musica_partida_normal = null
	musica_gol_de_ouro = null
	sfx_inicio_partida = null
	sfx_gol = null
	sfx_vitoria_trofeu = null
	sfx_fogos_artificio = null
	musica_menu = null
	som_ambiente_torcida = null
	sfx_apito_final = null
	if instancia == self:
		instancia = null


func _process(_delta: float) -> void:
	_sincronizar_estado_pausa_imediato()


# --- DOMINIO PRINCIPAL / PROCESSADORES DE ESTADO ---
func _sincronizar_estado_pausa_imediato() -> void:
	if not is_inside_tree():
		return
	var pausado_agora: bool = get_tree().paused
	if pausado_agora != arvore_estava_pausada:
		arvore_estava_pausada = pausado_agora
		_aplicar_estado_pausa_audio(pausado_agora)


func _aplicar_estado_pausa_audio(pausado: bool) -> void:
	var idx_sfx: int = AudioServer.get_bus_index(BUS_SFX)
	var idx_amb: int = AudioServer.get_bus_index(BUS_AMBIENTE)
	if pausado:
		if idx_sfx >= 0:
			sfx_mutado_antes_pause = AudioServer.is_bus_mute(idx_sfx)
			AudioServer.set_bus_mute(idx_sfx, true)
		if idx_amb >= 0:
			ambiente_mutado_antes_pause = AudioServer.is_bus_mute(idx_amb)
			AudioServer.set_bus_mute(idx_amb, true)
		_animar_volume_musica(VOLUME_MUSICA_PAUSE_DB, 0.15)
	else:
		if idx_sfx >= 0:
			AudioServer.set_bus_mute(idx_sfx, sfx_mutado_antes_pause)
		if idx_amb >= 0:
			AudioServer.set_bus_mute(idx_amb, ambiente_mutado_antes_pause)
		_animar_volume_musica(VOLUME_MUSICA_PADRAO_DB, 0.2)


# --- API PUBLICA ---
static func tocar_inicio_partida() -> void:
	if instancia == null:
		return
	instancia._sincronizar_estado_pausa_imediato()
	instancia._cancelar_tween_ducking()
	instancia.parar_fogos()
	instancia.executar_sfx_evento(instancia.sfx_inicio_partida)
	instancia.executar_musica(instancia.musica_partida_normal, true)
	if instancia.som_ambiente_torcida != null:
		instancia.executar_ambiente(instancia.som_ambiente_torcida, true)


static func tocar_gol_de_ouro() -> void:
	if instancia == null:
		return
	instancia._sincronizar_estado_pausa_imediato()
	instancia._cancelar_tween_ducking()
	instancia.parar_fogos()
	instancia.executar_sfx_evento(instancia.sfx_inicio_partida)
	instancia.executar_musica(instancia.musica_gol_de_ouro, true)


static func tocar_gol() -> void:
	if instancia == null:
		return
	instancia._sincronizar_estado_pausa_imediato()
	instancia.executar_sfx_evento(instancia.sfx_gol)
	instancia.aplicar_ducking_temporario(VOLUME_MUSICA_DUCKING_DB, 1.1)


static func tocar_fim_partida() -> void:
	if instancia == null:
		return
	instancia.parar_ambiente()
	if instancia.sfx_apito_final != null:
		instancia.executar_sfx_evento(instancia.sfx_apito_final)


static func tocar_tela_vitoria() -> void:
	if instancia == null:
		return
	instancia._sincronizar_estado_pausa_imediato()
	instancia._cancelar_tween_ducking()
	instancia.parar_ambiente()
	instancia.parar_musica()
	if instancia.sfx_vitoria_trofeu != null:
		instancia.executar_sfx_evento(instancia.sfx_vitoria_trofeu)
	if instancia.sfx_fogos_artificio != null:
		instancia.executar_fogos(instancia.sfx_fogos_artificio)


static func tocar_musica_menu() -> void:
	if instancia == null:
		return
	instancia.parar_fogos()
	if instancia.musica_menu != null:
		instancia.executar_musica(instancia.musica_menu)
	else:
		instancia.parar_musica()


static func parar_audio_partida() -> void:
	if instancia == null:
		return
	if instancia.player_sfx_evento != null:
		instancia.player_sfx_evento.stop()
	instancia.parar_fogos()
	instancia.parar_ambiente()
	instancia.parar_musica()


func executar_musica(stream: AudioStream, reiniciar_se_igual: bool = false) -> void:
	if player_musica == null:
		return
	if stream == null:
		player_musica.stop()
		player_musica.stream = null
		return
	if player_musica.stream == stream and player_musica.playing and not reiniciar_se_igual:
		return
	player_musica.stop()
	player_musica.stream = stream
	player_musica.volume_db = VOLUME_MUSICA_PADRAO_DB
	if DisplayServer.get_name() != "headless":
		player_musica.play(0.0)


func parar_musica() -> void:
	if player_musica != null:
		player_musica.stop()


func executar_ambiente(stream: AudioStream, reiniciar_se_igual: bool = false) -> void:
	if player_ambiente == null or stream == null:
		return
	if player_ambiente.stream == stream and player_ambiente.playing and not reiniciar_se_igual:
		return
	player_ambiente.stop()
	player_ambiente.stream = stream
	if DisplayServer.get_name() != "headless":
		player_ambiente.play(0.0)


func parar_ambiente() -> void:
	if player_ambiente != null:
		player_ambiente.stop()


func executar_sfx_evento(stream: AudioStream, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if player_sfx_evento == null or stream == null:
		return
	player_sfx_evento.stop()
	player_sfx_evento.stream = stream
	player_sfx_evento.pitch_scale = pitch
	player_sfx_evento.volume_db = volume_db
	if DisplayServer.get_name() != "headless":
		player_sfx_evento.play(0.0)


func executar_fogos(stream: AudioStream, volume_db: float = -2.0) -> void:
	if player_fogos == null or stream == null:
		return
	player_fogos.stop()
	player_fogos.stream = stream
	player_fogos.volume_db = volume_db
	if DisplayServer.get_name() != "headless":
		player_fogos.play(0.0)


func parar_fogos() -> void:
	if player_fogos != null:
		player_fogos.stop()


func aplicar_ducking_temporario(volume_alvo_db: float, duracao: float) -> void:
	if player_musica == null or not player_musica.playing:
		return
	_cancelar_tween_ducking()
	tween_ducking = create_tween()
	tween_ducking.tween_property(player_musica, "volume_db", volume_alvo_db, 0.1)
	tween_ducking.tween_interval(maxf(duracao - 0.35, 0.05))
	tween_ducking.tween_property(player_musica, "volume_db", VOLUME_MUSICA_PADRAO_DB, 0.25)


# --- AUXILIARES / SETTERS ---
func _cancelar_tween_ducking() -> void:
	if tween_ducking != null and tween_ducking.is_valid():
		tween_ducking.kill()
func _garantir_barramentos() -> void:
	for nome_bus: StringName in [BUS_SFX, BUS_MUSIC, BUS_AMBIENTE, BUS_UI]:
		if AudioServer.get_bus_index(nome_bus) == -1:
			var novo_idx: int = AudioServer.bus_count
			AudioServer.add_bus(novo_idx)
			AudioServer.set_bus_name(novo_idx, String(nome_bus))
			AudioServer.set_bus_send(novo_idx, BUS_MASTER)


func _carregar_streams_padrao() -> void:
	if musica_partida_normal == null:
		musica_partida_normal = load(CAMINHO_MUSICA_PARTIDA_NORMAL) as AudioStream
	if musica_gol_de_ouro == null:
		musica_gol_de_ouro = load(CAMINHO_MUSICA_GOL_DE_OURO) as AudioStream
	if sfx_inicio_partida == null:
		sfx_inicio_partida = load(CAMINHO_SFX_INICIO_PARTIDA) as AudioStream
	if sfx_gol == null:
		sfx_gol = load(CAMINHO_SFX_GOL) as AudioStream
	if sfx_vitoria_trofeu == null:
		sfx_vitoria_trofeu = load(CAMINHO_SFX_VITORIA) as AudioStream
	if sfx_fogos_artificio == null:
		sfx_fogos_artificio = load(CAMINHO_SFX_FOGOS) as AudioStream
	var mp3_normal: AudioStreamMP3 = musica_partida_normal as AudioStreamMP3
	if mp3_normal != null:
		mp3_normal.loop = true
	var mp3_ouro: AudioStreamMP3 = musica_gol_de_ouro as AudioStreamMP3
	if mp3_ouro != null:
		mp3_ouro.loop = true
	var mp3_fogos: AudioStreamMP3 = sfx_fogos_artificio as AudioStreamMP3
	if mp3_fogos != null:
		mp3_fogos.loop = true


func _criar_players() -> void:
	player_musica = AudioStreamPlayer.new()
	player_musica.name = "PlayerMusica"
	player_musica.bus = BUS_MUSIC
	player_musica.volume_db = VOLUME_MUSICA_PADRAO_DB
	add_child(player_musica)

	player_ambiente = AudioStreamPlayer.new()
	player_ambiente.name = "PlayerAmbiente"
	player_ambiente.bus = BUS_AMBIENTE
	player_ambiente.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(player_ambiente)

	player_sfx_evento = AudioStreamPlayer.new()
	player_sfx_evento.name = "PlayerSfxEvento"
	player_sfx_evento.bus = BUS_SFX
	player_sfx_evento.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(player_sfx_evento)

	player_fogos = AudioStreamPlayer.new()
	player_fogos.name = "PlayerFogos"
	player_fogos.bus = BUS_SFX
	player_fogos.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(player_fogos)


func _animar_volume_musica(volume_alvo_db: float, duracao: float) -> void:
	if player_musica == null:
		return
	if tween_ducking != null and tween_ducking.is_valid():
		tween_ducking.kill()
	tween_ducking = create_tween()
	tween_ducking.tween_property(player_musica, "volume_db", volume_alvo_db, duracao)
