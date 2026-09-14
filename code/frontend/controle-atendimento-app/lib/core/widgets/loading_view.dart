import 'package:flutter/material.dart';

/// Indicador de carregamento compartilhado entre telas.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
