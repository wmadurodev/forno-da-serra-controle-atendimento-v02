# Passo 26 — Cor cinza sólida nas colunas/ícones de Entregue, Devolvido e Retirado no Balcão

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-15. Sem correspondência em `docs/`.
> **Depende de:** Passo 13 (fundo das colunas do Kanban), Passo 25 (ícones do navegador do footer).

## Objetivo

Para as fases finais `entregue`, `devolvido` e `retirado_no_balcao`, tanto o fundo da coluna do Kanban quanto o fundo do ícone correspondente no navegador do footer (Passo 25) passam a usar um tom de **cinza sólido** (em vez da cor sólida em tom de laranja usada pelas demais colunas via `_corColuna`, Passo 13). As demais 4 fases (`aguardando_atendimento`, `em_atendimento`, `em_execucao`, `enviado`) continuam com a cor sólida laranja atual, sem mudança.

**Histórico da conversa (2026-09-15):** a primeira versão pedia um degradê de cinza nas fases `enviado, entregue, devolvido`; revisado para as fases `entregue, devolvido, retirado_no_balcao` (`enviado` fica com a cor laranja normal); por fim o usuário pediu para usar **cor sólida**, sem degradê, mesmo padrão das demais colunas.

## Alteração

```dart
/// Cor cinza sólida para as fases finais (`entregue`, `devolvido`,
/// `retirado_no_balcao`) — Passo 26. Substitui a cor laranja de
/// `_corColuna` só para essas 3 fases, progressivamente mais escura entre
/// si; `enviado` e as demais fases continuam com `_corColuna`.
Color? _corCinza(PedidoStatus status) {
  return switch (status) {
    PedidoStatus.entregue => Colors.grey.shade300,
    PedidoStatus.devolvido => Colors.grey.shade400,
    PedidoStatus.retiradoNoBalcao => Colors.grey.shade500,
    _ => null,
  };
}
```

Em `quadro_atendimento_screen.dart`, os dois pontos que hoje pintam o fundo com `cor` (vindo de `_corColuna`) passam a usar `_corCinza(status) ?? cor`:

- **`_KanbanColuna.build`**: `decoration: BoxDecoration(color: _corCinza(status) ?? cor, borderRadius: BorderRadius.circular(16))`.
- **`_QuadroViewState._iconeFase`**: `decoration: BoxDecoration(color: _corCinza(status) ?? cor, shape: BoxShape.circle)`.

Nenhum `gradient`/`LinearGradient` é usado — cor sólida em ambos os casos, igual ao padrão já usado pelas outras 4 fases.

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Colunas `entregue`, `devolvido` e `retirado_no_balcao` no Kanban mostram fundo cinza sólido, em vez da cor laranja.
- [ ] Ícones dessas 3 fases no footer mostram o mesmo cinza sólido.
- [ ] As colunas/ícones de `aguardando_atendimento`, `em_atendimento`, `em_execucao` e `enviado` continuam com a cor sólida laranja de antes, sem alteração.
- [ ] Os 3 cinzas ficam visivelmente mais escuros na ordem entregue → devolvido → retirado no balcão.

## Fora de Escopo deste Passo

- Mudar a cor de fundo dos cards de Pedido dentro dessas colunas (Passo 13/14, branco/vermelho) — só o fundo da coluna e do ícone do footer mudam.
