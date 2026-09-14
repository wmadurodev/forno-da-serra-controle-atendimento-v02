import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/loading_view.dart';
import '../../pedido/data/pedido_repository.dart';
import '../../pedido/domain/pedido.dart';
import '../domain/fluxo_atendimento.dart';
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
              onPressed: () => _snack(context, 'Disponível a partir do Passo 4'),
            ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Busca de Pedidos',
            onPressed: () => _snack(context, 'Funcionalidade não implementada nesta fase'),
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
}

class _KanbanColuna extends StatelessWidget {
  const _KanbanColuna({
    required this.status,
    required this.pedidos,
    required this.somenteLeitura,
    required this.controller,
  });

  final PedidoStatus status;
  final List<Pedido> pedidos;
  final bool somenteLeitura;
  final QuadroAtendimentoController controller;

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
