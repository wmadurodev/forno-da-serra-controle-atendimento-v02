# Passo 6 — Edição de Pedido em Execução (Tela 9)

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Referências obrigatórias:** `docs/controle-atendimento-prototype.md` §3.9 (Tela 9), §4.3 (card `em_execucao`), **P-6**; `docs/controle-atendimento-functional.md` **FN-4**, §7 (critério de "cadastro completo"), §8; `docs/controle-atendimento-non-functional.md` §5 (armazenamento da imagem).
> **Depende de:** Passos 1 a 5, concluídos e validados.

## Objetivo

Implementar a Tela 9 (Edição de Pedido em Execução), acionada pelo botão **"Editar"** do card `em_execucao` na Tela 4. Permite alterar **todos** os campos editáveis do Pedido — tanto do grupo Cadastro quanto do grupo Execução — sem realizar nenhuma transição de `status` (**FN-4**: os campos de Execução podem ser alterados enquanto o Fluxo de Atendimento permanecer `aberto`, mesmo após `em_execucao`).

## Escopo deste Passo

**Incluído:**
- Tela 9 — Edição de Pedido em Execução, completa.
- Botão "Editar" do card `em_execucao` (Tela 4): troca o placeholder "Disponível a partir do Passo 6" pela navegação real.

**Não incluído (fica para passos seguintes):**
- "Cancelar" (Tela 7) — Passo 7.
- "Devolvido" (Tela 8) — Passo 8.

## Tela 9 — Edição de Pedido em Execução

Local: `lib/features/pedido/presentation/edicao_pedido_execucao_screen.dart`. Recebe o `Pedido` (sempre pré-selecionado, sempre em `em_execucao` — só é aberta a partir do card `em_execucao`). Diferente da Tela 5, **todos os campos abrem imediatamente habilitados e pré-preenchidos** — não há etapa de confirmação de identificador.

Campos (`prototype.md` §3.9):

| Campo (UI) | Nome técnico | Grupo | Observações |
|---|---|---|---|
| Identificador do Pedido | `identificador` | — | Somente leitura. |
| Nome do Cliente | `nome_cliente` | Cadastro | Obrigatório (o pedido já passou por `em_atendimento`, que exige este campo — §7). |
| Tipo de Entrega | `tipo_entrega` | Cadastro | Obrigatório. |
| Tipo de Pagamento | `tipo_pagamento` | Cadastro | Obrigatório. |
| Endereço | `endereco` | Cadastro | Obrigatório somente se `tipo_entrega = delivery`. |
| Observação | `observacao` | Cadastro | Opcional. |
| Mesa | `mesa` | Execução | Obrigatória. |
| Restrições | `restricoes` | Execução | Opcional. |
| Valor Pagamento | `valor_pagamento` | Execução | Opcional. |
| Imagem do Pedido | `imagem_pedido_ref` | Execução | Exibe a imagem atual; botão "Tirar Outra Foto" (opcional) substitui a imagem — mesmo mecanismo de armazenamento da Tela 6 (`ImagemPedidoStorage`, sobrescrevendo o arquivo do pedido). Sem nova captura, mantém a imagem atual. |

Footer: botões **Gravar** e **Fechar**.

| Ação | Comportamento |
|---|---|
| Gravar, campos obrigatórios ausentes | Não grava; erro de validação inline. |
| Gravar, válido | Salva todas as alterações; `status` permanece `em_execucao` (nenhuma transição — **FN-4**). Retorna (`pop`) para a Tela 4. |
| Fechar | Descarta tudo (inclusive uma nova foto tirada e não gravada) e retorna (`pop`) para a Tela 4, sem alterar o pedido. |

## Tela 4 — Ajuste

Em `pedido_card.dart` / `quadro_atendimento_screen.dart`: botão "Editar" do card `em_execucao` abre `EdicaoPedidoExecucaoScreen(pedido: pedido)` via `Navigator.push`; ao retornar, recarregar o quadro (`controller.load()`).

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo Android real.
- [ ] Card `em_execucao`, botão "Editar": abre a Tela 9 com todos os campos já habilitados e pré-preenchidos (incluindo a imagem atual).
- [ ] Alterar um campo de Cadastro (ex.: `nome_cliente`) e Gravar: atualiza o pedido, mantendo `status = em_execucao`, refletido no card ao voltar para a Tela 4.
- [ ] Alterar um campo de Execução (ex.: `mesa`) e Gravar: atualiza o pedido, mantendo `status = em_execucao`.
- [ ] Tirar uma nova foto e Gravar: a miniatura do card é atualizada com a nova imagem.
- [ ] Não tirar nova foto e Gravar: a imagem original permanece inalterada.
- [ ] Limpar um campo obrigatório (ex.: `mesa` ou `nome_cliente`) e tentar Gravar: exibe erro de validação, sem gravar.
- [ ] Botão "Fechar": retorna à Tela 4 sem alterar nada no banco, mesmo que uma nova foto tenha sido tirada.

## Fora de Escopo deste Passo

- Telas 7 e 8 — Passos 7 e 8.
- Testes automatizados de UI — não obrigatórios para a validação deste passo.
