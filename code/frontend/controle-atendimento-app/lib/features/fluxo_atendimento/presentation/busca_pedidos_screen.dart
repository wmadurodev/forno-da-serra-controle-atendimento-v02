import 'package:flutter/material.dart';

import '../../pedido/data/pedido_repository.dart';
import 'resultado_busca_pedidos_screen.dart';

/// Busca de Pedidos (Passo 27, `functional.md` §5.5, **P-7**) — formulário
/// de busca dentro do Fluxo de Atendimento informado. Estende os campos de
/// busca originais (nome, identificador, mesa, endereço) com Observação e
/// Restrição, a pedido do usuário desta iniciativa de implementação.
class BuscaPedidosScreen extends StatefulWidget {
  const BuscaPedidosScreen({
    super.key,
    required this.fluxoAtendimentoId,
    required this.somenteLeitura,
  });

  final String fluxoAtendimentoId;

  /// `true` quando o Fluxo de Atendimento está `fechado` — os resultados
  /// (Passo 28) não mostram botões de ação nesse caso.
  final bool somenteLeitura;

  @override
  State<BuscaPedidosScreen> createState() => _BuscaPedidosScreenState();
}

class _BuscaPedidosScreenState extends State<BuscaPedidosScreen> {
  final _identificadorController = TextEditingController();
  final _nomeController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _mesaController = TextEditingController();
  final _observacaoController = TextEditingController();
  final _restricaoController = TextEditingController();

  late final Map<CampoBuscaPedido, TextEditingController> _controllers = {
    CampoBuscaPedido.identificador: _identificadorController,
    CampoBuscaPedido.nomeCliente: _nomeController,
    CampoBuscaPedido.endereco: _enderecoController,
    CampoBuscaPedido.mesa: _mesaController,
    CampoBuscaPedido.observacao: _observacaoController,
    CampoBuscaPedido.restricoes: _restricaoController,
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Só um campo pode ter valor por vez — ao digitar em um, os outros são
  /// limpos (e ficam desabilitados, ver `_campoBusca`).
  void _onCampoAlterado(TextEditingController alterado) {
    if (alterado.text.isNotEmpty) {
      for (final controller in _controllers.values) {
        if (controller != alterado) controller.clear();
      }
    }
    setState(() {});
  }

  bool get _algumPreenchido =>
      _controllers.values.any((c) => c.text.trim().isNotEmpty);

  void _onLimpar() {
    setState(() {
      for (final controller in _controllers.values) {
        controller.clear();
      }
    });
  }

  void _onBuscar() {
    CampoBuscaPedido? campo;
    var valor = '';
    for (final entry in _controllers.entries) {
      final texto = entry.value.text.trim();
      if (texto.isNotEmpty) {
        campo = entry.key;
        valor = texto;
        break;
      }
    }
    if (campo == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultadoBuscaPedidosScreen(
          fluxoAtendimentoId: widget.fluxoAtendimentoId,
          somenteLeitura: widget.somenteLeitura,
          campo: campo!,
          valor: valor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Busca de Pedidos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _campoBusca(
              'Identificador do Pedido',
              _identificadorController,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            _campoBusca('Nome', _nomeController),
            const SizedBox(height: 12),
            _campoBusca('Endereço', _enderecoController),
            const SizedBox(height: 12),
            _campoBusca('Mesa', _mesaController),
            const SizedBox(height: 12),
            _campoBusca('Observação', _observacaoController),
            const SizedBox(height: 12),
            _campoBusca('Restrição', _restricaoController),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _algumPreenchido ? _onLimpar : null,
                  child: const Text('Limpar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: _algumPreenchido ? _onBuscar : null,
                  child: const Text('Buscar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campoBusca(
    String label,
    TextEditingController controller, {
    bool autofocus = false,
  }) {
    final habilitado =
        _controllers.values.every((c) => c.text.isEmpty) ||
        controller.text.isNotEmpty;
    return TextField(
      controller: controller,
      enabled: habilitado,
      autofocus: autofocus,
      decoration: InputDecoration(labelText: label),
      onChanged: (_) => _onCampoAlterado(controller),
    );
  }
}
