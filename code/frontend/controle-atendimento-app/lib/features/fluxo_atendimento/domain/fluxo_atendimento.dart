/// Status do Fluxo de Atendimento — `docs/controle-atendimento-data-structure.md` §4.1.
enum FluxoAtendimentoStatus {
  aberto,
  fechado;

  String get value => switch (this) {
        FluxoAtendimentoStatus.aberto => 'aberto',
        FluxoAtendimentoStatus.fechado => 'fechado',
      };

  static FluxoAtendimentoStatus fromValue(String value) {
    return switch (value) {
      'aberto' => FluxoAtendimentoStatus.aberto,
      'fechado' => FluxoAtendimentoStatus.fechado,
      _ => throw ArgumentError('Status de Fluxo de Atendimento inválido: $value'),
    };
  }
}

/// Entidade Fluxo de Atendimento — `docs/controle-atendimento-data-structure.md` §2.
class FluxoAtendimento {
  const FluxoAtendimento({
    required this.identificador,
    required this.status,
  });

  final String identificador;
  final FluxoAtendimentoStatus status;

  factory FluxoAtendimento.fromMap(Map<String, Object?> map) {
    return FluxoAtendimento(
      identificador: map['identificador']! as String,
      status: FluxoAtendimentoStatus.fromValue(map['status']! as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'identificador': identificador,
      'status': status.value,
    };
  }
}
