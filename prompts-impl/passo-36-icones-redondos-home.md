# Passo 36 — Fundo Redondo nos Ícones do Card de Fluxo (Home)

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-15. Sem correspondência em `docs/`.
> **Depende de:** Passo 1 (Home), Passo 29 (ícone de cifrão), Passo 33 (ícone de moto).

## Objetivo

Os ícones da `trailing` `Row` de cada card de fluxo na Home (cifrão, moto, fechar, excluir) ganham um fundo redondo tipo botão, como já existe nos ícones do cabeçalho da Tela 4 (Passo 13).

## Levantamento

O Passo 13 já resolveu exatamente esse mesmo pedido para outra tela: trocou os `IconButton`s do cabeçalho do Kanban por `IconButton.filledTonal`, que desenha um fundo circular tonal atrás do ícone — sem precisar de nenhum `Container`/`CircleAvatar` manual. `home_screen.dart` hoje usa `IconButton` simples (sem fundo) nos 4 ícones da linha de cada fluxo (`attach_money`, `two_wheeler`, `done_all` condicional, `delete_outline`). Mesma solução se aplica aqui.

## Alteração — `home_screen.dart`

Trocar as 4 ocorrências de `IconButton(` por `IconButton.filledTonal(` na `trailing` `Row` de `_buildBody`:

```dart
trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    IconButton.filledTonal(
      icon: const Icon(Icons.attach_money),
      tooltip: 'Valores de Pagamento',
      onPressed: () => _onValoresPagamento(context, fluxo),
    ),
    IconButton.filledTonal(
      icon: const Icon(Icons.two_wheeler),
      tooltip: 'Prestação de Contas com o Motoqueiro',
      onPressed: () => _onPrestacaoContasMotoqueiro(context, fluxo),
    ),
    if (aberto)
      IconButton.filledTonal(
        icon: const Icon(Icons.done_all),
        tooltip: 'Fechar Fluxo de Atendimento',
        onPressed: () => _onFecharFluxo(context, fluxo),
      ),
    IconButton.filledTonal(
      icon: const Icon(Icons.delete_outline),
      tooltip: 'Excluir Fluxo de Atendimento',
      onPressed: () => _onExcluirFluxo(context, fluxo),
    ),
  ],
),
```

Como cada `IconButton.filledTonal` fica um pouco mais largo que um `IconButton` comum, pode ser necessário revisar visualmente se os 3-4 ícones ainda cabem confortavelmente na `trailing` (a `Row` já é `mainAxisSize: MainAxisSize.min`, sem `Expanded`, então o `ListTile` só cresce a `trailing` conforme necessário — a decidir no build/validação manual se algum ajuste extra de espaçamento é preciso).

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Cada ícone da linha de fluxo na Home (cifrão, moto, fechar quando aberto, excluir) aparece com um fundo circular tonal atrás, igual ao padrão já usado no cabeçalho da Tela 4.
- [ ] Nenhuma mudança de comportamento — os 4 `onPressed` continuam os mesmos.
- [ ] Em um fluxo `fechado` (sem o ícone de fechar), os 3 ícones restantes continuam com o mesmo tratamento visual, sem quebrar o layout.

## Fora de Escopo deste Passo

- Ícones de qualquer outra tela — só a linha de fluxo da Home é mencionada pelo usuário.
