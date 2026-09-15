import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../pedido/data/pedido_repository.dart';
import '../../pedido/domain/pedido.dart';
import '../domain/fluxo_atendimento.dart';

/// Popup com os Pedidos `delivery` de um Fluxo de Atendimento, para a
/// Prestação de Contas com o Motoqueiro — Passo 33 (Home).
class PrestacaoContasMotoqueiroDialog extends StatefulWidget {
  const PrestacaoContasMotoqueiroDialog({super.key, required this.fluxo});

  final FluxoAtendimento fluxo;

  @override
  State<PrestacaoContasMotoqueiroDialog> createState() => _PrestacaoContasMotoqueiroDialogState();
}

class _PrestacaoContasMotoqueiroDialogState extends State<PrestacaoContasMotoqueiroDialog> {
  bool _carregando = true;
  List<Pedido> _pedidos = const [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final repository = context.read<PedidoRepository>();
    final pedidos = await repository.listDelivery(widget.fluxo.identificador);
    if (!mounted) return;
    setState(() {
      _pedidos = pedidos;
      _carregando = false;
    });
  }

  String _horario(Pedido pedido) {
    final dataHoraEnviado = pedido.dataHoraEnviado;
    if (dataHoraEnviado == null) return '--:--';
    final hora = dataHoraEnviado.hour.toString().padLeft(2, '0');
    final minuto = dataHoraEnviado.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }

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
                    'Prestação de Contas com o Motoqueiro — ${widget.fluxo.identificador}',
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
                child: Text('Nenhum pedido delivery neste fluxo.'),
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
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$nome (${_horario(pedido)})', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(pedido.endereco ?? ''),
                      ],
                    );
                  },
                ),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total de Entregas', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${_pedidos.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
