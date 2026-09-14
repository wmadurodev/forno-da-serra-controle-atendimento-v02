import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/loading_view.dart';
import '../data/fluxo_atendimento_repository.dart';
import '../domain/fluxo_atendimento.dart';
import 'cadastro_fluxo_screen.dart';
import 'fluxo_atendimento_placeholder_screen.dart';
import 'home_controller.dart';

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
      appBar: AppBar(title: const Text('Controle de Atendimento')),
      body: _buildBody(controller),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onNovoFluxo(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo Fluxo'),
      ),
    );
  }

  Widget _buildBody(HomeController controller) {
    if (controller.loading) {
      return const LoadingView();
    }

    if (controller.fluxos.isEmpty) {
      return const Center(
        child: Text('Nenhum fluxo de atendimento cadastrado ainda'),
      );
    }

    return ListView.builder(
      itemCount: controller.fluxos.length,
      itemBuilder: (context, index) {
        final fluxo = controller.fluxos[index];
        return ListTile(
          title: Text(fluxo.identificador),
          subtitle: Text(
            fluxo.status == FluxoAtendimentoStatus.aberto ? 'Aberto' : 'Fechado',
          ),
          onTap: () => _onFluxoSelecionado(context, fluxo),
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

  void _onFluxoSelecionado(BuildContext context, FluxoAtendimento fluxo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FluxoAtendimentoPlaceholderScreen(fluxo: fluxo),
      ),
    );
  }
}
