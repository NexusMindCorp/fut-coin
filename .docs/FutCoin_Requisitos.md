# FutCoin: Documento de Requisitos e Contexto

> Contexto atualizado em 10/11/2026 conforme ADR-001 e decisões do planejamento. Descreve o comportamento esperado. Estado real: M0/M1 e FEAT-002/003 concluídos; núcleo físico jogável na prévia F6, partida com regras ainda pendente. Itens **[A DEFINIR]** continuam abertos. O enunciado original está em `Trabalho 2 - 2026.3.md`.

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
- Duração padrão: **3 minutos**, definida por variável exportada (`@export`) para permitir aumentar (ex.: 5 min).
- O cronômetro deve pausar durante a animação de gol e durante o pause.
- **Empate:** não existe empate final. Se o tempo acabar com o placar igual, entra o **gol de ouro**:
  - A moeda troca para um **sprite dourado especial**.
  - O **próximo gol encerra a partida**, e quem marcar vence.
  - A tela final mostra o resultado normalmente.
- **Tempo esgotado com a moeda em movimento:** o jogo **espera a moeda parar totalmente** antes de contabilizar o resultado final. Se a moeda entrar no gol durante essa espera, o gol **conta normalmente**. Só depois que a moeda parar (ou após um gol) o placar é verificado: se houver diferença, a partida termina; se estiver empatado, entra o gol de ouro.

### 3.4 Gols
- Cada gol tem um **sensor** (`Area2D`) para detectar a moeda.
- Para evitar gols falsos pela borda, o gol só conta quando a moeda estiver **inteiramente dentro** (ou depois de passar totalmente da linha).
- Ao marcar: a moeda é **escondida**, toca a **animação de gol** (com SFX), o placar é atualizado e a jogada é reiniciada.
- Alinhamento em 10/11: ocultar também indicador ativo/mira e bloquear novos tiros durante `GOL_ANIMANDO`; restaurar no reinício. Detecção/coordenação na FEAT-004 e apresentação/áudio integrados na FEAT-005/M4.

### 3.5 Início de partida e reinício após gol
- **Início da partida:** o time que começa com a moeda é escolhido de forma **aleatória**.
- **Após um gol:** a moeda volta ao **centro do campo** e **quem sofreu o gol começa jogando**.
- **Gol de ouro:** o time que começa o gol de ouro com a moeda no centro segue a mesma lógica de início (**[A DEFINIR no planejamento]**: aleatório ou quem sofreu o último gol).

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

- Reservar faixa **superior** para placar/cronômetro, reutilizando `scenes/ui/hub/hub.tscn` adaptado a 640×360. HUD fixo na tela, sem cobrir o campo jogável ou consumir cliques destinados à moeda. Ajustar composição e câmera em conjunto: os 20 px atuais de margem não comportam automaticamente o banner de 44 px.

- **Placar no estilo futebol**, contendo:
  - **Brasões** dos dois times.
  - **Gols** de cada time.
  - **Cronômetro** da partida.
- Sugestão: **indicador de vez**, destacando o time que joga no turno.
- A **seta de mira** (direção e força) faz parte da interface de jogo.
- Borda pulsante rente à moeda indica a vez: aço azulado dos pregos para Corinthians, vermelho dos pregos para Flamengo. Atualizar a cada turno; na prévia FEAT-003 a cor é fixa e provisória. Cor por equipe/degradê da seta permanece sugestão de polimento, sem definição final; amarelo atual mantido.

---

## 7. Telas e fluxo

1. **Menu principal:** Jogar, **Créditos** e Sair.
2. **Tela versus:** apresenta os times fixos do MVP: Corinthians (P1, prata, esquerda) e Flamengo (P2, vermelho, direita). Segue para a partida; seleção de times fica fora do MVP.
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
- **Configurações em variáveis exportadas (`@export`):** duração da partida, força máxima, zona morta/escala do arrasto (força mínima zero), amortecimento, tolerância de contato com paredes e ativação do gol de ouro.
- **Organização:** cenas separadas para menu, versus, partida (`main_game`), pause, tela final, créditos, moeda, prego, gol e HUD. Seguir ADR-001, sem `TelaBase` ou `TimeDados` como Resource. Código legível e comentado, pois cada integrante será questionado sobre ele.
- **Exportação:** exportar e testar o executável **Linux** desde cedo (não só no dia da entrega), e deixá-lo na pasta `build/` do repositório (**público** no GitHub).

---

## 10. Escopo e prioridades (prazo: 20/11/2026)

**Essencial (MVP):**
1. Menu principal, versus com times fixos, partida, tela final e créditos
2. Moeda com lançamento por arrasto e física (paredes e pregos)
3. Turnos entre 2 jogadores locais, com liberação só com a moeda parada
4. Gols com sensor, animação de gol e placar
5. Câmera horizontal com travas
6. Cronômetro e **gol de ouro** em caso de empate
7. Pause, áudio básico e HUD

**Desejável (se sobrar tempo):**
- Efeitos extras (tremor de câmera, brilho nos pregos, partículas)
- Mais times além dos 2 iniciais
- Seleção de times (após os testes do MVP)
- Ajustes de balanceamento (força, atrito, duração)

**Fora do escopo do protótipo:** jogador contra CPU, multiplayer online, mais de 2 times jogáveis.

---

## 11. Pendências (não bloqueiam o planejamento)

Estes pontos serão definidos depois e **não precisam estar fechados** para iniciar o planejamento:

1. Implementar o pause já aprovado na ADR-001 (M3).
2. Conferir condições de uso/atribuição dos brasões de `_EasilyImpressed` e fechar nomes/funções dos integrantes nos créditos.
3. Validar nas cenas os tamanhos já definidos, o contraste da aura e o espaçamento entre pregos (M1/M3).
4. Música e SFX: origem dos arquivos e créditos.
5. Quem começa o gol de ouro (detalhe menor, ver seção 3.5).
