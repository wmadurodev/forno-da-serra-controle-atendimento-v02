import 'package:flutter/material.dart';

import '../../pedido/domain/pedido.dart';

/// Cor/ícone de cada fase do Pedido, compartilhados entre o Kanban (Tela 4,
/// Passos 13/14/25/26) e a Busca de Pedidos (Passo 27).

/// Fundo das colunas do Kanban: um único tom, escurecendo da coluna mais à
/// esquerda para a mais à direita — Passo 13 (revisão a pedido do usuário:
/// sem degradê, cor sólida por coluna). Usa `deepOrange`, a mesma base do
/// `colorSchemeSeed` do app (`core/theme/app_theme.dart`), em vez de azul,
/// para combinar com o restante da identidade visual do app.
Color corColuna(int index, int totalColunas) {
  final t = totalColunas <= 1 ? 0.0 : index / (totalColunas - 1);
  return Color.lerp(Colors.deepOrange.shade50, Colors.deepOrange.shade200, t)!;
}

/// Cor cinza sólida para as fases finais (`entregue`, `devolvido`,
/// `retirado_no_balcao`) — Passo 26 (revisão: sem degradê, cor sólida como
/// nas demais fases; `enviado` volta à cor laranja de `corColuna`).
/// Progressivamente mais escura entre si.
Color? corCinza(PedidoStatus status) {
  return switch (status) {
    PedidoStatus.entregue => Colors.grey.shade300,
    PedidoStatus.devolvido => Colors.grey.shade400,
    PedidoStatus.retiradoNoBalcao => Colors.grey.shade500,
    _ => null,
  };
}

/// Ícone sugestivo de cada fase — usado no navegador do footer (Passo 25),
/// no cabeçalho da coluna correspondente do Kanban (Passo 26), e nos blocos
/// da Busca de Pedidos (Passo 27). Ordem alinhada à de `PedidoStatus.values`
/// (Passo 14, `retirado_no_balcao` por último).
const iconePorFase = {
  PedidoStatus.aguardandoAtendimento: Icons.hourglass_empty,
  PedidoStatus.emAtendimento: Icons.support_agent_outlined,
  PedidoStatus.emExecucao: Icons.local_pizza_outlined,
  PedidoStatus.enviado: Icons.two_wheeler,
  PedidoStatus.entregue: Icons.check_circle_outline,
  PedidoStatus.devolvido: Icons.assignment_return_outlined,
  PedidoStatus.retiradoNoBalcao: Icons.storefront_outlined,
};
