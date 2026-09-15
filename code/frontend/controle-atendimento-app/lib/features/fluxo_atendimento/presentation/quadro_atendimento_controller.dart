import 'package:flutter/foundation.dart';

import '../../pedido/data/pedido_repository.dart';
import '../../pedido/domain/pedido.dart';

/// Critério de visualização do Kanban por cancelamento (Passo 13) — filtro
/// puramente de exibição, não persistido, não afeta a consulta ao banco.
enum FiltroPedidoVisualizacao { todos, somenteCancelados, somenteNaoCancelados }

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
  FiltroPedidoVisualizacao filtro = FiltroPedidoVisualizacao.todos;

  List<Pedido> pedidosDe(PedidoStatus status) {
    final todos = porStatus[status] ?? const [];
    return switch (filtro) {
      FiltroPedidoVisualizacao.todos => todos,
      FiltroPedidoVisualizacao.somenteCancelados => todos.where((p) => p.cancelado).toList(),
      FiltroPedidoVisualizacao.somenteNaoCancelados => todos.where((p) => !p.cancelado).toList(),
    };
  }

  void alterarFiltro(FiltroPedidoVisualizacao novoFiltro) {
    filtro = novoFiltro;
    notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    notifyListeners();

    final pedidos = await _repository.listByFluxo(fluxoAtendimentoId);
    porStatus = {
      for (final status in PedidoStatus.values)
        status: pedidos.where((p) => p.status == status).toList()..sort(_compararPorDataHoraDesc),
    };

    loading = false;
    notifyListeners();
  }

  /// Mais recente primeiro; pedidos sem carimbo (Passo 12) vão ao final,
  /// desempatados por `identificador` — Passo 13.
  static int _compararPorDataHoraDesc(Pedido a, Pedido b) {
    final dataA = a.dataHoraStatusAtual;
    final dataB = b.dataHoraStatusAtual;
    if (dataA == null && dataB == null) return a.identificador.compareTo(b.identificador);
    if (dataA == null) return 1;
    if (dataB == null) return -1;
    return dataB.compareTo(dataA);
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
