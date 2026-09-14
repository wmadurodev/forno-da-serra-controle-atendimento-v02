import 'package:flutter/material.dart';

import '../domain/fluxo_atendimento.dart';

/// Tela 4 provisória (`docs/controle-atendimento-prototype.md` §3.4).
///
/// Implementação mínima apenas para fechar a navegação ponta a ponta no
/// Passo 1. O quadro Kanban completo é implementado no Passo 3.
class FluxoAtendimentoPlaceholderScreen extends StatelessWidget {
  const FluxoAtendimentoPlaceholderScreen({super.key, required this.fluxo});

  final FluxoAtendimento fluxo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(fluxo.identificador)),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Quadro de pedidos — implementação prevista para o Passo 3',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
