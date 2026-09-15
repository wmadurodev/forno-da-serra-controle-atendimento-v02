# Passo 29 — Valores de Pagamento lançados por Fluxo (Home)

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-15. Sem correspondência em `docs/`.
> **Depende de:** Passo 1 (Home), Passo 5 (`valor_pagamento` preenchido na Execução de Pedido).

## Objetivo

Na Home (Tela 2), cada linha de Fluxo de Atendimento ganha um novo ícone de cifrão (`$`), **antes** do ícone de fechamento (Passo 11). Tocando nele, abre um popup listando todos os Pedidos daquele fluxo que têm `valor_pagamento` preenchido — Identificador, Nome, Tipo de Pagamento e Valor de cada um — com o total somado.

## Regras

1. O ícone de cifrão aparece em **toda** linha de fluxo, `aberto` ou `fechado` (é uma consulta, não uma ação de escrita) — sempre antes do ícone de fechamento (que só existe para fluxos `aberto`, Passo 11) e do ícone de exclusão.
2. A listagem só inclui Pedidos com `valor_pagamento` **não nulo** — os demais (sem valor lançado) não aparecem.
3. Pedidos cancelados continuam aparecendo na listagem, se tiverem valor lançado (mesmo padrão de **FN-7**: cancelamento não esconde o Pedido de listagens/buscas).
4. O popup soma o `valor_pagamento` de todos os Pedidos listados e mostra o total.

## `PedidoRepository` — nova consulta

```dart
Future<List<Pedido>> listComValorPagamento(String fluxoAtendimentoId) async {
  final db = await _appDatabase.database;
  final rows = await db.query(
    _table,
    where: 'fluxo_atendimento_id = ? AND valor_pagamento IS NOT NULL',
    whereArgs: [fluxoAtendimentoId],
    orderBy: 'identificador ASC',
  );
  return rows.map(Pedido.fromMap).toList();
}
```

## Novo widget — `ValoresPagamentoDialog`

`lib/features/fluxo_atendimento/presentation/valores_pagamento_dialog.dart`, recebendo o `FluxoAtendimento`. `StatefulWidget` (busca é assíncrona):
- `Dialog` custom (mesmo padrão visual de `FecharFluxoDialog`/`ExcluirFluxoDialog`): título + ícone **X** no canto superior direito para fechar (sem nenhuma outra ação — é só informativo).
- Ao abrir, chama `PedidoRepository.listComValorPagamento(fluxo.identificador)`; enquanto carrega, mostra um indicador de progresso.
- Se a lista vier vazia: mensagem "Nenhum pedido com valor de pagamento lançado.".
- Caso contrário: lista rolável (altura máxima limitada, ex. `ConstrainedBox(maxHeight: 320)`) com um item por Pedido, seguida de uma linha de total, somando `valor_pagamento` de todos os Pedidos listados.

**Revisão (2026-09-15):** o item de cada Pedido mostra só duas linhas — `"(Tipo de Pagamento) Nome do Cliente"` em negrito (tipo de pagamento entre parênteses, na frente do nome; se `nomeCliente` estiver vazio, usa o `identificador` como texto de exibição) e o Valor (`R$ 00.00`) logo abaixo. O Identificador deixou de aparecer como linha própria.

## Alteração em `home_screen.dart`

No `trailing` (`Row`) de cada linha de fluxo, adicionar um `IconButton` com `Icons.attach_money`, tooltip "Valores de Pagamento", **antes** do `IconButton` condicional de fechamento (`Icons.done_all`) e do de exclusão:
```dart
trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    IconButton(
      icon: const Icon(Icons.attach_money),
      tooltip: 'Valores de Pagamento',
      onPressed: () => _onValoresPagamento(context, fluxo),
    ),
    if (aberto)
      IconButton(
        icon: const Icon(Icons.done_all),
        tooltip: 'Fechar Fluxo de Atendimento',
        onPressed: () => _onFecharFluxo(context, fluxo),
      ),
    IconButton(
      icon: const Icon(Icons.delete_outline),
      tooltip: 'Excluir Fluxo de Atendimento',
      onPressed: () => _onExcluirFluxo(context, fluxo),
    ),
  ],
),
```
Novo método `_onValoresPagamento` abre o diálogo via `showDialog`, sem precisar recarregar a lista de fluxos depois (é só leitura, não altera nada).

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Toda linha de fluxo (aberto ou fechado) mostra o ícone de cifrão antes dos demais ícones.
- [ ] Tocar no cifrão abre o popup com os Pedidos daquele fluxo que têm valor de pagamento lançado, cada um com Identificador/Nome/Tipo de Pagamento/Valor, e o total somado no fim.
- [ ] Pedidos sem `valor_pagamento` não aparecem na lista.
- [ ] Fluxo sem nenhum Pedido com valor lançado mostra a mensagem de lista vazia, sem quebrar a tela.
- [ ] Fechar o popup (ícone X) não altera nada na Home.

## Fora de Escopo deste Passo

- Qualquer edição de valor a partir deste popup — é só consulta/totalização.
- Filtrar por tipo de pagamento ou por período — lista tudo que tem valor lançado no fluxo selecionado.
