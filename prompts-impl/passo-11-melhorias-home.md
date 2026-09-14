# Passo 11 — Melhorias na Home (Tela 2)

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-14. Cobre 5 melhorias na Home, sem correspondência prévia em `docs/controle-atendimento-functional.md`, `docs/controle-atendimento-data-structure.md` ou `docs/controle-atendimento-prototype.md` — as decisões de modelagem e de UI necessárias são tomadas neste prompt.
> **Depende de:** Passo 1 (Home), Passo 10 (`SlideToConfirmButton`, `FecharFluxoDialog`). Não afeta os Passos 2 a 9.

## Objetivo

Cinco melhorias na Home (Tela 2), listadas pelo usuário:

1. Ordenação decrescente da listagem por ordem de criação (mais recente no topo), com uma nova chave sequencial dedicada a isso.
2. Layout em cards, com um novo background de tela mais agradável.
3. Trocar o ícone de cadeado (fechamento de fluxo) por outro que deixe mais claro que a ação fecha o Fluxo de Atendimento.
4. Cor de fundo diferenciada nos cards de fluxos `fechado`.
5. Nova opção de exclusão total do Fluxo de Atendimento e de todos os seus Pedidos (hard delete em cascata).

## 1. Nova chave sequencial e ordenação

**Problema:** `identificador` (`docs/controle-atendimento-data-structure.md` §2) é texto livre, editável pelo usuário a qualquer momento enquanto o fluxo está `aberto` — não serve como critério confiável de ordem de criação. A listagem hoje ordena por `identificador DESC` (`FluxoAtendimentoRepository.listAll`), o que é apenas coincidência alfabética, não ordem real de criação.

**Decisão técnica deste passo:** adicionar coluna `id INTEGER PRIMARY KEY AUTOINCREMENT` à tabela `fluxo_atendimento`, como nova chave técnica sequencial (uso interno, não exibida na UI, não substitui `identificador` como chave de negócio). `identificador` deixa de ser `PRIMARY KEY` e passa a `TEXT NOT NULL UNIQUE` (mantém unicidade e continua sendo a chave usada por `pedido.fluxo_atendimento_id` e por toda a navegação/UI existente — nenhum outro arquivo do app muda por causa disso).

**Migração (`AppDatabase`, `code/frontend/controle-atendimento-app/lib/core/database/app_database.dart`):**
- Sobe `version` de `1` para `2`.
- `onCreate` (banco novo): cria `fluxo_atendimento` já com `id INTEGER PRIMARY KEY AUTOINCREMENT, identificador TEXT NOT NULL UNIQUE, status TEXT NOT NULL CHECK (...)`.
- `onUpgrade` (banco existente, `oldVersion == 1`): SQLite não permite alterar a `PRIMARY KEY` de uma tabela existente via `ALTER TABLE` — recriar a tabela:
  1. `ALTER TABLE fluxo_atendimento RENAME TO fluxo_atendimento_old`.
  2. Criar `fluxo_atendimento` no formato novo (acima).
  3. `INSERT INTO fluxo_atendimento (identificador, status) SELECT identificador, status FROM fluxo_atendimento_old ORDER BY rowid ASC` — preserva a ordem de inserção original via `rowid` (não há outra pista de ordem de criação nos dados existentes), e o novo `id` é atribuído automaticamente nessa mesma ordem.
  4. `DROP TABLE fluxo_atendimento_old`.
  5. Repetir dentro da mesma transação de `onUpgrade` (o `sqflite` já executa `onUpgrade` em transação).
- `pedido` não muda de schema (a FK continua em `identificador`, que segue `UNIQUE`).

**Domínio (`FluxoAtendimento`, `lib/features/fluxo_atendimento/domain/fluxo_atendimento.dart`):** novo campo `final int? id` (nulo antes de persistir, presente após `fromMap`/inserção). `toMap()` não inclui `id` na escrita (autoincrement).

**Repositório (`FluxoAtendimentoRepository`):**
- `listAll()`: `orderBy: 'id DESC'` (era `'identificador DESC'`).
- `insert`: após `db.insert(...)`, usar o `id` retornado (é o `rowid`/`id` autoincrementado) para devolver o `FluxoAtendimento` já com `id` preenchido, se o chamador precisar — avaliar se `insert` precisa passar a retornar `Future<FluxoAtendimento>` em vez de `Future<void>` (checar os usos atuais em `CadastroFluxoScreen`/controller correspondente antes de decidir; manter `Future<void>` se nada consumir o retorno).
- `getAberto`, `fechar`: continuam operando por `identificador` (sem mudança de assinatura).

## 2. Layout em cards + background da tela

Em `home_screen.dart`, trocar cada `ListTile` por um `Card` (com o conteúdo do `ListTile` — título, subtítulo, trailing — dentro de um `ListTile` interno ou de um `Padding`/`Row` equivalente), com espaçamento entre cards (`padding` no `ListView.builder` + `SizedBox`/`margin` no `Card`, ex. `EdgeInsets.symmetric(horizontal: 12, vertical: 6)`).

`Scaffold.backgroundColor` da Home: uma cor de fundo neutra e agradável, coerente com a identidade "Forno da Serra" (tom quente/creme), ex. `Color(0xFFFFF8E7)` — ajustável livremente, é uma escolha estética sem regra de negócio associada.

## 3. Ícone de fechamento de fluxo

Trocar `Icons.lock_outline` (usado hoje no `IconButton` de fechar fluxo, `home_screen.dart`) por `Icons.done_all` — comunica melhor "tudo concluído, pode fechar" do que um cadeado (que sugere trava/segurança, não encerramento). Manter o `tooltip` "Fechar Fluxo de Atendimento". Ícone escolhido pelo usuário entre 4 opções apresentadas (`flag_circle`, `power_settings_new`, `event_busy`, `done_all`).

## 4. Cor de fundo dos cards de fluxo `fechado`

No `Card` de cada fluxo (item 2), aplicar `color` condicional: fluxos `aberto` usam a cor padrão do tema (`Theme.of(context).cardColor` ou omitir `color`); fluxos `fechado` usam um tom acinzentado (ex. `Colors.grey.shade300`), reforçando visualmente que o fluxo está encerrado/somente leitura.

## 5. Exclusão total do Fluxo de Atendimento e seus Pedidos

**Regra:** exclusão definitiva (hard delete) do fluxo e de **todos** os pedidos vinculados a ele, sem manter histórico — mesmo padrão de "Excluir Pedido" (`functional.md` **FN-6**), aplicado agora ao fluxo inteiro. Disponível para fluxo `aberto` ou `fechado` (não há pré-condição de status: se o fluxo `aberto` for excluído, a próxima abertura do app simplesmente não encontra fluxo aberto e cai na Home, comportamento já suportado pela Tela 1).

**`FluxoAtendimentoRepository`, novo método:**
```dart
Future<void> excluirComPedidos(String identificador) async {
  final db = await _appDatabase.database;
  await db.transaction((txn) async {
    await txn.delete('pedido', where: 'fluxo_atendimento_id = ?', whereArgs: [identificador]);
    await txn.delete(_table, where: 'identificador = ?', whereArgs: [identificador]);
  });
}
```
Exclui pedidos antes do fluxo por causa da FK `pedido.fluxo_atendimento_id REFERENCES fluxo_atendimento(identificador)` com `PRAGMA foreign_keys = ON` (`AppDatabase._open`) — excluir na ordem inversa violaria a constraint. Também remove as imagens de pedido do armazenamento local (`ImagemPedidoStorage`, ver Passo 5) associadas aos pedidos excluídos, se esse storage expuser um método de remoção; caso não exponha, deixar como ponto em aberto (ver "Fora de Escopo").

**`HomeController`:** novo método `excluirFluxo(FluxoAtendimento fluxo)`, análogo a `fecharFluxo` — chama o repositório e recarrega a lista.

**UI (`home_screen.dart`):** cada card ganha uma segunda ação (além do ícone de fechar, quando aplicável) — um `IconButton` com `Icons.delete_outline`, tooltip "Excluir Fluxo de Atendimento", visível em qualquer fluxo (`aberto` ou `fechado`). Ao tocar, abre um novo diálogo `ExcluirFluxoDialog` (`lib/features/fluxo_atendimento/presentation/excluir_fluxo_dialog.dart`), reaproveitando o `SlideToConfirmButton` (`lib/core/widgets/slide_to_confirm_button.dart`, criado no Passo 10) — mesmo padrão de "arrastar para confirmar" do fechamento de fluxo, por ser uma ação irreversível e de maior impacto (apaga também todos os pedidos). Texto do diálogo explícito sobre a exclusão em cascata dos pedidos. Ícone **X** no canto superior direito fecha sem excluir, igual ao `FecharFluxoDialog`.

Se o diálogo retornar `true`, chama `HomeController.excluirFluxo(fluxo)`.

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Banco existente (versão 1) migra sem perda de dados: fluxos e pedidos preexistentes continuam visíveis após o upgrade.
- [ ] Novo fluxo criado aparece no topo da lista; a ordem não depende mais do texto de `identificador`.
- [ ] Lista da Home exibida em cards, com o novo background de tela aplicado.
- [ ] Ícone de fechamento não é mais um cadeado.
- [ ] Cards de fluxo `fechado` têm cor de fundo visivelmente diferente dos `aberto`.
- [ ] Botão de excluir presente em todo card (aberto ou fechado); ao confirmar via slide, o fluxo e todos os seus pedidos somem da Home/quadro Kanban e do banco.
- [ ] Cancelar a exclusão (X ou soltar o slide antes do fim) não altera nada.

## Fora de Escopo deste Passo

- Exibir o novo `id` sequencial na UI — é uma chave técnica interna, não um dado de negócio.
- Alterar a FK de `pedido` para apontar para o novo `id` em vez de `identificador` — mudança de maior risco, sem necessidade funcional identificada neste passo.
- Remoção física dos arquivos de imagem dos pedidos excluídos, caso `ImagemPedidoStorage` não exponha essa operação hoje — resolver como um passo futuro dedicado, se o acúmulo de arquivos órfãos vier a ser um problema real.
- Reabertura de fluxo excluído ou desfazer exclusão — não existe undo.
