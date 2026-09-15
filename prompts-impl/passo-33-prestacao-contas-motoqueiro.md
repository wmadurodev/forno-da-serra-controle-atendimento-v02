# Passo 33 — Prestação de Contas com o Motoqueiro

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-15. Sem correspondência em `docs/`.
> **Depende de:** Passo 1 (Home), Passo 29 (mesmo padrão de popup, `ValoresPagamentoDialog`).

## Objetivo

Na Home, cada linha de fluxo de atendimento ganha um novo ícone (`Icons.two_wheeler` — escolhido via `AskUserQuestion` dentre `two_wheeler`/`moped`/`delivery_dining`) que abre um popup de "Prestação de Contas com o Motoqueiro": lista os Pedidos `delivery` daquele fluxo com status `enviado`, `entregue` ou `devolvido`, com nome do cliente + horário de envio e endereço, e totaliza o número de entregas.

> **Revisão (2026-09-15):** o critério original desta seção só filtrava por Tipo de Entrega `delivery`, sem restrição de status — o usuário corrigiu em seguida para also exigir status `enviado`/`entregue`/`devolvido` (Pedidos delivery ainda em `aguardando_atendimento`/`em_atendimento`/`em_execucao` não entram na prestação de contas, pois ainda não saíram com o motoqueiro).

## Levantamento

O padrão a seguir é o do Passo 29 (`ValoresPagamentoDialog` + `$` na Home): um novo `IconButton` na `trailing` `Row` de cada `ListTile` de fluxo (`home_screen.dart`), abrindo um `Dialog` que carrega os dados via `PedidoRepository` no `initState`.

`Pedido` já tem tudo que é necessário, sem precisar de nova coluna:
- `tipoEntrega == TipoEntrega.delivery` e `status` em `{enviado, entregue, devolvido}` — filtro da listagem.
- `nomeCliente` — pode ser nulo/vazio (mesmo fallback do Passo 29: usa `identificador` se `nomeCliente` estiver vazio).
- `dataHoraEnviado` (Passo 12) — "horário de envio". Com o filtro de status corrigido, todo Pedido retornado já passou por `enviado` em algum momento, então `dataHoraEnviado` está sempre preenchido nesse conjunto (o fallback `--:--` no diálogo vira defensivo, não alcançável na prática).
- `endereco` — já obrigatório para `delivery` desde o Passo 23.

## Nova consulta — `PedidoRepository.listDelivery`

```dart
/// Pedidos `delivery` já enviados de um Fluxo de Atendimento (status
/// `enviado`, `entregue` ou `devolvido`) — Passo 33 (Home, popup de
/// Prestação de Contas com o Motoqueiro).
Future<List<Pedido>> listDelivery(String fluxoAtendimentoId) async {
  final db = await _appDatabase.database;
  final statusValidos = [PedidoStatus.enviado, PedidoStatus.entregue, PedidoStatus.devolvido]
      .map((status) => status.value)
      .toList();
  final rows = await db.query(
    _table,
    where: 'fluxo_atendimento_id = ? AND tipo_entrega = ? AND status IN (${statusValidos.map((_) => '?').join(', ')})',
    whereArgs: [fluxoAtendimentoId, TipoEntrega.delivery.value, ...statusValidos],
    orderBy: 'identificador ASC',
  );
  return rows.map(Pedido.fromMap).toList();
}
```

## Novo diálogo — `prestacao_contas_motoqueiro_dialog.dart`

Mesmo formato do `ValoresPagamentoDialog` (título + botão fechar, lista com `ConstrainedBox(maxHeight: 320)` + `ListView.separated`, rodapé com o total):

```dart
class PrestacaoContasMotoqueiroDialog extends StatefulWidget {
  const PrestacaoContasMotoqueiroDialog({super.key, required this.fluxo});
  final FluxoAtendimento fluxo;
  // ... createState análogo ao ValoresPagamentoDialog
}
```

- Carrega via `PedidoRepository.listDelivery(widget.fluxo.identificador)`.
- Título: `'Prestação de Contas com o Motoqueiro — ${widget.fluxo.identificador}'`.
- Item da lista (2 linhas, mesmo padrão visual do Passo 29):
  ```dart
  final nome = (pedido.nomeCliente?.isNotEmpty ?? false) ? pedido.nomeCliente! : pedido.identificador;
  final horario = pedido.dataHoraEnviado != null
      ? '${pedido.dataHoraEnviado!.hour.toString().padLeft(2, '0')}:${pedido.dataHoraEnviado!.minute.toString().padLeft(2, '0')}'
      : '--:--';
  // Text('$nome ($horario)', bold)
  // Text(pedido.endereco ?? '')
  ```
- Mensagem de lista vazia: `'Nenhum pedido delivery neste fluxo.'`.
- Rodapé: `'Total de Entregas'` à esquerda, `_pedidos.length` à direita (mesmo estilo em negrito do total de valores).

## Alteração — `home_screen.dart`

Novo `IconButton` na `trailing` `Row`, entre o cifrão (Passo 29) e o botão de fechar fluxo:
```dart
IconButton(
  icon: const Icon(Icons.two_wheeler),
  tooltip: 'Prestação de Contas com o Motoqueiro',
  onPressed: () => _onPrestacaoContasMotoqueiro(context, fluxo),
),
```
com o `_onPrestacaoContasMotoqueiro` análogo ao `_onValoresPagamento` já existente.

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Cada linha de fluxo (aberto ou fechado) na Home mostra o novo ícone de moto, entre o cifrão e o ícone de fechar/excluir.
- [ ] Tocar no ícone abre o popup listando somente os Pedidos `delivery` daquele fluxo com status `enviado`, `entregue` ou `devolvido` — Pedidos `delivery` ainda em `aguardando_atendimento`/`em_atendimento`/`em_execucao` não aparecem.
- [ ] Cada item mostra `Nome (HH:mm)` em negrito (horário de envio) e o Endereço embaixo.
- [ ] Rodapé mostra o total de entregas (quantidade de itens listados).
- [ ] Fluxo sem nenhum Pedido `delivery` mostra a mensagem de lista vazia, sem quebrar.

## Fora de Escopo deste Passo

- Valor a pagar ao motoqueiro (frete) — não existe esse campo no modelo hoje; fora de escopo.
