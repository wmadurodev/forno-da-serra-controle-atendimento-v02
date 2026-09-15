import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Abre e mantém a única instância do banco SQLite local do app,
/// conforme `docs/controle-atendimento-non-functional.md` §4.
class AppDatabase {
  AppDatabase._internal();

  static final AppDatabase instance = AppDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    return _database ??= await _open();
  }

  Future<Database> _open() async {
    final databasesPath = await getDatabasesPath();
    final dbPath = p.join(databasesPath, 'controle_atendimento.db');

    return openDatabase(
      dbPath,
      version: 3,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE fluxo_atendimento (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            identificador TEXT NOT NULL UNIQUE,
            status TEXT NOT NULL CHECK (status IN ('aberto', 'fechado'))
          )
        ''');

        await db.execute('''
          CREATE TABLE pedido (
            identificador TEXT PRIMARY KEY,
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
          CREATE INDEX idx_pedido_fluxo_atendimento_id
          ON pedido(fluxo_atendimento_id)
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Passo 11: nova chave sequencial `id` para ordenar a Home por
          // ordem real de criação. SQLite não permite alterar a PRIMARY KEY
          // de uma tabela existente via ALTER TABLE — recria a tabela.
          await db.execute('ALTER TABLE fluxo_atendimento RENAME TO fluxo_atendimento_old');
          await db.execute('''
            CREATE TABLE fluxo_atendimento (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              identificador TEXT NOT NULL UNIQUE,
              status TEXT NOT NULL CHECK (status IN ('aberto', 'fechado'))
            )
          ''');
          await db.execute('''
            INSERT INTO fluxo_atendimento (identificador, status)
            SELECT identificador, status FROM fluxo_atendimento_old ORDER BY rowid ASC
          ''');
          await db.execute('DROP TABLE fluxo_atendimento_old');
        }
        if (oldVersion < 3) {
          // Passo 12: carimbos de data/hora de cada mudança de estado do
          // Pedido, e do cancelamento. Nulos para pedidos já existentes.
          for (final coluna in [
            'data_hora_aguardando_atendimento',
            'data_hora_em_atendimento',
            'data_hora_em_execucao',
            'data_hora_retirado_no_balcao',
            'data_hora_enviado',
            'data_hora_entregue',
            'data_hora_devolvido',
            'data_hora_cancelamento',
          ]) {
            await db.execute('ALTER TABLE pedido ADD COLUMN $coluna TEXT');
          }
        }
      },
    );
  }
}
