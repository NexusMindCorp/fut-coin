# Pipeline de assets — FEAT-001

Ferramenta de desenvolvimento offline; o jogo exportado não depende de Python ou Pillow. Os 14 PNGs desta pasta são originais preservados. O script reamostra imagens e gera proceduralmente a moeda e os quadros de animação. A pasta é ignorada pelo Godot por meio de `.gdignore`.

## Ambiente

Requer Python 3.10 ou superior e `Pillow==12.3.0`. Ambiente verificado: Python 3.12.4 no Windows. Instale apenas no ambiente virtual local, que está ignorado pelo Git.

PowerShell, a partir da raiz do projeto (use o caminho do Python 3.12 se `python` apontar para uma versão antiga):

```powershell
py -3.12 -m venv assets/_fonte/.venv
& assets/_fonte/.venv/Scripts/python.exe -m pip install -r assets/_fonte/requirements.txt
& assets/_fonte/.venv/Scripts/python.exe assets/_fonte/processar_assets.py --conferir
```

Linux, a partir da raiz:

```sh
python3 -m venv assets/_fonte/.venv
assets/_fonte/.venv/bin/python -m pip install -r assets/_fonte/requirements.txt
assets/_fonte/.venv/bin/python assets/_fonte/processar_assets.py --conferir
```

O download da dependência exige rede na instalação; a geração não usa rede. Execução no Linux ainda não foi verificada.

## Uso

Use o interpretador do ambiente virtual nos comandos abaixo:

```sh
python assets/_fonte/processar_assets.py --conferir
python assets/_fonte/processar_assets.py --saida CAMINHO_PARA_PASTA_DE_REVISAO
python assets/_fonte/processar_assets.py
```

- `--conferir`: gera em diretório temporário, compara dimensões, modo e pixels dos 24 PNGs com `assets/` e remove o temporário ao terminar. Retorna código 1 em caso de divergência ou falha, sem sobrescrever os assets atuais.
- `--saida`: cria a estrutura `sprites/entities`, `levels` e `ui/{hud,menus,times}` na pasta escolhida. Prefira uma pasta fora do projeto para o Godot não importar cópias de revisão. Arquivos de mesmo nome nessa saída serão sobrescritos.
- Sem opções: regenera os PNGs finais em `assets/`, sobrescrevendo os arquivos de mesmo nome. Preserve alterações manuais e revise o diff antes de commitar. `.import` não é escrito ou removido pelo pipeline.
- `--saida` e `--conferir` são mutuamente exclusivos. Saída dentro dos originais ou por PNGs com links é recusada. Pastas de destino ausentes são criadas automaticamente.

O script confere os 14 arquivos fonte antes da geração e compara seus SHA-256 ao final. Isso detecta mudanças durante a execução; não atesta sua identidade com versões históricas. A moeda original é preservada, mas a moeda final é desenhada por código.

## Contrato de entrega

| Saída | Dimensões / quadros |
|:---|:---|
| Campo e atlas | 1152×320 e 128×128, células de 16×16 |
| Moedas estáticas | 28×28 |
| Sheets da moeda | 224×28, oito quadros de 28×28 |
| Pregos estáticos e sheets de impacto | 12×12 e 48×12, quatro quadros |
| Banner, nove brasões e versus | 320×44, 48×48 e 640×360 |

`moeda_dourada_sheet.png` contém brilho dourado; `moeda_dourada_giro_sheet.png` contém giro. O atlas tem 32 recortes estáticos e oito sequências de quatro quadros; mapa das sequências e responsabilidades de integração constam na [FEAT-001](../../.agent/features/feat-001-pipeline-assets.md).

A conferência compara pixels decodificados: compressão PNG pode variar entre ambientes sem mudar a imagem. Na migração de Pillow 9.5.0/zlib 1.2.11 para Pillow 12.3.0/zlib 1.3.1, os 24 PNGs preservaram seus pixels, mas somente seis mantiveram os mesmos bytes. Não são gerados recursos `TileSet`/`SpriteFrames`, colisões ou cenas; sua integração fica nas FEAT-002/003/005. Não há testes automatizados de aparência/UI.

Referência da dependência: [Pillow 12.3.0](https://github.com/python-pillow/Pillow/tree/12.3.0). O pin é uma dependência da ferramenta existente, sem addon ou biblioteca nova no jogo.
