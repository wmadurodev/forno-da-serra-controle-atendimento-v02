# Passo 13 — Melhorias na Execução do Fluxo de Atendimento (Tela 4)

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-14. Sem correspondência prévia em `docs/controle-atendimento-functional.md`, `docs/controle-atendimento-data-structure.md` ou `docs/controle-atendimento-prototype.md` — as decisões de UI são definidas neste prompt.
> **Depende de:** Passo 3 (quadro Kanban), Passo 9 (botão "Sair" no header), Passo 12 (`dataHoraStatusAtual`, usado para a nova ordenação). Não depende dos Passos 10/11 (Home) nem os afeta.

## Objetivo

Cinco melhorias na Tela 4 (Execução do Fluxo de Atendimento), listadas pelo usuário:

1. Remover o ícone de voltar do header.
2. Background em degradê por coluna do Kanban, para diferenciar visualmente cada estágio.
3. Botões do header mais estilizados, mantendo os ícones atuais.
4. Ordenar os cards de cada coluna em ordem decrescente de data/hora (mais recente no topo).
5. Novo botão no header para filtrar a visualização por cancelamento (Todos / Somente Cancelados / Somente Não Cancelados), com indicação visual quando o filtro não é "Todos".

## 1. Remover o botão de voltar do header

Em `_QuadroView.build` (`quadro_atendimento_screen.dart`), `AppBar(automaticallyImplyLeading: false, ...)`. A tela já tem o botão "Sair" (Passo 9, com diálogo de confirmação) como única forma de sair pelo header.

**Atenção (fora de escopo):** isso remove apenas o ícone de voltar do `AppBar`. O botão/gesto de voltar do sistema Android (hardware ou gesto de borda) **não é afetado** por esta mudança — continua chamando `Navigator.pop` diretamente, sem passar pela confirmação de "Sair". Interceptar o back do sistema (`PopScope`) não foi pedido e fica fora deste passo.

## 2. Background sólido por coluna, escurecendo da esquerda para a direita

**Revisão (2026-09-14):** a versão original deste item usava um degradê por coluna, com uma cor diferente por `PedidoStatus`. O usuário pediu para trocar por um único tom, em cor **sólida** (sem degradê dentro da coluna), escurecendo progressivamente da coluna mais à esquerda para a mais à direita. Uma primeira revisão usou azul; o usuário então pediu para trocar por uma cor que combinasse melhor com a identidade visual do app — trocado para `deepOrange`, a mesma base do `colorSchemeSeed` do tema (`core/theme/app_theme.dart`).

Em `quadro_atendimento_screen.dart`:
```dart
Color _corColuna(int index, int totalColunas) {
  final t = totalColunas <= 1 ? 0.0 : index / (totalColunas - 1);
  return Color.lerp(Colors.deepOrange.shade50, Colors.deepOrange.shade200, t)!;
}
```
`index` é a posição da coluna na ordem de `PedidoStatus.values` (a mesma ordem em que as colunas aparecem da esquerda para a direita no Kanban) — usar `PedidoStatus.values.indexed` ao montar as colunas em `_buildQuadro`. `_KanbanColuna` recebe a cor já calculada (`cor: Color`) e aplica em `Container(decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(16)), clipBehavior: Clip.antiAlias, ...)`. Tom-base e range (`shade50` → `shade200`) ajustáveis livremente — o ponto obrigatório é: uma única cor-base, sólida (não degradê), escurecendo da esquerda para a direita, e alinhada ao `colorSchemeSeed` do app.

**Revisão adicional (2026-09-14):** cada bloco de coluna tem os cantos arredondados (`borderRadius: BorderRadius.circular(16)`, `clipBehavior: Clip.antiAlias` para os cards não vazarem dos cantos), e há um espaçamento de `12` entre colunas adjacentes (`SizedBox(width: 12)` entre os itens do `Row` em `_buildQuadro`, mais um `padding` horizontal de `8` no `SingleChildScrollView` para não colar a primeira/última coluna nas bordas da tela). O título de cada coluna (`"${status.titulo} (${pedidos.length})"`) é centralizado horizontalmente (`SizedBox(width: double.infinity)` + `Text(..., textAlign: TextAlign.center)`), já que o `Column` da coluna usa `crossAxisAlignment.start` para os cards.

## 3. Botões do header mais estilizados

Trocar os `IconButton` simples do `AppBar.actions` ("Novo Pedido", "Busca de Pedidos", "Sair", e o novo botão de filtro do item 5) por `IconButton.filledTonal` (Material 3, fundo levemente colorido, mais destaque que o ícone "flat" atual) — mesmo ícone e `tooltip` de cada um, só a variante do botão muda. Adicionar um pequeno espaçamento (`SizedBox(width: 4)`) entre os botões do `actions` para não ficarem colados, já que a variante `filledTonal` ocupa mais espaço visual que o `IconButton` padrão.

## 4. Ordenação por data/hora decrescente

Em `QuadroAtendimentoController.load()` (`quadro_atendimento_controller.dart`), depois de agrupar `pedidos` por status, ordenar cada lista por `dataHoraStatusAtual` (`Pedido`, Passo 12) decrescente — mais recente no topo. Pedidos sem carimbo (criados antes do Passo 12) vão para o final da lista, ordenados entre si por `identificador` (critério de desempate estável, evita reordenação aparentemente aleatória):

```dart
int _compararPorDataHoraDesc(Pedido a, Pedido b) {
  final dataA = a.dataHoraStatusAtual;
  final dataB = b.dataHoraStatusAtual;
  if (dataA == null && dataB == null) return a.identificador.compareTo(b.identificador);
  if (dataA == null) return 1;
  if (dataB == null) return -1;
  return dataB.compareTo(dataA);
}
```

Aplicar `.sort(_compararPorDataHoraDesc)` em cada lista de `porStatus` antes de `notifyListeners()`.

## 5. Filtro de visualização (Todos / Cancelados / Não Cancelados)

**Novo enum** (em `quadro_atendimento_controller.dart`, é um critério de visualização local à tela — não é persistido):
```dart
enum FiltroPedidoVisualizacao { todos, somenteCancelados, somenteNaoCancelados }
```

**`QuadroAtendimentoController`:**
- Novo campo `FiltroPedidoVisualizacao filtro = FiltroPedidoVisualizacao.todos`.
- Novo método `alterarFiltro(FiltroPedidoVisualizacao novoFiltro)`: atualiza `filtro` e chama `notifyListeners()` — **não** recarrega do banco, é um filtro puramente de exibição sobre os dados já carregados.
- `pedidosDe(PedidoStatus status)` passa a aplicar o filtro sobre a lista já ordenada:
```dart
List<Pedido> pedidosDe(PedidoStatus status) {
  final todos = porStatus[status] ?? const [];
  return switch (filtro) {
    FiltroPedidoVisualizacao.todos => todos,
    FiltroPedidoVisualizacao.somenteCancelados => todos.where((p) => p.cancelado).toList(),
    FiltroPedidoVisualizacao.somenteNaoCancelados => todos.where((p) => !p.cancelado).toList(),
  };
}
```

**Novo widget** `lib/features/fluxo_atendimento/presentation/filtro_pedidos_dialog.dart` (`FiltroPedidosDialog`): `SimpleDialog` com um `RadioListTile<FiltroPedidoVisualizacao>` para cada uma das 3 opções ("Todos", "Somente Cancelados", "Somente Não Cancelados"), valor atual vindo de `controller.filtro`. Selecionar uma opção já fecha o diálogo (`Navigator.pop(context, opcaoSelecionada)`) — sem botão de confirmar separado, padrão comum de diálogo de seleção única no Android.

**Botão no header:** novo `IconButton.filledTonal` no `AppBar.actions` (posicionado antes do botão de busca), ícone `Icons.filter_list` quando `filtro == todos`, e `Icons.filter_alt` (preenchido) quando o filtro é qualquer um dos outros dois — sinalizando visualmente que o Kanban está mostrando conteúdo filtrado. Tooltip: "Filtrar Pedidos". Ao tocar, abre `FiltroPedidosDialog`; se o diálogo retornar um valor, chama `controller.alterarFiltro(valor)`.

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Header da Tela 4 não exibe mais o ícone de voltar.
- [ ] Cada coluna do Kanban tem um fundo sólido (sem degradê) em um único tom (azul), progressivamente mais escuro da esquerda para a direita.
- [ ] Há espaçamento visível entre colunas adjacentes, e os cantos de cada bloco de coluna são arredondados.
- [ ] Botões do header (Novo Pedido, Filtro, Busca, Sair) usam a variante estilizada, mantendo os ícones e tooltips atuais.
- [ ] Em cada coluna, o pedido com a mudança de estado mais recente aparece no topo.
- [ ] Botão de filtro abre o diálogo com as 3 opções; selecionar "Somente Cancelados" ou "Somente Não Cancelados" atualiza o Kanban imediatamente (sem reconsultar o banco) e o ícone do botão de filtro muda para indicar filtro ativo; selecionar "Todos" volta ao ícone padrão e mostra tudo novamente.

## Fora de Escopo deste Passo

- Interceptar o botão/gesto de voltar do sistema Android (`PopScope`) — só o ícone do `AppBar` é removido.
- Persistir o filtro de visualização entre sessões ou ao sair/reentrar na tela — reinicia em "Todos" a cada abertura da Tela 4.
- Implementar a "Busca de Pedidos" (**P-7**, já fora de escopo do plano inteiro).
