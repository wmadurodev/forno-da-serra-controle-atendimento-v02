# Passo 24 — Renomear "Enviado" para "Enviar" e confirmar Enviar/Retirado/Entregue

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-15. Sem correspondência em `docs/`.
> **Depende de:** Passo 15 (rótulo abaixo do ícone, `PedidoCard._acao`).

## Objetivo

1. No card `em_execucao`, o rótulo do botão "Enviado" passa a "Enviar" (mesmo ícone e ação).
2. Diálogo de confirmação simples e nativo (mesmo padrão do "Excluir Pedido" já existente, `docs/controle-atendimento-prototype.md` §5 — não conta como tela numerada) antes de disparar:
   - "Enviar" (card `em_execucao`, delivery).
   - "Retirado" (card `em_execucao`, retirada no balcão).
   - "Entregue" (card `enviado`).

**Não muda:** "Editar" e "Cancelar" (`em_execucao`), "Devolvido" (`enviado`) — continuam sem diálogo de confirmação, disparando a ação direto.

## Alteração — `PedidoCard._buildFooter` (`lib/features/fluxo_atendimento/presentation/pedido_card.dart`)

Novo helper genérico de confirmação, ao lado do já existente `_confirmarExclusao`:
```dart
Future<void> _confirmarAcao(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  required Future<void> Function() acao,
}) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(titulo),
      content: Text(mensagem),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Confirmar')),
      ],
    ),
  );
  if (confirmar == true) {
    await acao();
  }
}
```

`case PedidoStatus.emExecucao` e `case PedidoStatus.enviado` passam a:
```dart
case PedidoStatus.emExecucao:
  botoes = [
    if (pedido.tipoEntrega == TipoEntrega.delivery)
      _acao(
        Icons.local_shipping_outlined,
        'Enviar',
        () => _confirmarAcao(
          context,
          titulo: 'Enviar Pedido',
          mensagem: 'Confirma o envio do pedido "${pedido.identificador}"?',
          acao: onEnviado,
        ),
      )
    else
      _acao(
        Icons.storefront_outlined,
        'Retirado',
        () => _confirmarAcao(
          context,
          titulo: 'Retirado',
          mensagem: 'Confirma que o pedido "${pedido.identificador}" foi retirado no balcão?',
          acao: onRetirado,
        ),
      ),
    _acao(Icons.edit_outlined, 'Editar', onEditarExecucao),
    _acao(Icons.cancel_outlined, 'Cancelar', onCancelar),
  ];
case PedidoStatus.enviado:
  botoes = [
    _acao(
      Icons.check_circle_outline,
      'Entregue',
      () => _confirmarAcao(
        context,
        titulo: 'Entregue',
        mensagem: 'Confirma que o pedido "${pedido.identificador}" foi entregue?',
        acao: onEntregue,
      ),
    ),
    _acao(Icons.assignment_return_outlined, 'Devolvido', onDevolvido),
  ];
```
Textos exatos dos diálogos ajustáveis livremente — o ponto obrigatório é: um diálogo simples de confirmar/cancelar antes de cada uma dessas 3 ações, e o rótulo "Enviar" no lugar de "Enviado".

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Card `em_execucao` (delivery) mostra "Enviar" no lugar de "Enviado".
- [ ] Tocar em "Enviar", "Retirado" ou "Entregue" abre um diálogo de confirmação; confirmar executa a ação normalmente (mesmo comportamento de antes), cancelar não altera nada.
- [ ] "Editar", "Cancelar" e "Devolvido" continuam sem diálogo, disparando a ação direto (comportamento inalterado).

## Fora de Escopo deste Passo

- Diálogo de confirmação para "Atender", "Executar", "Editar", "Cancelar" ou "Devolvido" — não foi pedido.
