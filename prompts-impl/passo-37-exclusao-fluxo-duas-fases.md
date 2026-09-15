# Passo 37 — Exclusão de Fluxo em Duas Fases

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-15. Sem correspondência em `docs/`.
> **Depende de:** Passo 11 (`ExcluirFluxoDialog`, `SlideToConfirmButton`).

## Objetivo

O diálogo de Excluir Fluxo de Atendimento (`ExcluirFluxoDialog`) passa a exigir **2 arrastos sequenciais** em vez de 1, para reforçar a segurança de uma ação irreversível (exclusão em cascata do fluxo + todos os pedidos):

- **Fase 1** — botão arrastável habilitado desde a abertura do diálogo, com o texto "Arraste para excluir - Fase 1".
- **Fase 2** — botão arrastável **desabilitado** até a Fase 1 ser concluída; ao ser habilitado, o texto é "Arraste para excluir - Fase 2"; só ao ser arrastado até o final é que a exclusão de fato é confirmada (`Navigator.pop(true)`).

O diálogo de Fechar Fluxo de Atendimento (`FecharFluxoDialog`) **não muda** — o pedido do usuário foi só sobre a exclusão.

## Levantamento

`SlideToConfirmButton` (`lib/core/widgets/slide_to_confirm_button.dart`, Passo 11) hoje não tem noção de "desabilitado": o gesto de arrastar sempre responde, só é ignorado depois que o próprio botão já foi confirmado (`_confirmado`). Precisa de um novo parâmetro `enabled` para cobrir o caso da Fase 2 antes da Fase 1 ser concluída.

`ExcluirFluxoDialog` hoje é um `StatelessWidget` com um único `SlideToConfirmButton`. Precisa virar `StatefulWidget` para guardar se a Fase 1 já foi confirmada.

## Alteração — `SlideToConfirmButton`

Novo parâmetro `enabled` (default `true`):
```dart
class SlideToConfirmButton extends StatefulWidget {
  const SlideToConfirmButton({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onConfirmed;
  final bool enabled;
  // ...
}
```
Nos handlers de gesto, ignorar quando desabilitado (igual já ocorre com `_confirmado`):
```dart
onHorizontalDragUpdate: (details) {
  if (!widget.enabled || _confirmado) return;
  // ...
},
onHorizontalDragEnd: (details) {
  if (!widget.enabled || _confirmado) return;
  // ...
},
```
Feedback visual de desabilitado: quando `!widget.enabled`, usar tons acinzentados em vez das cores de "ação destrutiva" (trilho com opacidade reduzida, círculo do thumb em `Colors.grey.shade400` em vez de `colorScheme.error`).

## Alteração — `ExcluirFluxoDialog`

Vira `StatefulWidget` com um `bool _fase1Confirmada = false`:
```dart
class ExcluirFluxoDialog extends StatefulWidget {
  const ExcluirFluxoDialog({super.key, required this.fluxo});
  final FluxoAtendimento fluxo;
  @override
  State<ExcluirFluxoDialog> createState() => _ExcluirFluxoDialogState();
}

class _ExcluirFluxoDialogState extends State<ExcluirFluxoDialog> {
  bool _fase1Confirmada = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        // ... cabeçalho e texto de aviso sem mudança ...
        children: [
          // ...
          SlideToConfirmButton(
            label: 'Arraste para excluir - Fase 1',
            onConfirmed: () => setState(() => _fase1Confirmada = true),
          ),
          const SizedBox(height: 12),
          SlideToConfirmButton(
            label: 'Arraste para excluir - Fase 2',
            enabled: _fase1Confirmada,
            onConfirmed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }
}
```

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Ao abrir "Excluir Fluxo de Atendimento", só o botão da Fase 1 responde ao arrastar; o da Fase 2 está visualmente acinzentado e não responde a toques/arrastos.
- [ ] Arrastar a Fase 1 até o final habilita a Fase 2 (cor normal de ação destrutiva, passa a responder ao arrastar).
- [ ] Arrastar a Fase 2 até o final é que efetivamente exclui o fluxo (`Navigator.pop(true)`), fechando o diálogo.
- [ ] Fechar o diálogo pelo X a qualquer momento (mesmo com a Fase 1 já concluída) cancela a exclusão, sem excluir nada.
- [ ] `FecharFluxoDialog` continua com um único arrasto, sem nenhuma mudança.

## Fora de Escopo deste Passo

- `FecharFluxoDialog` (fechamento de fluxo) — explicitamente não mencionado pelo usuário, continua com 1 fase só.
- Qualquer outra ação destrutiva do app (ex. excluir um Pedido na Busca — não usa `SlideToConfirmButton` hoje).
