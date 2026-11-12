# Inventário de créditos e atribuições (FutCoin)

Somente entradas verificadas nos registros do projeto (`README.md`, `.docs/planejamento.md`, histórico do Git). Itens sem autoria confirmada **não** são declarados aqui nem na tela de créditos.

| Item | Caminho local | Autor / fonte | Observação |
|:---|:---|:---|:---|
| Brasões dos 9 times | `assets/ui/times/*.png` (originais em `assets/_fonte/`) | `_EasilyImpressed` — reddit.com/r/futebol/comments/1enir7l | Prova de autorização em `image.png` (raiz). Atribuição obrigatória |
| Música e efeitos sonoros existentes | `assets/sounds/**`, exceto `torcida_gol.mp3` | Pixabay: Kim Lightyear, Retro BGM Chan, DRAGON-STUDIO | Links de atribuição no `README.md`. Mapeamento arquivo → autor **pendente de confirmação** |
| Comemoração de torcida no gol | `assets/sounds/sfx/torcida_gol.mp3` | [misjoc — Small crowd cheering / Freesound 400590](https://freesound.org/people/misjoc/sounds/400590/) | [CC0](https://creativecommons.org/publicdomain/zero/1.0/). Derivado de 2,4 s da prévia pública HQ; fade de entrada/saída e limitação de pico. Fonte em `assets/_fonte/audio/torcida_misjoc_400590_hq.mp3` |
| Tela de confronto (versus) | `assets/ui/menus/tela_versus.png` | Gianlucca Paiva | Commit `50b14d3` |
| Motor de jogo | — | Godot Engine 4.7 (MIT) | — |

## Pendências de confirmação

Apito final (FEAT-009/etapa 5): `assets/sounds/sfx/apito_final.mp3` deriva exclusivamente do `start_sound.mp3` já incluído no grupo Pixabay acima; três sopros recortados, sem alteração de pitch. Receita em `assets/_fonte/audio/apito_final.md`. Não é nova fonte externa; mapeamento individual do som original permanece pendente.

Miniaturas Lanczos do Hub (FEAT-008): `assets/ui/times/hud/*.png` são reduções de 18×18 dos PNGs de _EasilyImpressed já creditados acima, sem redesenho. Geradas pela API nativa de imagem da Godot; fonte e atribuição originais preservadas. Não são novos emblemas autorais.

- Funções de cada desenvolvedor e demais integrantes (a tela lista hoje os dois autores presentes no Git: Gianlucca Paiva e Gabriel Lineker).
- Mapeamento de cada `.mp3` (incluindo `menu_sound.mp3`) ao autor do Pixabay.
- Origem/ferramenta da arte restante (campo, moeda, pregos, banner, troféu e arte do menu, esta última gerada por IA e reamostrada pelo pipeline `assets/_fonte/processar_assets.py`).
