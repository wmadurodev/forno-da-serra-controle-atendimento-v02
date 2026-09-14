import 'package:flutter/foundation.dart';

import '../data/fluxo_atendimento_repository.dart';
import '../domain/fluxo_atendimento.dart';

/// Estado da Tela 2 — Home (`docs/controle-atendimento-prototype.md` §3.2).
class HomeController extends ChangeNotifier {
  HomeController(this._repository) {
    load();
  }

  final FluxoAtendimentoRepository _repository;

  bool loading = true;
  List<FluxoAtendimento> fluxos = [];

  Future<void> load() async {
    loading = true;
    notifyListeners();

    fluxos = await _repository.listAll();

    loading = false;
    notifyListeners();
  }
}
