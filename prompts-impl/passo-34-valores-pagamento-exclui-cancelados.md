# Passo 34 — Relatório de Valores de Pagamento não mostra Pedidos Cancelados

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-15. Sem correspondência em `docs/`.
> **Depende de:** Passo 29 (popup de Valores de Pagamento na Home, `ValoresPagamentoDialog` + `PedidoRepository.listComValorPagamento`).

## Objetivo

O popup de Valores de Pagamento (Passo 29) deixa de listar Pedidos com `cancelado == true` — mesmo que tenham `valor_pagamento` lançado.

## Levantamento

`PedidoRepository.listComValorPagamento` (usada só pelo `ValoresPagamentoDialog`, Passo 29) filtra hoje apenas por `fluxo_atendimento_id` e `valor_pagamento IS NOT NULL`, sem considerar a coluna `cancelado`. Um Pedido cancelado mantém seu `valor_pagamento` (Tela 7 — Cancelamento de Pedido não limpa esse campo, só marca `cancelado = 1` e grava o motivo), então hoje ele aparece no relatório mesmo não devendo mais ser cobrado/pago.

## Alteração — `PedidoRepository.listComValorPagamento`

```dart
Future<List<Pedido>> listComValorPagamento(String fluxoAtendimentoId) async {
  final db = await _appDatabase.database;
  final rows = await db.query(
    _table,
    where: 'fluxo_atendimento_id = ? AND valor_pagamento IS NOT NULL AND cancelado = 0',
    whereArgs: [fluxoAtendimentoId],
    orderBy: 'identificador ASC',
  );
  return rows.map(Pedido.fromMap).toList();
}
```

Nenhuma mudança em `ValoresPagamentoDialog` — o total somado (`_total`) já é derivado só da lista que a consulta devolve.

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Um Pedido cancelado com valor de pagamento lançado não aparece mais no popup de Valores de Pagamento.
- [ ] O total somado do popup passa a refletir só os Pedidos não cancelados.
- [ ] Pedidos não cancelados com valor de pagamento continuam aparecendo normalmente.

## Fora de Escopo deste Passo

- Qualquer outro relatório/tela (ex. Prestação de Contas com o Motoqueiro, Passo 33, Busca de Pedidos, cards do Kanban) — nenhum deles foi mencionado pelo usuário; este passo altera só `listComValorPagamento`.
