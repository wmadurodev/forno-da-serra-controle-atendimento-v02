# Passo 40 — Mover o header da Tela 4 para um novo footer, abaixo do navegador de fases

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-16. Sem correspondência em `docs/`.
> **Depende de:** Passo 13 (header atual da Tela 4), Passo 25 (navegador de fases no footer).

## Objetivo

Na Tela 4 (Execução do Fluxo de Atendimento — Kanban), remover o `AppBar` (header) da aplicação e criar um novo footer, posicionado **abaixo** do navegador de fases já existente (Passo 25), contendo todos os elementos hoje presentes no header.

## Levantamento

Header atual (`quadro_atendimento_screen.dart`, `_QuadroViewState.build`, `Scaffold.appBar`):

```dart
appBar: AppBar(
  automaticallyImplyLeading: false,
  title: Text(fluxo.identificador),
  actions: [
    if (!_somenteLeitura) ...[
      IconButton.filledTonal(icon: const Icon(Icons.add), tooltip: 'Novo Pedido', onPressed: ...),
      const SizedBox(width: 4),
    ],
    IconButton.filledTonal(icon: Icon(filtro ativo ? Icons.filter_alt : Icons.filter_list), tooltip: 'Filtrar Pedidos', onPressed: ...),
    const SizedBox(width: 4),
    IconButton.filledTonal(icon: const Icon(Icons.search), tooltip: 'Busca de Pedidos', onPressed: ...),
    const SizedBox(width: 4),
    IconButton.filledTonal(icon: const Icon(Icons.logout), tooltip: 'Sair', onPressed: ...),
  ],
),
```

Elementos a migrar, todos com o mesmo comportamento/condição atuais:
- Título: `fluxo.identificador`.
- "Novo Pedido" (`Icons.add`) — só quando `!_somenteLeitura`.
- "Filtrar Pedidos" (`Icons.filter_list`/`Icons.filter_alt`, conforme `controller.filtro`).
- "Busca de Pedidos" (`Icons.search`).
- "Sair" (`Icons.logout`).

Footer atual (`bottomNavigationBar`, Passo 25) é só `_buildNavegadorFases` (ícones de fase). Vira o primeiro bloco de um novo footer composto; o bloco com os elementos do header (ex-`AppBar`) entra **abaixo** dele.

## Alteração — `quadro_atendimento_screen.dart`

1. Remover `appBar: AppBar(...)` do `Scaffold`.
2. `body` deixa de poder contar com o `SafeArea` implícito do `AppBar` no topo — envolver `controller.loading ? const LoadingView() : _buildQuadro(context, controller)` em `SafeArea(bottom: false, child: ...)` para preservar o respiro da status bar.
3. `bottomNavigationBar` passa a ser uma `Column(mainAxisSize: MainAxisSize.min)` com dois blocos, nesta ordem:
   - `_buildNavegadorFases(controller)` (inalterado).
   - Novo `_buildHeaderFooter(context, controller)`: `SafeArea(top: false, child: Padding(...))` com uma `Row` reproduzindo o conteúdo do `AppBar` removido — título (`Text(fluxo.identificador)`, `Expanded` para não ser espremido pelos ícones) à esquerda, e os mesmos 4 `IconButton.filledTonal` (com a mesma condição `if (!_somenteLeitura)` para "Novo Pedido") à direita, na mesma ordem em que apareciam no header.
4. Métodos `_abrirCadastroPedido`, `_abrirFiltro`, `_abrirBusca`, `_confirmarSaida` continuam exatamente iguais — só muda de onde são chamados (novo footer em vez do `AppBar.actions`).

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Tela 4 não exibe mais `AppBar` no topo; o identificador do fluxo e os 4 ícones de ação (Novo Pedido/Filtrar/Buscar/Sair) aparecem em uma nova faixa no footer, abaixo do navegador de fases.
- [ ] Em fluxo `fechado` (`_somenteLeitura == true`), "Novo Pedido" continua ausente do novo footer.
- [ ] Ícone de filtro continua alternando `filter_list`/`filter_alt` conforme `controller.filtro`.
- [ ] As 4 ações (Novo Pedido, Filtrar, Buscar, Sair) continuam funcionando exatamente como antes.
- [ ] Navegador de fases (Passo 25) e seu destaque (Passo 28) continuam funcionando sem mudança, acima do novo bloco.
- [ ] Conteúdo da tela (colunas do Kanban) não fica coberto pela status bar no topo (checar `SafeArea` do `body`).

## Fora de Escopo deste Passo

- Alterar o header/AppBar de qualquer outra tela do app — só a Tela 4.
- Alterar a ordem, os ícones ou o comportamento das ações migradas — é só um reposicionamento.
