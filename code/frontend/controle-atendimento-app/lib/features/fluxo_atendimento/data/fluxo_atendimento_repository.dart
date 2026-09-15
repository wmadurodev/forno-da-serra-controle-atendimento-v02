import '../../../core/database/app_database.dart';
import '../../../core/storage/imagem_pedido_storage.dart';
import '../domain/fluxo_atendimento.dart';

/// Acesso à tabela `fluxo_atendimento`.
///
/// Aplica a regra de unicidade de `docs/controle-atendimento-data-structure.md`
/// §2 ("no máximo um registro com `status = aberto`"), que não é expressável
/// como constraint de coluna no schema.
class FluxoAtendimentoRepository {
  FluxoAtendimentoRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  static const _table = 'fluxo_atendimento';

  Future<List<FluxoAtendimento>> listAll() async {
    final db = await _appDatabase.database;
    final rows = await db.query(_table, orderBy: 'id DESC');
    return rows.map(FluxoAtendimento.fromMap).toList();
  }

  Future<FluxoAtendimento?> getAberto() async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      _table,
      where: 'status = ?',
      whereArgs: [FluxoAtendimentoStatus.aberto.value],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return FluxoAtendimento.fromMap(rows.first);
  }

  Future<void> insert(FluxoAtendimento fluxo) async {
    if (fluxo.status == FluxoAtendimentoStatus.aberto) {
      final existenteAberto = await getAberto();
      if (existenteAberto != null) {
        throw StateError(
          'Já existe um Fluxo de Atendimento aberto (${existenteAberto.identificador}).',
        );
      }
    }
    final db = await _appDatabase.database;
    await db.insert(_table, fluxo.toMap());
  }

  /// Finaliza o fluxo (`functional.md` §5.3) — sem pré-condição sobre os
  /// pedidos nele contidos.
  Future<void> fechar(String identificador) async {
    final db = await _appDatabase.database;
    await db.update(
      _table,
      {'status': FluxoAtendimentoStatus.fechado.value},
      where: 'identificador = ?',
      whereArgs: [identificador],
    );
  }

  /// Exclusão definitiva (hard delete, `functional.md` FN-6) do fluxo e de
  /// todos os seus Pedidos — Passo 11. Exclui os pedidos antes do fluxo por
  /// causa da FK `pedido.fluxo_atendimento_id` com `PRAGMA foreign_keys = ON`.
  /// Também apaga os arquivos de imagem desses Pedidos (Passo 21) — busca os
  /// caminhos antes da transação, e só apaga os arquivos depois que a
  /// exclusão no banco for concluída com sucesso.
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
}
