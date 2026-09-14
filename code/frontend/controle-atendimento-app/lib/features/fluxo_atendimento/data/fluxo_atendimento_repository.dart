import '../../../core/database/app_database.dart';
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
    final rows = await db.query(_table, orderBy: 'identificador DESC');
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
}
