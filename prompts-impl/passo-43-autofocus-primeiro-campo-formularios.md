# Passo 43 — Autofoco no primeiro campo de todo formulário de entrada/alteração de dados

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-16. Sem correspondência em `docs/`.
> **Depende de:** nenhum passo específico — abrange todas as telas de formulário já implementadas.

## Objetivo

Em todo formulário de entrada/alteração de dados do app, o cursor deve começar posicionado no primeiro campo de texto ao abrir a tela, com o teclado virtual (soft keyboard) já aberto automaticamente — poupando o usuário de precisar tocar no campo antes de digitar.

## Levantamento

Telas com campo(s) de texto (`grep -rl "TextFormField\|TextField" lib/features`), todas candidatas:

| Tela | Arquivo | Primeiro campo (editável) | Observação |
|---|---|---|---|
| 3 — Cadastro do Fluxo de Atendimento | `cadastro_fluxo_screen.dart` | Identificador | Campo único, pré-preenchido com a data sugerida. |
| 5 — Cadastro de Pedido | `cadastro_pedido_screen.dart` | Identificador do Pedido **ou** Nome do Cliente | Formulário em 2 estágios — ver nota abaixo. |
| 6 — Execução de Pedido | `execucao_pedido_screen.dart` | Mesa | O bloco de foto vem antes na tela, mas não é campo de texto. |
| 9 — Edição de Pedido em Execução | `edicao_pedido_execucao_screen.dart` | Nome do Cliente | O 1º `TextFormField` da tela é "Identificador do Pedido", mas é `readOnly: true` — não faz sentido focar nele (usuário não pode digitar); o alvo real é o próximo campo editável. |
| 7 — Cancelamento de Pedido | `cancelamento_pedido_screen.dart` | Motivo | Campo único. |
| 8 — Devolução de Entrega | `devolucao_entrega_screen.dart` | Motivo da Devolução | Campo único. |
| Busca de Pedidos | `busca_pedidos_screen.dart` | Identificador do Pedido | Não edita um registro, mas é um formulário de entrada de dados (critérios de busca) — incluído no escopo. Os outros 5 campos ficam desabilitados quando um deles é preenchido; focar o primeiro não interfere nisso. |

**Nota sobre a Tela 5 (`cadastro_pedido_screen.dart`):** o formulário tem 2 estágios — (1) campo "Identificador do Pedido" sozinho, até o usuário tocar "Confirmar"; (2) após confirmado, os demais campos aparecem (`_buildCamposCadastro`), começando por "Nome do Cliente". Quando a tela abre via `pedidoExistente` (botões "Atendimento"/"Editar" da Tela 4), o estágio 2 já começa visível (identificador vem `readOnly` e pré-preenchido). O foco automático deve ser condicional ao estágio: campo "Identificador" só quando ainda não confirmado (`!_identificadorConfirmado`); campo "Nome do Cliente" sempre que a seção de cadastro estiver visível (`_identificadorConfirmado`). O widget `autofocus: true` do Flutter dispara quando o `Focus`/`EditableText` correspondente é inserido na árvore pela primeira vez (não a cada rebuild), então isso funciona tanto na abertura inicial (Identificador **ou** Nome do Cliente, dependendo de `pedidoExistente`) quanto na transição dinâmica (Identificador confirmado → seção de Nome do Cliente aparece pela primeira vez, ganha foco nesse momento) — sem precisar de `FocusNode` manual.

## Alteração

Em cada tela listada, adicionar `autofocus: true` (ou `autofocus: <condição>` na Tela 5, ver acima) no `TextFormField`/`TextField` do primeiro campo editável — nenhuma outra mudança de comportamento, validação ou layout.

- `cadastro_fluxo_screen.dart`: `TextFormField` do Identificador → `autofocus: true`.
- `cadastro_pedido_screen.dart`: `TextFormField` do Identificador (em `_buildCampoIdentificador`) → `autofocus: !_identificadorConfirmado`; `TextFormField` de Nome do Cliente (em `_buildCamposCadastro`) → `autofocus: true`.
- `execucao_pedido_screen.dart`: `TextFormField` de Mesa → `autofocus: true`.
- `edicao_pedido_execucao_screen.dart`: `TextFormField` de Nome do Cliente (o 2º da tela, 1º editável) → `autofocus: true`. O campo Identificador (`readOnly: true`) **não** recebe autofocus.
- `cancelamento_pedido_screen.dart`: `TextFormField` de Motivo → `autofocus: true`.
- `devolucao_entrega_screen.dart`: `TextFormField` de Motivo da Devolução → `autofocus: true`.
- `busca_pedidos_screen.dart`: campo "Identificador do Pedido" → `autofocus: true` (adicionar parâmetro `autofocus` ao helper `_campoBusca`, default `false`, passando `true` só nessa primeira chamada).

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Abrir cada uma das 7 telas listadas: o teclado virtual abre automaticamente, com o cursor no primeiro campo editável, sem precisar tocar nele.
- [ ] Tela 5, entrada "Novo Pedido" (sem `pedidoExistente`): teclado abre no campo Identificador; após tocar "Confirmar", o foco passa automaticamente para "Nome do Cliente" (teclado permanece aberto, sem precisar tocar no campo).
- [ ] Tela 5, entrada "Atendimento"/"Editar" (com `pedidoExistente`): teclado já abre direto no campo "Nome do Cliente" (Identificador já vem `readOnly`, sem foco).
- [ ] Tela 9: teclado abre no campo "Nome do Cliente", não no campo "Identificador do Pedido" (que é somente leitura).
- [ ] Nenhuma mudança de validação, layout ou comportamento de gravação em nenhuma das telas.

## Fora de Escopo deste Passo

- Diálogos (`AlertDialog`s de confirmação, `FiltroPedidosDialog`, `ValoresPagamentoDialog`, `PrestacaoContasMotoqueiroDialog`) — nenhum deles tem campo de texto para o usuário preencher.
- Mudar a ordem dos campos ou o fluxo de navegação por `TextInputAction`/`onFieldSubmitted` entre campos — só o foco inicial.
