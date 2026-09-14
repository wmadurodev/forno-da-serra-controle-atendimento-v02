import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/fluxo_atendimento_repository.dart';
import 'fluxo_atendimento_placeholder_screen.dart';
import 'home_screen.dart';

/// Tela 1 — Splash (`docs/controle-atendimento-functional.md` §5.1,
/// `docs/controle-atendimento-prototype.md` §3.1).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _verificarFluxoAberto();
  }

  Future<void> _verificarFluxoAberto() async {
    final repository = context.read<FluxoAtendimentoRepository>();
    final fluxoAberto = await repository.getAberto();

    if (!mounted) return;

    if (fluxoAberto != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => FluxoAtendimentoPlaceholderScreen(fluxo: fluxoAberto),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Controle de Atendimento'),
          ],
        ),
      ),
    );
  }
}
