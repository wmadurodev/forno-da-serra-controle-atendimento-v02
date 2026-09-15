import 'dart:io';

import 'package:flutter/material.dart';

import '../../pedido/domain/pedido.dart';
import 'imagem_pedido_tela_cheia.dart';

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
    required this.onExecutar,
    required this.onEditarExecucao,
    required this.onCancelar,
    required this.onDevolvido,
  });

  final Pedido pedido;
  final bool somenteLeitura;
  final Future<void> Function() onExcluir;
  final Future<void> Function() onRetirado;
  final Future<void> Function() onEnviado;
  final Future<void> Function() onEntregue;
  final VoidCallback onAtendimento;
  final VoidCallback onEditarCadastro;
  final VoidCallback onExecutar;
  final VoidCallback onEditarExecucao;
  final VoidCallback onCancelar;
  final VoidCallback onDevolvido;

  /// Formata `HH:mm` (hora local do dispositivo) — Passo 12.
  static String _horaMinuto(DateTime dataHora) {
    String pad2(int v) => v.toString().padLeft(2, '0');
    return '${pad2(dataHora.hour)}:${pad2(dataHora.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final dataHoraStatusAtual = pedido.dataHoraStatusAtual;
    final titulo = dataHoraStatusAtual != null
        ? '${pedido.identificador} (${_horaMinuto(dataHoraStatusAtual)})'
        : pedido.identificador;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: pedido.cancelado ? Colors.red.shade100 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            if (pedido.cancelado) ..._camposCancelado(),
            ..._campos(context),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _camposCancelado() {
    final dataHoraCancelamento = pedido.dataHoraCancelamento;
    final textoCancelado =
        dataHoraCancelamento != null ? 'Cancelado (${_horaMinuto(dataHoraCancelamento)})' : 'Cancelado';
    final widgets = <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          textoCancelado,
          style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
        ),
      ),
    ];
    if (pedido.motivoCancelamento != null && pedido.motivoCancelamento!.isNotEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(pedido.motivoCancelamento!, style: TextStyle(color: Colors.red.shade900)),
        ),
      );
    }
    return widgets;
  }

  /// Lista única de campos, sem distinção por status: cada um só aparece
  /// se tiver valor — Passo 14. Ordem: Cliente, Mesa, Entrega, Endereço,
  /// Pagamento, Observação, Restrições, Imagem, Motivo da Devolução.
  List<Widget> _campos(BuildContext context) {
    final widgets = <Widget>[];

    void campo(IconData icone, String? valor, {bool negrito = false}) {
      if (valor == null || valor.isEmpty) return;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icone, size: 16, color: Colors.black54),
              const SizedBox(width: 6),
              Expanded(
                child: Text(valor, style: negrito ? const TextStyle(fontWeight: FontWeight.bold) : null),
              ),
            ],
          ),
        ),
      );
    }

    if (pedido.nomeCliente != null && pedido.nomeCliente!.isNotEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(pedido.nomeCliente!, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }
    campo(Icons.table_restaurant_outlined, pedido.mesa);
    campo(Icons.local_shipping_outlined, pedido.tipoEntrega?.titulo);
    if (pedido.tipoEntrega == TipoEntrega.delivery) {
      campo(Icons.location_on_outlined, pedido.endereco);
    }
    campo(Icons.payments_outlined, pedido.tipoPagamento?.titulo);
    campo(Icons.notes_outlined, pedido.observacao, negrito: true);
    campo(Icons.warning_amber_outlined, pedido.restricoes);
    if (pedido.imagemPedidoRef != null) {
      final caminhoImagem = pedido.imagemPedidoRef!;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => ImagemPedidoTelaCheia(caminhoImagem: caminhoImagem),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.file(File(caminhoImagem), height: 120, fit: BoxFit.cover),
            ),
          ),
        ),
      );
    }
    campo(Icons.assignment_return_outlined, pedido.motivoDevolucao);

    return widgets;
  }

  Widget _buildFooter(BuildContext context) {
    if (pedido.cancelado || somenteLeitura) return const SizedBox.shrink();

    final List<Widget> botoes;
    switch (pedido.status) {
      case PedidoStatus.aguardandoAtendimento:
        botoes = [
          IconButton(
            icon: const Icon(Icons.support_agent_outlined),
            tooltip: 'Atendimento',
            onPressed: onAtendimento,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Excluir',
            onPressed: () => _confirmarExclusao(context),
          ),
        ];
      case PedidoStatus.emAtendimento:
        botoes = [
          IconButton(icon: const Icon(Icons.play_circle_outline), tooltip: 'Executar', onPressed: onExecutar),
          IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Editar', onPressed: onEditarCadastro),
          IconButton(icon: const Icon(Icons.cancel_outlined), tooltip: 'Cancelar', onPressed: onCancelar),
        ];
      case PedidoStatus.emExecucao:
        botoes = [
          if (pedido.tipoEntrega == TipoEntrega.delivery)
            IconButton(
              icon: const Icon(Icons.local_shipping_outlined),
              tooltip: 'Enviado',
              onPressed: () => onEnviado(),
            )
          else
            IconButton(
              icon: const Icon(Icons.storefront_outlined),
              tooltip: 'Retirado',
              onPressed: () => onRetirado(),
            ),
          IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Editar', onPressed: onEditarExecucao),
          IconButton(icon: const Icon(Icons.cancel_outlined), tooltip: 'Cancelar', onPressed: onCancelar),
        ];
      case PedidoStatus.enviado:
        botoes = [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: 'Entregue',
            onPressed: () => onEntregue(),
          ),
          IconButton(
            icon: const Icon(Icons.assignment_return_outlined),
            tooltip: 'Devolvido',
            onPressed: onDevolvido,
          ),
        ];
      case PedidoStatus.retiradoNoBalcao:
      case PedidoStatus.entregue:
      case PedidoStatus.devolvido:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: botoes,
        ),
      ),
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
