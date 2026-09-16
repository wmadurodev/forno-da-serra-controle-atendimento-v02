# Passo 42 — Navegar até a coluna do novo status após incluir/alterar um Pedido

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-16. Sem correspondência em `docs/`.
> **Depende de:** Passo 25 (`ScrollController`/`_rolarParaFase`), Passo 28 (`_indiceFaseVisivel`), Passo 39 (restauração de rolagem pós-`load()`).

## Objetivo

Na Tela 4 (Execução do Fluxo de Atendimento — Kanban), sempre que a ação do usuário resultar em um Pedido **novo** ou em uma **mudança de status** de um Pedido existente, o Kanban deve rolar automaticamente até a coluna do status resultante — em vez de restaurar a coluna que estava visível antes da ação (comportamento do Passo 39, que continua valendo quando o status **não** muda).

Exemplos do pedido do usuário:
- Usuário vendo a coluna "Retirado no Balcão" (ou qualquer outra) e inclui um Pedido novo → Kanban rola até "Aguardando Atendimento" ou "Em Atendimento", conforme o status com que o Pedido novo foi efetivamente gravado.
- Usuário em qualquer coluna e leva um Pedido a "Em Execução", "Enviado" etc. → Kanban rola até a coluna do novo status.

## Levantamento

Ações que podem mudar o status de um Pedido (ou criar um novo), todas seguidas de `controller.load()`:

1. **`_abrirCadastroPedido`** (`CadastroPedidoScreen`, Tela 5) — cobre os 3 pontos de entrada (header/footer "Novo Pedido", card "Atendimento", card "Editar"). `_onGravar` já calcula um único `novoStatus` local cobrindo todos os casos (Passo 22/18): pedido novo ou ainda `aguardando_atendimento` → `em_atendimento` se `cadastroCompleto`, senão continua `aguardando_atendimento`; pedido já além de `aguardando_atendimento` (via "Editar") → mantém `base.status` (FN-8, status nunca regride). Hoje a tela sempre fecha com `Navigator.of(context).pop()` (sem valor) ao gravar com sucesso.
2. **`_abrirExecucaoPedido`** (`ExecucaoPedidoScreen`, Tela 6) — sempre grava com `status: PedidoStatus.emExecucao`. Fecha com `Navigator.of(context).pop()` (sem valor) ao gravar.
3. **`_abrirDevolucao`** (`DevolucaoEntregaScreen`, Tela 8) — sempre grava com `status: PedidoStatus.devolvido`. Fecha com `Navigator.of(context).pop()` (sem valor) ao confirmar.
4. **`_abrirEdicaoExecucao`** (Tela 9) e **`_abrirCancelamento`** (Tela 7) — **não** mudam o status do Pedido (edição em Tela 9 preserva tudo; cancelamento só marca `cancelado=true`). Continuam usando a restauração do Passo 39 sem alteração — como o status não muda, a coluna visível antes e depois é a mesma.
5. Ações rápidas do card (`_KanbanColuna`, botões "Retirado"/"Enviado"/"Entregue", Passo 24) — chamam `controller.atualizarStatus(pedido, novoStatus)` diretamente, com o `novoStatus` já conhecido em cada call site (`PedidoStatus.retiradoNoBalcao`/`.enviado`/`.entregue`), sem passar por nenhuma tela nova.
6. Exclusão de Pedido (`onExcluir`) — remove o Pedido, não há coluna de destino; sem mudança neste passo (mantém restauração do Passo 39).

**Correção proposta:**
- Nas 3 telas que hoje fecham com `pop()` sem valor após um `novoStatus` conhecido (Cadastro, Execução, Devolução), passar a fechar com `pop(novoStatus)` no caminho de sucesso — "Fechar"/"Cancelar" continuam com `pop()` sem valor.
- Em `_QuadroViewState`, novo campo `PedidoStatus? _statusAlvoAposRecarga`. Os 3 `_abrirXxx` correspondentes capturam o valor retornado pelo `Navigator.push` e, se não-nulo, atribuem a `_statusAlvoAposRecarga` antes de chamar `controller.load()`.
- Para as ações rápidas do card, novo callback `onAtualizarStatus` passado de `_QuadroViewState` para `_KanbanColuna` (substituindo as chamadas diretas a `controller.atualizarStatus(...)`), que grava `_statusAlvoAposRecarga = novoStatus` antes de delegar para `controller.atualizarStatus`.
- `_restaurarPosicaoScroll` (Passo 39) passa a dar prioridade a `_statusAlvoAposRecarga` quando presente (rolagem **animada**, mesma sensação de `_rolarParaFase`/toque no footer — é uma navegação visível, não uma restauração silenciosa), consumindo-o (`= null`) em seguida; sem ele, cai de volta no comportamento atual (`jumpTo` para `_indiceFaseVisivel`).

## Alterações

### `cadastro_pedido_screen.dart`

Em `_onGravar`, após `await repository.salvar(pedido);`:
```dart
if (!mounted) return;
Navigator.of(context).pop(novoStatus);
```
(`novoStatus` já existe como variável local no método — nenhum cálculo novo necessário.)

### `execucao_pedido_screen.dart`

Em `_onGravar`, após `await repository.salvar(pedido);`:
```dart
if (!mounted) return;
Navigator.of(context).pop(PedidoStatus.emExecucao);
```

### `devolucao_entrega_screen.dart`

Em `_onConfirmar`, após `await repository.salvar(pedido);`:
```dart
if (!mounted) return;
Navigator.of(context).pop(PedidoStatus.devolvido);
```

### `quadro_atendimento_screen.dart`

Em `_QuadroViewState`:
```dart
PedidoStatus? _statusAlvoAposRecarga;

void _restaurarPosicaoScroll() {
  if (!_scrollController.hasClients) return;
  final statusAlvo = _statusAlvoAposRecarga;
  _statusAlvoAposRecarga = null;
  final maximo = _scrollController.position.maxScrollExtent;
  if (statusAlvo != null) {
    final indice = PedidoStatus.values.indexOf(statusAlvo);
    final offsetAlvo = _paddingInicial + indice * (_larguraColuna + _espacamento);
    _scrollController.animateTo(
      offsetAlvo.clamp(0.0, maximo),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    return;
  }
  final offsetAlvo = _paddingInicial + _indiceFaseVisivel * (_larguraColuna + _espacamento);
  _scrollController.jumpTo(offsetAlvo.clamp(0.0, maximo));
}
```

`_abrirCadastroPedido`, `_abrirExecucaoPedido`, `_abrirDevolucao` capturam o retorno tipado do `push`:
```dart
Future<void> _abrirCadastroPedido(
  BuildContext context,
  QuadroAtendimentoController controller, {
  Pedido? pedidoExistente,
}) async {
  final novoStatus = await Navigator.of(context).push<PedidoStatus>(
    MaterialPageRoute(
      builder: (_) => CadastroPedidoScreen(
        fluxoAtendimentoId: fluxo.identificador,
        pedidoExistente: pedidoExistente,
      ),
    ),
  );
  if (novoStatus != null) _statusAlvoAposRecarga = novoStatus;
  await controller.load();
}
```
(mesmo padrão para `_abrirExecucaoPedido`/`ExecucaoPedidoScreen` e `_abrirDevolucao`/`DevolucaoEntregaScreen`). `_abrirEdicaoExecucao` e `_abrirCancelamento` **não** mudam — continuam sem capturar retorno.

Novo helper, delegando para o controller e marcando o alvo de navegação:
```dart
Future<void> _atualizarStatusENavegar(
  QuadroAtendimentoController controller,
  Pedido pedido,
  PedidoStatus novoStatus,
) {
  _statusAlvoAposRecarga = novoStatus;
  return controller.atualizarStatus(pedido, novoStatus);
}
```

`_buildQuadro` passa esse helper para `_KanbanColuna` como novo parâmetro `onAtualizarStatus: (pedido, status) => _atualizarStatusENavegar(controller, pedido, status)`.

Em `_KanbanColuna`: novo campo `onAtualizarStatus`; as 3 chamadas diretas trocam de `controller.atualizarStatus(pedido, PedidoStatus.X)` para `onAtualizarStatus(pedido, PedidoStatus.X)`, mantendo o mesmo `_executar` (try/catch de `StateError`) ao redor. `onExcluir` não muda (continua usando `controller.excluir(pedido)` diretamente — exclusão não tem coluna de destino).

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Visualizando a coluna "Retirado no Balcão" (ou qualquer outra que não seja a primeira), tocar "Novo Pedido" e gravar um Pedido incompleto (sem todos os campos obrigatórios) → Kanban rola até "Aguardando Atendimento".
- [ ] Mesmo teste, mas preenchendo todos os campos obrigatórios (cadastro completo) → Kanban rola até "Em Atendimento".
- [ ] A partir de um card `aguardando_atendimento`, tocar "Atender" e gravar com cadastro completo → Kanban rola até "Em Atendimento".
- [ ] A partir de um card `em_atendimento`, tocar "Executar" e gravar → Kanban rola até "Em Execução".
- [ ] A partir de um card `enviado`, tocar "Devolvido" e confirmar → Kanban rola até "Devolvido".
- [ ] Ações rápidas do card ("Retirado", "Enviar", "Entregue") continuam levando o Kanban até a coluna do novo status.
- [ ] Editar um card `em_atendimento` via "Editar" (Tela 5) sem mudar de status, ou editar via Tela 9, ou cancelar um Pedido (Tela 7) → Kanban permanece na coluna que já estava visível (comportamento do Passo 39, sem regressão).
- [ ] Excluir um Pedido continua restaurando a coluna anterior (Passo 39), sem mudança neste passo.
- [ ] Destaque do navegador de fases do footer (Passo 28) acompanha corretamente a nova coluna depois da rolagem automatizada.
- [ ] Botões "Fechar"/"Cancelar" das 3 telas alteradas continuam fechando sem gravar e sem disparar a navegação automática (o Kanban restaura a coluna anterior, como hoje).

## Fora de Escopo deste Passo

- Mudar a lógica de cálculo de `novoStatus` em `CadastroPedidoScreen` (Passo 18/22) — só passa a ser retornado pela tela, sem alteração de valor.
- Navegar automaticamente em exclusão de Pedido ou em telas que não mudam status (Tela 9, Cancelamento).
- Persistir a coluna alvo entre sessões do app.
