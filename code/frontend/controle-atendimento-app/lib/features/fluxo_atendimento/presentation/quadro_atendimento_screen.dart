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
  final _scrollController = ScrollController();

  FluxoAtendimento get fluxo => widget.fluxo;
  bool get _somenteLeitura => fluxo.status == FluxoAtendimentoStatus.fechado;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Rola o Kanban horizontalmente até a coluna de `status` ficar alinhada
  /// à esquerda da tela visível — Passo 25.
  void _rolarParaFase(PedidoStatus status) {
    final indice = PedidoStatus.values.indexOf(status);
    const larguraColuna = 300.0;
    const espacamento = 12.0;
    const paddingInicial = 8.0;
    final offsetAlvo = paddingInicial + indice * (larguraColuna + espacamento);
    final maximo = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      offsetAlvo.clamp(0.0, maximo),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildNavegadorFases(QuadroAtendimentoController controller) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final status in PedidoStatus.values)
              _iconeFase(status, iconePorFase[status]!, controller.pedidosDe(status).length),
          ],
        ),
      ),
    );
  }

  Widget _iconeFase(PedidoStatus status, IconData icone, int quantidade) {
    final indiceReal = PedidoStatus.values.indexOf(status);
    final cor = corCinza(status) ?? corColuna(indiceReal, PedidoStatus.values.length);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: status.titulo,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _rolarParaFase(status),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
              child: Icon(icone, color: Colors.black87),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text('$quantidade', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<QuadroAtendimentoController>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(fluxo.identificador),
        actions: [
          if (!_somenteLeitura) ...[
            IconButton.filledTonal(
              icon: const Icon(Icons.add),
              tooltip: 'Novo Pedido',
              onPressed: () => _abrirCadastroPedido(context, controller),
            ),
            const SizedBox(width: 4),
          ],
          IconButton.filledTonal(
            icon: Icon(controller.filtro == FiltroPedidoVisualizacao.todos ? Icons.filter_list : Icons.filter_alt),
            tooltip: 'Filtrar Pedidos',
            onPressed: () => _abrirFiltro(context, controller),
          ),
          const SizedBox(width: 4),
          IconButton.filledTonal(
            icon: const Icon(Icons.search),
            tooltip: 'Busca de Pedidos',
            onPressed: () => _abrirBusca(context, controller),
          ),
          const SizedBox(width: 4),
          IconButton.filledTonal(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => _confirmarSaida(context),
          ),
        ],
      ),
      body: controller.loading ? const LoadingView() : _buildQuadro(context, controller),
      bottomNavigationBar: _buildNavegadorFases(controller),
    );
  }

  Future<void> _abrirFiltro(BuildContext context, QuadroAtendimentoController controller) async {
    final novoFiltro = await showDialog<FiltroPedidoVisualizacao>(
      context: context,
      builder: (_) => FiltroPedidosDialog(filtroAtual: controller.filtro),
    );
    if (novoFiltro != null) {
      controller.alterarFiltro(novoFiltro);
    }
  }

  Future<void> _abrirBusca(BuildContext context, QuadroAtendimentoController controller) async {
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

  Widget _buildQuadro(BuildContext context, QuadroAtendimentoController controller) {
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
                        _abrirCadastroPedido(context, controller, pedidoExistente: pedidoExistente),
                    onAbrirExecucaoPedido: (context, pedido) => _abrirExecucaoPedido(context, controller, pedido),
                    onAbrirEdicaoExecucao: (context, pedido) => _abrirEdicaoExecucao(context, controller, pedido),
                    onAbrirCancelamento: (context, pedido) => _abrirCancelamento(context, controller, pedido),
                    onAbrirDevolucao: (context, pedido) => _abrirDevolucao(context, controller, pedido),
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
        content: const Text('Deseja sair da execução deste fluxo de atendimento?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Sair')),
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
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CadastroPedidoScreen(
          fluxoAtendimentoId: fluxo.identificador,
          pedidoExistente: pedidoExistente,
        ),
      ),
    );
    await controller.load();
  }

  Future<void> _abrirExecucaoPedido(
    BuildContext context,
    QuadroAtendimentoController controller,
    Pedido pedido,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ExecucaoPedidoScreen(pedido: pedido)),
    );
    await controller.load();
  }

  Future<void> _abrirEdicaoExecucao(
    BuildContext context,
    QuadroAtendimentoController controller,
    Pedido pedido,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EdicaoPedidoExecucaoScreen(pedido: pedido)),
    );
    await controller.load();
  }

  Future<void> _abrirCancelamento(
    BuildContext context,
    QuadroAtendimentoController controller,
    Pedido pedido,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CancelamentoPedidoScreen(pedido: pedido)),
    );
    await controller.load();
  }

  Future<void> _abrirDevolucao(
    BuildContext context,
    QuadroAtendimentoController controller,
    Pedido pedido,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DevolucaoEntregaScreen(pedido: pedido)),
    );
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
  });

  final PedidoStatus status;
  final Color cor;
  final List<Pedido> pedidos;
  final bool somenteLeitura;
  final QuadroAtendimentoController controller;
  final Future<void> Function(BuildContext context, Pedido? pedidoExistente) onAbrirCadastroPedido;
  final Future<void> Function(BuildContext context, Pedido pedido) onAbrirExecucaoPedido;
  final Future<void> Function(BuildContext context, Pedido pedido) onAbrirEdicaoExecucao;
  final Future<void> Function(BuildContext context, Pedido pedido) onAbrirCancelamento;
  final Future<void> Function(BuildContext context, Pedido pedido) onAbrirDevolucao;

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
                        onExcluir: () => _executar(context, () => controller.excluir(pedido)),
                        onRetirado: () => _executar(
                          context,
                          () => controller.atualizarStatus(pedido, PedidoStatus.retiradoNoBalcao),
                        ),
                        onEnviado: () => _executar(
                          context,
                          () => controller.atualizarStatus(pedido, PedidoStatus.enviado),
                        ),
                        onEntregue: () => _executar(
                          context,
                          () => controller.atualizarStatus(pedido, PedidoStatus.entregue),
                        ),
                        onAtendimento: () => onAbrirCadastroPedido(context, pedido),
                        onEditarCadastro: () => onAbrirCadastroPedido(context, pedido),
                        onExecutar: () => onAbrirExecucaoPedido(context, pedido),
                        onEditarExecucao: () => onAbrirEdicaoExecucao(context, pedido),
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

  Future<void> _executar(BuildContext context, Future<void> Function() acao) async {
    try {
      await acao();
    } on StateError catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}
