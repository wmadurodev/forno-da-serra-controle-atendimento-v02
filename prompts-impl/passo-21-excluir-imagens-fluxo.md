# Passo 21 — Excluir também as imagens dos Pedidos ao excluir um Fluxo de Atendimento

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-15 — fecha uma lacuna já anotada como "fora de escopo" no Passo 11.
> **Depende de:** Passo 11 (`FluxoAtendimentoRepository.excluirComPedidos`), Passo 5 (`ImagemPedidoStorage`), Passo 20 (arquivos de imagem nomeados por `id`).

## Objetivo

Ao excluir definitivamente um Fluxo de Atendimento (Home, ícone de exclusão + `ExcluirFluxoDialog`, Passo 11), além de apagar o fluxo e seus Pedidos do banco, apagar também os arquivos de imagem (`imagem_pedido_ref`) desses Pedidos do armazenamento local — hoje eles ficam órfãos em `pedidos_imagens/` depois da exclusão.

## Alteração

**`ImagemPedidoStorage`** (`lib/core/storage/imagem_pedido_storage.dart`) — novo método:
```dart
Future<void> excluir(String caminho) async {
  final arquivo = File(caminho);
  if (await arquivo.exists()) {
    await arquivo.delete();
  }
}
```

**`FluxoAtendimentoRepository.excluirComPedidos`** (`lib/features/fluxo_atendimento/data/fluxo_atendimento_repository.dart`) — buscar os `imagem_pedido_ref` de todos os Pedidos do fluxo **antes** de apagá-los do banco, e apagar os arquivos correspondentes **depois** que a transação de exclusão do banco for concluída com sucesso (não apagar arquivo algum se a exclusão do banco falhar):

```dart
Future<void> excluirComPedidos(String identificador) async {
  final db = await _appDatabase.database;
  final pedidos = await db.query(
    'pedido',
    columns: ['imagem_pedido_ref'],
    where: 'fluxo_atendimento_id = ?',
    whereArgs: [identificador],
  );

  await db.transaction((txn) async {
    await txn.delete('pedido', where: 'fluxo_atendimento_id = ?', whereArgs: [identificador]);
    await txn.delete(_table, where: 'identificador = ?', whereArgs: [identificador]);
  });

  final imagemStorage = ImagemPedidoStorage();
  for (final pedido in pedidos) {
    final caminho = pedido['imagem_pedido_ref'] as String?;
    if (caminho != null) {
      await imagemStorage.excluir(caminho);
    }
  }
}
```

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Excluir um Fluxo de Atendimento que tenha Pedidos com imagem: os arquivos correspondentes em `pedidos_imagens/` deixam de existir depois da exclusão (verificável via `adb shell run-as ... ls`).
- [ ] Excluir um Fluxo de Atendimento sem nenhum Pedido com imagem continua funcionando normalmente (nenhuma tentativa de apagar arquivo inexistente causa erro).
- [ ] Pedidos de outros fluxos (não excluídos) mantêm suas imagens intactas.

## Fora de Escopo deste Passo

- Excluir a imagem ao excluir um Pedido individual (`PedidoRepository.excluir`, botão "Excluir" do card `aguardando_atendimento`) — esse Pedido nunca tem imagem nesse estágio (só é definida a partir da Execução), então não há lacuna prática ali.
- Qualquer limpeza de arquivos órfãos pré-existentes (de exclusões feitas antes deste passo) — só as exclusões feitas a partir de agora removem os arquivos.
