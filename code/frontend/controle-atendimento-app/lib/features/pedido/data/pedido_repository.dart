import '../../../core/database/app_database.dart';
import '../../fluxo_atendimento/domain/fluxo_atendimento.dart';
import '../domain/pedido.dart';

/// Campos pesquisáveis na Busca de Pedidos (Passo 27, `functional.md` §5.5
/// — estendido com `observacao` e `restricoes` a pedido do usuário).
enum CampoBuscaPedido { identificador, nomeCliente, endereco, mesa, observacao, restricoes }

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

  /// Pedido mais recente (maior `id`) com este identificador, em qualquer
  /// Fluxo de Atendimento — usado como molde de Cadastro para um Pedido
  /// novo (Passo 18). `identificador` não é mais único (nem globalmente,
  /// nem por fluxo), por isso a busca é sempre "o mais recente".
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

  /// Busca de Pedidos (Passo 27, `functional.md` §5.5) — sempre dentro de um
  /// único Fluxo de Atendimento. Só `mesa` faz correspondência exata; os
  /// demais campos buscam por conteúdo parcial (`LIKE`).
  Future<List<Pedido>> buscar(String fluxoAtendimentoId, CampoBuscaPedido campo, String valor) async {
    final coluna = switch (campo) {
      CampoBuscaPedido.identificador => 'identificador',
      CampoBuscaPedido.nomeCliente => 'nome_cliente',
      CampoBuscaPedido.endereco => 'endereco',
      CampoBuscaPedido.mesa => 'mesa',
      CampoBuscaPedido.observacao => 'observacao',
      CampoBuscaPedido.restricoes => 'restricoes',
    };
    final exata = campo == CampoBuscaPedido.mesa;
    final db = await _appDatabase.database;
    final rows = await db.query(
      _table,
      where: "fluxo_atendimento_id = ? AND $coluna ${exata ? '= ?' : 'LIKE ?'}",
      whereArgs: [fluxoAtendimentoId, exata ? valor : '%$valor%'],
    );
    return rows.map(Pedido.fromMap).toList();
  }

  /// Cria ou atualiza o Pedido, por `id` — desde o Passo 18, `identificador`
  /// não identifica uma linha unicamente (pode haver vários Pedidos com o
  /// mesmo identificador).
  Future<void> salvar(Pedido pedido) async {
    await _garantirFluxoAberto(pedido.fluxoAtendimentoId);
    final db = await _appDatabase.database;
    if (pedido.id == null) {
      await db.insert(_table, pedido.toMap());
    } else {
      await db.update(_table, pedido.toMap(), where: 'id = ?', whereArgs: [pedido.id]);
    }
  }

  Future<void> excluir(Pedido pedido) async {
    await _garantirFluxoAberto(pedido.fluxoAtendimentoId);
    final db = await _appDatabase.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [pedido.id]);
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
      where: 'id = ?',
      whereArgs: [pedido.id],
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
