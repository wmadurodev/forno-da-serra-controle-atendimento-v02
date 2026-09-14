import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/database/app_database.dart';
import 'core/theme/app_theme.dart';
import 'features/fluxo_atendimento/data/fluxo_atendimento_repository.dart';
import 'features/fluxo_atendimento/presentation/splash_screen.dart';

void main() {
  runApp(const ControleAtendimentoApp());
}

class ControleAtendimentoApp extends StatelessWidget {
  const ControleAtendimentoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<FluxoAtendimentoRepository>(
      create: (_) => FluxoAtendimentoRepository(AppDatabase.instance),
      child: MaterialApp(
        title: 'Controle de Atendimento',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
