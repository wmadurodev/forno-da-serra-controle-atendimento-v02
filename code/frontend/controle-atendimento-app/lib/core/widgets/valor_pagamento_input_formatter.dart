import 'package:flutter/services.dart';

/// Só aceita dígitos e um separador decimal (`,` ou `.`), com no máximo 2
/// dígitos depois do separador — Passo 30 (campo "Valor Pagamento", Telas
/// 6 e 9). Qualquer edição que resultaria em texto fora desse formato é
/// rejeitada, mantendo o valor anterior.
class ValorPagamentoInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final texto = newValue.text;
    if (texto.isEmpty) return newValue;
    if (!RegExp(r'^\d*([.,]\d{0,2})?$').hasMatch(texto)) {
      return oldValue;
    }
    return newValue;
  }
}

/// Valida que o Valor Pagamento, quando informado, é um valor monetário
/// válido (no máximo 2 casas decimais, sem sinal negativo) — Passo 30. O
/// campo é opcional: vazio é sempre válido.
String? validarValorPagamento(String? value) {
  final texto = value?.trim() ?? '';
  if (texto.isEmpty) return null;
  final valido = RegExp(r'^\d+([.,]\d{1,2})?$').hasMatch(texto);
  if (!valido) {
    return 'Informe um valor monetário válido (até 2 casas decimais)';
  }
  return null;
}
