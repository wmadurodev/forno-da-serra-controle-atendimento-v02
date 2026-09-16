# Passo 41 — Confirmar saída ao usar o botão "Voltar" do Android na Tela 4

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-16. Sem correspondência em `docs/`.
> **Depende de:** Passo 9 (diálogo de confirmação de "Sair"), Passo 40 (footer de ação, onde o botão "Sair" vive hoje).

## Objetivo

Na Tela 4 (Execução do Fluxo de Atendimento — Kanban), se o usuário pressionar o botão físico/gestual "Voltar" do Android, o app deve pedir a mesma confirmação já usada pelo botão "Sair" do footer de ação (Passo 9/40) — em vez de simplesmente voltar para a Home sem perguntar (comportamento padrão do sistema, hoje não interceptado nessa tela).

## Levantamento

`_confirmarSaida` (`quadro_atendimento_screen.dart`) já implementa exatamente o fluxo desejado — diálogo de confirmação seguido de `pushAndRemoveUntil` para a `HomeScreen` quando confirmado:

```dart
Future<void> _confirmarSaida(BuildContext context) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Sair'),
      content: const Text('Deseja sair da execução deste fluxo de atendimento?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Sair')),
      ],
    ),
  );

  if (confirmar == true && context.mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }
}
```

Hoje ela só é chamada pelo botão "Sair" do footer de ação. O botão "Voltar" do Android (gesto ou tecla física) não é interceptado — o `Scaffold` da Tela 4 não está envolto em nenhum `PopScope`, então o pop padrão do `Navigator` acontece sem diálogo algum.

**Correção proposta:** envolver o `Scaffold` de `_QuadroViewState.build` em um `PopScope`, com `canPop: false` (impede o pop automático do sistema) e `onPopInvokedWithResult` chamando `_confirmarSaida(context)` quando `didPop == false` — reaproveitando o mesmo método/diálogo do botão "Sair", sem duplicar lógica.

## Alteração — `quadro_atendimento_screen.dart`

Em `_QuadroViewState.build`:

```dart
@override
Widget build(BuildContext context) {
  final controller = context.watch<QuadroAtendimentoController>();

  return PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (didPop) return;
      _confirmarSaida(context);
    },
    child: Scaffold(
      body: SafeArea(...),
      bottomNavigationBar: Column(...),
    ),
  );
}
```

Notas:
- `PopScope` (não o `WillPopScope`, deprecated) é a API atual para interceptar pop de navegação nesta versão do Flutter (3.47).
- `canPop: false` garante que o botão/gesto "Voltar" nunca saia da tela sozinho — a única forma de sair é confirmando o diálogo (mesmo comportamento do botão "Sair" do footer).
- `_confirmarSaida` já checa `context.mounted` antes de navegar e já faz o `pushAndRemoveUntil` correto para a Home — nenhuma mudança nela é necessária.
- Sem mudanças em `_confirmarSaida`, no botão "Sair" do footer de ação, nem em nenhuma outra tela.

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Na Tela 4, pressionar o botão/gesto "Voltar" do Android abre o mesmo diálogo "Sair — Deseja sair da execução deste fluxo de atendimento?".
- [ ] Confirmando ("Sair") no diálogo aberto pelo botão "Voltar", o app navega para a Home (mesmo destino do botão "Sair" do footer).
- [ ] Cancelando ("Cancelar") no diálogo aberto pelo botão "Voltar", o app permanece na Tela 4, sem navegar.
- [ ] Botão "Sair" do footer de ação continua funcionando exatamente como antes (mesmo diálogo, mesmo destino).
- [ ] Diálogos abertos a partir da Tela 4 (Cadastro/Execução/Cancelamento/Devolução de Pedido, Filtro, Busca) não são afetados — o `PopScope` está apenas no `Scaffold` da Tela 4, não interfere no pop dessas rotas/diálogos filhas.

## Fora de Escopo deste Passo

- Interceptar o botão "Voltar" em qualquer outra tela do app — só a Tela 4.
- Mudar o texto, os botões ou o destino do diálogo de confirmação — é o mesmo diálogo do botão "Sair", só passa a ser disparado também pelo "Voltar".
