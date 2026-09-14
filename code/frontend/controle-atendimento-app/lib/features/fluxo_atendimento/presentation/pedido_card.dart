import 'package:flutter/material.dart';

import '../../pedido/domain/pedido.dart';

/// Card de Pedido exibido nas colunas do quadro Kanban da Tela 4
/// (`docs/controle-atendimento-prototype.md` §4).
class PedidoCard extends StatelessWidget {
  const PedidoCard({
    super.key,
    required this.pedido,
    required this.somenteLeitura,
    required this.onExcluir,
    required this.onRetirado,
    required this.onEnviado,
    required this.onEntregue,
    required this.onAtendimento,
    required this.onEditarCadastro,
  });

  final Pedido pedido;
  final bool somenteLeitura;
  final Future<void> Function() onExcluir;
  final Future<void> Function() onRetirado;
  final Future<void> Function() onEnviado;
  final Future<void> Function() onEntregue;
  final VoidCallback onAtendimento;
  final VoidCallback onEditarCadastro;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pedido.identificador, style: Theme.of(context).textTheme.titleMedium),
            if (pedido.cancelado)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('cancelado', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ..._campos(),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _campos() {
    final widgets = <Widget>[];

    void add(String label, String? valor) {
      if (valor == null || valor.isEmpty) return;
      widgets.add(Padding(padding: const EdgeInsets.only(top: 4), child: Text('$label: $valor')));
    }

    switch (pedido.status) {
      case PedidoStatus.aguardandoAtendimento:
        break;
      case PedidoStatus.emAtendimento:
        add('Cliente', pedido.nomeCliente);
        add('Entrega', pedido.tipoEntrega?.titulo);
        add('Pagamento', pedido.tipoPagamento?.titulo);
        if (pedido.tipoEntrega == TipoEntrega.delivery) add('Endereço', pedido.endereco);
        add('Observação', pedido.observacao);
      case PedidoStatus.emExecucao:
      case PedidoStatus.retiradoNoBalcao:
      case PedidoStatus.enviado:
      case PedidoStatus.entregue:
      case PedidoStatus.devolvido:
        add('Cliente', pedido.nomeCliente);
        add('Entrega', pedido.tipoEntrega?.titulo);
        add('Pagamento', pedido.tipoPagamento?.titulo);
        if (pedido.tipoEntrega == TipoEntrega.delivery) add('Endereço', pedido.endereco);
        add('Observação', pedido.observacao);
        add('Mesa', pedido.mesa);
        add('Restrições', pedido.restricoes);
        add('Imagem', pedido.imagemPedidoRef);
        if (pedido.status == PedidoStatus.devolvido) add('Motivo da Devolução', pedido.motivoDevolucao);
    }

    return widgets;
  }

  Widget _buildFooter(BuildContext context) {
    if (pedido.cancelado || somenteLeitura) return const SizedBox.shrink();

    final List<Widget> botoes;
    switch (pedido.status) {
      case PedidoStatus.aguardandoAtendimento:
        botoes = [
          OutlinedButton(onPressed: onAtendimento, child: const Text('Atendimento')),
          OutlinedButton(onPressed: () => _confirmarExclusao(context), child: const Text('Excluir')),
        ];
      case PedidoStatus.emAtendimento:
        botoes = [
          OutlinedButton(onPressed: () => _acaoFutura(context, 'Passo 5'), child: const Text('Executar')),
          OutlinedButton(onPressed: onEditarCadastro, child: const Text('Editar')),
          OutlinedButton(onPressed: () => _acaoFutura(context, 'Passo 7'), child: const Text('Cancelar')),
        ];
      case PedidoStatus.emExecucao:
        botoes = [
          if (pedido.tipoEntrega == TipoEntrega.delivery)
            OutlinedButton(onPressed: () => onEnviado(), child: const Text('Enviado'))
          else
            OutlinedButton(onPressed: () => onRetirado(), child: const Text('Retirado')),
          OutlinedButton(onPressed: () => _acaoFutura(context, 'Passo 6'), child: const Text('Editar')),
          OutlinedButton(onPressed: () => _acaoFutura(context, 'Passo 7'), child: const Text('Cancelar')),
        ];
      case PedidoStatus.enviado:
        botoes = [
          OutlinedButton(onPressed: () => onEntregue(), child: const Text('Entregue')),
          OutlinedButton(onPressed: () => _acaoFutura(context, 'Passo 8'), child: const Text('Devolvido')),
        ];
      case PedidoStatus.retiradoNoBalcao:
      case PedidoStatus.entregue:
      case PedidoStatus.devolvido:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(spacing: 8, runSpacing: 8, children: botoes),
    );
  }

  void _acaoFutura(BuildContext context, String passo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Disponível a partir do $passo')),
    );
  }

  Future<void> _confirmarExclusao(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir Pedido'),
        content: Text('Deseja excluir o pedido "${pedido.identificador}"? Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Excluir')),
        ],
      ),
    );

    if (confirmar == true) {
      await onExcluir();
    }
  }
}
