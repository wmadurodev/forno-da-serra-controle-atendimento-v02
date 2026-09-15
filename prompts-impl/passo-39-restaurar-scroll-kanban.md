# Passo 39 — Restaurar posição do Kanban após fechar diálogo/formulário

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-15. Sem correspondência em `docs/`.
> **Depende de:** Passo 25 (navegador de fases / `ScrollController` do Kanban), Passo 28 (`_indiceFaseVisivel`).

## Objetivo

Na Tela 4 (Execução do Fluxo de Atendimento — Kanban), sempre que um diálogo de confirmação ou um formulário de entrada de dados for aberto a partir dela (Cadastro/Execução/Edição de Execução/Cancelamento/Devolução de Pedido, ou os diálogos de confirmação de Excluir/Retirado/Enviar/Entregue do card), o app deve lembrar qual coluna de status estava visível e, ao fechar o diálogo/tela e recarregar os dados, rolar automaticamente o Kanban de volta para essa mesma coluna — em vez de voltar sempre para a primeira coluna, como acontece hoje.

## Levantamento

Causa raiz em `quadro_atendimento_screen.dart` (`_QuadroViewState.build`):

```dart
body: controller.loading ? const LoadingView() : _buildQuadro(context, controller),
```

Todo fechamento de diálogo/tela que altera dados passa por `QuadroAtendimentoController.load()` (`quadro_atendimento_controller.dart`):

```dart
Future<void> load() async {
  loading = true;
  notifyListeners();   // <- troca _buildQuadro por LoadingView, desmontando o SingleChildScrollView
  ...
  loading = false;
  notifyListeners();   // <- _buildQuadro é reconstruído do zero, SingleChildScrollView remonta em offset 0
}
```

`load()` é chamado ao final de **todos** os fluxos que fecham um diálogo/formulário sobre o Kanban:
- `_abrirCadastroPedido`, `_abrirExecucaoPedido`, `_abrirEdicaoExecucao`, `_abrirCancelamento`, `_abrirDevolucao` (telas via `Navigator.push`, em `quadro_atendimento_screen.dart`);
- `controller.excluir` e `controller.atualizarStatus` (chamados por `_KanbanColuna._executar`, a partir dos diálogos de confirmação nativos do `PedidoCard` — `_confirmarExclusao`/`_confirmarAcao`, Passo 24).

Como o `SingleChildScrollView` (com o `_scrollController`) é desmontado enquanto `loading == true` e remontado quando volta a `false`, o `ScrollController` perde a posição de rolagem — a nova `ScrollPosition` sempre nasce em offset 0 (primeira coluna), independente de onde o usuário estava.

`_QuadroViewState` já mantém `_indiceFaseVisivel` (Passo 28), atualizado continuamente pelo listener `_atualizarFaseVisivel` enquanto o usuário rola manualmente — esse índice não se perde durante o `load()` (é um campo de estado do `State`, não depende do `ScrollController`), então já serve como "a coluna que estava visível" sem precisar de nenhuma captura adicional no momento de abrir cada diálogo/formulário.

**Correção proposta:** centralizar a restauração em um único listener no `QuadroAtendimentoController`, em vez de duplicar a lógica em cada `_abrirXxx`/ação do card — cobre automaticamente os 7 pontos de chamada listados acima (presentes e futuros) sem repetição de código.

## Alteração — `quadro_atendimento_screen.dart`

Em `_QuadroViewState`:

```dart
final _scrollController = ScrollController();
late final QuadroAtendimentoController _controller;
bool _carregandoAnterior = true;

int _indiceFaseVisivel = 0;
// ... (sem mudança)

@override
void initState() {
  super.initState();
  _scrollController.addListener(_atualizarFaseVisivel);
  _controller = context.read<QuadroAtendimentoController>();
  _controller.addListener(_aoAtualizarController);
}

@override
void dispose() {
  _scrollController.removeListener(_atualizarFaseVisivel);
  _controller.removeListener(_aoAtualizarController);
  _scrollController.dispose();
  super.dispose();
}

/// Detecta a transição `loading: true -> false` (fim de um `load()`,
/// disparado ao fechar qualquer diálogo/formulário sobre o Kanban) e
/// restaura a rolagem na coluna que estava visível antes do refresh —
/// Passo 39. Sem isso, o `SingleChildScrollView` remonta em offset 0
/// (ver `build`, `controller.loading ? LoadingView() : _buildQuadro(...)`).
void _aoAtualizarController() {
  if (_carregandoAnterior && !_controller.loading) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _restaurarPosicaoScroll());
  }
  _carregandoAnterior = _controller.loading;
}

void _restaurarPosicaoScroll() {
  if (!_scrollController.hasClients) return;
  final offsetAlvo = _paddingInicial + _indiceFaseVisivel * (_larguraColuna + _espacamento);
  final maximo = _scrollController.position.maxScrollExtent;
  _scrollController.jumpTo(offsetAlvo.clamp(0.0, maximo));
}
```

Notas:
- `jumpTo` (não `animateTo`) — é uma restauração de estado, não uma navegação guiada pelo usuário; não deve haver animação visível de "varrendo" as colunas.
- `context.read<QuadroAtendimentoController>()` em `initState` funciona porque `_QuadroView` é filho direto do `ChangeNotifierProvider` que cria o controller (`QuadroAtendimentoScreen.build`) — o provider já está disponível no `context` nesse ponto.
- `_carregandoAnterior` começa em `true` porque `QuadroAtendimentoController.loading` também começa em `true` (carga inicial, no construtor); a primeira transição para `false` tenta restaurar `_indiceFaseVisivel` (ainda `0` nesse momento), o que é inofensivo (`jumpTo(0)`).
- Não é necessário capturar nada no momento em que cada diálogo/formulário é *aberto* — `_indiceFaseVisivel` já reflete continuamente a coluna visível (Passo 28) e não é afetado pela desmontagem do `SingleChildScrollView` durante o `loading`.

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Rolar o Kanban até uma coluna que não seja a primeira (ex.: `em_execucao`), abrir "Executar" em um card e gravar: ao voltar para o Kanban, a coluna `em_execucao` continua visível (sem saltar para `aguardando_atendimento`).
- [ ] Mesmo teste com Cadastro/Edição de Execução/Cancelamento/Devolução de Pedido (`Navigator.push` + `controller.load()` no retorno).
- [ ] Mesmo teste com as ações rápidas do card que passam por diálogo de confirmação (Excluir, Retirado, Enviar, Entregue) — Passo 24.
- [ ] Destaque do navegador de fases do footer (Passo 28) continua sincronizado com a coluna restaurada.
- [ ] Comportamento de toque nos ícones do footer (`_rolarParaFase`, Passo 25) inalterado — continua animado (`animateTo`), só a restauração pós-`load()` usa `jumpTo`.

## Fora de Escopo deste Passo

- Persistir a posição entre sessões do app (fechar e reabrir o app) — só entre aberturas/fechamentos de diálogo/formulário na mesma sessão da Tela 4.
- Mudar o comportamento de `_rolarParaFase` (toque no footer) ou o destaque do Passo 28.
