# Passo 18 — Reaproveitar dados do Pedido mais recente ao digitar o identificador

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-14. Decisões de escopo e de schema definidas nesta conversa (ver seção "Decisões" abaixo) — sem correspondência em `docs/`.
> **Depende de:** Passo 17 (`Pedido.id` sequencial — usado neste passo tanto para "mais recente" quanto para a correção de identidade nas escritas). Altera o comportamento descrito em **P-4** (confirmado) de `docs/controle-atendimento-prototype.md` §6 — este passo o substitui.

## Objetivo

Ao digitar um identificador na Tela 5 (Cadastro de Pedido, fluxo "Novo Pedido" a partir do botão do header) e confirmar: buscar, em **todos os Fluxos de Atendimento** (não só o atual), o Pedido **mais recente** cujo identificador seja **exatamente igual** ao digitado; se encontrado, usar seus dados de Cadastro (Cliente, Entrega, Pagamento, Endereço — **exceto Observação**) para pré-preencher o formulário; ao gravar, **sempre criar um Pedido novo** (nunca editar o encontrado), usando o identificador digitado.

## Decisões tomadas nesta conversa (perguntas feitas ao usuário)

1. **Escopo da busca:** todos os Fluxos de Atendimento (histórico completo), não só o fluxo atual.
2. **Correspondência exata, sempre:** a busca usa `identificador = <digitado>` (nunca "contém"/parcial) — mesmo quando o identificador digitado já existe no fluxo atual, o resultado é só um molde; o comportamento passa a ser sempre criar um Pedido novo (substitui o fluxo "Iniciar Pedido" de **P-4**, que reaproveitava a mesma linha).
3. **`pedido.identificador` deixa de ter qualquer constraint de unicidade** — nem global (como é desde o Passo 1), nem por fluxo. O sistema deve permitir múltiplos Pedidos com o mesmo identificador, inclusive no mesmo Fluxo de Atendimento. Decisão explícita do usuário, necessária para a funcionalidade pedida funcionar (ex.: reaproveitar o identificador de um Pedido de um fluxo antigo, ou até do mesmo fluxo, em um Pedido novo).

## Risco central deste passo — sem `identificador` único, ele não serve mais para identificar uma linha

Depois deste passo, pode existir mais de um Pedido com o mesmo `identificador` (inclusive no mesmo fluxo). Todo código que hoje localiza/atualiza/exclui um Pedido específico usando `WHERE identificador = ?` está incorreto a partir daqui — precisa passar a usar `id` (a chave técnica sequencial do Passo 17), que continua sendo única por definição (`PRIMARY KEY AUTOINCREMENT`). Isso afeta `PedidoRepository` inteiro:

- **`excluir(pedido)`**: hoje `WHERE identificador = ?` — passaria a apagar **todas** as linhas com aquele identificador. Trocar para `WHERE id = ?`, `whereArgs: [pedido.id]`.
- **`atualizarStatus(pedido, novoStatus)`**: mesmo problema (`WHERE identificador = ?` atualizaria todas as linhas com aquele identificador). Trocar para `WHERE id = ?`.
- **`salvar(pedido)`** (reescrito no Passo 17 para checar existência por `identificador`): não faz mais sentido checar por `identificador` (pode haver várias). Nova regra, mais simples que a do Passo 17: se `pedido.id == null` → `INSERT` (Pedido novo); se `pedido.id != null` → `UPDATE ... WHERE id = ?` (edição de um Pedido existente). Não precisa mais da consulta de existência do Passo 17.

```dart
Future<void> salvar(Pedido pedido) async {
  await _garantirFluxoAberto(pedido.fluxoAtendimentoId);
  final db = await _appDatabase.database;
  if (pedido.id == null) {
    await db.insert(_table, pedido.toMap());
  } else {
    await db.update(_table, pedido.toMap(), where: 'id = ?', whereArgs: [pedido.id]);
  }
}
```

**Consequência prática, crítica, nas telas:** todo lugar que reconstrói um `Pedido(...)` para editar um já existente precisa agora incluir `id: <pedido original>.id` — sem isso, `salvar()` interpretaria a edição como um Pedido novo (`id == null`) e criaria uma **linha duplicada** a cada edição, em vez de atualizar. Arquivos a corrigir (todos constroem `final pedido = Pedido(...)` para chamar `repository.salvar(pedido)`):

| Arquivo | Variável de origem | Campo a adicionar |
|---|---|---|
| `cadastro_pedido_screen.dart` (`_onGravar`) | `base` (= `_pedidoBase`) | `id: base?.id` (nulo no fluxo "Novo Pedido" deste passo — ver abaixo — e no `pedidoExistente` real quando vier de "Editar") |
| `execucao_pedido_screen.dart` (`_onGravar`) | `widget.pedido` | `id: widget.pedido.id` |
| `edicao_pedido_execucao_screen.dart` (`_onGravar`) | `widget.pedido` | `id: widget.pedido.id` |
| `cancelamento_pedido_screen.dart` (`_onConfirmar`) | `pedidoOriginal` | `id: pedidoOriginal.id` |
| `devolucao_entrega_screen.dart` (`_onConfirmar`) | `pedidoOriginal` | `id: pedidoOriginal.id` |

## Schema

`identificador` perde o `UNIQUE` (mantém `NOT NULL`, continua obrigatório). Sobe `version` de `4` para `5`. `onCreate` já cria `pedido` com `identificador TEXT NOT NULL` (sem `UNIQUE`). `onUpgrade` (`oldVersion < 5`): recriar a tabela (mesmo padrão dos Passos 11/17), **copiando o `id` existente explicitamente** (ao contrário das migrações anteriores, aqui `id` já existe e não pode ser reatribuído por ordem de inserção — precisa manter os valores atuais):

```dart
if (oldVersion < 5) {
  await db.execute('ALTER TABLE pedido RENAME TO pedido_old');
  await db.execute('''
    CREATE TABLE pedido (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      identificador TEXT NOT NULL,
      fluxo_atendimento_id TEXT NOT NULL REFERENCES fluxo_atendimento(identificador),
      -- ... demais colunas idênticas às do Passo 17 (status, cancelado,
      -- nome_cliente, tipo_entrega, tipo_pagamento, endereco, observacao,
      -- restricoes, valor_pagamento, mesa, imagem_pedido_ref,
      -- motivo_cancelamento, motivo_devolucao, e os 8 campos
      -- data_hora_* do Passo 12)
    )
  ''');
  await db.execute('''
    INSERT INTO pedido (id, identificador, fluxo_atendimento_id, status, cancelado,
      nome_cliente, tipo_entrega, tipo_pagamento, endereco, observacao, restricoes,
      valor_pagamento, mesa, imagem_pedido_ref, motivo_cancelamento, motivo_devolucao,
      data_hora_aguardando_atendimento, data_hora_em_atendimento, data_hora_em_execucao,
      data_hora_retirado_no_balcao, data_hora_enviado, data_hora_entregue,
      data_hora_devolvido, data_hora_cancelamento)
    SELECT id, identificador, fluxo_atendimento_id, status, cancelado,
      nome_cliente, tipo_entrega, tipo_pagamento, endereco, observacao, restricoes,
      valor_pagamento, mesa, imagem_pedido_ref, motivo_cancelamento, motivo_devolucao,
      data_hora_aguardando_atendimento, data_hora_em_atendimento, data_hora_em_execucao,
      data_hora_retirado_no_balcao, data_hora_enviado, data_hora_entregue,
      data_hora_devolvido, data_hora_cancelamento
    FROM pedido_old
  ''');
  await db.execute('DROP TABLE pedido_old');
  await db.execute('CREATE INDEX idx_pedido_fluxo_atendimento_id ON pedido(fluxo_atendimento_id)');
}
```
(`id` é copiado explicitamente na mesma coluna `INTEGER PRIMARY KEY AUTOINCREMENT` — o SQLite aceita valores explícitos e mantém o contador de autoincremento consistente com o maior `id` já usado.)

## `PedidoRepository` — nova busca

Remove `buscarPorIdentificador(fluxoAtendimentoId, identificador)` (única chamadora é reescrita abaixo). Novo método:
```dart
Future<Pedido?> buscarMaisRecentePorIdentificador(String identificador) async {
  final db = await _appDatabase.database;
  final rows = await db.query(
    _table,
    where: 'identificador = ?',
    whereArgs: [identificador],
    orderBy: 'id DESC',
    limit: 1,
  );
  if (rows.isEmpty) return null;
  return Pedido.fromMap(rows.first);
}
```

## `CadastroPedidoScreen` — `_onConfirmarIdentificador` reescrito

```dart
Future<void> _onConfirmarIdentificador() async {
  if (!_identificadorFormKey.currentState!.validate()) return;

  setState(() => _buscando = true);

  final repository = context.read<PedidoRepository>();
  final identificador = _identificadorController.text.trim();
  final maisRecente = await repository.buscarMaisRecentePorIdentificador(identificador);

  if (!mounted) return;
  setState(() {
    _buscando = false;
    _pedidoBase = null; // sempre cria um Pedido novo — Passo 18.
    _identificadorConfirmado = true;
    if (maisRecente != null) {
      _nomeClienteController.text = maisRecente.nomeCliente ?? '';
      _tipoEntrega = maisRecente.tipoEntrega;
      _tipoPagamento = maisRecente.tipoPagamento;
      _enderecoController.text = maisRecente.endereco ?? '';
      // Observação NÃO é copiada do registro encontrado — pedido do usuário.
    }
  });
}
```

`_pedidoBase` sempre `null` neste ponto garante que `_onGravar` trate como criação (`base == null`): novo `id` gerado no `INSERT`, `dataHoraAguardandoAtendimento` carimbado com `DateTime.now()` (lógica já existente do Passo 12), e nenhum campo de execução (mesa, imagem, restrições) ou de cancelamento/devolução herdado do registro encontrado — só os campos de Cadastro listados acima.

**Não afeta** o outro caminho de entrada de `CadastroPedidoScreen` — quando aberta com `pedidoExistente` (botões "Atendimento"/"Editar" dos cards do Kanban, Passo 3/6), `_pedidoBase` continua sendo definido diretamente em `initState` a partir do Pedido real (edição de verdade, preserva `id`), sem passar por `_onConfirmarIdentificador`.

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Banco existente (versão 4) migra sem perda de dados; todos os `id` de Pedidos existentes são preservados exatamente (não trocam de valor).
- [ ] Criar um Pedido com um identificador já usado por outro Pedido (em qualquer fluxo, inclusive o atual) não é mais bloqueado — os dois passam a coexistir.
- [ ] Ao digitar um identificador que corresponde a um Pedido já existente (de qualquer fluxo) e confirmar: Cliente, Entrega, Pagamento e Endereço vêm pré-preenchidos com os dados desse Pedido (o mais recente, se houver mais de um com o mesmo identificador); Observação **não** vem preenchida.
- [ ] Gravar esse formulário cria um **Pedido novo** (linha nova, novo `id`) — o Pedido encontrado permanece intocado.
- [ ] Editar um Pedido já existente (Cadastro, Execução, Edição de Execução, Cancelamento, Devolução) continua atualizando a mesma linha (mesmo `id`) — nenhuma edição cria uma linha duplicada.
- [ ] Excluir um Pedido ou mudar seu status (Retirado/Enviado/Entregue) afeta só aquela linha específica, mesmo que existam outros Pedidos com o mesmo identificador.

## Fora de Escopo deste Passo

- Qualquer indicação visual no Kanban de que existem múltiplos Pedidos com o mesmo identificador — não foi pedido.
- Filtrar o registro-molde por status (ex.: ignorar Pedidos cancelados) — não foi pedido; usa-se sempre o mais recente, qualquer que seja seu status.
