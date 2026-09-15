# Passo 28 — Destacar no footer a fase visível no Kanban

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-15. Sem correspondência em `docs/`.
> **Depende de:** Passo 25 (navegador de fases no footer, `ScrollController`, `_rolarParaFase`).

## Objetivo

No navegador de fases do footer da Tela 4 (Passo 25), destacar visualmente (um círculo/anel em volta do ícone) a fase cuja coluna está atualmente visível/alinhada à esquerda no Kanban. Ao abrir a tela, a coluna `aguardando_atendimento` é a primeira visível, então seu ícone já nasce destacado. Rolando o Kanban manualmente (arrastando), o destaque acompanha a coluna que fica visível. Tocando em um ícone do footer (`_rolarParaFase`, Passo 25), o destaque também vai para aquele ícone.

## Alteração — `quadro_atendimento_screen.dart` (`_QuadroViewState`)

**Novo estado:** `int _indiceFaseVisivel = 0;` — índice (em `PedidoStatus.values`) da coluna considerada "visível" no momento.

**Listener no `_scrollController`**, registrado em `initState` e removido em `dispose` antes de `.dispose()`:
```dart
static const _larguraColuna = 300.0;
static const _espacamento = 12.0;
static const _paddingInicial = 8.0;

@override
void initState() {
  super.initState();
  _scrollController.addListener(_atualizarFaseVisivel);
}

@override
void dispose() {
  _scrollController.removeListener(_atualizarFaseVisivel);
  _scrollController.dispose();
  super.dispose();
}

void _atualizarFaseVisivel() {
  final indice = ((_scrollController.offset - _paddingInicial) / (_larguraColuna + _espacamento))
      .round()
      .clamp(0, PedidoStatus.values.length - 1);
  if (indice != _indiceFaseVisivel) {
    setState(() => _indiceFaseVisivel = indice);
  }
}
```
(`_rolarParaFase` passa a usar as mesmas constantes de classe `_larguraColuna`/`_espacamento`/`_paddingInicial`, em vez de declará-las localmente de novo.)

O cálculo arredonda para a coluna mais próxima do início do percurso de rolagem — o destaque muda assim que o usuário rola além do meio do caminho entre duas colunas, dando uma resposta natural durante o gesto de arrastar (não precisa rolar até o fim para o destaque mudar).

## Destaque visual no ícone

`_iconeFase` ganha um anel (borda circular) ao redor do círculo colorido existente, visível só quando `PedidoStatus.values.indexOf(status) == _indiceFaseVisivel` **e o dispositivo está em modo retrato** (revisão abaixo):
```dart
Widget _iconeFase(PedidoStatus status, IconData icone, int quantidade) {
  final indiceReal = PedidoStatus.values.indexOf(status);
  final cor = corCinza(status) ?? corColuna(indiceReal, PedidoStatus.values.length);
  final orientacaoRetrato = MediaQuery.orientationOf(context) == Orientation.portrait;
  final ativo = orientacaoRetrato && indiceReal == _indiceFaseVisivel;
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Tooltip(
        message: status.titulo,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _rolarParaFase(status),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: ativo ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3) : null,
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
              child: Icon(icone, color: Colors.black87),
            ),
          ),
        ),
      ),
      const SizedBox(height: 2),
      Text('$quantidade', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
    ],
  );
}
```
Cor/espessura do anel ajustáveis livremente — o ponto obrigatório é: só um ícone destacado por vez, correspondente à coluna visível.

## Revisão (2026-09-15) — destaque só em modo retrato

O usuário pediu para o destaque só valer quando o dispositivo está em modo **retrato** (`Orientation.portrait`, via `MediaQuery.orientationOf(context)`). Em modo paisagem, nenhum ícone fica destacado — faz sentido porque, com a tela mais larga, várias colunas ficam visíveis ao mesmo tempo, e não há uma única "coluna visível" para destacar. O rastreamento de `_indiceFaseVisivel` (listener do `ScrollController`) continua rodando normalmente em paisagem, só a exibição do anel é que fica condicionada à orientação — assim, ao girar de volta para retrato, o destaque correto já aparece imediatamente, sem esperar um novo evento de rolagem.

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Ao abrir a Tela 4, o ícone de "Aguardando Atendimento" já aparece destacado (círculo em volta).
- [ ] Rolar o Kanban manualmente (arrastar) até a próxima coluna ficar visível move o destaque para o ícone correspondente no footer.
- [ ] Tocar em qualquer ícone do footer rola até a coluna (Passo 25) e also atualiza o destaque para aquele ícone.
- [ ] Só um ícone fica destacado por vez.
- [ ] Em modo paisagem, nenhum ícone do footer aparece destacado; girando de volta para retrato, o destaque correto reaparece imediatamente.

## Fora de Escopo deste Passo

- Qualquer indicação de progresso/porcentagem de rolagem — só o destaque binário (ativo/inativo) por ícone.
