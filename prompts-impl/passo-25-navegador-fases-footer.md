# Passo 25 — Navegador de fases no footer da Execução do Fluxo de Atendimento

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-15. Sem correspondência em `docs/`.
> **Depende de:** Passo 13 (colunas do Kanban, `_corColuna`, espaçamento/largura), Passo 14 (ordem de exibição das colunas — `retirado_no_balcao` por último).

## Objetivo

Novo footer fixo na Tela 4 (Execução do Fluxo de Atendimento) com um "navegador" das 7 fases do Pedido. Cada fase é um ícone sugestivo dentro de um fundo arredondado, colorido com a mesma cor da coluna correspondente no Kanban (Passo 13). Tocar em um ícone rola o Kanban horizontalmente até a coluna daquela fase ficar visível, alinhada à esquerda da tela — como aconteceria numa rolagem manual até ali.

## Ordem das fases no navegador

**Revisão (2026-09-15):** a primeira versão deste passo listava os ícones numa ordem "de negócio" fixa (`aguardando_atendimento, em_atendimento, em_execucao, retirado_no_balcao, enviado, entregue, devolvido`), diferente da ordem de exibição das colunas no Kanban. O usuário pediu para os ícones seguirem a **mesma ordem das colunas do Kanban** — ou seja, a ordem de `PedidoStatus.values` (Passo 14: `aguardando_atendimento, em_atendimento, em_execucao, enviado, entregue, devolvido, retirado_no_balcao` — `retirado_no_balcao` por último). O navegador do footer itera `PedidoStatus.values` diretamente, na mesma ordem da esquerda para a direita do Kanban — não há mais divergência entre a posição do ícone e a posição da coluna.

## Ícones sugeridos por fase

| Fase | Ícone |
|---|---|
| `aguardando_atendimento` | `Icons.hourglass_empty` |
| `em_atendimento` | `Icons.support_agent_outlined` (mesmo da ação "Atender") |
| `em_execucao` | `Icons.restaurant_outlined` |
| `retirado_no_balcao` | `Icons.storefront_outlined` (mesmo da ação "Retirado") |
| `enviado` | `Icons.local_shipping_outlined` (mesmo da ação "Enviar") |
| `entregue` | `Icons.check_circle_outline` (mesmo da ação "Entregue") |
| `devolvido` | `Icons.assignment_return_outlined` (mesmo da ação/motivo "Devolvido") |

Ícones exatos ajustáveis livremente — reaproveitar os já usados nas ações do card (Passo 14) mantém a linguagem visual consistente.

## Rolagem até a coluna clicada

Hoje o `SingleChildScrollView` horizontal do Kanban (`_buildQuadro`, `quadro_atendimento_screen.dart`) não tem um `ScrollController` nomeado. `_QuadroView` precisa virar `StatefulWidget` (hoje é `StatelessWidget`) para guardar um `ScrollController` (criado em `initState`, liberado em `dispose`), atribuído ao `SingleChildScrollView(controller: _scrollController, ...)`.

Cálculo do offset alvo para a coluna de índice `i` (0-based, em `PedidoStatus.values`), usando as constantes já existentes (largura de coluna `300`, espaçamento entre colunas `12`, padding inicial do `SingleChildScrollView` `8` — todos do Passo 13):
```dart
void _rolarParaFase(PedidoStatus status) {
  final indice = PedidoStatus.values.indexOf(status);
  const larguraColuna = 300.0;
  const espacamento = 12.0;
  const paddingInicial = 8.0;
  final offsetAlvo = paddingInicial + indice * (larguraColuna + espacamento);
  final maximo = _scrollController.position.maxScrollExtent;
  _scrollController.animateTo(
    offsetAlvo.clamp(0.0, maximo),
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );
}
```

## Footer — novo widget

`Scaffold.bottomNavigationBar` da Tela 4 ganha uma barra (`SafeArea` + `Row`, `MainAxisAlignment.spaceEvenly`) de 7 itens, um por fase, na mesma ordem de `PedidoStatus.values` (ordem das colunas). Cada item mostra o ícone com fundo redondo e, abaixo, **a quantidade de cards daquela fase** (revisão 2026-09-15 — mesmo valor já mostrado no cabeçalho da coluna, via `controller.pedidosDe(status).length`, já considerando o filtro ativo, Passo 13):
```dart
Widget _iconeFase(PedidoStatus status, IconData icone, int quantidade) {
  final indiceReal = PedidoStatus.values.indexOf(status);
  final cor = _corColuna(indiceReal, PedidoStatus.values.length); // mesma função do Passo 13
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Tooltip(
        message: status.titulo,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _rolarParaFase(status),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
            child: Icon(icone, color: Colors.black87),
          ),
        ),
      ),
      const SizedBox(height: 2),
      Text('$quantidade', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
    ],
  );
}
```

## Ícone também no cabeçalho da coluna (revisão 2026-09-15)

O cabeçalho de cada coluna do Kanban (`_KanbanColuna`, hoje só `'${status.titulo} (${pedidos.length})'` centralizado) passa a mostrar o mesmo ícone de `_iconePorFase[status]` antes do texto, ambos dentro de um `Row` centralizado:
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Icon(_iconePorFase[status], size: 18),
    const SizedBox(width: 6),
    Flexible(
      child: Text('${status.titulo} (${pedidos.length})', textAlign: TextAlign.center, style: ...),
    ),
  ],
)
```

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Footer da Tela 4 mostra 7 ícones, na mesma ordem das colunas do Kanban: Aguardando Atendimento, Em Atendimento, Em Execução, Enviado, Entregue, Devolvido, Retirado no Balcão (por último).
- [ ] Cada ícone tem fundo redondo na mesma cor da coluna correspondente no Kanban.
- [ ] Abaixo de cada ícone do footer aparece a quantidade de cards daquela fase, igual ao número mostrado no cabeçalho da coluna (respeitando o filtro ativo, se houver).
- [ ] O cabeçalho de cada coluna do Kanban mostra o mesmo ícone da fase, antes do nome/contagem.
- [ ] Tocar em qualquer ícone do footer rola o Kanban horizontalmente até a coluna daquela fase, com a coluna ficando alinhada à esquerda da tela visível.
- [ ] Tocar no ícone de uma fase cuja coluna já está visível não quebra nada (rolagem para a posição já correta, ou sem efeito perceptível).
- [ ] Tocar no ícone da última coluna (Retirado no Balcão, mais à direita) rola até o fim do Kanban sem espaço vazio sobrando (offset limitado a `maxScrollExtent`).

## Fora de Escopo deste Passo

- Indicar visualmente no footer qual coluna está atualmente visível (destaque/seleção) — não foi pedido, só a navegação por toque.
- Rolagem vertical ou dentro de uma coluna — só a rolagem horizontal entre colunas do Kanban.
