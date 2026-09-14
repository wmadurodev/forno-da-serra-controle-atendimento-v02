# Passo 3 — Execução do Fluxo de Atendimento (Tela 4, Quadro Kanban)

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Referências obrigatórias:** `docs/controle-atendimento-prototype.md` §3.4 (Tela 4), §4 (cards por coluna), §5 (regras transversais de UI); `docs/controle-atendimento-functional.md` regras gerais 1–3, §6 (máquina de estados do Pedido); `docs/controle-atendimento-data-structure.md` §3 (entidade Pedido), §4.2–4.4 (enumerações).
> **Depende de:** Passos 1 e 2, concluídos e validados.

## Objetivo

Substituir a Tela 4 placeholder do Passo 1 pela Tela 4 real: quadro Kanban com uma coluna por `status` de Pedido, exibindo os cards com os campos corretos por coluna (`prototype.md` §4). Como a criação de Pedidos (Tela 5) só é implementada no Passo 4, o quadro nasce vazio no uso normal — a validação deste passo depende de inserir `pedido`s manualmente no banco (mesmo mecanismo já usado para validar o Passo 1: teste automatizado do repositório ou inserção direta no arquivo do banco).

## Escopo deste Passo

**Incluído:**
- Entidade `Pedido` (domínio) e `PedidoRepository` (dados), cobrindo leitura, exclusão e atualização simples de `status`.
- Tela 4 real, substituindo `FluxoAtendimentoPlaceholderScreen` (removida): header, quadro Kanban com as 7 colunas de `status` (`data-structure.md` §4.2), cards com os campos e o rótulo "cancelado" por coluna (`prototype.md` §4).
- Ações de card **que não dependem de telas ainda não implementadas** (Passos 4 a 8), implementadas de verdade:
  - **Excluir** (coluna `aguardando_atendimento`): diálogo de confirmação nativo + hard delete (`functional.md` **FN-6**).
  - **Retirado** (coluna `em_execucao`, `tipo_entrega = retirada_balcao`): `status → retirado_no_balcao`.
  - **Enviado** (coluna `em_execucao`, `tipo_entrega = delivery`): `status → enviado`.
  - **Entregue** (coluna `enviado`): `status → entregue`.
- Ações de card **que abrem uma tela de um passo futuro**: mantidas visíveis (para não alterar o layout do footer nos passos seguintes), mas com um `SnackBar` "Disponível a partir do Passo N" no lugar da navegação real (mesmo padrão do botão "Novo Fluxo" no Passo 1):
  - **Atendimento** e **Editar** (coluna `em_atendimento`, abrem a Tela 5) → "Disponível a partir do Passo 4".
  - **Executar** (coluna `em_atendimento`, abre a Tela 6) → "Disponível a partir do Passo 5".
  - **Editar** (coluna `em_execucao`, abre a Tela 9) → "Disponível a partir do Passo 6".
  - **Cancelar** (colunas `em_atendimento` e `em_execucao`, abre a Tela 7) → "Disponível a partir do Passo 7".
  - **Devolvido** (coluna `enviado`, abre a Tela 8) → "Disponível a partir do Passo 8".
- Botão **"Novo Pedido"** no header: mantido visível, com `SnackBar` "Disponível a partir do Passo 4" (abre a Tela 5 — Passo 4).
- Botão **"Busca de Pedidos"** no header: mantido visível, com `SnackBar` "Funcionalidade não implementada nesta fase" (**P-7** — não está previsto para nenhum passo do plano atual, diferente dos itens acima).
- Modo somente leitura quando `fluxo.status == fechado` (`functional.md` regra geral 2, `prototype.md` §5): nenhum botão de ação é exibido em nenhum card, e o botão "Novo Pedido" some do header. "Busca de Pedidos" permanece (é uma consulta, não uma escrita).

**Não incluído (fica para passos seguintes):**
- Telas 5, 6, 7, 8, 9 propriamente ditas — Passos 4 a 8.
- Edição do `identificador` do Fluxo de Atendimento a partir da Tela 4 (**FN-3**) — o prototype não define onde esse controle apareceria na Tela 4; adiado até haver definição de UI.
- Busca de Pedidos funcional (**P-7**) — fora do escopo de todo o plano atual, não só deste passo.

## Modelo de Dados (novo)

Nova feature `lib/features/pedido/`:

```
lib/features/pedido/
  domain/
    pedido.dart   # enums PedidoStatus, TipoEntrega, TipoPagamento + classe Pedido
  data/
    pedido_repository.dart
```

`Pedido` espelha as colunas da tabela `pedido` (`docs/controle-atendimento-non-functional.md` §4, já criada no Passo 1): `identificador`, `fluxo_atendimento_id`, `status`, `cancelado`, `nome_cliente`, `tipo_entrega`, `tipo_pagamento`, `endereco`, `observacao`, `restricoes`, `valor_pagamento`, `mesa`, `imagem_pedido_ref`, `motivo_cancelamento`, `motivo_devolucao`.

`PedidoRepository`:
- `listByFluxo(fluxoAtendimentoId)`: todos os pedidos do fluxo, ordenados por `identificador` ascendente (ordem de chegada — decisão de implementação deste passo, não especificada nos documentos de origem).
- `excluir(pedido)`: hard delete.
- `atualizarStatus(pedido, novoStatus)`: `UPDATE` do `status`.

Ambas as operações de escrita devem, antes de executar, verificar que o Fluxo de Atendimento associado está `aberto` (regra geral 3 — toda escrita em Pedido exige fluxo `aberto`), lançando `StateError` caso contrário — mesmo padrão de guarda de regra de negócio já usado em `FluxoAtendimentoRepository.insert` no Passo 1.

Registrar `Provider<PedidoRepository>` em `main.dart`, ao lado do `Provider<FluxoAtendimentoRepository>` já existente.

## Tela 4 — Quadro de Atendimento

Local: `lib/features/fluxo_atendimento/presentation/quadro_atendimento_screen.dart` (substitui e remove `fluxo_atendimento_placeholder_screen.dart`; atualizar as referências em `splash_screen.dart`, `home_screen.dart` e `cadastro_fluxo_screen.dart`).

**Header (`AppBar`):**
- Título: `fluxo.identificador`.
- Ações: botão "Novo Pedido" (oculto se `fluxo.status == fechado`) e botão "Busca de Pedidos", conforme comportamento descrito acima.

**Corpo:** quadro Kanban com rolagem horizontal, uma coluna por valor de `PedidoStatus`, nesta ordem (`data-structure.md` §4.2): `aguardando_atendimento` → `em_atendimento` → `em_execucao` → `retirado_no_balcao` → `enviado` → `entregue` → `devolvido`. Cada coluna tem rolagem vertical independente e exibe os pedidos daquele `status` como cards.

**Cards** (`prototype.md` §4, regras transversais):
- `cancelado = true`: exibir rótulo "cancelado" em vermelho; ocultar todo o footer de ações do card (independente da coluna).
- `endereco` exibido apenas quando `tipo_entrega = delivery`.
- Campos por coluna e botões de footer: exatamente conforme `prototype.md` §4.1 a §4.7 (colunas `retirado_no_balcao`, `entregue` e `devolvido` são terminais — sem footer).
- Se `fluxo.status == fechado`: nenhum footer de ação em nenhum card (independentemente de `cancelado`).

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Com um `fluxo_atendimento` aberto sem nenhum `pedido`: as 7 colunas aparecem vazias, com rolagem horizontal funcionando.
- [ ] Inserindo manualmente (via teste do repositório ou diretamente no banco) um `pedido` para cada `status`, associados ao fluxo aberto: cada card aparece na coluna correta, com os campos definidos em `prototype.md` §4 para aquele `status`.
- [ ] Um `pedido` com `cancelado = true`: exibe o rótulo "cancelado" em vermelho e nenhum botão de footer, na coluna do seu `status` atual.
- [ ] Um `pedido` com `tipo_entrega = retirada_balcao` não exibe `endereco`, mesmo que o campo esteja preenchido no banco; um com `tipo_entrega = delivery` exibe.
- [ ] Botão "Excluir" no card `aguardando_atendimento`: pede confirmação e, ao confirmar, remove o pedido do quadro e do banco.
- [ ] Botões "Retirado"/"Enviado" (conforme `tipo_entrega`) no card `em_execucao`: movem o pedido para a coluna correta.
- [ ] Botão "Entregue" no card `enviado`: move o pedido para a coluna `entregue`.
- [ ] Botões que abrem telas futuras (Atendimento, Editar, Executar, Cancelar, Devolvido) e o botão "Novo Pedido": exibem o `SnackBar` "Disponível a partir do Passo N" correspondente, sem navegar nem quebrar o app.
- [ ] Botão "Busca de Pedidos": exibe `SnackBar` de funcionalidade não implementada.
- [ ] Com o `fluxo_atendimento` `fechado`: nenhum card exibe botões de ação, e o botão "Novo Pedido" não aparece no header.

## Fora de Escopo deste Passo

- Telas 5 a 9 — Passos 4 a 8.
- Edição do `identificador` do Fluxo de Atendimento (**FN-3**) a partir da Tela 4.
- Busca de Pedidos funcional (**P-7**).
- Testes automatizados de UI — não obrigatórios para a validação deste passo.
