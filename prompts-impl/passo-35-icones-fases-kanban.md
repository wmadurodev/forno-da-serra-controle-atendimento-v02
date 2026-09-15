# Passo 35 — Troca de Ícones das Fases no Kanban

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-15. Sem correspondência em `docs/`.
> **Depende de:** Passo 25 (navegador de fases do footer), Passo 26 (cabeçalho de coluna usa o mesmo ícone), Passo 27 (Busca de Pedidos reaproveita o mesmo mapa), Passo 33 (ícone de moto da Prestação de Contas com o Motoqueiro).

## Objetivo

Trocar 2 dos ícones do mapa `iconePorFase` (`fase_pedido_visual.dart`), usado no navegador do footer da Tela 4, no cabeçalho de cada coluna do Kanban e nos blocos da Busca de Pedidos:

- **`enviado`**: `Icons.local_shipping_outlined` → `Icons.two_wheeler` (o mesmo ícone de moto usado na Home para a Prestação de Contas com o Motoqueiro, Passo 33).
- **`emExecucao`**: `Icons.restaurant_outlined` (talheres) → `Icons.local_pizza_outlined` (fatia de pizza, escolhido via `AskUserQuestion` — o usuário pediu explicitamente um ícone de pizza em vez das opções de forno/churrasqueira oferecidas).

Nenhuma outra fase muda.

## Levantamento

`iconePorFase` já é o único lugar de onde vêm os ícones das 3 telas que os usam (Kanban footer/cabeçalho — Passos 25/26 — e Busca de Pedidos — Passo 27), então a mudança é só nesse mapa, em `fase_pedido_visual.dart`. Não há necessidade de tocar em `quadro_atendimento_screen.dart`, `resultado_busca_pedidos_screen.dart` nem `home_screen.dart`.

## Alteração — `fase_pedido_visual.dart`

```dart
const iconePorFase = {
  PedidoStatus.aguardandoAtendimento: Icons.hourglass_empty,
  PedidoStatus.emAtendimento: Icons.support_agent_outlined,
  PedidoStatus.emExecucao: Icons.local_pizza_outlined,
  PedidoStatus.enviado: Icons.two_wheeler,
  PedidoStatus.entregue: Icons.check_circle_outline,
  PedidoStatus.devolvido: Icons.assignment_return_outlined,
  PedidoStatus.retiradoNoBalcao: Icons.storefront_outlined,
};
```

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] No footer da Tela 4, o ícone da fase `enviado` é o de moto (`two_wheeler`) e o de `em_execucao` é o de pizza (`local_pizza_outlined`).
- [ ] O cabeçalho das colunas `enviado` e `em_execucao` no Kanban usa os mesmos novos ícones.
- [ ] Os blocos de resultado da Busca de Pedidos (Passo 27) para essas 2 fases também usam os novos ícones.
- [ ] As demais 5 fases continuam com os ícones atuais, sem mudança.

## Fora de Escopo deste Passo

- Cores das colunas/ícones (`corColuna`/`corCinza`) — inalteradas.
- Ícone da Prestação de Contas com o Motoqueiro na Home (Passo 33) — continua o mesmo `Icons.two_wheeler`; este passo só reaproveita o mesmo ícone para a fase `enviado` do Kanban, sem alterar a Home.
