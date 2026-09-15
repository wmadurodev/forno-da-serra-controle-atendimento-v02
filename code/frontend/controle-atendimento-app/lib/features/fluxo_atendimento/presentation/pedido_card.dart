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
          _acao(Icons.support_agent_outlined, 'Atender', onAtendimento),
          _acao(Icons.delete_outline, 'Excluir', () => _confirmarExclusao(context)),
        ];
      case PedidoStatus.emAtendimento:
        botoes = [
          _acao(Icons.play_circle_outline, 'Executar', onExecutar),
          _acao(Icons.edit_outlined, 'Editar', onEditarCadastro),
          _acao(Icons.cancel_outlined, 'Cancelar', onCancelar),
        ];
      case PedidoStatus.emExecucao:
        botoes = [
          if (pedido.tipoEntrega == TipoEntrega.delivery)
            _acao(
              Icons.two_wheeler,
              'Enviar',
              () => _confirmarAcao(
                context,
                titulo: 'Enviar Pedido',
                mensagem: 'Confirma o envio do pedido "${pedido.identificador}"?',
                acao: onEnviado,
              ),
            )
          else
            _acao(
              Icons.storefront_outlined,
              'Retirado',
              () => _confirmarAcao(
                context,
                titulo: 'Retirado',
                mensagem: 'Confirma que o pedido "${pedido.identificador}" foi retirado no balcão?',
                acao: onRetirado,
              ),
            ),
          _acao(Icons.edit_outlined, 'Editar', onEditarExecucao),
          _acao(Icons.cancel_outlined, 'Cancelar', onCancelar),
        ];
      case PedidoStatus.enviado:
        botoes = [
          _acao(
            Icons.check_circle_outline,
            'Entregue',
            () => _confirmarAcao(
              context,
              titulo: 'Entregue',
              mensagem: 'Confirma que o pedido "${pedido.identificador}" foi entregue?',
              acao: onEntregue,
            ),
          ),
          _acao(Icons.assignment_return_outlined, 'Devolvido', onDevolvido),
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

  /// Ícone de ação com o nome da ação em cinza logo abaixo — Passo 15.
  Widget _acao(IconData icone, String rotulo, VoidCallback? onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone),
            const SizedBox(height: 2),
            Text(rotulo, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          ],
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

  /// Diálogo de confirmação simples e nativo (Passo 24) — usado antes de
  /// "Enviar", "Retirado" e "Entregue".
  Future<void> _confirmarAcao(
    BuildContext context, {
    required String titulo,
    required String mensagem,
    required Future<void> Function() acao,
  }) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirmar == true) {
      await acao();
    }
  }
}
