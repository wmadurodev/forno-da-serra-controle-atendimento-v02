# Passo 32 — Limite de Tamanho do Valor de Pagamento

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-15. Sem correspondência em `docs/`.
> **Depende de:** Passo 30 (máscara e validação do campo Valor Pagamento, `ValorPagamentoInputFormatter`/`validarValorPagamento` em `lib/core/widgets/valor_pagamento_input_formatter.dart`, compartilhado pelas Telas 6 e 9).

## Objetivo

O campo "Valor Pagamento" (Telas 6 e 9) passa a aceitar **no máximo 8 caracteres**, contando o separador decimal (`,` ou `.`) — ex. `99999,99` (5 dígitos inteiros + separador + 2 decimais) é o maior valor digitável.

## Levantamento

O formatador compartilhado `ValorPagamentoInputFormatter` (`lib/core/widgets/valor_pagamento_input_formatter.dart`, Passo 30) já intercepta toda edição do campo nas duas telas e rejeita o que não bate com o formato monetário (`^\d*([.,]\d{0,2})?$`), sem hoje impor limite de tamanho total — um usuário pode digitar um número inteiro arbitrariamente longo (ex. "123456789"). Como o formatador já é o único ponto de entrada em ambas as telas, o limite de tamanho entra ali, sem precisar tocar nas telas.

## Alteração — `valor_pagamento_input_formatter.dart`

```dart
class ValorPagamentoInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final texto = newValue.text;
    if (texto.isEmpty) return newValue;
    if (texto.length > 8) return oldValue;
    if (!RegExp(r'^\d*([.,]\d{0,2})?$').hasMatch(texto)) {
      return oldValue;
    }
    return newValue;
  }
}
```

Não há mudança no validador `validarValorPagamento` nem nas duas telas — o limite é imposto só na digitação, no mesmo formatador já compartilhado.

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Nas Telas 6 e 9, o campo Valor Pagamento não aceita mais de 8 caracteres no total (ex. tentar digitar "123456,78" para em "12345,67" — ou comportamento equivalente de bloquear o 9º caractere).
- [ ] Valores dentro do limite (ex. "99999,99", "100", "10,5") continuam sendo aceitos normalmente.
- [ ] Comportamento existente do Passo 30 (rejeitar letras, segundo separador, 3ª casa decimal) continua funcionando.

## Fora de Escopo deste Passo

- Qualquer mudança no armazenamento (`valor_pagamento` continua `REAL` no SQLite, sem limite de precisão numérica) ou na exibição do valor em outras telas (Passo 29, cards do Kanban).
