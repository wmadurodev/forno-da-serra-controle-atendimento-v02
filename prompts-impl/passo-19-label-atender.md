# Passo 19 — Renomear o rótulo "Atendimento" para "Atender" no card

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-14. Ajuste de texto, sem correspondência em `docs/`.
> **Depende de:** Passo 15 (rótulo abaixo do ícone de ação, `PedidoCard._acao`).

## Objetivo

No card de Pedido em `aguardando_atendimento` (Tela 4), o ícone de ação que hoje mostra o rótulo "Atendimento" passa a mostrar "Atender".

## Alteração

Em `lib/features/fluxo_atendimento/presentation/pedido_card.dart`, no `_buildFooter`, trocar:
```dart
_acao(Icons.support_agent_outlined, 'Atendimento', onAtendimento),
```
por:
```dart
_acao(Icons.support_agent_outlined, 'Atender', onAtendimento),
```
Mesmo ícone e mesma ação (`onAtendimento`) — só o texto do rótulo muda.

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Card de Pedido em `aguardando_atendimento` mostra "Atender" abaixo do ícone, no lugar de "Atendimento".
- [ ] Tocar no ícone continua abrindo a Tela 5 normalmente (nenhuma mudança de comportamento).

## Fora de Escopo deste Passo

- Qualquer outro rótulo ou ícone do card.
