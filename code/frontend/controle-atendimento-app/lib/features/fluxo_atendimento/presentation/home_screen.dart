import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/loading_view.dart';
import '../data/fluxo_atendimento_repository.dart';
import '../domain/fluxo_atendimento.dart';
import 'cadastro_fluxo_screen.dart';
import 'excluir_fluxo_dialog.dart';
import 'fechar_fluxo_dialog.dart';
import 'home_controller.dart';
import 'quadro_atendimento_screen.dart';
import 'valores_pagamento_dialog.dart';

/// Fundo da tela — Passo 11, tom quente/creme sem regra de negócio associada.
const _homeBackgroundColor = Color(0xFFFFF8E7);

/// Fundo dos cards de fluxo `fechado` — Passo 11, reforça visualmente que o
/// fluxo está encerrado/somente leitura.
final _fluxoFechadoCardColor = Colors.grey.shade300;

/// Tela 2 — Home (`docs/controle-atendimento-prototype.md` §3.2).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeController(context.read<FluxoAtendimentoRepository>()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeController>();

    return Scaffold(
      backgroundColor: _homeBackgroundColor,
      appBar: AppBar(title: const Text('Controle de Atendimento')),
      body: _buildBody(context, controller),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onNovoFluxo(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo Fluxo'),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeController controller) {
    if (controller.loading) {
      return const LoadingView();
    }

    if (controller.fluxos.isEmpty) {
      return const Center(
        child: Text('Nenhum fluxo de atendimento cadastrado ainda'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      itemCount: controller.fluxos.length,
      itemBuilder: (context, index) {
        final fluxo = controller.fluxos[index];
        final aberto = fluxo.status == FluxoAtendimentoStatus.aberto;
        return Card(
          color: aberto ? null : _fluxoFechadoCardColor,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text(fluxo.identificador),
            subtitle: Text(aberto ? 'Aberto' : 'Fechado'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_money),
                  tooltip: 'Valores de Pagamento',
                  onPressed: () => _onValoresPagamento(context, fluxo),
                ),
                if (aberto)
                  IconButton(
                    icon: const Icon(Icons.done_all),
                    tooltip: 'Fechar Fluxo de Atendimento',
                    onPressed: () => _onFecharFluxo(context, fluxo),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Excluir Fluxo de Atendimento',
                  onPressed: () => _onExcluirFluxo(context, fluxo),
                ),
              ],
            ),
            onTap: () => _onFluxoSelecionado(context, fluxo),
          ),
        );
      },
    );
  }

  Future<void> _onNovoFluxo(BuildContext context) async {
    final controller = context.read<HomeController>();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CadastroFluxoScreen()),
    );
    await controller.load();
  }

  Future<void> _onValoresPagamento(BuildContext context, FluxoAtendimento fluxo) async {
    await showDialog<void>(
      context: context,
      builder: (_) => ValoresPagamentoDialog(fluxo: fluxo),
    );
  }

  Future<void> _onFecharFluxo(BuildContext context, FluxoAtendimento fluxo) async {
    final controller = context.read<HomeController>();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => FecharFluxoDialog(fluxo: fluxo),
    );
    if (confirmado == true) {
      await controller.fecharFluxo(fluxo);
    }
  }

  Future<void> _onExcluirFluxo(BuildContext context, FluxoAtendimento fluxo) async {
    final controller = context.read<HomeController>();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => ExcluirFluxoDialog(fluxo: fluxo),
    );
    if (confirmado == true) {
      await controller.excluirFluxo(fluxo);
    }
  }

  void _onFluxoSelecionado(BuildContext context, FluxoAtendimento fluxo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuadroAtendimentoScreen(fluxo: fluxo),
      ),
    );
  }
}
