class_name Creditos
extends Control

# --- CONSTANTES ---
const CAMINHO_MENU_PRINCIPAL: String = "res://scenes/ui/menu_principal.tscn"
const COR_TITULO: String = "#ffeb47"
const COR_SECAO: String = "#8cc8ff"
const DESENVOLVEDORES: Array[String] = [
	"Gianlucca Paiva",
	"Gabriel Lineker",
]
const SECOES_ATRIBUICAO: Array[Dictionary] = [
	{
		"titulo": "BRASÕES DOS TIMES",
		"linhas": [
			"Arte original por _EasilyImpressed (autorização do autor registrada).",
			"Origem: reddit.com/r/futebol/comments/1enir7l",
		],
	},
	{
		"titulo": "MÚSICA E EFEITOS SONOROS",
		"linhas": [
			"Pixabay: Kim Lightyear, Retro BGM Chan e DRAGON-STUDIO.",
		],
	},
	{
		"titulo": "TELA DE CONFRONTO (VERSUS)",
		"linhas": [
			"Arte por Gianlucca Paiva.",
		],
	},
	{
		"titulo": "MOTOR DE JOGO",
		"linhas": [
			"Godot Engine 4.7 (licença MIT).",
		],
	},
]

# --- REFERENCIAS A NODES ---
@onready var texto_creditos: RichTextLabel = $Painel/Margem/Coluna/Texto
@onready var botao_voltar: Button = $Painel/Margem/Coluna/BotaoVoltar

# --- ESTADO ---
var transicionando: bool = false


# --- INICIALIZACAO E LOOP DE FISICA/PROCESSAMENTO ---
func _ready() -> void:
	AudioManager.tocar_musica_menu()
	if texto_creditos != null:
		texto_creditos.text = montar_texto_creditos()
	if botao_voltar != null:
		botao_voltar.mouse_entered.connect(_focar_botao_voltar)
		botao_voltar.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if transicionando:
		return
	if event.is_action_pressed(&"pausar", false, true) and not event.is_echo():
		get_viewport().set_input_as_handled()
		_on_botao_voltar_pressed()


# --- API PUBLICA ---
static func montar_texto_creditos() -> String:
	var linhas: PackedStringArray = PackedStringArray()
	linhas.append("[center][color=%s][b]CRÉDITOS[/b][/color][/center]" % COR_TITULO)
	linhas.append("")
	linhas.append("[center][color=%s]DESENVOLVEDORES[/color][/center]" % COR_SECAO)
	for nome: String in DESENVOLVEDORES:
		linhas.append("[center]%s[/center]" % nome)
	for secao: Dictionary in SECOES_ATRIBUICAO:
		linhas.append("")
		linhas.append("[center][color=%s]%s[/color][/center]" % [COR_SECAO, str(secao["titulo"])])
		for linha: String in secao["linhas"]:
			linhas.append("[center]%s[/center]" % linha)
	return "\n".join(linhas)


# --- AUXILIARES / SETTERS ---
func _focar_botao_voltar() -> void:
	if not transicionando and botao_voltar != null and not botao_voltar.disabled:
		botao_voltar.grab_focus()


func _on_botao_voltar_pressed() -> void:
	if transicionando:
		return
	transicionando = true
	if botao_voltar != null:
		botao_voltar.disabled = true
	if not is_inside_tree():
		return
	var erro: Error = get_tree().change_scene_to_file(CAMINHO_MENU_PRINCIPAL)
	if erro != OK:
		push_error("Falha ao transicionar para '%s' (erro %d)." % [CAMINHO_MENU_PRINCIPAL, erro])
		transicionando = false
		if botao_voltar != null:
			botao_voltar.disabled = false
			botao_voltar.grab_focus()
