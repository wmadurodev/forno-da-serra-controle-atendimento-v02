# Passo 16 — Botão "Concluído" no teclado dos campos de Motivo (multilinha)

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** correção de bug relatada diretamente pelo usuário desta iniciativa de implementação, em 2026-09-14, na Tela 7 (Cancelamento de Pedido). Sem correspondência em `docs/` — é um ajuste de comportamento do teclado, não de regra de negócio.

## Bug

Na Tela 7 (`CancelamentoPedidoScreen`, `lib/features/pedido/presentation/cancelamento_pedido_screen.dart`), o campo "Motivo" (`TextFormField`, `maxLines: 3`) não define `textInputAction`. Um `TextFormField` multilinha sem essa propriedade usa por padrão `TextInputAction.newline`, e o teclado Android não mostra o botão "Concluído"/"Done" — a única forma de fechar o teclado é tocar fora do campo ou usar o botão de voltar do sistema, o que não é óbvio para o usuário.

**Mesmo problema encontrado em outro lugar do app** (mesma causa raiz, mesmo campo "Motivo"): `DevolucaoEntregaScreen` (Tela 8, `lib/features/pedido/presentation/devolucao_entrega_screen.dart`), campo "Motivo da Devolução", também `maxLines: 3` sem `textInputAction`. O usuário só relatou o caso da Tela 7, mas como é o mesmo bug no mesmo tipo de campo, este passo corrige os dois.

## Correção

Em ambos os `TextFormField`, adicionar:
```dart
textInputAction: TextInputAction.done,
onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
```
`textInputAction: TextInputAction.done` faz o teclado mostrar o botão "Concluído" mesmo em um campo multilinha (em vez de inserir quebra de linha); `onFieldSubmitted` fecha o teclado ao tocar nesse botão (sem isso, o botão apareceria mas não faria nada em um campo multilinha).

Arquivos:
- `lib/features/pedido/presentation/cancelamento_pedido_screen.dart` (campo "Motivo").
- `lib/features/pedido/presentation/devolucao_entrega_screen.dart` (campo "Motivo da Devolução").

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Ao tocar no campo "Motivo" da Tela 7 (Cancelamento), o teclado mostra um botão "Concluído"/"Done"; tocar nele fecha o teclado.
- [ ] Mesmo comportamento no campo "Motivo da Devolução" da Tela 8 (Devolução de Entrega).
- [ ] Digitar múltiplas linhas nesses campos antes de tocar em "Concluído" continua funcionando normalmente (o botão só fecha o teclado, não impede quebras de linha durante a digitação — comportamento padrão do Android para `TextInputAction.done` em campo multilinha).

## Fora de Escopo deste Passo

- Qualquer outro campo de texto do app — só os dois campos "Motivo" (`maxLines: 3`) têm esse problema (`grep -rn "maxLines" lib` confirma que são os únicos multilinha).
