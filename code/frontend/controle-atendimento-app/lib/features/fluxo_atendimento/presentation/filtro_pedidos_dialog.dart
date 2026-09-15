import 'package:flutter/material.dart';

import 'quadro_atendimento_controller.dart';

/// Diálogo de seleção do critério de visualização do Kanban por
/// cancelamento (Passo 13). Selecionar uma opção já fecha o diálogo,
/// devolvendo o valor escolhido via `Navigator.pop`.
class FiltroPedidosDialog extends StatelessWidget {
  const FiltroPedidosDialog({super.key, required this.filtroAtual});

  final FiltroPedidoVisualizacao filtroAtual;

  static const _opcoes = {
    FiltroPedidoVisualizacao.todos: 'Todos',
    FiltroPedidoVisualizacao.somenteCancelados: 'Somente Cancelados',
    FiltroPedidoVisualizacao.somenteNaoCancelados: 'Somente Não Cancelados',
  };

  @override
  Widget build(BuildContext context) {
    return RadioGroup<FiltroPedidoVisualizacao>(
      groupValue: filtroAtual,
      onChanged: (valor) {
        if (valor != null) Navigator.of(context).pop(valor);
      },
      child: SimpleDialog(
        title: const Text('Filtrar Pedidos'),
        children: [
          for (final entry in _opcoes.entries)
            RadioListTile<FiltroPedidoVisualizacao>(title: Text(entry.value), value: entry.key),
        ],
      ),
    );
  }
}
