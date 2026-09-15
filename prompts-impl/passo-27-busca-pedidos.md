# Passo 27 — Busca de Pedidos (P-7)

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** implementa `docs/controle-atendimento-functional.md` §5.5, explicitamente marcada como **fora de escopo da UI** em `docs/controle-atendimento-prototype.md` (**P-7**) — "o botão existe no header, mas sem ação implementada". O usuário desta iniciativa de implementação pediu, em 2026-09-15, para implementá-la agora, **estendendo** o conjunto de campos de busca de `functional.md` §5.5 (que lista só `nome_cliente`, `identificador`, `mesa`, `endereco`) com mais dois campos: `observacao` e `restricoes`.
> **Depende de:** Passo 3 (Kanban, ícone de busca no header já existe mas sem ação), Passo 13/14/25/26 (cores/ícones/ordenação por fase, reaproveitados nos blocos de resultado).

## Objetivo

Ao tocar no ícone de busca (lupa) do header da Tela 4, abrir uma tela de Busca de Pedidos com 6 campos (Identificador do Pedido, Nome, Endereço, Mesa, Observação, Restrição). O usuário preenche **um só** desses campos e toca em "Buscar"; o sistema lista os Pedidos do fluxo atual que combinam com o critério, agrupados por status (mesma ordem das colunas do Kanban) e, dentro de cada grupo, ordenados por data/hora do status atual (mesmo critério do Kanban, Passo 13) — só que organizados **verticalmente em blocos**, um por status, em vez de colunas horizontais.

## Regras de negócio

1. **Um só campo por vez.** Assim que o usuário digita em um campo, os outros 5 ficam desabilitados (e são limpos) até aquele campo voltar a ficar vazio.
2. **Botão "Buscar" desabilitado** enquanto todos os campos estiverem vazios.
3. **Correspondência exata vs. parcial:** só o campo **Mesa** faz busca exata (`mesa = ?`); os outros 5 (Identificador, Nome, Endereço, Observação, Restrição) fazem busca por conteúdo parcial (`LIKE '%valor%'`).
4. **Escopo:** busca só dentro do Fluxo de Atendimento atualmente aberto na Tela 4 (`functional.md` §5.5, "dentro de um fluxo de atendimento selecionado").
5. Pedidos cancelados continuam aparecendo nos resultados (**FN-7**, já confirmado) — sem tratamento especial além do já existente no `PedidoCard` (Passo 12/14).

## `PedidoRepository` — nova busca

```dart
enum CampoBuscaPedido { identificador, nomeCliente, endereco, mesa, observacao, restricoes }

Future<List<Pedido>> buscar(String fluxoAtendimentoId, CampoBuscaPedido campo, String valor) async {
  final coluna = switch (campo) {
    CampoBuscaPedido.identificador => 'identificador',
    CampoBuscaPedido.nomeCliente => 'nome_cliente',
    CampoBuscaPedido.endereco => 'endereco',
    CampoBuscaPedido.mesa => 'mesa',
    CampoBuscaPedido.observacao => 'observacao',
    CampoBuscaPedido.restricoes => 'restricoes',
  };
  final exata = campo == CampoBuscaPedido.mesa;
  final db = await _appDatabase.database;
  final rows = await db.query(
    _table,
    where: "fluxo_atendimento_id = ? AND $coluna ${exata ? '= ?' : 'LIKE ?'}",
    whereArgs: [fluxoAtendimentoId, exata ? valor : '%$valor%'],
  );
  return rows.map(Pedido.fromMap).toList();
}
```
`coluna` vem de um `switch` fechado sobre um enum interno (não é texto vindo do usuário) — sem risco de injeção SQL.

## Nova tela — `BuscaPedidosScreen` (formulário)

`lib/features/fluxo_atendimento/presentation/busca_pedidos_screen.dart`, recebendo `fluxoAtendimentoId` e `somenteLeitura` (`true` quando o fluxo está `fechado` — repassado à tela de resultados). Estrutura:
- `AppBar` com título "Busca de Pedidos".
- Formulário com 6 `TextField` (um `TextEditingController` cada), regra de mútua exclusão via um handler comum:
  ```dart
  void _onCampoAlterado(TextEditingController alterado) {
    if (alterado.text.isNotEmpty) {
      for (final c in _todosControllers) {
        if (c != alterado) c.clear();
      }
    }
    setState(() {});
  }
  ```
  Cada campo: `enabled: _todosControllers.every((c) => c.text.isEmpty) || alterado.text.isNotEmpty` (ou seja, habilitado só se nenhum campo estiver preenchido, ou se for exatamente o campo já preenchido).
- Botões no rodapé (mesmo padrão "Cancelar/Confirmar" já usado em outras telas do app): **"Limpar"** (limpa todos os 6 campos) e **"Buscar"**, ambos ativos só quando algum campo tem valor.
- Ao buscar: identifica qual dos 6 controllers está preenchido, mapeia para o `CampoBuscaPedido` correspondente, e **navega para `ResultadoBuscaPedidosScreen`** passando `fluxoAtendimentoId`, `somenteLeitura`, `campo` e `valor` — o formulário não guarda nem exibe resultados.

## Revisão (2026-09-15) — tela de resultados separada, "Limpar" e ações nos cards

A versão original deste passo mostrava os resultados na mesma tela do formulário, em modo somente leitura. O usuário pediu três mudanças:
1. Um botão **"Limpar"** no formulário, para zerar os campos preenchidos.
2. Resultados em uma **tela separada** (`ResultadoBuscaPedidosScreen`), aberta ao tocar em "Buscar".
3. Cards de resultado com os **mesmos botões de ação do Kanban**, de acordo com o status de cada Pedido — deixam de ser somente leitura (exceto quando o Fluxo de Atendimento está `fechado`, mesma regra do Kanban).

### Nova tela — `ResultadoBuscaPedidosScreen`

`lib/features/fluxo_atendimento/presentation/resultado_busca_pedidos_screen.dart`, recebendo `fluxoAtendimentoId`, `somenteLeitura`, `campo` (`CampoBuscaPedido`) e `valor` — guarda os **parâmetros da busca**, não a lista de resultados, para poder recarregar (`PedidoRepository.buscar(...)` de novo) depois de qualquer ação sobre um Pedido (mesmo padrão de recarregar do `QuadroAtendimentoController.load()`).

- `AppBar` com título "Resultados da Busca"; botão de voltar padrão retorna ao formulário (que mantém os valores já digitados).
- `initState` dispara a busca; enquanto carrega, mostra `LoadingView` (Passo 1).
- Agrupamento e ordenação idênticos à versão original: por `status` (ordem de `PedidoStatus.values`, Passo 14), `dataHoraStatusAtual` decrescente dentro do grupo (Passo 13), bloco vertical por status com o ícone/cor da coluna correspondente (`iconePorFase`/`corColuna`/`corCinza`, extraídos para `fase_pedido_visual.dart` — arquivo novo, compartilhado com `quadro_atendimento_screen.dart`, evitando um import circular entre as duas telas).
- Cada `PedidoCard` do resultado usa `somenteLeitura: widget.somenteLeitura` e os **mesmos callbacks de ação do Kanban** (`_KanbanColuna`): `onExcluir`/`onRetirado`/`onEnviado`/`onEntregue` chamam `PedidoRepository` diretamente (sem `QuadroAtendimentoController` — a tela de resultados não tem um); `onAtendimento`/`onEditarCadastro`/`onExecutar`/`onEditarExecucao`/`onCancelar`/`onDevolvido` navegam para as mesmas telas de Pedido (`CadastroPedidoScreen`, `ExecucaoPedidoScreen`, `EdicaoPedidoExecucaoScreen`, `CancelamentoPedidoScreen`, `DevolucaoEntregaScreen`). Toda ação, ao voltar, recarrega a busca (`_carregar()`) — um Pedido que deixou de combinar com o critério (ex.: teve o campo buscado alterado) desaparece da lista, o que é o comportamento esperado.
- Erros de `StateError` (ex.: fluxo fechado) mostrados via `SnackBar`, mesmo padrão do `_KanbanColuna._executar`.

`quadro_atendimento_screen.dart`: `_abrirBusca` agora recebe o `QuadroAtendimentoController` e chama `controller.load()` ao voltar da busca, já que ações tomadas nos resultados podem ter alterado Pedidos do Kanban atual.

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Tocar na lupa do header da Tela 4 abre a Busca de Pedidos com os 6 campos vazios e os botões "Limpar"/"Buscar" desabilitados.
- [ ] Preencher um campo desabilita os outros 5; limpar aquele campo reabilita todos; "Limpar" zera todos de uma vez.
- [ ] Tocar em "Buscar" abre a tela de Resultados da Busca (tela separada); voltar retorna ao formulário com os valores preenchidos ainda lá.
- [ ] Buscar por Mesa só retorna Pedidos com o valor exatamente igual; buscar pelos demais campos retorna Pedidos cujo valor contém o texto digitado (em qualquer posição).
- [ ] Resultados aparecem agrupados por status, na mesma ordem das colunas do Kanban, cada grupo com o mesmo ícone/cor daquela coluna, cards ordenados por data/hora decrescente dentro do grupo.
- [ ] Cards de resultado mostram os mesmos botões de ação do Kanban para o status do Pedido (ex.: "Executar"/"Editar"/"Cancelar" para `em_atendimento`), e tocar neles funciona (abre a tela correspondente ou aplica a mudança de status) e atualiza a lista de resultados.
- [ ] Se o Fluxo de Atendimento estiver `fechado`, os cards de resultado não mostram nenhum botão de ação (somente leitura), igual ao Kanban.
- [ ] Buscar sem nenhum resultado mostra uma mensagem clara, sem quebrar a tela.

## Fora de Escopo deste Passo

- Buscar em outros fluxos além do atualmente aberto — fora do que `functional.md` §5.5 descreve.
- Combinar mais de um critério na mesma busca (ex.: nome + mesa) — a regra de negócio pedida é um campo por vez.
