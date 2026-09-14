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

class _QuadroView extends StatelessWidget {
  const _QuadroView({required this.fluxo});

  final FluxoAtendimento fluxo;

  bool get _somenteLeitura => fluxo.status == FluxoAtendimentoStatus.fechado;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<QuadroAtendimentoController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(fluxo.identificador),
        actions: [
          if (!_somenteLeitura)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Novo Pedido',
              onPressed: () => _abrirCadastroPedido(context, controller),
            ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Busca de Pedidos',
            onPressed: () => _snack(context, 'Funcionalidade não implementada nesta fase'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => _confirmarSaida(context),
          ),
        ],
      ),
      body: controller.loading ? const LoadingView() : _buildQuadro(context, controller),
    );
  }

  Widget _buildQuadro(BuildContext context, QuadroAtendimentoController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: PedidoStatus.values
                .map(
                  (status) => SizedBox(
                    width: 300,
                    height: constraints.maxHeight,
                    child: _KanbanColuna(
                      status: status,
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
                )
                .toList(),
          ),
        );
      },
    );
  }

  void _snack(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '${status.titulo} (${pedidos.length})',
              style: Theme.of(context).textTheme.titleSmall,
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
