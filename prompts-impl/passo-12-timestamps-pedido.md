# Passo 12 — Data/Hora de cada mudança de estado do Pedido

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-14. Sem correspondência prévia em `docs/controle-atendimento-functional.md`, `docs/controle-atendimento-data-structure.md` ou `docs/controle-atendimento-prototype.md` — os novos campos e as regras de preenchimento são definidos neste prompt.
> **Depende de:** Passos 1–9 (todas as telas/transições de Pedido já implementadas). Não depende do Passo 10 nem 11, mas convive com eles (ambos mexem em telas diferentes).

## Objetivo

Registrar a data/hora exata em que cada Pedido atingiu cada estado da sua máquina de estados, e a data/hora do cancelamento (evento independente do `status`, ver `functional.md` §6.1 e `data-structure.md` §3, atributo `cancelado`). Exibir essa informação nos cards do quadro Kanban (Tela 4): identificador seguido do horário da mudança de estado mais recente, e — no caso de pedido cancelado — o horário do cancelamento e o motivo.

## 1. Novas colunas em `pedido`

Oito novas colunas `TEXT` (ISO 8601, nulas até o evento ocorrer), uma por evento:

| Coluna | Evento |
|---|---|
| `data_hora_aguardando_atendimento` | Pedido criado (linha inserida pela primeira vez — independe de o pedido já nascer em `em_atendimento` quando o cadastro é preenchido completo na primeira gravação). |
| `data_hora_em_atendimento` | Status alcançou `em_atendimento`. |
| `data_hora_em_execucao` | Status alcançou `em_execucao`. |
| `data_hora_retirado_no_balcao` | Status alcançou `retirado_no_balcao`. |
| `data_hora_enviado` | Status alcançou `enviado`. |
| `data_hora_entregue` | Status alcançou `entregue`. |
| `data_hora_devolvido` | Status alcançou `devolvido`. |
| `data_hora_cancelamento` | Pedido cancelado (`cancelado: false → true`). |

**Migração (`AppDatabase`):** sobe `version` de `2` para `3` (Passo 11 introduziu a `2`). `onCreate` já cria `pedido` com as 8 colunas. `onUpgrade` (`oldVersion < 3`): 8x `ALTER TABLE pedido ADD COLUMN <coluna> TEXT` (todas nulas por padrão — pedidos já existentes ficam sem histórico anterior, o que é aceitável, não há como reconstruir retroativamente).

**Domínio (`Pedido`):** 8 novos campos `final DateTime? dataHoraX`. `fromMap`: `DateTime.tryParse(map['coluna'] as String? ?? '')` (ou helper equivalente que retorna `null` para string vazia/ausente). `toMap`: `dataHoraX?.toIso8601String()`.

Novo getter de conveniência:
```dart
DateTime? get dataHoraStatusAtual => switch (status) {
  PedidoStatus.aguardandoAtendimento => dataHoraAguardandoAtendimento,
  PedidoStatus.emAtendimento => dataHoraEmAtendimento,
  PedidoStatus.emExecucao => dataHoraEmExecucao,
  PedidoStatus.retiradoNoBalcao => dataHoraRetiradoNoBalcao,
  PedidoStatus.enviado => dataHoraEnviado,
  PedidoStatus.entregue => dataHoraEntregue,
  PedidoStatus.devolvido => dataHoraDevolvido,
};
```

## 2. Regra geral de preenchimento — **ATENÇÃO ao padrão de escrita já existente**

`PedidoRepository.salvar()` usa `db.insert(..., conflictAlgorithm: ConflictAlgorithm.replace)` — substitui a linha inteira. Todo `_onGravar`/`_onConfirmar` das telas de Pedido já reconstrói um `Pedido(...)` completo copiando cada campo do pedido base (ver `cadastro_pedido_screen.dart`, `execucao_pedido_screen.dart`, `edicao_pedido_execucao_screen.dart`, `cancelamento_pedido_screen.dart`, `devolucao_entrega_screen.dart`). **As 8 novas colunas seguem o mesmo padrão: se um desses pontos de gravação não incluir explicitamente um dos 8 campos no novo `Pedido(...)`, o valor é perdido (vira `null`) na gravação.** Cada carimbo só é gravado **uma vez** — na transição de entrada daquele estado — e preservado em todas as gravações posteriores. Padrão a aplicar em cada campo, em cada tela: `base.dataHoraX` (preservar) quando já preenchido, ou `DateTime.now()` apenas no momento exato em que aquele estado é alcançado pela primeira vez.

`PedidoRepository.atualizarStatus()` já faz `db.update` parcial (só a coluna `status`) — não sofre desse risco; basta acrescentar a coluna de carimbo correspondente ao `Map` do `update`.

## 3. Pontos de gravação — o que mudar em cada arquivo

### `PedidoRepository.atualizarStatus` (`data/pedido_repository.dart`)

Usado para as transições `em_execucao → retirado_no_balcao`, `em_execucao → enviado`, `enviado → entregue` (chamado por `QuadroAtendimentoController.atualizarStatus`, a partir de `PedidoCard.onRetirado/onEnviado/onEntregue`). Adicionar ao `Map` do `update` a coluna correspondente ao `novoStatus` com `DateTime.now().toIso8601String()` (mapa `PedidoStatus → nome da coluna`, cobrindo pelo menos `retiradoNoBalcao`, `enviado`, `entregue`).

### `CadastroPedidoScreen._onGravar` (Tela 5 — criação e edição de Cadastro)

- `dataHoraAguardandoAtendimento`: `base?.dataHoraAguardandoAtendimento ?? DateTime.now()` (marca a criação da linha, mesmo se o `novoStatus` calculado já for `em_atendimento` na primeira gravação).
- `dataHoraEmAtendimento`: `base?.dataHoraEmAtendimento ?? (novoStatus == PedidoStatus.emAtendimento ? DateTime.now() : null)`.
- Demais 6 campos: `base?.dataHoraX` (preservar; nesta tela nunca são alcançados diretamente, mas precisam ser copiados do `base` para não se perderem quando esta tela é usada para editar um pedido — via botão "Editar" do card `em_atendimento` — que já tenha, por exemplo, `dataHoraCancelamento` preenchido de um cancelamento anterior... **exceto** que cancelamento é feito por tela própria; copiar por segurança/robustez de qualquer forma).

### `ExecucaoPedidoScreen._onGravar` (Tela 6)

- `dataHoraEmExecucao`: `widget.pedido.dataHoraEmExecucao ?? DateTime.now()`.
- Demais 7 campos: `widget.pedido.dataHoraX` (preservar).

### `EdicaoPedidoExecucaoScreen._onGravar` (Tela 9 — não muda `status`, Passo 6)

- Todos os 8 campos: `widget.pedido.dataHoraX` (preservar sem exceção — esta tela nunca altera `status` nem `cancelado`).

### `CancelamentoPedidoScreen._onConfirmar` (Tela 7)

- `dataHoraCancelamento`: `pedidoOriginal.dataHoraCancelamento ?? DateTime.now()`.
- Demais 7 campos: `pedidoOriginal.dataHoraX` (preservar).

### `DevolucaoEntregaScreen._onConfirmar` (Tela 8)

- `dataHoraDevolvido`: `pedidoOriginal.dataHoraDevolvido ?? DateTime.now()`.
- Demais 7 campos: `pedidoOriginal.dataHoraX` (preservar).

## 4. UI — `PedidoCard` (`lib/features/fluxo_atendimento/presentation/pedido_card.dart`)

**Título do card:** identificador seguido do horário (`HH:mm`, hora local do dispositivo) da mudança para o estado atual — `pedido.dataHoraStatusAtual`. Formato: `"$identificador (HH:mm)"`. Se por algum motivo o carimbo daquele estado ainda for `null` (não deveria acontecer para pedidos criados após este passo), omitir o sufixo — sem quebrar a tela.

Exemplo do enunciado: pedido `8979` criado em `aguardando_atendimento` às 13:23 → título `8979 (13:23)`; ao passar para `em_atendimento` às 14:12 → título no card da coluna `em_atendimento` passa a `8979 (14:12)`.

**Pedido cancelado:** substituir o texto fixo `'cancelado'` (linha atual, vermelho e negrito) por:
- Uma linha `"Cancelado (HH:mm)"` usando `pedido.dataHoraCancelamento`, no mesmo estilo (vermelho, negrito).
- Uma linha abaixo com o motivo (`pedido.motivoCancelamento`), se preenchido.
- Cor de fundo do `Card` diferenciada quando `pedido.cancelado` (ex.: `Colors.red.shade50`), para distinguir visualmente de pedidos não cancelados — análogo à cor diferenciada de fluxo fechado do Passo 11.

O título do card (identificador + horário do estado atual) continua sendo exibido normalmente mesmo quando o pedido está cancelado — o bloco "Cancelado (HH:mm)" + motivo é adicional, exibido logo abaixo do título, como já ocorre hoje com o texto `'cancelado'`.

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Banco existente (versão 2) migra sem perda de dados; pedidos preexistentes continuam visíveis, com os novos campos nulos (sem horário retroativo).
- [ ] Criar um pedido novo e avançá-lo por todos os estados (`aguardando_atendimento` → `em_atendimento` → `em_execucao` → `retirado_no_balcao` ou `enviado` → `entregue`/`devolvido`): cada card, na coluna correspondente, mostra `identificador (HH:mm)` com o horário correto daquela transição — não o horário da criação repetido em todas as colunas.
- [ ] Editar um pedido já em `em_atendimento` (botão "Editar" do card) ou em `em_execucao` (Tela 9) não altera o horário já registrado para aquele estado.
- [ ] Cancelar um pedido: card mostra "Cancelado (HH:mm)" com o horário do cancelamento e o motivo informado (se houver), com o fundo do card diferenciado.
- [ ] Horários mostrados usam o fuso horário local do dispositivo.

## Fora de Escopo deste Passo

- Reconstruir/estimar horários de pedidos criados antes deste passo — ficam com os novos campos nulos.
- Exibir os 8 carimbos de uma vez em algum relatório/histórico consolidado — apenas o horário do estado atual (e do cancelamento, se aplicável) aparece no card, conforme pedido pelo usuário.
- Editar manualmente esses horários pela UI.
