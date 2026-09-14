# Passo 8 — Devolução de Entrega (Tela 8)

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Referências obrigatórias:** `docs/controle-atendimento-prototype.md` §3.8 (Tela 8), §4.5 (card `enviado`); `docs/controle-atendimento-functional.md` §6.2 (transição 3.9), **FN-1**; `docs/controle-atendimento-data-structure.md` §3 (`motivo_devolucao`), **DS-8**.
> **Depende de:** Passos 1 a 7, concluídos e validados.

## Objetivo

Implementar a Tela 8 (Devolução de Entrega), acionada pelo botão **"Devolvido"** do card `enviado` na Tela 4. Grava a transição `enviado → devolvido` (`functional.md` §6.2, 3.9). Este é o **último passo do plano** (`prompts-impl/00-plano-geral.md` §4) — ao ser validado, todas as 9 telas do protótipo estarão implementadas.

## Escopo deste Passo

**Incluído:**
- Tela 8 — Devolução de Entrega, completa.
- Botão "Devolvido" do card `enviado` (Tela 4): troca o placeholder "Disponível a partir do Passo 8" pela navegação real.

**Não incluído:** nada — este é o último passo planejado. Eventuais funcionalidades ainda pendentes (ex.: Busca de Pedidos, **P-7**; Finalizar Fluxo de Atendimento, `functional.md` §5.3, sem tela definida no protótipo) ficam fora do escopo de todo o plano atual, não apenas deste passo.

## Tela 8 — Devolução de Entrega

Local: `lib/features/pedido/presentation/devolucao_entrega_screen.dart`. Recebe o `Pedido` a marcar como devolvido (sempre pré-selecionado — só é aberta a partir do card `enviado`).

Campo (`prototype.md` §3.8, `data-structure.md` §3):

| Campo (UI) | Nome técnico | Observações |
|---|---|---|
| Motivo da Devolução | `motivo_devolucao` | Obrigatório. A UI sugere "Não encontrado" e "Devolvido pelo cliente", mas aceita texto livre — implementar como dois atalhos (chips/botões) que preenchem o campo de texto, mantendo-o sempre editável. |

Footer: botões **Confirmar** e **Cancelar**.

| Ação | Comportamento |
|---|---|
| Confirmar, sem motivo preenchido | Não grava; erro de validação inline. |
| Confirmar, com motivo preenchido | Grava o Pedido com `status = devolvido` e `motivo_devolucao` (**FN-1**/**DS-8**: o valor definitivo do enum é `devolvido`). Retorna (`pop`) para a Tela 4. |
| Cancelar | Fecha a tela sem alterar o pedido, retorna (`pop`) para a Tela 4. |

## Tela 4 — Ajuste

Em `pedido_card.dart` / `quadro_atendimento_screen.dart`: botão "Devolvido" do card `enviado` abre `DevolucaoEntregaScreen(pedido: pedido)` via `Navigator.push`; ao retornar, recarregar o quadro (`controller.load()`).

Lembrete (já implementado desde o Passo 3): a coluna `devolvido` exibe os mesmos elementos do card `enviado`, acrescido do Motivo da Devolução, sem footer (estado terminal).

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Card `enviado`, botão "Devolvido": abre a Tela 8.
- [ ] Confirmar sem motivo preenchido: não grava, exibe erro de validação.
- [ ] Tocar em um dos atalhos ("Não encontrado" / "Devolvido pelo cliente"): preenche o campo de texto, mantendo-o editável.
- [ ] Confirmar com um motivo (sugerido ou digitado livremente): o pedido aparece na coluna `devolvido` ao voltar para a Tela 4, exibindo o Motivo da Devolução no card.
- [ ] Botão "Cancelar": retorna à Tela 4 sem alterar o pedido.

## Fora de Escopo deste Passo (e do plano atual)

- Busca de Pedidos (**P-7**).
- Finalizar (fechar) um Fluxo de Atendimento pela UI (`functional.md` §5.3) — sem tela definida no protótipo.
- Edição do `identificador` do Fluxo de Atendimento a partir da Tela 4 (**FN-3**).
- Testes automatizados de UI — não obrigatórios para a validação deste passo.
