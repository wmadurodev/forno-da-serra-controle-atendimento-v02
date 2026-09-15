import 'package:flutter/material.dart';

import '../../../core/widgets/slide_to_confirm_button.dart';
import '../domain/fluxo_atendimento.dart';

/// Diálogo de confirmação para excluir definitivamente um Fluxo de
/// Atendimento e todos os seus Pedidos (Passo 11) — exclusão em cascata,
/// sem manter histórico (`functional.md` FN-6, aplicado ao fluxo inteiro).
/// Usa o mesmo controle de "arrastar para confirmar" do fechamento de
/// fluxo, por ser uma ação irreversível e de maior impacto.
///
/// Retorna `true` (via `Navigator.pop`) se confirmado, `false`/`null` se
/// descartado pelo ícone de fechar.
class ExcluirFluxoDialog extends StatefulWidget {
  const ExcluirFluxoDialog({super.key, required this.fluxo});

  final FluxoAtendimento fluxo;

  @override
  State<ExcluirFluxoDialog> createState() => _ExcluirFluxoDialogState();
}

class _ExcluirFluxoDialogState extends State<ExcluirFluxoDialog> {
  /// Passo 37: exclusão exige 2 arrastos sequenciais; a Fase 2 só é
  /// habilitada depois que a Fase 1 é concluída.
  bool _fase1Confirmada = false;

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
                    'Excluir Fluxo de Atendimento',
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
              'Arraste até o final, nas 2 etapas abaixo, para excluir definitivamente o fluxo '
              '"${widget.fluxo.identificador}" e TODOS os seus pedidos. '
              'Essa ação não pode ser desfeita.',
            ),
            const SizedBox(height: 24),
            SlideToConfirmButton(
              label: 'Arraste para excluir - Fase 1',
              onConfirmed: () => setState(() => _fase1Confirmada = true),
            ),
            const SizedBox(height: 12),
            SlideToConfirmButton(
              label: 'Arraste para excluir - Fase 2',
              enabled: _fase1Confirmada,
              onConfirmed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }
}
