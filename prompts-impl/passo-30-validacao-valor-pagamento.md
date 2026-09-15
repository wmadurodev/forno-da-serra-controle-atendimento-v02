# Passo 30 — Máscara e Validação do Valor de Pagamento

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-15. Sem correspondência em `docs/`.
> **Depende de:** Passo 5 (campo Valor Pagamento na Execução de Pedido), Passo 6 (mesmo campo na Edição de Pedido em Execução).

## Objetivo

O campo "Valor Pagamento" passa a ter, nas duas telas onde existe (Tela 6 — Execução de Pedido, e Tela 9 — Edição de Pedido em Execução):
1. Uma **máscara de entrada** que só permite dígitos e um separador decimal (`,` ou `.`), limitando a **no máximo 2 dígitos** depois do separador enquanto o usuário digita.
2. Uma **validação** ao gravar, garantindo que o valor final seja um valor monetário válido.

O campo continua **opcional** (`data-structure.md` §3) — vazio continua sendo válido.

## Levantamento

| Tela | Arquivo | Já valida o formulário no Gravar? |
|---|---|---|
| 6 — Execução de Pedido | `execucao_pedido_screen.dart` | Sim, `_formKey.currentState!.validate()` já é chamado — só falta o `validator`/`inputFormatters` no campo |
| 9 — Edição de Pedido em Execução | `edicao_pedido_execucao_screen.dart` | Sim, mesma coisa |

Nenhuma das duas telas tem `validator` ou `inputFormatters` hoje no `TextFormField` de "Valor Pagamento" — o valor só é convertido (`double.tryParse(texto.replaceAll(',', '.'))`) sem checagem de formato nem restrição de digitação.

## Máscara de entrada (`inputFormatters`)

Novo `TextInputFormatter` (pode viver em `lib/core/widgets/` ou como classe privada duplicada nas duas telas, seguindo o padrão já usado no app de não ter um arquivo de validadores/formatadores compartilhado — a decidir por quem implementar; reaproveitar é preferível dado que a lógica é idêntica nas duas telas):
```dart
/// Só aceita dígitos e um separador decimal (`,` ou `.`), com no máximo 2
/// dígitos depois do separador — Passo 30.
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
```
Qualquer edição que resultaria em texto fora desse formato (letra, segundo separador, 3ª casa decimal) é rejeitada — o campo simplesmente não aceita o caractere, permanecendo no valor anterior. Permite o estado intermediário "10," (separador digitado, ainda sem casas decimais) enquanto o usuário completa a digitação.

## Validador (ao gravar)

```dart
String? _validarValorPagamento(String? value) {
  final texto = value?.trim() ?? '';
  if (texto.isEmpty) return null; // campo opcional
  final valido = RegExp(r'^\d+([.,]\d{1,2})?$').hasMatch(texto);
  if (!valido) {
    return 'Informe um valor monetário válido (até 2 casas decimais)';
  }
  return null;
}
```
Cobre os casos que a máscara sozinha permite como estado intermediário mas não são válidos para gravar (ex. terminar digitando só o separador, sem nenhuma casa decimal: "10,"). Não aceita sinal negativo (valor monetário não deveria ser negativo) — consistente com a máscara, que também não permite `-`.

## Aplicação nas duas telas

```dart
TextFormField(
  controller: _valorPagamentoController,
  decoration: const InputDecoration(labelText: 'Valor Pagamento'),
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  inputFormatters: [ValorPagamentoInputFormatter()],
  validator: _validarValorPagamento,
),
```

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Campo Valor Pagamento vazio continua sendo aceito (campo opcional) em ambas as telas.
- [ ] Digitar letras ou símbolos (exceto `,`/`.`) no campo não surte efeito — o caractere não aparece.
- [ ] Digitar uma 3ª casa decimal (ex. tentar completar "10,555") não é aceito — o campo para em "10,55".
- [ ] Digitar um segundo separador decimal (ex. "10,5,") não é aceito.
- [ ] Terminar a digitação só com o separador e sem casas decimais (ex. "10,") bloqueia o Gravar com a mensagem de erro.
- [ ] Valores válidos com vírgula ou ponto como separador, com 0, 1 ou 2 casas decimais (ex. "10", "10,5", "10.50"), gravam normalmente.
- [ ] Não é possível digitar sinal negativo no campo.

## Fora de Escopo deste Passo

- Qualquer mudança no armazenamento (`valor_pagamento` continua `REAL` no SQLite) ou na exibição do valor em outras telas (Passo 29, cards do Kanban).
- Formatação de milhar (ex. "1.234,56") — o campo aceita só um valor simples sem separador de milhar.
