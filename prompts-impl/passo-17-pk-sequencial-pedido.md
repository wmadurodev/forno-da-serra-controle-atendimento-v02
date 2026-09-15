# Passo 17 — Chave primária sequencial na tabela `pedido`

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-14 — mesma decisão já aplicada a `fluxo_atendimento` no Passo 11, agora estendida a `pedido`. Sem correspondência em `docs/controle-atendimento-data-structure.md` (que documenta `identificador` como chave de negócio — ver §3 — não como chave técnica de banco).
> **Depende de:** Passo 12 (última migração de schema de `pedido`, versão 3). Não depende dos Passos 13-16 (mudanças de UI, não de schema).

## Objetivo

Trocar a `PRIMARY KEY` da tabela `pedido` de `identificador` (texto, chave de negócio) para um novo `id INTEGER PRIMARY KEY AUTOINCREMENT` (chave técnica interna, não exibida na UI) — mesma decisão e mesmo motivo do Passo 11 para `fluxo_atendimento`: uma chave de negócio em texto não é o ideal como chave técnica de banco (mutabilidade, tipo, ausência de ordenação natural garantida).

## Risco central deste passo — `salvar()` depende de `identificador` ser a `PRIMARY KEY`

`PedidoRepository.salvar()` (`lib/features/pedido/data/pedido_repository.dart`) hoje faz:
```dart
await db.insert(_table, pedido.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
```
Isso funciona como um "upsert" (grava um pedido novo OU atualiza um existente com o mesmo método) **porque** `identificador` é a `PRIMARY KEY`: ao inserir um `identificador` já existente, o SQLite detecta o conflito de PK e resolve com `REPLACE` (a linha antiga é apagada e uma nova é inserida no lugar). É assim que `CadastroPedidoScreen`, `ExecucaoPedidoScreen`, `EdicaoPedidoExecucaoScreen`, `CancelamentoPedidoScreen` e `DevolucaoEntregaScreen` conseguem usar o mesmo `salvar()` tanto para criar quanto para editar um Pedido.

**Se `identificador` deixar de ser a `PRIMARY KEY`** (mesmo virando `UNIQUE`), o `REPLACE` do SQLite ainda dispara (`UNIQUE` também conflita), **mas `REPLACE` é um `DELETE` + `INSERT`, não um `UPDATE`** — cada edição de um Pedido já existente passaria a apagar a linha e criar outra, com um **novo `id` autoincrementado a cada gravação**. Isso quebra a própria razão de existir de uma chave sequencial estável (deixaria de refletir a ordem real de criação, mudando a cada edição) e é, de forma mais geral, incorreto para qualquer chave primária: a identidade da linha não deveria mudar a cada `UPDATE` lógico.

**Correção necessária, portanto, junto com a troca de PK:** reescrever `PedidoRepository.salvar()` para não depender mais de `conflictAlgorithm: ConflictAlgorithm.replace`. Verificar primeiro se já existe um Pedido com aquele `identificador`; se não existir, `INSERT`; se existir, `UPDATE` (preservando o `id` da linha existente):

```dart
Future<void> salvar(Pedido pedido) async {
  await _garantirFluxoAberto(pedido.fluxoAtendimentoId);
  final db = await _appDatabase.database;
  final existente = await db.query(
    _table,
    columns: ['identificador'],
    where: 'identificador = ?',
    whereArgs: [pedido.identificador],
    limit: 1,
  );
  if (existente.isEmpty) {
    await db.insert(_table, pedido.toMap());
  } else {
    await db.update(_table, pedido.toMap(), where: 'identificador = ?', whereArgs: [pedido.identificador]);
  }
}
```

Nenhuma tela precisa mudar — todas continuam chamando `PedidoRepository.salvar(pedido)` do mesmo jeito; a correção fica isolada no repositório.

## Schema

`identificador` deixa de ser `PRIMARY KEY` e passa a `TEXT NOT NULL UNIQUE` (preserva a unicidade de hoje — igual ao que o Passo 11 fez em `fluxo_atendimento.identificador`). Novo `id INTEGER PRIMARY KEY AUTOINCREMENT` como primeira coluna. Nenhuma outra coluna muda.

**Migração:** sobe `version` de `3` para `4`. `onCreate` já cria `pedido` no formato novo. `onUpgrade` (`oldVersion < 4`): SQLite não permite alterar a `PRIMARY KEY` de uma tabela existente via `ALTER TABLE` — recriar a tabela (mesmo padrão do Passo 11 para `fluxo_atendimento`, agora com todas as colunas de `pedido`, incluindo as 8 de data/hora do Passo 12):

```dart
if (oldVersion < 4) {
  await db.execute('ALTER TABLE pedido RENAME TO pedido_old');
  await db.execute('''
    CREATE TABLE pedido (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      identificador TEXT NOT NULL UNIQUE,
      fluxo_atendimento_id TEXT NOT NULL REFERENCES fluxo_atendimento(identificador),
      status TEXT NOT NULL CHECK (status IN (
        'aguardando_atendimento', 'em_atendimento', 'em_execucao',
        'retirado_no_balcao', 'enviado', 'entregue', 'devolvido'
      )),
      cancelado INTEGER NOT NULL DEFAULT 0,
      nome_cliente TEXT,
      tipo_entrega TEXT CHECK (tipo_entrega IN ('delivery', 'retirada_balcao')),
      tipo_pagamento TEXT CHECK (tipo_pagamento IN ('pix', 'cartao', 'dinheiro')),
      endereco TEXT,
      observacao TEXT,
      restricoes TEXT,
      valor_pagamento REAL,
      mesa TEXT,
      imagem_pedido_ref TEXT,
      motivo_cancelamento TEXT,
      motivo_devolucao TEXT,
      data_hora_aguardando_atendimento TEXT,
      data_hora_em_atendimento TEXT,
      data_hora_em_execucao TEXT,
      data_hora_retirado_no_balcao TEXT,
      data_hora_enviado TEXT,
      data_hora_entregue TEXT,
      data_hora_devolvido TEXT,
      data_hora_cancelamento TEXT
    )
  ''');
  await db.execute('''
    INSERT INTO pedido (
      identificador, fluxo_atendimento_id, status, cancelado, nome_cliente,
      tipo_entrega, tipo_pagamento, endereco, observacao, restricoes,
      valor_pagamento, mesa, imagem_pedido_ref, motivo_cancelamento, motivo_devolucao,
      data_hora_aguardando_atendimento, data_hora_em_atendimento, data_hora_em_execucao,
      data_hora_retirado_no_balcao, data_hora_enviado, data_hora_entregue,
      data_hora_devolvido, data_hora_cancelamento
    )
    SELECT
      identificador, fluxo_atendimento_id, status, cancelado, nome_cliente,
      tipo_entrega, tipo_pagamento, endereco, observacao, restricoes,
      valor_pagamento, mesa, imagem_pedido_ref, motivo_cancelamento, motivo_devolucao,
      data_hora_aguardando_atendimento, data_hora_em_atendimento, data_hora_em_execucao,
      data_hora_retirado_no_balcao, data_hora_enviado, data_hora_entregue,
      data_hora_devolvido, data_hora_cancelamento
    FROM pedido_old ORDER BY rowid ASC
  ''');
  await db.execute('DROP TABLE pedido_old');
  await db.execute('CREATE INDEX idx_pedido_fluxo_atendimento_id ON pedido(fluxo_atendimento_id)');
}
```
(o índice em `fluxo_atendimento_id` precisa ser recriado depois do `DROP TABLE pedido_old`, já que pertencia à tabela antiga.)

## Domínio (`Pedido`)

Novo campo `final int? id` (nulo antes de persistir), preenchido em `fromMap` (`id: map['id']! as int`), **não incluído em `toMap()`** (autoincrement, mesmo padrão de `FluxoAtendimento.id` do Passo 11).

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Banco existente (versão 3) migra sem perda de dados: pedidos preexistentes, com todos os seus campos (incluindo os carimbos de data/hora do Passo 12), continuam íntegros após o upgrade.
- [ ] Criar um Pedido novo, editá-lo várias vezes (cadastro, execução, cancelamento, devolução) mantém o mesmo `id` interno ao longo de todas as edições — nenhuma edição gera uma linha nova.
- [ ] Todo o fluxo de Pedido (Telas 5 a 9) continua funcionando exatamente como antes — este passo não muda nenhum comportamento visível, só a chave técnica interna.
- [ ] Tentar criar dois pedidos com o mesmo `identificador` continua sendo bloqueado (agora por `UNIQUE`, antes por `PRIMARY KEY`) com o mesmo efeito prático.

## Fora de Escopo deste Passo

- Exibir o novo `id` na UI — é uma chave técnica interna, como em `FluxoAtendimento.id`.
- Mudar a FK de `pedido.fluxo_atendimento_id` para apontar para `fluxo_atendimento.id` em vez de `identificador` — sem necessidade funcional identificada.
- Revisar se `identificador` deveria ser único apenas dentro do mesmo Fluxo de Atendimento (em vez de globalmente único, como é hoje) — é um comportamento pré-existente, não alterado por este passo.
