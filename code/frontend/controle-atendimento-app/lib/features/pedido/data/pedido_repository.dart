import '../../../core/database/app_database.dart';
import '../../fluxo_atendimento/domain/fluxo_atendimento.dart';
import '../domain/pedido.dart';

/// Acesso à tabela `pedido`.
///
/// Aplica a regra geral 3 de `docs/controle-atendimento-functional.md`
/// ("toda operação de escrita sobre um Pedido exige que o Fluxo de
/// Atendimento ao qual ele pertence esteja `aberto`"), que não é
/// expressável como constraint de coluna no schema.
class PedidoRepository {
  PedidoRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  static const _table = 'pedido';
  static const _tableFluxoAtendimento = 'fluxo_atendimento';

  Future<List<Pedido>> listByFluxo(String fluxoAtendimentoId) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      _table,
      where: 'fluxo_atendimento_id = ?',
      whereArgs: [fluxoAtendimentoId],
      orderBy: 'identificador ASC',
    );
    return rows.map(Pedido.fromMap).toList();
  }

  Future<void> excluir(Pedido pedido) async {
    await _garantirFluxoAberto(pedido.fluxoAtendimentoId);
    final db = await _appDatabase.database;
    await db.delete(_table, where: 'identificador = ?', whereArgs: [pedido.identificador]);
  }

  Future<void> atualizarStatus(Pedido pedido, PedidoStatus novoStatus) async {
    await _garantirFluxoAberto(pedido.fluxoAtendimentoId);
    final db = await _appDatabase.database;
    await db.update(
      _table,
      {'status': novoStatus.value},
      where: 'identificador = ?',
      whereArgs: [pedido.identificador],
    );
  }

  Future<void> _garantirFluxoAberto(String fluxoAtendimentoId) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      _tableFluxoAtendimento,
      columns: ['status'],
      where: 'identificador = ?',
      whereArgs: [fluxoAtendimentoId],
      limit: 1,
    );
    final status = rows.isEmpty ? null : FluxoAtendimentoStatus.fromValue(rows.first['status']! as String);
    if (status != FluxoAtendimentoStatus.aberto) {
      throw StateError('O Fluxo de Atendimento está fechado; não é possível alterar o Pedido.');
    }
  }
}
