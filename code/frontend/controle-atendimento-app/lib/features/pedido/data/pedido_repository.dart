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

  Future<Pedido?> buscarPorIdentificador(String fluxoAtendimentoId, String identificador) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      _table,
      where: 'fluxo_atendimento_id = ? AND identificador = ?',
      whereArgs: [fluxoAtendimentoId, identificador],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Pedido.fromMap(rows.first);
  }

  /// Cria ou atualiza o Pedido. Não usa `conflictAlgorithm.replace` — desde
  /// o Passo 17, `identificador` não é mais a `PRIMARY KEY` de `pedido`
  /// (é `id`, sequencial), e `replace` faria um `DELETE`+`INSERT` a cada
  /// edição, mudando o `id` da linha a cada gravação.
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

  Future<void> excluir(Pedido pedido) async {
    await _garantirFluxoAberto(pedido.fluxoAtendimentoId);
    final db = await _appDatabase.database;
    await db.delete(_table, where: 'identificador = ?', whereArgs: [pedido.identificador]);
  }

  /// Coluna de data/hora correspondente à entrada em cada estado (Passo 12).
  /// `null` para os estados cuja data/hora não é gravada por este método
  /// (`aguardando_atendimento` e `em_atendimento`, gravados nas respectivas
  /// telas de Cadastro/Execução).
  static String? _colunaDataHora(PedidoStatus status) => switch (status) {
        PedidoStatus.retiradoNoBalcao => 'data_hora_retirado_no_balcao',
        PedidoStatus.enviado => 'data_hora_enviado',
        PedidoStatus.entregue => 'data_hora_entregue',
        PedidoStatus.devolvido => 'data_hora_devolvido',
        PedidoStatus.aguardandoAtendimento || PedidoStatus.emAtendimento || PedidoStatus.emExecucao => null,
      };

  Future<void> atualizarStatus(Pedido pedido, PedidoStatus novoStatus) async {
    await _garantirFluxoAberto(pedido.fluxoAtendimentoId);
    final db = await _appDatabase.database;
    final coluna = _colunaDataHora(novoStatus);
    await db.update(
      _table,
      {
        'status': novoStatus.value,
        ?coluna: DateTime.now().toIso8601String(),
      },
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
