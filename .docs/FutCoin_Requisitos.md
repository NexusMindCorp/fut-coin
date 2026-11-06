# FutCoin: Documento de Requisitos e Contexto

> Documento de contexto para planejamento do projeto com a IA. Descreve o conceito, as regras, os requisitos do Trabalho 2 e os pontos ainda em aberto. Itens marcados como **[A DEFINIR]** devem ser discutidos e fechados no planejamento.

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
| Animação de sprites e tiles | Sprite da moeda (rolagem/giro), animação de gol, moeda de ouro, tiles/pregos animados (ex.: brilho ao colidir) |
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
- **Limite de força perto da parede:** se a moeda estiver muito próxima da parede e o jogador tentar puxar na direção da parede, a força máxima é limitada.
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

- **Placar no estilo futebol**, contendo:
  - **Brasões** dos dois times.
  - **Gols** de cada time.
  - **Cronômetro** da partida.
- Sugestão: **indicador de vez**, destacando o time que joga no turno.
- A **seta de mira** (direção e força) faz parte da interface de jogo.

---

## 7. Telas e fluxo

1. **Menu principal:** Jogar, **Créditos** e Sair.
2. **Seleção de times:** navegação por **setinhas**. No protótipo existem **2 times pré-definidos**. Botão **Play** leva direto à partida.
3. **Partida (Main Game):** todo o gameplay descrito acima, com **sistema de pause**.
4. **Tela final:** resultado da partida (incluindo vitória por gol de ouro) com as opções:
   - **Reiniciar** a partida
   - **Voltar à seleção de times**
   - **Voltar ao menu**
   - (Sugestão) botão de **Créditos**
5. **Créditos:** acessível pelo menu principal (e opcionalmente pela tela final). A mesma cena pode ser reaproveitada nos dois lugares. Deve conter:
   - Integrantes do grupo e suas funções
   - **Artista externo responsável pelos brasões** **[A DEFINIR: nome e licença/condições de uso]**
   - Demais fontes de assets (música, SFX, fontes tipográficas, etc.)

### Pause
- Sistema de pause durante a partida (congelar física, cronômetro e animações de jogo), com opções como continuar, reiniciar e voltar ao menu.
- **[A DEFINIR]** Implementação conforme as recomendações da infraestrutura de IA do grupo.

---

## 8. Direção de arte e resolução

- **Estilo:** pixel art **16 bits**, em todos os elementos (campo, pregos, moeda, HUD, menus, brasões).
- **Resolução base recomendada: 480×270 (16:9)**, com **escala inteira** (×2 = 960×540, ×4 = 1920×1080).

### Configuração sugerida na Godot
- Stretch Mode `viewport`, Aspect `keep`, Scale Mode `integer`.
- Filtro de textura padrão `Nearest`.
- Evitar janelas que não sejam múltiplos inteiros de 480×270 (ex.: 1280×720 resulta em escala de 2,67×).
- Ativar o *snap 2D transforms to pixel* e verificar se a câmera não gera jitter.

### Tamanhos de referência (estimativas iniciais)
Valores aproximados para 480×270, **apenas ponto de partida**:
- HUD no topo: ~32 a 40 px de altura (sobrando ~230 px para o campo).
- Moeda: ~14 a 16 px de diâmetro.
- Cabeça dos pregos: ~8 a 10 px.
- Brasões: ~24 a 32 px (ou múltiplos, para reduzir sem borrar).

> ⚠️ **Instrução importante para a IA:** os tamanhos acima são estimativas. **Analise os assets que o grupo já possui** (imagens existentes no repositório/projeto, incluindo os brasões do artista externo) **e ajuste as recomendações** de resolução base, tamanho da moeda, dos pregos, do HUD e dos brasões com base nas **dimensões e no nível de detalhe reais dessas imagens**. Se os assets existentes sugerirem outra resolução base, **proponha o ajuste e justifique**.

---

## 9. Recomendações técnicas (Godot)

- **Moeda:** `RigidBody2D` com material de física (bounce/fricção) e `linear_damp` para frear naturalmente. Ativar `continuous_cd` e limitar a velocidade máxima para evitar **tunelamento** através de pregos e paredes.
- **Pregos e paredes:** `StaticBody2D` com colisão.
- **Gols:** `Area2D` posicionada atrás da linha do gol.
- **Estados do jogo:** usar uma máquina de estados simples para o fluxo da partida (por exemplo: aguardando jogada, mirando, moeda em movimento, gol, fim de partida, pausado).
- **Configurações em variáveis exportadas (`@export`):** duração da partida, força máxima/mínima, atrito, limite de força perto da parede e ativação do gol de ouro.
- **Organização:** cenas separadas para menu, seleção de times, partida, tela final, créditos, moeda, prego, gol e HUD. Código **legível e comentado**, pois cada integrante será questionado sobre ele.
- **Exportação:** exportar e testar o executável **Linux** desde cedo (não só no dia da entrega), e deixá-lo na pasta `build/` do repositório (**público** no GitHub).

---

## 10. Escopo e prioridades (prazo: 20/11/2026)

**Essencial (MVP):**
1. Menu principal, seleção de times, partida, tela final e créditos
2. Moeda com lançamento por arrasto e física (paredes e pregos)
3. Turnos entre 2 jogadores locais, com liberação só com a moeda parada
4. Gols com sensor, animação de gol e placar
5. Câmera horizontal com travas
6. Cronômetro e **gol de ouro** em caso de empate
7. Pause, áudio básico e HUD

**Desejável (se sobrar tempo):**
- Efeitos extras (tremor de câmera, brilho nos pregos, partículas)
- Mais times além dos 2 iniciais
- Ajustes de balanceamento (força, atrito, duração)

**Fora do escopo do protótipo:** jogador contra CPU, multiplayer online, mais de 2 times jogáveis.

---

## 11. Pendências (não bloqueiam o planejamento)

Estes pontos serão definidos depois e **não precisam estar fechados** para iniciar o planejamento:

1. Implementação do pause conforme as recomendações da infraestrutura de IA.
2. Nome do artista dos brasões e condições de uso/licença, para os créditos.
3. Ajuste final de resolução e tamanhos com base nos assets reais do grupo.
4. Música e SFX: origem dos arquivos e créditos.
5. Quem começa o gol de ouro (detalhe menor, ver seção 3.5).
