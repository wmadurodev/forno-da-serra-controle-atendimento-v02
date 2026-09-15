import 'package:flutter/material.dart';

/// Controle deslizante horizontal que só dispara [onConfirmed] quando
/// arrastado até o final do percurso — usado para confirmar ações
/// destrutivas/irreversíveis sem risco de toque acidental.
class SlideToConfirmButton extends StatefulWidget {
  const SlideToConfirmButton({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onConfirmed;

  /// Quando `false`, o controle não responde a arrastos e usa uma cor
  /// neutra em vez da cor de ação destrutiva — Passo 37 (confirmação de
  /// exclusão de fluxo em 2 fases sequenciais).
  final bool enabled;

  @override
  State<SlideToConfirmButton> createState() => _SlideToConfirmButtonState();
}

class _SlideToConfirmButtonState extends State<SlideToConfirmButton> {
  static const _thumbSize = 48.0;
  static const _limiarConfirmacao = 0.9;

  double _posicao = 0;
  bool _confirmado = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final percursoMaximo = constraints.maxWidth - _thumbSize;

        return Container(
          height: _thumbSize,
          decoration: BoxDecoration(
            color: widget.enabled
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(_thumbSize / 2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.enabled ? colorScheme.onSurfaceVariant : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
              Positioned(
                left: _posicao,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (!widget.enabled || _confirmado) return;
                    setState(() {
                      _posicao = (_posicao + details.delta.dx).clamp(0, percursoMaximo);
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (!widget.enabled || _confirmado) return;
                    if (_posicao >= percursoMaximo * _limiarConfirmacao) {
                      setState(() {
                        _posicao = percursoMaximo;
                        _confirmado = true;
                      });
                      widget.onConfirmed();
                    } else {
                      setState(() => _posicao = 0);
                    }
                  },
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.enabled ? colorScheme.error : Colors.grey.shade400,
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      color: widget.enabled ? colorScheme.onError : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
