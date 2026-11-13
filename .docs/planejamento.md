# FutCoin — Planejamento consolidado

Estado vigente em 13/11/2026. Grupo: Gabriel Lineker e Gianlucca Paiva. Prazo do enunciado: 20/11/2026. O enunciado original permanece em [Trabalho 2](Trabalho%202%20-%202026.3.md); regras atuais em [requisitos](FutCoin_Requisitos.md).

## Entrega implementada

| Marco | Estado |
|:---|:---|
| M0 — Fundação e assets | Concluído: Godot 4.7, resolução interna 640×360, escala inteira, pipeline e fontes preservadas |
| M1 — Física e controle | Concluído e aprovado: moeda de raio 14, impulso/velocidade máximos 800, amortecimento 1,2, restituição 0,7, ricochete livre, mira e câmera horizontal |
| M2 — Regras | Concluído: turnos locais, gols, partida de 300 s, última jogada após tempo esgotado e Gol de Ouro obrigatório |
| M3 — Fluxo e interface | Concluído: menu, nove clubes sem repetição, partida/HUD, pausa, resultado e créditos |
| M4 — Polimento e limpeza | Polimento aprovado; limpeza autorizada e consolidação concluídos. Créditos confirmados completos pelo usuário. Roteiro preparado após limpeza |
| M5 — Linux e submissão | Última etapa, ainda pendente; não confundir testes Windows com teste da entrega Linux |

## Decisões vigentes

- Dois jogadores no mesmo computador, mouse compartilhado, turnos alternados. Não há CPU ou rede.
- Sorteio inicial com aviso «<time> começa!»; após gol, saída de quem sofreu. Gol de Ouro tem sorteio independente.
- Lançamento permitido em qualquer direção, inclusive contra parede em contato; não existe seta cinza/X nem veto direcional.
- Seta amarela/laranja/vermelha indica terços de força. Brasões de HUD 18×18; outros brasões preservados.
- Gol apresentado por 2,2 s, torcida curta e redução temporária da música. Encerramento espera comemoração e apito final, com fallback se áudio faltar.
- Tigre do menu: 1% por carregamento, sorteios independentes.
- Forward+ mantido. Eventual decisão de compatibilidade só após avaliar a máquina Linux alvo.
- Arquitetura da ADR-001: juiz, componentes, sinais, grupos e dados estáticos; um Autoload de áudio. Nenhuma TelaBase ou biblioteca adicional.

## Limpeza encerrada no escopo aprovado

- Quatro refatorações concluídas: foco dos botões, seleção compartilhada dos lados, controle de botões da tela final e aplicação de cor dos pregos.
- Removidos Menu vazio e prévia exclusiva do campo com script/.uid. Restam 15 cenas; prévia da moeda mantida como suporte da suíte 003.
- Removidos três métodos sem chamadas e suporte sem configuração a deslize, impacto de parede e torcida contínua. Sons ativos, barramento Ambiente e torcida de gol preservados.
- Removidos 16 .gitkeep de diretórios já preenchidos; preservados os de build/ e assets/fonts/.
- Todos os PNGs, animações, originais e arquivos de som mantidos por decisão do usuário. Personalização de cores e estrutura do juiz mantidas. Candidatos opcionais restantes foram encerrados sem execução; não são novas pendências.
- Documentos atuais consolidados; registros de implementação anteriores permanecem nos relatórios datados e no Git. Propostas antigas descartadas não fazem parte do escopo.

## Validação de fechamento

Na implementação de 13/11: suíte 003 com 11.941 verificações, suíte 004 com 138, ambas sem falhas. Editor e sete cenas executados em Godot 4.7.2/D3D12, retorno zero. Caminhos/sinais e codificação conferidos; scripts sem print. A consolidação posterior somente em Markdown não aciona nova execução de Godot/testes. Esses resultados não equivalem à homologação Linux.

## Apresentação

[Roteiro e guia de estudo](roteiro_apresentacao.md) cobre todos os scripts GDScript, fluxo em cinco passos, arquitetura e proposta de divisão baseada nos commits reais. A divisão sugerida não substitui o conhecimento de todo o código por ambos, exigido pelo professor. Não foi informada duração obrigatória da apresentação; o roteiro não inventa limite de tempo.

## O que falta

1. Estudar/ensaiar o roteiro e, pelo mesmo representante do grupo, confirmar o agendamento da apresentação.
2. Na última etapa: configurar preset/templates, exportar em build/, testar no Linux alvo e conferir renderer, tamanho e permissão de execução. O planejamento prevê proteção de binários em .gitattributes e instruções do executável real no README; fazer isso no lote Linux.
3. Conferir que o repositório final está público e publicado. Um único representante deve enviar o link no Classroom; o mesmo deve agendar a apresentação. Essas ações externas ainda não foram verificadas.

Não há atribuições de crédito, novas funcionalidades ou polimento de áudio em aberto neste planejamento. README permanece sem referência a agentes, conforme instrução do usuário.
