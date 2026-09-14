import 'package:flutter/foundation.dart';

import '../../pedido/data/pedido_repository.dart';
import '../../pedido/domain/pedido.dart';

/// Estado da Tela 4 — Execução do Fluxo de Atendimento
/// (`docs/controle-atendimento-prototype.md` §3.4).
class QuadroAtendimentoController extends ChangeNotifier {
  QuadroAtendimentoController(this._repository, this.fluxoAtendimentoId) {
    load();
  }

  final PedidoRepository _repository;
  final String fluxoAtendimentoId;

  bool loading = true;
  Map<PedidoStatus, List<Pedido>> porStatus = {};

  List<Pedido> pedidosDe(PedidoStatus status) => porStatus[status] ?? const [];

  Future<void> load() async {
    loading = true;
    notifyListeners();

    final pedidos = await _repository.listByFluxo(fluxoAtendimentoId);
    porStatus = {
      for (final status in PedidoStatus.values)
        status: pedidos.where((p) => p.status == status).toList(),
    };

    loading = false;
    notifyListeners();
  }

  Future<void> excluir(Pedido pedido) async {
    await _repository.excluir(pedido);
    await load();
  }

  Future<void> atualizarStatus(Pedido pedido, PedidoStatus novoStatus) async {
    await _repository.atualizarStatus(pedido, novoStatus);
    await load();
  }
}
