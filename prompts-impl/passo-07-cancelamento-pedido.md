# Passo 7 — Cancelamento de Pedido (Tela 7)

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Referências obrigatórias:** `docs/controle-atendimento-prototype.md` §3.7 (Tela 7), §4.2/§4.3 (cards `em_atendimento`/`em_execucao`); `docs/controle-atendimento-functional.md` §6.2 (transição 3.5), §6.1 (nota do diagrama — cancelamento não é transição de `status`), §8.
> **Depende de:** Passos 1 a 6, concluídos e validados.

## Objetivo

Implementar a Tela 7 (Cancelamento de Pedido), acionada pelo botão **"Cancelar"** dos cards `em_atendimento` e `em_execucao` na Tela 4. Define `cancelado = true` no Pedido, preservando o `status` corrente (`functional.md` §6.2, 3.5) — cancelamento é a marcação de um atributo independente, não uma transição de estado.

## Escopo deste Passo

**Incluído:**
- Tela 7 — Cancelamento de Pedido, completa.
- Botão "Cancelar" dos cards `em_atendimento` e `em_execucao` (Tela 4): troca o placeholder "Disponível a partir do Passo 7" pela navegação real.

**Não incluído (fica para passos seguintes):**
- "Devolvido" (Tela 8) — Passo 8.

## Tela 7 — Cancelamento de Pedido

Local: `lib/features/pedido/presentation/cancelamento_pedido_screen.dart`. Recebe o `Pedido` a cancelar (sempre pré-selecionado — só é aberta a partir de um card).

Campo (`prototype.md` §3.7):

| Campo (UI) | Nome técnico | Observações |
|---|---|---|
| Motivo | `motivo_cancelamento` | Opcional — texto livre (`functional.md` §8). |

Footer: botões **Confirmar** e **Cancelar**.

| Ação | Comportamento |
|---|---|
| Confirmar | Grava o Pedido com `cancelado = true` e `motivo_cancelamento` (o texto informado, ou `null` se vazio), **mantendo o `status` atual** (`em_atendimento` ou `em_execucao`, o que já estava). Retorna (`pop`) para a Tela 4. |
| Cancelar (botão) | Fecha a tela sem alterar o pedido, retorna (`pop`) para a Tela 4. |

Nenhuma outra alteração é feita no Pedido — os demais campos permanecem exatamente como estavam.

## Tela 4 — Ajuste

Em `pedido_card.dart` / `quadro_atendimento_screen.dart`: botão "Cancelar" dos cards `em_atendimento` e `em_execucao` abre `CancelamentoPedidoScreen(pedido: pedido)` via `Navigator.push`; ao retornar, recarregar o quadro (`controller.load()`).

Lembrete (`prototype.md` §4, regras transversais, já implementado desde o Passo 3): um Pedido com `cancelado = true` exibe o rótulo "cancelado" em vermelho e **nenhum footer de ações**, na coluna do seu `status` atual — logo, após cancelar, os botões "Cancelar"/"Executar"/"Editar"/etc. daquele card somem automaticamente.

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Card `em_atendimento`, botão "Cancelar": abre a Tela 7.
- [ ] Card `em_execucao`, botão "Cancelar": abre a Tela 7.
- [ ] Confirmar sem preencher o Motivo: cancela o pedido (`cancelado = true`, `motivo_cancelamento = null`), mantendo o `status` e a coluna atuais; o card volta a aparecer com o rótulo "cancelado" em vermelho e sem nenhum botão de ação.
- [ ] Confirmar com um Motivo preenchido: cancela o pedido, gravando o motivo informado.
- [ ] Botão "Cancelar" (footer da Tela 7): retorna à Tela 4 sem alterar o pedido.

## Fora de Escopo deste Passo

- Tela 8 (Devolução de Entrega) — Passo 8.
- Testes automatizados de UI — não obrigatórios para a validação deste passo.
