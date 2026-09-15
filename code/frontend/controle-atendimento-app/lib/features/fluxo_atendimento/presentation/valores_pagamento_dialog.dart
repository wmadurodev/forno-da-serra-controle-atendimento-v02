import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../pedido/data/pedido_repository.dart';
import '../../pedido/domain/pedido.dart';
import '../domain/fluxo_atendimento.dart';

/// Popup com os Pedidos de um Fluxo de Atendimento que têm valor de
/// pagamento lançado, e o total somado — Passo 29 (Home).
class ValoresPagamentoDialog extends StatefulWidget {
  const ValoresPagamentoDialog({super.key, required this.fluxo});

  final FluxoAtendimento fluxo;

  @override
  State<ValoresPagamentoDialog> createState() => _ValoresPagamentoDialogState();
}

class _ValoresPagamentoDialogState extends State<ValoresPagamentoDialog> {
  bool _carregando = true;
  List<Pedido> _pedidos = const [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final repository = context.read<PedidoRepository>();
    final pedidos = await repository.listComValorPagamento(widget.fluxo.identificador);
    if (!mounted) return;
    setState(() {
      _pedidos = pedidos;
      _carregando = false;
    });
  }

  double get _total => _pedidos.fold(0.0, (soma, pedido) => soma + (pedido.valorPagamento ?? 0));

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Valores de Pagamento — ${widget.fluxo.identificador}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_carregando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_pedidos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Nenhum pedido com valor de pagamento lançado.'),
              )
            else ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _pedidos.length,
                  separatorBuilder: (_, _) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final pedido = _pedidos[index];
                    final nome = (pedido.nomeCliente?.isNotEmpty ?? false) ? pedido.nomeCliente! : pedido.identificador;
                    final tipoPagamento = pedido.tipoPagamento != null ? '(${pedido.tipoPagamento!.titulo}) ' : '';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$tipoPagamento$nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('R\$ ${pedido.valorPagamento!.toStringAsFixed(2)}'),
                      ],
                    );
                  },
                ),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('R\$ ${_total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
