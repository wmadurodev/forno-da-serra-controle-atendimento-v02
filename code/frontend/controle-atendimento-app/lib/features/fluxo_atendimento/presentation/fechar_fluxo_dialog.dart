import 'package:flutter/material.dart';

import '../../../core/widgets/slide_to_confirm_button.dart';
import '../domain/fluxo_atendimento.dart';

/// Diálogo de confirmação para fechar um Fluxo de Atendimento a partir da
/// Home (`functional.md` §5.3). Usa um controle de "arrastar para
/// confirmar" para evitar o fechamento por toque acidental.
///
/// Retorna `true` (via `Navigator.pop`) se confirmado, `false`/`null` se
/// descartado pelo ícone de fechar.
class FecharFluxoDialog extends StatelessWidget {
  const FecharFluxoDialog({super.key, required this.fluxo});

  final FluxoAtendimento fluxo;

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
                    'Fechar Fluxo de Atendimento',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Arraste até o final para confirmar o fechamento do fluxo '
              '"${fluxo.identificador}". Essa ação não pode ser desfeita pela interface.',
            ),
            const SizedBox(height: 24),
            SlideToConfirmButton(
              label: 'Arraste para fechar',
              onConfirmed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }
}
