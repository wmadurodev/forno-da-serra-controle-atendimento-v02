import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/database/app_database.dart';
import 'core/theme/app_theme.dart';
import 'features/fluxo_atendimento/data/fluxo_atendimento_repository.dart';
import 'features/fluxo_atendimento/presentation/splash_screen.dart';
import 'features/pedido/data/pedido_repository.dart';

void main() {
  runApp(const ControleAtendimentoApp());
}

class ControleAtendimentoApp extends StatelessWidget {
  const ControleAtendimentoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FluxoAtendimentoRepository>(
          create: (_) => FluxoAtendimentoRepository(AppDatabase.instance),
        ),
        Provider<PedidoRepository>(
          create: (_) => PedidoRepository(AppDatabase.instance),
        ),
      ],
      child: MaterialApp(
        title: 'Controle de Atendimento',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
