# Passo 4 — Cadastro de Pedido (Tela 5)

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Referências obrigatórias:** `docs/controle-atendimento-prototype.md` §3.5 (Tela 5), §4.1/§4.2 (cards `aguardando_atendimento`/`em_atendimento`), **P-4**; `docs/controle-atendimento-functional.md` §6.2 (transições 3.1/3.2), §7 (critério de "cadastro completo"), regra geral 3.
> **Depende de:** Passos 1 a 3, concluídos e validados.

## Objetivo

Implementar a Tela 5 (Cadastro de Pedido), cobrindo os três pontos de entrada previstos na documentação: botão **"Novo Pedido"** do header da Tela 4 (sem pedido pré-selecionado — fluxo "Novo Pedido"/"Iniciar Pedido" via busca por identificador, **P-4**), botão **"Atendimento"** do card `aguardando_atendimento` (pedido pré-selecionado, fluxo "Iniciar Pedido") e botão **"Editar"** do card `em_atendimento` (pedido pré-selecionado, edição dos dados de Cadastro).

## Escopo deste Passo

**Incluído:**
- `PedidoRepository`: novos métodos `buscarPorIdentificador` e `salvar` (upsert), com a mesma guarda de fluxo `aberto` já usada em `excluir`/`atualizarStatus`.
- Tela 5 — Cadastro de Pedido, completa, cobrindo os 3 pontos de entrada acima.
- Tela 4: troca dos placeholders "Disponível a partir do Passo 4" por navegação real, nos três pontos:
  - Header "Novo Pedido".
  - Card `aguardando_atendimento`, botão "Atendimento".
  - Card `em_atendimento`, botão "Editar".
- Recarregar o quadro (Tela 4) ao voltar da Tela 5, refletindo o pedido criado/alterado.

**Não incluído (fica para passos seguintes):**
- Botão "Excluir" — já implementado no Passo 3, sem mudanças.
- "Executar" (Tela 6) — Passo 5.
- "Editar" do card `em_execucao` (Tela 9) — Passo 6.
- "Cancelar" (Tela 7) — Passo 7.
- "Devolvido" (Tela 8) — Passo 8.

## Decisões de Implementação (não explícitas na documentação de origem)

Os documentos de origem deixam duas lacunas de UI/comportamento para a Tela 5; decisões adotadas para viabilizar a implementação:

1. **Ação que dispara a busca por identificador** (`prototype.md` §3.5, passo 2 — "o usuário informa o Identificador e confirma"): o footer só define **Gravar**/**Fechar**, sem um terceiro botão para essa confirmação inicial. Adotado: um botão **"Confirmar"** inline, ao lado do campo Identificador, visível apenas enquanto os demais campos estão desabilitados. Ao confirmar, o campo Identificador passa a somente leitura (chave do Pedido) e os demais campos são habilitados (pré-preenchidos ou em branco, conforme a busca).
2. **Pedido com dados de Cadastro parcialmente preenchidos, mas não completos** (`functional.md` §7): a documentação só cobre os extremos ("só identificador" → `aguardando_atendimento`; "cadastro completo" → `em_atendimento`). Adotado: os dados digitados são sempre gravados como informados; o `status` resultante é `em_atendimento` **somente se** o critério de "cadastro completo" (§7) for satisfeito, senão permanece/retorna `aguardando_atendimento` — exceto se o pedido, ao ser aberto na tela, já estava em um `status` posterior a `aguardando_atendimento` (ex.: reaberto para edição a partir do card `em_atendimento`), caso em que o `status` **nunca regride** (**FN-8**): a Tela 5 então só atualiza os campos de Cadastro, preservando o `status` atual do pedido.

## `PedidoRepository` — Novos Métodos

```dart
Future<Pedido?> buscarPorIdentificador(String fluxoAtendimentoId, String identificador);
Future<void> salvar(Pedido pedido); // insert ou update (upsert pela chave `identificador`)
```

Ambos aplicam a mesma guarda de "Fluxo de Atendimento aberto" já usada em `excluir`/`atualizarStatus`.

## Tela 5 — Cadastro de Pedido

Local: `lib/features/pedido/presentation/cadastro_pedido_screen.dart`.

Parâmetros do widget:
- `fluxoAtendimentoId` (sempre — o fluxo aberto corrente).
- `pedidoExistente` (opcional): quando fornecido (entradas "Atendimento" e "Editar" da Tela 4), a tela abre diretamente no modo "campos habilitados e pré-preenchidos", pulando a etapa de busca por identificador.

Campos (`prototype.md` §3.5, `data-structure.md` §3):

| Campo (UI) | Nome técnico | Observações |
|---|---|---|
| Identificador do Pedido | `identificador` | Único campo habilitado antes da confirmação (ver decisão 1 acima); somente leitura depois. |
| Nome do Cliente | `nome_cliente` | Texto livre. |
| Tipo de Entrega | `tipo_entrega` | Seleção `delivery` / `retirada_balcao`, sem valor pré-selecionado. |
| Tipo de Pagamento | `tipo_pagamento` | Seleção `pix` / `cartao` / `dinheiro`, sem valor pré-selecionado. |
| Endereço | `endereco` | Exibido apenas quando `tipo_entrega = delivery` (**DS-4**). |
| Observação | `observacao` | Opcional. |

Comportamento:

| Situação | Comportamento |
|---|---|
| Tela aberta com `pedidoExistente` | Identificador somente leitura, demais campos habilitados e pré-preenchidos com os dados do pedido. |
| Tela aberta sem `pedidoExistente` (a partir do header) | Apenas Identificador habilitado; demais campos desabilitados até a confirmação. |
| Confirmar Identificador (sem `pedidoExistente`), identificador já existe no fluxo atual | Busca o pedido (`buscarPorIdentificador`); pré-preenche e habilita os demais campos com os dados encontrados; Identificador passa a somente leitura (**P-4**, fluxo "Iniciar Pedido"). |
| Confirmar Identificador (sem `pedidoExistente`), identificador não existe no fluxo atual | Habilita os demais campos em branco; Identificador passa a somente leitura (fluxo "Novo Pedido"). |
| Confirmar Identificador, campo vazio | Não avança; erro de validação inline. |
| Gravar | Calcula "cadastro completo" (`functional.md` §7: `nome_cliente` + `tipo_entrega` + `tipo_pagamento` preenchidos, e `endereco` preenchido se `tipo_entrega = delivery`). Monta o Pedido (novo ou a partir do encontrado/`pedidoExistente`, preservando os demais campos — Execução, Cancelamento, Devolução — inalterados) com o `status` conforme a decisão de implementação 2 acima. Chama `salvar` e retorna (`pop`) para a Tela 4. |
| Fechar | Descarta tudo e retorna (`pop`) para a Tela 4, sem gravar. |

## Tela 4 — Ajustes

Em `pedido_card.dart` e `quadro_atendimento_screen.dart`:
- Botão "Atendimento" (`aguardando_atendimento`) e "Editar" (`em_atendimento`): abrem `CadastroPedidoScreen(fluxoAtendimentoId: pedido.fluxoAtendimentoId, pedidoExistente: pedido)` via `Navigator.push`; ao retornar, recarregar o quadro (`controller.load()`).
- Botão "Novo Pedido" do header: abre `CadastroPedidoScreen(fluxoAtendimentoId: fluxo.identificador)` (sem `pedidoExistente`); ao retornar, recarregar o quadro.

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Header "Novo Pedido" abre a Tela 5 com apenas o campo Identificador habilitado.
- [ ] Confirmar um identificador novo (sem pedido correspondente no fluxo aberto): habilita os demais campos em branco.
- [ ] Preencher só o Identificador e Gravar: cria um pedido em `aguardando_atendimento`, visível na coluna correspondente ao voltar para a Tela 4.
- [ ] Preencher Identificador + todos os campos de Cadastro (incluindo Endereço, se `delivery`) e Gravar: cria um pedido em `em_atendimento`, visível na coluna correta.
- [ ] Card `aguardando_atendimento`, botão "Atendimento": abre a Tela 5 já com os campos habilitados (Identificador somente leitura); completar o cadastro e Gravar promove o pedido para `em_atendimento`.
- [ ] Card `em_atendimento`, botão "Editar": abre a Tela 5 com os dados atuais pré-preenchidos; alterar um campo e Gravar atualiza o pedido, mantendo `status = em_atendimento` (mesmo que, hipoteticamente, os campos fiquem incompletos após a edição — sem retrocesso, **FN-8**).
- [ ] Botão "Fechar" em qualquer um dos fluxos acima: retorna à Tela 4 sem alterar nada no banco.
- [ ] Confirmar Identificador com o campo vazio: exibe erro de validação, sem avançar.

## Fora de Escopo deste Passo

- Telas 6, 7, 8, 9 — Passos 5 a 8.
- Testes automatizados de UI — não obrigatórios para a validação deste passo.
