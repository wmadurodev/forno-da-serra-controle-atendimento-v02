# Passo 44 — Estilo dos rótulos ("hints") dos campos, em todos os formulários

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-17. Sem correspondência em `docs/`.
> **Depende de:** nenhum passo específico — aplica-se a todo `TextFormField`/`DropdownButtonFormField` já implementado no app.

## Objetivo

Em todo formulário do app, o texto do rótulo do campo (o texto que ocupa o campo antes/quando ele não está preenchido, ex.: "Nome do Cliente", "Identificador do Pedido") deve usar uma fonte um pouco menor que a atual e a cor cinza claro (`light gray`), em vez do estilo padrão do Material.

## Levantamento

Nenhum campo do app usa `hintText`/`hintStyle` do `InputDecoration` — todos usam `labelText` (rótulo flutuante padrão do Material). O app também não define hoje nenhum `InputDecorationTheme` em `lib/core/theme/app_theme.dart` — cada campo herda o estilo padrão do Material 3.

Como nenhum campo sobrescreve o estilo do próprio rótulo individualmente (`grep -rn "labelStyle\|floatingLabelStyle" lib` não retorna nada), a forma correta de cobrir "todos os formulários" de uma vez, sem editar campo por campo, é declarar um `InputDecorationTheme` no tema global (`appTheme`, em `app_theme.dart`) — herdado automaticamente por todo `TextFormField`/`DropdownButtonFormField` do app, presente e futuro.

## Alteração

Em `lib/core/theme/app_theme.dart`, adicionar ao `ThemeData` de `appTheme`:

```dart
inputDecorationTheme: InputDecorationTheme(
  labelStyle: WidgetStateTextStyle.resolveWith(
    (states) => TextStyle(fontSize: 15.6, color: Colors.grey.shade400),
  ),
),
```

- `labelStyle` cobre só o rótulo "em repouso" (campo vazio, sem foco — a posição de "hint", dentro do campo): fonte menor e cinza claro.
- `floatingLabelStyle` **não é definido** (fica no padrão do Material) — quando o campo ganha foco ou é preenchido e o rótulo "flutua" para cima, ele volta ao tamanho/cor originais do tema (padrão M3: cor primária quando focado). Ver "Revisão" abaixo — a primeira versão deste passo também tinha definido `floatingLabelStyle` igual ao `labelStyle`, o que o usuário pediu para reverter.
- Nenhuma tela precisa de alteração individual — o efeito é automático em todos os `TextFormField`/`DropdownButtonFormField` existentes (Telas 3, 5, 6, 7, 8, 9 e Busca de Pedidos).

## Revisão (mesmo dia)

Pedido do usuário: o rótulo, depois que o campo é selecionado (focado) ou preenchido, deve voltar ao tamanho e cor originais (antes deste passo) — só a aparência "em repouso" (campo vazio, sem foco) deve ficar menor/cinza.

A primeira implementação definia `labelStyle` **e** `floatingLabelStyle` com o mesmo `TextStyle` fixo, então o rótulo ficava pequeno/cinza também quando flutuando. Correção, investigada diretamente no código-fonte do Flutter (`input_decorator.dart`, `_getFloatingLabelStyle`): quando `floatingLabelStyle` não é definido no tema, o Flutter cai de volta em `decoration.labelStyle` como base do estilo flutuante — mas **apenas se esse `labelStyle` for usado sem passar por resolução de estado**. Um `TextStyle` fixo (`const TextStyle(...)`) tem seus valores lidos diretamente nesse fallback e por isso "vazava" para o estado flutuante. Trocando `labelStyle` para um `WidgetStateTextStyle.resolveWith(...)` (em vez de um `TextStyle` fixo), esse mesmo fallback deixa de ter efeito: pela documentação da própria classe, um `WidgetStateTextStyle` "se comporta como um `TextStyle()` vazio" quando usado fora de uma resolução de estado (`WidgetStateProperty.resolveAs`) — então, no fallback do rótulo flutuante, ele não sobrescreve nada e o Flutter usa o padrão do Material. Já no cálculo do rótulo "em repouso" (`_getInlineLabelStyle`), o Flutter sempre resolve `decoration.labelStyle` via `WidgetStateProperty.resolveAs(...)`, então nosso estilo pequeno/cinza continua sendo aplicado normalmente nesse estado.

## Revisão 2 (mesmo dia)

Pedido do usuário: aumentar em 20% o tamanho do rótulo "em repouso". `fontSize` do `labelStyle` ajustado de `13` para `15.6` (13 × 1.2). Nenhuma outra mudança — cor, comportamento no estado flutuante (Revisão 1, acima) e todo o resto permanecem iguais.

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Em qualquer formulário do app, o rótulo de cada campo aparece em fonte menor e cinza claro quando o campo está vazio/sem foco.
- [ ] Ao focar ou preencher o campo (rótulo "flutuante" no topo), o rótulo volta ao tamanho e cor originais do tema (padrão Material, cor primária quando focado) — não fica mais pequeno/cinza nesse estado.
- [ ] Nenhuma mudança de validação, comportamento ou layout além do estilo do texto do rótulo.

## Fora de Escopo deste Passo

- Estilo do texto digitado pelo usuário nos campos (cor/tamanho do valor em si) — tratado à parte no Passo 45 apenas para o campo Identificador do Pedido da Tela 5.
- Diálogos sem campo de texto.
