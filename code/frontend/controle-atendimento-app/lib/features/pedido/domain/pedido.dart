/// Status do Pedido — `docs/controle-atendimento-data-structure.md` §4.2.
enum PedidoStatus {
  aguardandoAtendimento,
  emAtendimento,
  emExecucao,
  retiradoNoBalcao,
  enviado,
  entregue,
  devolvido;

  String get value => switch (this) {
        PedidoStatus.aguardandoAtendimento => 'aguardando_atendimento',
        PedidoStatus.emAtendimento => 'em_atendimento',
        PedidoStatus.emExecucao => 'em_execucao',
        PedidoStatus.retiradoNoBalcao => 'retirado_no_balcao',
        PedidoStatus.enviado => 'enviado',
        PedidoStatus.entregue => 'entregue',
        PedidoStatus.devolvido => 'devolvido',
      };

  String get titulo => switch (this) {
        PedidoStatus.aguardandoAtendimento => 'Aguardando Atendimento',
        PedidoStatus.emAtendimento => 'Em Atendimento',
        PedidoStatus.emExecucao => 'Em Execução',
        PedidoStatus.retiradoNoBalcao => 'Retirado no Balcão',
        PedidoStatus.enviado => 'Enviado',
        PedidoStatus.entregue => 'Entregue',
        PedidoStatus.devolvido => 'Devolvido',
      };

  static PedidoStatus fromValue(String value) {
    return switch (value) {
      'aguardando_atendimento' => PedidoStatus.aguardandoAtendimento,
      'em_atendimento' => PedidoStatus.emAtendimento,
      'em_execucao' => PedidoStatus.emExecucao,
      'retirado_no_balcao' => PedidoStatus.retiradoNoBalcao,
      'enviado' => PedidoStatus.enviado,
      'entregue' => PedidoStatus.entregue,
      'devolvido' => PedidoStatus.devolvido,
      _ => throw ArgumentError('Status de Pedido inválido: $value'),
    };
  }
}

/// Tipo de Entrega — `docs/controle-atendimento-data-structure.md` §4.3.
enum TipoEntrega {
  delivery,
  retiradaBalcao;

  String get value => switch (this) {
        TipoEntrega.delivery => 'delivery',
        TipoEntrega.retiradaBalcao => 'retirada_balcao',
      };

  String get titulo => switch (this) {
        TipoEntrega.delivery => 'Delivery',
        TipoEntrega.retiradaBalcao => 'Retirada no Balcão',
      };

  static TipoEntrega fromValue(String value) {
    return switch (value) {
      'delivery' => TipoEntrega.delivery,
      'retirada_balcao' => TipoEntrega.retiradaBalcao,
      _ => throw ArgumentError('Tipo de Entrega inválido: $value'),
    };
  }
}

/// Tipo de Pagamento — `docs/controle-atendimento-data-structure.md` §4.4.
enum TipoPagamento {
  pix,
  cartao,
  dinheiro;

  String get value => switch (this) {
        TipoPagamento.pix => 'pix',
        TipoPagamento.cartao => 'cartao',
        TipoPagamento.dinheiro => 'dinheiro',
      };

  String get titulo => switch (this) {
        TipoPagamento.pix => 'Pix',
        TipoPagamento.cartao => 'Cartão',
        TipoPagamento.dinheiro => 'Dinheiro',
      };

  static TipoPagamento fromValue(String value) {
    return switch (value) {
      'pix' => TipoPagamento.pix,
      'cartao' => TipoPagamento.cartao,
      'dinheiro' => TipoPagamento.dinheiro,
      _ => throw ArgumentError('Tipo de Pagamento inválido: $value'),
    };
  }
}

/// Entidade Pedido — `docs/controle-atendimento-data-structure.md` §3.
class Pedido {
  const Pedido({
    required this.identificador,
    required this.fluxoAtendimentoId,
    required this.status,
    required this.cancelado,
    this.nomeCliente,
    this.tipoEntrega,
    this.tipoPagamento,
    this.endereco,
    this.observacao,
    this.restricoes,
    this.valorPagamento,
    this.mesa,
    this.imagemPedidoRef,
    this.motivoCancelamento,
    this.motivoDevolucao,
    this.dataHoraAguardandoAtendimento,
    this.dataHoraEmAtendimento,
    this.dataHoraEmExecucao,
    this.dataHoraRetiradoNoBalcao,
    this.dataHoraEnviado,
    this.dataHoraEntregue,
    this.dataHoraDevolvido,
    this.dataHoraCancelamento,
  });

  final String identificador;
  final String fluxoAtendimentoId;
  final PedidoStatus status;
  final bool cancelado;
  final String? nomeCliente;
  final TipoEntrega? tipoEntrega;
  final TipoPagamento? tipoPagamento;
  final String? endereco;
  final String? observacao;
  final String? restricoes;
  final double? valorPagamento;
  final String? mesa;
  final String? imagemPedidoRef;
  final String? motivoCancelamento;
  final String? motivoDevolucao;

  /// Data/hora em que cada estado foi alcançado, e do cancelamento — Passo 12.
  /// Preenchidos uma única vez, na transição de entrada daquele estado.
  final DateTime? dataHoraAguardandoAtendimento;
  final DateTime? dataHoraEmAtendimento;
  final DateTime? dataHoraEmExecucao;
  final DateTime? dataHoraRetiradoNoBalcao;
  final DateTime? dataHoraEnviado;
  final DateTime? dataHoraEntregue;
  final DateTime? dataHoraDevolvido;
  final DateTime? dataHoraCancelamento;

  /// Data/hora em que o pedido alcançou o `status` atual — usado no título
  /// do card do Kanban (`docs/controle-atendimento-prototype.md` §4).
  DateTime? get dataHoraStatusAtual => switch (status) {
        PedidoStatus.aguardandoAtendimento => dataHoraAguardandoAtendimento,
        PedidoStatus.emAtendimento => dataHoraEmAtendimento,
        PedidoStatus.emExecucao => dataHoraEmExecucao,
        PedidoStatus.retiradoNoBalcao => dataHoraRetiradoNoBalcao,
        PedidoStatus.enviado => dataHoraEnviado,
        PedidoStatus.entregue => dataHoraEntregue,
        PedidoStatus.devolvido => dataHoraDevolvido,
      };

  static DateTime? _parseDataHora(Object? valor) {
    if (valor is! String || valor.isEmpty) return null;
    return DateTime.tryParse(valor);
  }

  factory Pedido.fromMap(Map<String, Object?> map) {
    return Pedido(
      identificador: map['identificador']! as String,
      fluxoAtendimentoId: map['fluxo_atendimento_id']! as String,
      status: PedidoStatus.fromValue(map['status']! as String),
      cancelado: (map['cancelado']! as int) != 0,
      nomeCliente: map['nome_cliente'] as String?,
      tipoEntrega: (map['tipo_entrega'] as String?) != null
          ? TipoEntrega.fromValue(map['tipo_entrega']! as String)
          : null,
      tipoPagamento: (map['tipo_pagamento'] as String?) != null
          ? TipoPagamento.fromValue(map['tipo_pagamento']! as String)
          : null,
      endereco: map['endereco'] as String?,
      observacao: map['observacao'] as String?,
      restricoes: map['restricoes'] as String?,
      valorPagamento: map['valor_pagamento'] as double?,
      mesa: map['mesa'] as String?,
      imagemPedidoRef: map['imagem_pedido_ref'] as String?,
      motivoCancelamento: map['motivo_cancelamento'] as String?,
      motivoDevolucao: map['motivo_devolucao'] as String?,
      dataHoraAguardandoAtendimento: _parseDataHora(map['data_hora_aguardando_atendimento']),
      dataHoraEmAtendimento: _parseDataHora(map['data_hora_em_atendimento']),
      dataHoraEmExecucao: _parseDataHora(map['data_hora_em_execucao']),
      dataHoraRetiradoNoBalcao: _parseDataHora(map['data_hora_retirado_no_balcao']),
      dataHoraEnviado: _parseDataHora(map['data_hora_enviado']),
      dataHoraEntregue: _parseDataHora(map['data_hora_entregue']),
      dataHoraDevolvido: _parseDataHora(map['data_hora_devolvido']),
      dataHoraCancelamento: _parseDataHora(map['data_hora_cancelamento']),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'identificador': identificador,
      'fluxo_atendimento_id': fluxoAtendimentoId,
      'status': status.value,
      'cancelado': cancelado ? 1 : 0,
      'nome_cliente': nomeCliente,
      'tipo_entrega': tipoEntrega?.value,
      'tipo_pagamento': tipoPagamento?.value,
      'endereco': endereco,
      'observacao': observacao,
      'restricoes': restricoes,
      'valor_pagamento': valorPagamento,
      'mesa': mesa,
      'imagem_pedido_ref': imagemPedidoRef,
      'motivo_cancelamento': motivoCancelamento,
      'motivo_devolucao': motivoDevolucao,
      'data_hora_aguardando_atendimento': dataHoraAguardandoAtendimento?.toIso8601String(),
      'data_hora_em_atendimento': dataHoraEmAtendimento?.toIso8601String(),
      'data_hora_em_execucao': dataHoraEmExecucao?.toIso8601String(),
      'data_hora_retirado_no_balcao': dataHoraRetiradoNoBalcao?.toIso8601String(),
      'data_hora_enviado': dataHoraEnviado?.toIso8601String(),
      'data_hora_entregue': dataHoraEntregue?.toIso8601String(),
      'data_hora_devolvido': dataHoraDevolvido?.toIso8601String(),
      'data_hora_cancelamento': dataHoraCancelamento?.toIso8601String(),
    };
  }
}
