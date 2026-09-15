import 'dart:io';

import 'package:flutter/material.dart';

/// Visualização em tela cheia da imagem do Pedido (Passo 14) — aberta ao
/// tocar na miniatura do card. Fecha via o X no canto superior direito.
class ImagemPedidoTelaCheia extends StatelessWidget {
  const ImagemPedidoTelaCheia({super.key, required this.caminhoImagem});

  final String caminhoImagem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: InteractiveViewer(child: Image.file(File(caminhoImagem)))),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Fechar',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
