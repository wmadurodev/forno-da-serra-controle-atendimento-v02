import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/loading_view.dart';
import '../../pedido/data/pedido_repository.dart';
import '../../pedido/domain/pedido.dart';
import '../../pedido/presentation/cadastro_pedido_screen.dart';
import '../../pedido/presentation/cancelamento_pedido_screen.dart';
import '../../pedido/presentation/devolucao_entrega_screen.dart';
import '../../pedido/presentation/edicao_pedido_execucao_screen.dart';
import '../../pedido/presentation/execucao_pedido_screen.dart';
import '../domain/fluxo_atendimento.dart';
import 'busca_pedidos_screen.dart';
import 'fase_pedido_visual.dart';
import 'filtro_pedidos_dialog.dart';
import 'home_screen.dart';
import 'pedido_card.dart';
import 'quadro_atendimento_controller.dart';

/// Tela 4 — Execução do Fluxo de Atendimento
/// (`docs/controle-atendimento-prototype.md` §3.4).
class QuadroAtendimentoScreen extends StatelessWidget {
  const QuadroAtendimentoScreen({super.key, required this.fluxo});

  final FluxoAtendimento fluxo;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => QuadroAtendimentoController(
        context.read<PedidoRepository>(),
        fluxo.identificador,
      ),
      child: _QuadroView(fluxo: fluxo),
    );
  }
}

class _QuadroView extends StatefulWidget {
  const _QuadroView({required this.fluxo});

  final FluxoAtendimento fluxo;

  @override
  State<_QuadroView> createState() => _QuadroViewState();
}

class _QuadroViewState extends State<_QuadroView> {
  static const _larguraColuna = 300.0;
  static const _espacamento = 12.0;
  static const _paddingInicial = 8.0;

  final _scrollController = ScrollController();
  late final QuadroAtendimentoController _controller;
  bool _carregandoAnterior = true;

  /// Índice (em `PedidoStatus.values`) da coluna considerada visível no
  /// momento — usado para destacar o ícone correspondente no footer
  /// (Passo 28) e para restaurar a rolagem após um refresh (Passo 39).
  int _indiceFaseVisivel = 0;

  /// Status para o qual o Kanban deve rolar após o próximo `load()`, em vez
  /// de restaurar `_indiceFaseVisivel` — setado antes de incluir/alterar um
  /// Pedido, consumido (voltando a `null`) em `_restaurarPosicaoScroll`
  /// (Passo 42).
  PedidoStatus? _statusAlvoAposRecarga;

  FluxoAtendimento get fluxo => widget.fluxo;
  bool get _somenteLeitura => fluxo.status == FluxoAtendimentoStatus.fechado;

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

  /// Detecta a transição `loading: true -> false` (fim de um
  /// `QuadroAtendimentoController.load()`, disparado ao fechar qualquer
  /// diálogo/formulário sobre o Kanban) e restaura a rolagem na coluna que
  /// estava visível antes do refresh — Passo 39. Sem isso, `build` desmonta
  /// o `SingleChildScrollView` enquanto `loading == true` (troca por
  /// `LoadingView`) e ele remonta em offset 0 ao voltar para `false`.
  void _aoAtualizarController() {
    if (_carregandoAnterior && !_controller.loading) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _restaurarPosicaoScroll(),
      );
    }
    _carregandoAnterior = _controller.loading;
  }

  void _restaurarPosicaoScroll() {
    if (!_scrollController.hasClients) return;
    final statusAlvo = _statusAlvoAposRecarga;
    _statusAlvoAposRecarga = null;
    final maximo = _scrollController.position.maxScrollExtent;
    // Um status-alvo (Pedido novo/alterado, Passo 42) tem prioridade sobre a
    // restauração silenciosa (Passo 39) — é uma navegação deliberada, então
    // anima como `_rolarParaFase` em vez de saltar direto.
    if (statusAlvo != null) {
      final indice = PedidoStatus.values.indexOf(statusAlvo);
      final offsetAlvo =
          _paddingInicial + indice * (_larguraColuna + _espacamento);
      _scrollController.animateTo(
        offsetAlvo.clamp(0.0, maximo),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }
    final offsetAlvo =
        _paddingInicial + _indiceFaseVisivel * (_larguraColuna + _espacamento);
    _scrollController.jumpTo(offsetAlvo.clamp(0.0, maximo));
  }

  /// Grava o status-alvo (Passo 42) e delega para o controller — usado
  /// pelas ações rápidas do card (Retirado/Enviado/Entregue) em vez de
  /// chamar `controller.atualizarStatus` diretamente de `_KanbanColuna`.
  Future<void> _atualizarStatusENavegar(
    QuadroAtendimentoController controller,
    Pedido pedido,
    PedidoStatus novoStatus,
  ) {
    _statusAlvoAposRecarga = novoStatus;
    return controller.atualizarStatus(pedido, novoStatus);
  }

  /// Rola o Kanban horizontalmente até a coluna de `status` ficar alinhada
  /// à esquerda da tela visível — Passo 25.
  void _rolarParaFase(PedidoStatus status) {
    final indice = PedidoStatus.values.indexOf(status);
    final offsetAlvo =
        _paddingInicial + indice * (_larguraColuna + _espacamento);
    final maximo = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      offsetAlvo.clamp(0.0, maximo),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Atualiza `_indiceFaseVisivel` conforme a posição de rolagem do Kanban
  /// — Passo 28. Arredonda para a coluna mais próxima do início do
  /// percurso, então o destaque muda assim que o usuário rola além do meio
  /// do caminho entre duas colunas.
  void _atualizarFaseVisivel() {
    final indice =
        ((_scrollController.offset - _paddingInicial) /
                (_larguraColuna + _espacamento))
            .round()
            .clamp(0, PedidoStatus.values.length - 1);
    if (indice != _indiceFaseVisivel) {
      setState(() => _indiceFaseVisivel = indice);
    }
  }

  Widget _buildNavegadorFases(QuadroAtendimentoController controller) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            for (final status in PedidoStatus.values)
              Expanded(
                child: _iconeFase(
                  status,
                  iconePorFase[status]!,
                  controller.pedidosDe(status).length,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Diâmetro fixo do círculo de cada ícone de fase — não muda com `ativo`
  /// (Passo 40, correção de bug: variar o tamanho do container descentraliza
  /// o ícone dentro do próprio Stack, ver nota abaixo).
  static const _diametroIconeFase = 50.0;

  Widget _iconeFase(PedidoStatus status, IconData icone, int quantidade) {
    final indiceReal = PedidoStatus.values.indexOf(status);
    final cor =
        corCinza(status) ?? corColuna(indiceReal, PedidoStatus.values.length);
    // Destaque só em modo retrato — em paisagem várias colunas ficam
    // visíveis ao mesmo tempo, então marcar "a" coluna visível não faz
    // sentido (Passo 28, revisão).
    final orientacaoRetrato =
        MediaQuery.orientationOf(context) == Orientation.portrait;
    final ativo = orientacaoRetrato && indiceReal == _indiceFaseVisivel;
    return Center(
      child: Tooltip(
        message: status.titulo,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _rolarParaFase(status),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Tamanho do círculo fixo (`width`/`height` explícitos, sem
                // depender de padding) em qualquer estado — só cor/sombra
                // mudam com `ativo`; `alignment: Alignment.center` garante
                // o ícone sempre centralizado dentro do círculo,
                // independente da borda de destaque estar visível ou não.
                // O "crescimento" ao ficar ativo é só um `AnimatedScale`
                // (transformação de pintura, não afeta layout/posição).
                // Antes, o tamanho do Container variava com `ativo`
                // (padding/borda), o que descentralizava o ícone — ver
                // memória do projeto para o histórico da correção.
                AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  scale: ativo ? 1.12 : 1.0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: _diametroIconeFase,
                    height: _diametroIconeFase,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ativo
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: ativo ? 0.35 : 0.18,
                          ),
                          blurRadius: ativo ? 10 : 4,
                          offset: Offset(0, ativo ? 4 : 2),
                        ),
                      ],
                    ),
                    child: Icon(icone, color: Colors.black87),
                  ),
                ),
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '$quantidade',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<QuadroAtendimentoController>();

    // Botão/gesto "Voltar" do Android pede a mesma confirmação do botão
    // "Sair" do footer de ação, em vez de sair direto — Passo 41.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmarSaida(context);
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: controller.loading
              ? const LoadingView()
              : _buildQuadro(context, controller),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNavegadorFases(controller),
            _buildHeaderFooter(context, controller),
          ],
        ),
      ),
    );
  }

  /// Elementos que antes ficavam no `AppBar` (header) da Tela 4, movidos
  /// para um footer abaixo do navegador de fases (Passo 40). Fundo em
  /// gradiente diagonal (tons de `colorScheme.primary`, deepOrange), sem
  /// cantos arredondados; botões quadrados de canto arredondado com fundo
  /// em gradiente claro (branco→creme) e sombra própria (`_botaoFooterAcao`)
  /// — cores invertidas (fundo claro, ícone na cor da marca) para se
  /// destacarem sobre o gradiente do footer. Só este bloco recebeu o
  /// estilo — o navegador de fases acima permanece inalterado.
  static const _raioCantosFooter = 16.0;

  /// Botão de ação do footer (Novo Pedido/Filtrar/Buscar/Sair): fundo em
  /// gradiente claro com sombra própria — o `IconButton` em si fica
  /// transparente, envolto num `Material` (para o efeito de toque) dentro
  /// de um `Container` decorado (gradiente + sombra), ambos com o mesmo
  /// `borderRadius` para o toque não vazar dos cantos arredondados.
  Widget _botaoFooterAcao(
    BuildContext context, {
    required IconData icone,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(_raioCantosFooter);
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFFE0B2)],
        ),
        borderRadius: borderRadius,
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: IconButton(
          icon: Icon(icone),
          color: colorScheme.primary,
          tooltip: tooltip,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderFooter(
    BuildContext context,
    QuadroAtendimentoController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(colorScheme.primary, Colors.black, 0.25)!,
            colorScheme.primary,
            Color.lerp(colorScheme.primary, Colors.white, 0.15)!,
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  fluxo.identificador,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!_somenteLeitura) ...[
                _botaoFooterAcao(
                  context,
                  icone: Icons.add_rounded,
                  tooltip: 'Novo Pedido',
                  onPressed: () => _abrirCadastroPedido(context, controller),
                ),
                const SizedBox(width: 8),
              ],
              _botaoFooterAcao(
                context,
                icone: controller.filtro == FiltroPedidoVisualizacao.todos
                    ? Icons.filter_list_rounded
                    : Icons.filter_alt_rounded,
                tooltip: 'Filtrar Pedidos',
                onPressed: () => _abrirFiltro(context, controller),
              ),
              const SizedBox(width: 8),
              _botaoFooterAcao(
                context,
                icone: Icons.search_rounded,
                tooltip: 'Busca de Pedidos',
                onPressed: () => _abrirBusca(context, controller),
              ),
              const SizedBox(width: 8),
              _botaoFooterAcao(
                context,
                icone: Icons.logout_rounded,
                tooltip: 'Sair',
                onPressed: () => _confirmarSaida(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirFiltro(
    BuildContext context,
    QuadroAtendimentoController controller,
  ) async {
    final novoFiltro = await showDialog<FiltroPedidoVisualizacao>(
      context: context,
      builder: (_) => FiltroPedidosDialog(filtroAtual: controller.filtro),
    );
    if (novoFiltro != null) {
      controller.alterarFiltro(novoFiltro);
    }
  }

  Future<void> _abrirBusca(
    BuildContext context,
    QuadroAtendimentoController controller,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BuscaPedidosScreen(
          fluxoAtendimentoId: fluxo.identificador,
          somenteLeitura: _somenteLeitura,
        ),
      ),
    );
    await controller.load();
  }

  Widget _buildQuadro(
    BuildContext context,
    QuadroAtendimentoController controller,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (index, status) in PedidoStatus.values.indexed) ...[
                if (index > 0) const SizedBox(width: 12),
                SizedBox(
                  width: 300,
                  height: constraints.maxHeight,
                  child: _KanbanColuna(
                    status: status,
                    cor: corColuna(index, PedidoStatus.values.length),
                    pedidos: controller.pedidosDe(status),
                    somenteLeitura: _somenteLeitura,
                    controller: controller,
                    onAbrirCadastroPedido: (context, pedidoExistente) =>
                        _abrirCadastroPedido(
                          context,
                          controller,
                          pedidoExistente: pedidoExistente,
                        ),
                    onAbrirExecucaoPedido: (context, pedido) =>
                        _abrirExecucaoPedido(context, controller, pedido),
                    onAbrirEdicaoExecucao: (context, pedido) =>
                        _abrirEdicaoExecucao(context, controller, pedido),
                    onAbrirCancelamento: (context, pedido) =>
                        _abrirCancelamento(context, controller, pedido),
                    onAbrirDevolucao: (context, pedido) =>
                        _abrirDevolucao(context, controller, pedido),
                    onAtualizarStatus: (pedido, novoStatus) =>
                        _atualizarStatusENavegar(
                          controller,
                          pedido,
                          novoStatus,
                        ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmarSaida(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair'),
        content: const Text(
          'Deseja sair da execução deste fluxo de atendimento?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _abrirCadastroPedido(
    BuildContext context,
    QuadroAtendimentoController controller, {
    Pedido? pedidoExistente,
  }) async {
    final novoStatus = await Navigator.of(context).push<PedidoStatus>(
      MaterialPageRoute(
        builder: (_) => CadastroPedidoScreen(
          fluxoAtendimentoId: fluxo.identificador,
          pedidoExistente: pedidoExistente,
        ),
      ),
    );
    if (novoStatus != null) _statusAlvoAposRecarga = novoStatus;
    await controller.load();
  }

  Future<void> _abrirExecucaoPedido(
    BuildContext context,
    QuadroAtendimentoController controller,
    Pedido pedido,
  ) async {
    final novoStatus = await Navigator.of(context).push<PedidoStatus>(
      MaterialPageRoute(builder: (_) => ExecucaoPedidoScreen(pedido: pedido)),
    );
    if (novoStatus != null) _statusAlvoAposRecarga = novoStatus;
    await controller.load();
  }

  Future<void> _abrirEdicaoExecucao(
    BuildContext context,
    QuadroAtendimentoController controller,
    Pedido pedido,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EdicaoPedidoExecucaoScreen(pedido: pedido),
      ),
    );
    await controller.load();
  }

  Future<void> _abrirCancelamento(
    BuildContext context,
    QuadroAtendimentoController controller,
    Pedido pedido,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CancelamentoPedidoScreen(pedido: pedido),
      ),
    );
    await controller.load();
  }

  Future<void> _abrirDevolucao(
    BuildContext context,
    QuadroAtendimentoController controller,
    Pedido pedido,
  ) async {
    final novoStatus = await Navigator.of(context).push<PedidoStatus>(
      MaterialPageRoute(builder: (_) => DevolucaoEntregaScreen(pedido: pedido)),
    );
    if (novoStatus != null) _statusAlvoAposRecarga = novoStatus;
    await controller.load();
  }
}

class _KanbanColuna extends StatelessWidget {
  const _KanbanColuna({
    required this.status,
    required this.cor,
    required this.pedidos,
    required this.somenteLeitura,
    required this.controller,
    required this.onAbrirCadastroPedido,
    required this.onAbrirExecucaoPedido,
    required this.onAbrirEdicaoExecucao,
    required this.onAbrirCancelamento,
    required this.onAbrirDevolucao,
    required this.onAtualizarStatus,
  });

  final PedidoStatus status;
  final Color cor;
  final List<Pedido> pedidos;
  final bool somenteLeitura;
  final QuadroAtendimentoController controller;
  final Future<void> Function(BuildContext context, Pedido? pedidoExistente)
  onAbrirCadastroPedido;
  final Future<void> Function(BuildContext context, Pedido pedido)
  onAbrirExecucaoPedido;
  final Future<void> Function(BuildContext context, Pedido pedido)
  onAbrirEdicaoExecucao;
  final Future<void> Function(BuildContext context, Pedido pedido)
  onAbrirCancelamento;
  final Future<void> Function(BuildContext context, Pedido pedido)
  onAbrirDevolucao;

  /// Ações rápidas do card (Retirado/Enviado/Entregue) passam por aqui em
  /// vez de chamar `controller.atualizarStatus` direto, para o Kanban saber
  /// para qual coluna navegar após o refresh (Passo 42).
  final Future<void> Function(Pedido pedido, PedidoStatus novoStatus)
  onAtualizarStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: corCinza(status) ?? cor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(iconePorFase[status], size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${status.titulo} (${pedidos.length})',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: pedidos.isEmpty
                ? const SizedBox.shrink()
                : ListView.builder(
                    itemCount: pedidos.length,
                    itemBuilder: (context, index) {
                      final pedido = pedidos[index];
                      return PedidoCard(
                        pedido: pedido,
                        somenteLeitura: somenteLeitura,
                        onExcluir: () => _executar(
                          context,
                          () => controller.excluir(pedido),
                        ),
                        onRetirado: () => _executar(
                          context,
                          () => onAtualizarStatus(
                            pedido,
                            PedidoStatus.retiradoNoBalcao,
                          ),
                        ),
                        onEnviado: () => _executar(
                          context,
                          () => onAtualizarStatus(pedido, PedidoStatus.enviado),
                        ),
                        onEntregue: () => _executar(
                          context,
                          () =>
                              onAtualizarStatus(pedido, PedidoStatus.entregue),
                        ),
                        onAtendimento: () =>
                            onAbrirCadastroPedido(context, pedido),
                        onEditarCadastro: () =>
                            onAbrirCadastroPedido(context, pedido),
                        onExecutar: () =>
                            onAbrirExecucaoPedido(context, pedido),
                        onEditarExecucao: () =>
                            onAbrirEdicaoExecucao(context, pedido),
                        onCancelar: () => onAbrirCancelamento(context, pedido),
                        onDevolvido: () => onAbrirDevolucao(context, pedido),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _executar(
    BuildContext context,
    Future<void> Function() acao,
  ) async {
    try {
      await acao();
    } on StateError catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}
