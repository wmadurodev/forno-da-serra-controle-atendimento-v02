# Passo 15 — Rótulo abaixo dos ícones de ação nos cards (Tela 4)

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-14. Sem correspondência prévia em `docs/`.
> **Depende de:** Passo 14 (ícones de ação no rodapé do `PedidoCard`, hoje só com `tooltip`).

## Objetivo

Nos cards de Pedido do Kanban (`PedidoCard`, `lib/features/fluxo_atendimento/presentation/pedido_card.dart`), cada ícone de ação do rodapé (Passo 14) passa a exibir o nome da ação **abaixo do ícone**, em cinza — em vez de depender só do `tooltip` (que só aparece em toque longo/hover, pouco descobrível no Android).

## Alteração

Trocar cada `IconButton(icon: ..., tooltip: '<nome>', onPressed: ...)` do `_buildFooter` por um botão composto ícone + rótulo. Novo helper:

```dart
Widget _acao(IconData icone, String rotulo, VoidCallback? onPressed) {
  return InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone),
          const SizedBox(height: 2),
          Text(rotulo, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        ],
      ),
    ),
  );
}
```

Cada uma das 9 ações existentes (Atendimento, Excluir, Executar, Editar — cadastro e execução —, Cancelar, Enviado, Retirado, Entregue, Devolvido) passa a chamar `_acao(icone, 'Nome', onPressed)` no lugar do `IconButton` atual, mantendo o mesmo ícone já definido no Passo 14 e o mesmo texto que hoje está no `tooltip` (o `tooltip` deixa de ser necessário, já que o rótulo fica sempre visível — pode ser removido ou mantido como reforço de acessibilidade, à critério de quem implementar).

O `Wrap` que agrupa as ações no rodapé (`alignment: WrapAlignment.center`, Passo 14) permanece igual — só o tipo de widget de cada ação muda.

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Todo ícone de ação no rodapé de qualquer card, em qualquer status, mostra o nome da ação em cinza logo abaixo do ícone.
- [ ] Tocar em qualquer ação continua disparando o mesmo comportamento de antes (nenhuma mudança de funcionalidade, só de apresentação).
- [ ] Os botões continuam centralizados horizontalmente no card (Passo 14).

## Fora de Escopo deste Passo

- Qualquer mudança de ícone ou de comportamento das ações — só a adição do rótulo textual abaixo do ícone já existente.
