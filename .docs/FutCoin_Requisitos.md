# FutCoin — Requisitos e comportamento vigente

Consolidado em 13/11/2026 após limpeza autorizada. Este documento descreve o jogo implementado. O [enunciado original](Trabalho%202%20-%202026.3.md) define a entrega acadêmica; o [planejamento](planejamento.md) registra o fechamento e a etapa Linux pendente. Grupo confirmado: Gabriel Lineker e Gianlucca Paiva.

## 1. Requisitos do trabalho

| Requisito | Implementação |
|:---|:---|
| Tela inicial com iniciar | menu_principal: Jogar, Créditos e Sair do jogo |
| Animação de sprites e tiles | AnimatedSprite2D da moeda/pregos e TileMapLayer com TileSet animado |
| Animação geral sem sprites | Tweens de interface, força/troca de brasões e resultado |
| Detecção e tratamento de colisão | Moeda física, paredes/pregos e sensores geométricos de gol |
| Áudio e HUD | Música, efeitos, placar, tempo, brasões e indicação de turno |
| Câmera não estática | Camera2D acompanha moeda no eixo horizontal, limitada ao campo |
| Objetivo | Marcar mais gols; empate no tempo regulamentar leva a Gol de Ouro |
| Tela de créditos | Dois integrantes e atribuições; créditos confirmados completos pelo usuário |

Projeto Godot 4.7, 2D top-down, pixel art 16 bits, resolução interna 640×360. Entrega Linux em build/, repositório GitHub público e prazo 20/11/2026. Avaliação individual exige domínio de toda a implementação, inclusive possível alteração pontual durante apresentação.

## 2. Lançamentos e turnos

- Dois jogadores locais compartilham o mouse e a mesma moeda. No início, um time é sorteado e seu nome aparece no centro por 1,5 s antes do fade.
- Só o time da vez pode lançar, com a moeda parada. Clique esquerdo na moeda e arraste; a puxada define direção oposta e força. Voltar à zona morta anula o impulso.
- Zona morta 14 px, faixa de arrasto 96 px; impulso proporcional saturado em 800. O limite de velocidade é 800. A mira aceita margem de seleção de 2 px além do raio físico 14.
- Direção livre em 360°, inclusive contra paredes em contato e nos cantos. A física resolve os ricochetes. Sem veto direcional, indicador cinza ou X de bloqueio.
- A seta usa amarelo até 1/3, laranja até 2/3 e vermelho acima. Borda pulsante na moeda e destaque do HUD indicam posse; a cor acompanha o clube.
- Parada confirmada abaixo do limiar de 3 px/s por 0,2 s, considerando sleep; o próximo jogador só é liberado após resolução da jogada. Sem lançamento duplo.
- RigidBody2D com amortecimento 1,2, restituição 0,7, fricção zero, gravidade zero, rotação física travada e CCD por forma. Animação por quadros apresenta o movimento.

## 3. Campo e câmera

- Campo horizontal 1152×320, paredes e 22 pregos (11 de cada lado, formação 4-4-2 com goleiro). Colisões preservam passagens para moeda de diâmetro 28.
- Goleiros mantidos em (51,160) e (1100,160), incluindo assimetria aprovada. Não reposicionar automaticamente.
- Pregos usam base prata recolorida por shader para os clubes selecionados. Originais e variantes de imagens preservados no repositório.
- Câmera acompanha somente X com suavização e limites; Y fixa em 136 na partida para composição com HUD. A prévia de física usa seu enquadramento próprio. Reposicionamentos reinicializam smoothing/interpolação.
- HUD fixo na camada de interface, mantendo a área jogável. Resolução 640×360, escala inteira, filtro Nearest e snap 2D. Renderer Forward+ mantido até avaliação Linux.

## 4. Tempo, gols e resultado

- Tempo regulamentar de 5 minutos: 300 s no script, cena e Timer da partida. Parâmetro exportado continua ajustável explicitamente para testes.
- Pausa congela jogo e tempo; comemoração de gol também pausa o cronômetro.
- Se o tempo acaba com moeda em movimento, a jogada termina e eventual gol conta. A decisão do resultado ocorre depois dessa resolução.
- Gol válido exige moeda completamente além da linha e dentro da boca. Sensor Area2D usa amostragem de deslocamento para travessias rápidas, IDs da jogada e proteção contra teleporte/duplicatas.
- Ao marcar: moeda/mira ocultadas ou desabilitadas, placar atualizado e apresentação de 2,2 s com brasão, nome, placar e som. Depois, moeda no centro e saída de quem sofreu.
- Empate após tempo/última jogada: Gol de Ouro obrigatório, sem tempo adicional limite. Moeda dourada, novo sorteio independente, primeiro gol decide.
- Encerramento bloqueia novas jogadas, aguarda eventual comemoração, pausa de 0,25 s e apito final completo antes do resultado. Ausência/interrupção de som tem fallback e não pode impedir a transição.

## 5. Telas e interface

| Tela/componente | Uso |
|:---|:---|
| Menu principal | Iniciar, créditos e fechar aplicativo; tigre com chance independente de 1% por carregamento |
| Versus | Nove clubes, sem repetição entre lados; padrões Corinthians/Flamengo. Começar partida e Voltar, sem avanço automático |
| Partida/HUD | Brasões 18×18, gols, cronômetro, turno e botão de pausa |
| GolUI | Comemoração; componente distinto do sensor físico |
| Pause | Esc ou botão do HUD; Continuar, Reiniciar e Voltar ao menu. Pause usa SceneTree e não acrescenta estado ao enum da partida |
| Resultado | Vencedor/placar, troféu/fogos e botões Jogar Novamente, Trocar Times e Menu |
| Créditos | Dois integrantes e atribuições existentes, sem pendências reabertas |
| Prévia da moeda | Suporte F6 e ambiente da suíte 003; fora do fluxo do jogador |

Pausa volta ao menu sem declarar vencedor; não é empate esportivo. Trocar Times abre seleção, Jogar Novamente mantém os clubes. Fallbacks isolados de interface permanecem para desenvolvimento/apresentação.

## 6. Arquitetura e áudio

- MainGame é o juiz com estados AGUARDANDO_JOGADA, MIRANDO, MOEDA_EM_MOVIMENTO, GOL_ANIMANDO e FIM_DE_PARTIDA. Gol de Ouro é flag; pause pertence ao SceneTree.
- Pais chamam componentes; moeda/mira/sensores/menus emitem sinais. Sensores são encontrados por grupo com filtro de descendência para evitar interferência entre partidas.
- DadosTimes centraliza catálogo, nomes, cores e seleção. TelaFinal recebe resultado estático; sem Resource de times, TelaBase ou Autoload adicional de transporte.
- AudioManager (Autoload GerenciadorAudio) controla músicas/eventos e cinco barramentos. Sounds atende botões; AudioMoeda atende chute e impacto em pregos.
- Permanecem músicas de menu, partida e Gol de Ouro; apitos, gol, torcida curta, vitória e fogos. Suporte vazio a deslize, impacto de parede e torcida contínua foi removido. Nenhum arquivo sonoro foi apagado.

## 7. Fechamento e entrega

Limpeza autorizada encerrada: quatro refatorações, duas cenas dispensáveis removidas, três métodos sem chamadas removidos, ramos de áudio sem configuração retirados e .gitkeep redundantes removidos. Todos os PNGs/animações, duas suítes e a prévia da moeda foram mantidos por decisão do usuário. Recursos opcionais preservados não são pendências.

Roteiro em [roteiro_apresentacao.md](roteiro_apresentacao.md). Linux é a última etapa: preparar preset/export, testar executável no alvo, conferir permissão de execução e publicação em build/. Conferir repositório público, submissão no Classroom e agendamento pelo mesmo representante. Essas ações externas ainda não foram verificadas.
