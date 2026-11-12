# FutCoin: Documento de Requisitos e Contexto

> Contexto atualizado em 11/11/2026 conforme ADR-001 e decisões posteriores das FEAT-004 a 008. Partida, seleção dos nove clubes, fluxo de menus e áudio implementados; permanecem polimento/balanceamento de áudio (M4), confirmações de atribuição e export/teste Linux (M5). A suíte 004 foi revalidada com 127 verificações sem falhas; não foi reexecutada nesta revisão documental. Itens **[A DEFINIR]** continuam abertos. O enunciado original permanece em `Trabalho 2 - 2026.3.md`.

---

## 1. Visão geral

- **Nome:** FutCoin
- **Gênero:** futebol de moeda (inspirado no "futebol de prego" / jogo de botão), por turnos, 2 jogadores locais.
- **Perspectiva:** 2D com visão de cima (top-down). O campo fica na horizontal.
- **Estilo artístico:** **16 bits** (pixel art), sempre.
- **Engine:** Godot 4.x (2D).
- **Plataforma de entrega:** executável para **Linux** (pasta `build/` no repositório do GitHub).
- **Grupo:** até 4 pessoas. **Prazo de entrega: 20/11/2026.**
- **Assets:** podem ser próprios ou de terceiros, com crédito. Os **brasões dos times foram feitos por um artista externo** e precisam constar nos créditos.

---

## 2. Requisitos obrigatórios do Trabalho 2 (checklist)

| Requisito do trabalho | Como o FutCoin atende |
|---|---|
| Tela inicial com opção de iniciar o jogo | Menu principal com Jogar, Créditos e Sair |
| Animação de sprites e tiles | Animações da moeda/pregos e tiles animados do campo em `TileMapLayer`; ambos precisam funcionar nas cenas, não apenas existir como imagens |
| Animação geral sem sprites | Tweens: seta de força, placar pulsando ao gol, transições de tela, tremor de câmera |
| Colisão (Godot ou manual) | Moeda × paredes × pregos (física) e sensores nos gols |
| Áudio e HUD | Música, SFX (batida, gol, apito) e placar/cronômetro |
| Câmera não estática | Câmera segue a moeda no eixo horizontal, com travas nas extremidades |
| Objetivo a ser alcançado | Vencer a partida fazendo mais gols que o adversário (empate resolvido por gol de ouro) |
| Tela de créditos | Tela de créditos com o grupo e as fontes de assets |

**Critérios de avaliação a considerar:** atendimento aos requisitos mínimos, execução correta do projeto, **qualidade do código** e entrega no prazo. Cada membro será avaliado individualmente e precisa dominar todo o código, então o projeto deve ser **simples de ler, bem organizado e comentado**.

---

## 3. Regras do jogo

### 3.1 Modo de jogo
- Protótipo para **2 jogadores locais**, no mesmo computador, ambos usando o **mouse**.
- **Turnos alternados:** em cada turno, um jogador (um time) joga a moeda.
- A moeda é uma só, compartilhada, e é a "bola" do jogo.
- O jogador só pode lançar quando a moeda estiver **totalmente parada**. Usar um limiar de velocidade com um pequeno atraso, para evitar o estado "quase parada".
- Enquanto a moeda está em movimento, a câmera a acompanha. Quando ela para, o controle é liberado ao próximo jogador.

### 3.2 Mecânica de lançamento
- Estilo "estilingue": o jogador **clica e arrasta** o mouse, simulando puxar a moeda para trás, e uma **seta** indica **direção e força**. Ao soltar, a moeda é lançada.
- Direção livre em **360°**.
- **Parede em contato (esclarecimento em 09/11/2026):** bloquear lançamento contra a parede já encostada, evitando ricochete imediato; permitir saída para o campo ou tangente. Sem contato, permitir ricochetes normais. Considerar direção de lançamento, oposta à puxada, conforme FEAT-003.
- A seta aponta para onde a moeda será lançada. Força cresce com a puxada para fora da moeda e retorna a zero ao voltar à moeda.
- Valores de força mínima, máxima e escala do arrasto devem ser **configuráveis** (`@export`).

### 3.3 Duração e fim de partida
- Duração aprovada: **5 minutos (300 segundos)** na cena `main_game.tscn`, no padrão exportado do script e no Timer do cronômetro. A propriedade continua exportada para testes e ajustes explícitos.
- O cronômetro deve pausar durante a animação de gol e durante o pause.
- Encerramento aprovado em 12/11: bloquear novas jogadas, concluir comemoração quando houver, aguardar pausa de 0,25 s e tocar o apito final completo antes da tela de resultado. Ausência/interrupção de áudio não pode impedir a transição.
- **Empate:** não existe empate final. Se o tempo acabar com o placar igual, entra o **gol de ouro**:
  - A moeda troca para um **sprite dourado especial**.
  - O **próximo gol encerra a partida**, e quem marcar vence.
  - A tela final mostra o resultado normalmente.
  - Obrigatório, sem configuração de desativação e sem novo limite de tempo; a partida só tem conclusão esportiva após o primeiro gol dessa fase. Pausar, voltar ao menu e sair do aplicativo continuam disponíveis; abandonar não declara vencedor ou empate final.
- **Tempo esgotado com a moeda em movimento:** o jogo **espera a moeda parar totalmente** antes de contabilizar o resultado final. Se a moeda entrar no gol durante essa espera, o gol **conta normalmente**. Só depois que a moeda parar (ou após um gol) o placar é verificado: se houver diferença, a partida termina; se estiver empatado, entra o gol de ouro.

### 3.4 Gols
- Cada gol tem um **sensor** (`Area2D`) para detectar a moeda.
- Para evitar gols falsos pela borda, o gol só conta quando a moeda estiver **inteiramente dentro** (ou depois de passar totalmente da linha).
- Ao marcar: a moeda é **escondida**, toca a **animação de gol** (com SFX), o placar é atualizado e a jogada é reiniciada.
- Apresentação aprovada: **2,2 segundos**, com brasão, nome e placar em linhas próprias, torcida curta e redução temporária da música. Saídas de início, pós-gol e Gol de Ouro usam o apito anterior aprovado; trocas comuns de turno não tocam apito.
- Alinhamento em 10/11: ocultar também indicador ativo/mira e bloquear novos tiros durante `GOL_ANIMANDO`; restaurar no reinício. Detecção/coordenação na FEAT-004 e apresentação/áudio integrados na FEAT-005/M4.

### 3.5 Início de partida e reinício após gol
- **Início da partida:** o time que começa com a moeda é escolhido de forma **aleatória**.
- **Após um gol:** a moeda volta ao **centro do campo** e **quem sofreu o gol começa jogando**.
- **Gol de ouro:** moeda no centro e **novo sorteio independente** para definir quem começa, inclusive no empate em 0×0 (confirmado em 10/11/2026).

---

## 4. Campo e pregos

- Campo na **horizontal**, **fechado por paredes** (a moeda bate e quica).
- **11 pregos de cada lado (22 no total)**, com **colisão** (`StaticBody2D`).
- Visão de cima: o jogador enxerga apenas a **cabeça dos pregos**.
- Formação padrão de futebol de prego, **4-4-2**:
  - **2 zagueiros** e **2 laterais mais avançados** (4 na defesa).
  - **4 meias em losango** na região central.
  - **2 atacantes**, lado a lado e **bem afastados** entre si.
  - Como 4+4+2 somam 10, o **11º prego é o goleiro** (confirmado).
- O outro lado do campo é o **espelho** da formação.
- Sugestão inicial de layout de um lado (posição vertical em % da altura do campo, do gol para o ataque):

| Linha | Pregos | Posição vertical |
|---|---|---|
| Goleiro | 1 | 50% |
| Zagueiros | 2 | 35% e 65% |
| Laterais (mais avançados) | 2 | 12% e 88% |
| Losango: volante | 1 | 50% |
| Losango: meias laterais | 2 | 28% e 72% |
| Losango: meia ofensivo | 1 | 50% |
| Atacantes | 2 | 30% e 70% |

- As posições devem ser **ajustáveis no editor**. O espaço entre pregos precisa ser **maior que o diâmetro da moeda, com folga**, para a moeda nunca ficar presa.

---

## 5. Câmera

- `Camera2D` que **segue a moeda apenas no eixo horizontal**.
- O eixo vertical fica **fixo**, mostrando o **campo inteiro na vertical**.
- Ao se aproximar dos gols, a câmera **para de seguir** e **trava nas extremidades** do campo (ex.: `limit_left` / `limit_right`).
- Seguimento com suavização, **sem tremores** em pixel art (atenção ao jitter de subpixel).
- O campo deve ser maior que a tela na horizontal (algo entre 1,5× e 2× a largura da tela).

---

## 6. HUD

Planejamento detalhado de interface/fluxo/áudio na [FEAT-005](../.agent/features/feat-005-interface-fluxo-audio.md), integrado à partida, com refinamentos FEAT-006 a 010. Aprovado em 10/11: preservar banner de 44 px e recortar apenas 4 px decorativos do campo, mantendo toda a área jogável; versus manual com Começar partida e Voltar. Em 12/11 foram aprovados botões e textos uniformizados, preservando estrutura, fonte e layout. Composição implementada e registrada nas specs correspondentes.

- Reservar faixa **superior** para placar/cronômetro, reutilizando `scenes/ui/hub/hub.tscn` adaptado a 640×360. HUD fixo na tela, sem cobrir o campo jogável ou consumir cliques destinados à moeda. Ajustar composição e câmera em conjunto: os 20 px atuais de margem não comportam automaticamente o banner de 44 px.

- **Placar no estilo futebol**, contendo:
  - **Brasões** dos dois times.
  - **Gols** de cada time.
  - **Cronômetro** da partida.
- Sugestão: **indicador de vez**, destacando o time que joga no turno.
- A **seta de mira** (direção e força) faz parte da interface de jogo.
- Borda pulsante rente à moeda indica a vez com a cor do clube selecionado, consultada em `DadosTimes`; a prévia isolada pode usar cores de demonstração. Seta aprovada em três faixas de força: amarela até 1/3, laranja até 2/3, vermelha acima; bloqueio cinza com X. Comprimento e direção continuam indicando força e lançamento.

---

## 7. Telas e fluxo

1. **Menu principal:** Jogar, **Créditos** e Sair.
2. **Tela versus:** permite selecionar entre nove clubes, sem repetir o mesmo nos dois lados; Corinthians e Flamengo são os padrões iniciais. Botões **Começar partida** e **Voltar** ao menu; sem avanço automático. Seleção e catálogo centralizados em DadosTimes.
3. **Partida (Main Game):** todo o gameplay descrito acima, com **sistema de pause**.
4. **Tela final:** resultado da partida (incluindo vitória por gol de ouro) com as opções:
   - **Reiniciar** a partida
   - **Voltar ao menu**
   - (Sugestão) botão de **Créditos**
5. **Créditos:** acessível pelo menu principal (e opcionalmente pela tela final). A mesma cena pode ser reaproveitada nos dois lugares. Deve conter:
   - Integrantes do grupo e suas funções
   - **Artista dos brasões: `_EasilyImpressed`**, com prova de autorização em `image.png`; conferir condições de uso e atribuição antes da entrega.
   - Demais fontes de assets (música, SFX, fontes tipográficas, etc.)

### Pause
- Sistema de pause durante a partida (congelar física, cronômetro e animações de jogo), com opções como continuar, reiniciar e voltar ao menu.
- Decisão aprovada: pausa pelo `SceneTree`, menu ativo durante a pausa e opções Continuar, Reiniciar e Menu. Não é um estado adicional da máquina da partida.

---

## 8. Direção de arte e resolução

- **Estilo:** pixel art **16 bits**, em todos os elementos (campo, pregos, moeda, HUD, menus, brasões).
- **Resolução base aprovada: 640×360 (16:9)**, com **escala inteira** (×2 = 1280×720, ×3 = 1920×1080), conforme ADR-001.

### Configuração sugerida na Godot
- Stretch Mode `viewport`, Aspect `keep`, Scale Mode `integer`.
- Filtro de textura padrão `Nearest`.
- Janela de desenvolvimento em 1280×720 (escala ×2); preservar escala inteira em outros tamanhos.
- Ativar o *snap 2D transforms to pixel* e verificar se a câmera não gera jitter.

### Tamanhos dos assets processados (FEAT-001)
- Campo: 1152×320 px; composição com HUD e paredes a conferir no M1/M3.
- Moeda: 28×28 px; giro/brilho por quadros, sem rotação física.
- Cabeça dos pregos: 12×12 px.
- Brasões: 48×48 px; banner: 320×44 px; tela versus: 640×360 px.

> A análise dos originais e o processamento estão registrados na FEAT-001 e em `.docs/planejamento.md`. Espaçamento estático foi conferido na FEAT-002; FEAT-003 conferiu passagens dinâmicas, legibilidade da moeda e aura na prévia. Dificuldade e balanceamento continuam sujeitos a feedback.

---

## 9. Recomendações técnicas (Godot)

- **Moeda:** `RigidBody2D` com material de física (bounce/fricção) e `linear_damp` para frear naturalmente. Ativar `continuous_cd` e limitar a velocidade máxima para evitar **tunelamento** através de pregos e paredes.
- **Pregos e paredes:** `StaticBody2D` com colisão.
- **Gols:** `Area2D` posicionada atrás da linha do gol.
- **Estados do jogo:** aguardando jogada, mirando, moeda em movimento, gol animando e fim de partida. Pause pertence ao `SceneTree`; gol de ouro é uma flag, conforme ADR-001.
- **Configurações em variáveis exportadas (`@export`):** duração da partida, força máxima, zona morta/escala do arrasto (força mínima zero), amortecimento e tolerância de contato com paredes. Gol de ouro é regra obrigatória e não possui controle de desativação.
- **Organização:** cenas separadas para menu, versus, partida (`main_game`), pause, tela final, créditos, moeda, prego, gol e HUD. Seguir ADR-001, sem `TelaBase` ou `TimeDados` como Resource. Código legível e comentado, pois cada integrante será questionado sobre ele.
- **Exportação:** exportar e testar o executável **Linux** desde cedo (não só no dia da entrega), e deixá-lo na pasta `build/` do repositório (**público** no GitHub).

---

## 10. Escopo e prioridades (prazo: 20/11/2026)

**Essencial (MVP):**
1. Menu principal, versus com seleção dos nove clubes, partida, tela final e créditos
2. Moeda com lançamento por arrasto e física (paredes e pregos)
3. Turnos entre 2 jogadores locais, com liberação só com a moeda parada
4. Gols com sensor, animação de gol e placar
5. Câmera horizontal com travas
6. Cronômetro e **gol de ouro** em caso de empate
7. Pause, áudio básico e HUD

**Desejável (se sobrar tempo):**
- Efeitos extras (tremor de câmera, brilho nos pregos, partículas)
- Mais clubes além dos nove disponíveis (seleção já implementada)
- Ajustes de balanceamento (força, atrito, duração)

**Fora do escopo do protótipo:** jogador contra CPU, multiplayer online, mais de 2 jogadores simultâneos.

---

## 11. Pendências de entrega em 12/11/2026

1. Exportar e testar no Linux alvo; preset, renderer e executável sujeitos à conferência nesse ambiente.
2. Fechar mapeamento individual dos áudios antigos, demais origens pendentes de assets e funções dos integrantes, conforme inventário de créditos. Autorização e atribuição dos brasões já registradas.
3. Conferir checklist acadêmico e documentação final de entrega. Pause, seleção de nove clubes e refinamentos FEAT-009/010 já implementados e aprovados.

## Atualizações de apresentação confirmadas em 11/11/2026

O Hub usa reduções Lanczos de 18×18 dos PNGs originais, com escala 1:1 e posições anteriores. Demais telas preservam os brasões de 48×48; créditos originais mantidos. O escudo do clube sem a vez continua escurecido por decisão do usuário. O pause é desenhado acima de todo o HUD (`z_index = 2`), inclusive os emblemas. DadosTimes centraliza catálogo, cores e seleção estática; a UI não redefine a paleta. Dados de demonstração da TelaFinal foram mantidos por aprovação explícita para a apresentação.
