# Passo 38 — Ícone do Botão "Enviar" no Card usa a Moto

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-15. Sem correspondência em `docs/`.
> **Depende de:** Passo 24 (botão "Enviar" no card `em_execucao`), Passo 35 (ícone de moto `Icons.two_wheeler` para a fase `enviado`).

## Objetivo

O botão "Enviar" do card `em_execucao` (`PedidoCard._buildFooter`, só aparece para Pedidos `delivery`) passa a usar o mesmo ícone de moto (`Icons.two_wheeler`) já usado para a fase `enviado` no footer/cabeçalho do Kanban (Passo 35), em vez de `Icons.local_shipping_outlined`.

## Levantamento

`pedido_card.dart`, dentro de `_buildFooter`, caso `PedidoStatus.emExecucao` com `tipoEntrega == TipoEntrega.delivery`:
```dart
_acao(
  Icons.local_shipping_outlined,
  'Enviar',
  () => _confirmarAcao(...),
)
```
É o único lugar com esse ícone específico — troca direta, sem efeito colateral em outro botão/tela.

## Alteração — `pedido_card.dart`

```dart
_acao(
  Icons.two_wheeler,
  'Enviar',
  () => _confirmarAcao(
    context,
    titulo: 'Enviar Pedido',
    mensagem: 'Confirma o envio do pedido "${pedido.identificador}"?',
    acao: onEnviado,
  ),
)
```

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] No card `em_execucao` de um Pedido `delivery`, o botão "Enviar" mostra o ícone de moto (igual ao da fase `enviado` no footer/cabeçalho do Kanban).
- [ ] Comportamento do botão (diálogo de confirmação, `onEnviado`) inalterado.
- [ ] Botão "Retirado" (Pedidos não-`delivery`) continua com o ícone de loja (`storefront_outlined`), sem mudança.

## Fora de Escopo deste Passo

- Qualquer outro ícone do card ou do footer/cabeçalho do Kanban — só o botão "Enviar" muda.
