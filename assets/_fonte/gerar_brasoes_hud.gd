extends SceneTree

# Reducao offline dos PNGs originais, sem alterar desenho ou proporcao.
# Executar: godot --headless --path . --script res://assets/_fonte/gerar_brasoes_hud.gd
const PASTA_ORIGINAIS: String = "res://assets/ui/times"
const PASTA_DESTINO: String = "res://assets/ui/times/hud"
const TAMANHO_HUD: int = 18


func _initialize() -> void:
	var erro: Error = DirAccess.make_dir_recursive_absolute(PASTA_DESTINO)
	if erro != OK:
		push_error("Nao foi possivel criar a pasta dos brasoes do HUD: %d" % erro)
		quit(1)
		return
	for arquivo: String in DirAccess.get_files_at(PASTA_ORIGINAIS):
		if arquivo.get_extension() != "png":
			continue
		var imagem: Image = Image.new()
		erro = imagem.load_png_from_buffer(FileAccess.get_file_as_bytes(PASTA_ORIGINAIS.path_join(arquivo)))
		if erro != OK or imagem.is_empty():
			push_error("Nao foi possivel ler o brasao original: %s" % arquivo)
			quit(1)
			return
		if imagem.get_width() != imagem.get_height():
			push_error("O brasao precisa ser quadrado para preservar a proporcao: %s" % arquivo)
			quit(1)
			return
		imagem.resize(TAMANHO_HUD, TAMANHO_HUD, Image.INTERPOLATE_LANCZOS)
		erro = imagem.save_png(PASTA_DESTINO.path_join(arquivo))
		if erro != OK:
			push_error("Nao foi possivel gravar o brasao do HUD '%s': %d" % [arquivo, erro])
			quit(1)
			return
	quit(0)
