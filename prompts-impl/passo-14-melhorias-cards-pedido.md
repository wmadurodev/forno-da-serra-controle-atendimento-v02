# Passo 14 — Melhorias nos Cards de Pedido (Tela 4)

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-14. Sem correspondência prévia em `docs/controle-atendimento-functional.md`, `docs/controle-atendimento-data-structure.md` ou `docs/controle-atendimento-prototype.md` — as decisões de UI (ícones, ordem dos campos) são definidas neste prompt.
> **Depende de:** Passo 3 (Kanban), Passo 12 (`PedidoCard` com carimbos de data/hora e bloco de cancelamento), Passo 13 (colunas do Kanban). Não depende do Passo 11 (Home) nem o afeta.

## Objetivo

Revisar `PedidoCard` (`lib/features/fluxo_atendimento/presentation/pedido_card.dart`) e a ordem das colunas do Kanban:

1. Cards de `aguardando_atendimento` passam a mostrar todos os campos já preenchidos (hoje não mostram nenhum campo, mesmo que o pedido já tenha dados parciais de cadastro salvos).
2. Em todos os cards, os botões de ação viram ícones (sem texto).
3. Nome do cliente sem o label "Cliente:", em negrito.
4. Labels dos demais campos exibidos viram ícones.
5. Imagem do pedido: clicável, abre em tela cheia com um X para fechar.
6. Reordenar campos: Endereço logo abaixo de Entrega; Mesa logo abaixo de Cliente.
7. Valor de Observação em negrito.
8. Mover a coluna `retirado_no_balcao` para o final do Kanban.

## 1. Lista de campos unificada (mesma para todos os status)

Hoje `_campos()` tem um `switch` que não mostra nada para `aguardando_atendimento` e duplica a mesma lista de campos entre `em_atendimento` e o grupo `em_execucao`+. Como cada campo só é exibido quando tem valor (`nome_cliente`, `mesa`, `imagem_pedido_ref` etc. só existem a partir do estágio em que são preenchidos — `data-structure.md` §3), o `switch` é desnecessário: substituir por **uma única lista ordenada, sem distinção por status**, cada item exibido apenas se o campo correspondente do `Pedido` não for nulo/vazio. Isso já resolve o item 1 (pedido em `aguardando_atendimento` com cadastro parcial salvo passa a mostrar os campos preenchidos, do mesmo jeito que qualquer outro status).

**Ordem final dos campos** (cada um só aparece se tiver valor):
1. Nome do Cliente — sem ícone, sem label, **negrito** (item 3).
2. Mesa — ícone, sem label (logo abaixo do Cliente — item 6).
3. Tipo de Entrega — ícone, sem label.
4. Endereço — ícone, sem label, só quando `tipoEntrega == delivery` (logo abaixo de Entrega — item 6).
5. Tipo de Pagamento — ícone, sem label.
6. Observação — ícone, sem label, valor em **negrito** (item 7).
7. Restrições — ícone, sem label.
8. Imagem do Pedido — miniatura clicável (item 5).
9. Motivo da Devolução — ícone, sem label (continua condicionado a `pedido.motivoDevolucao != null`, que só é preenchido no evento de devolução — Passo 12).

O bloco de cancelamento (`_camposCancelado`, Passo 12: "Cancelado (HH:mm)" + motivo) não muda — continua exibido antes desta lista, sem ícones (já é um destaque à parte, em vermelho).

## 2. Ícones por campo (substituem os labels de texto)

Novo helper, no lugar do `add(label, valor)` atual:
```dart
Widget _campo(IconData icone, String valor, {bool negrito = false}) {
  return Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 16, color: Colors.black54),
        const SizedBox(width: 6),
        Expanded(
          child: Text(valor, style: negrito ? const TextStyle(fontWeight: FontWeight.bold) : null),
        ),
      ],
    ),
  );
}
```

| Campo | Ícone |
|---|---|
| Mesa | `Icons.table_restaurant_outlined` |
| Tipo de Entrega | `Icons.local_shipping_outlined` |
| Endereço | `Icons.location_on_outlined` |
| Tipo de Pagamento | `Icons.payments_outlined` |
| Observação | `Icons.notes_outlined` |
| Restrições | `Icons.warning_amber_outlined` |
| Motivo da Devolução | `Icons.assignment_return_outlined` |

Nome do Cliente **não** usa `_campo()` — é um `Text` simples em negrito, sem ícone nem label:
```dart
if (pedido.nomeCliente != null && pedido.nomeCliente!.isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(pedido.nomeCliente!, style: const TextStyle(fontWeight: FontWeight.bold)),
  ),
```

Ícones exatos ajustáveis livremente — o ponto obrigatório é: nenhum campo (exceto Cliente, tratado à parte) mostra mais o nome do campo como texto/label.

## 3. Imagem do pedido — clique para ampliar em tela cheia

A miniatura (`ClipRRect` + `Image.file`, altura 120) passa a ficar dentro de um `GestureDetector`/`InkWell` que abre uma nova tela em tela cheia ao ser tocada:

Novo widget `lib/features/fluxo_atendimento/presentation/imagem_pedido_tela_cheia.dart`:
```dart
class ImagemPedidoTelaCheia extends StatelessWidget {
  const ImagemPedidoTelaCheia({super.key, required this.caminhoImagem});

  final String caminhoImagem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: InteractiveViewer(child: Image.file(File(caminhoImagem)))),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
```
Em `PedidoCard`, a miniatura abre essa tela via `Navigator.push(context, MaterialPageRoute(fullscreenDialog: true, builder: (_) => ImagemPedidoTelaCheia(caminhoImagem: pedido.imagemPedidoRef!)))`. `InteractiveViewer` (pinça para zoom) é um extra razoável dado que a tela já existe para visualização — não obrigatório, pode ser um `Image.file` simples se preferir simplicidade.

## 4. Botões de ação viram ícones

Trocar cada `OutlinedButton(child: Text(...))` do `_buildFooter` por `IconButton` (mesmo `onPressed`), com `tooltip` igual ao texto removido (acessibilidade — o rótulo textual não desaparece, só deixa de ficar visível permanentemente):

| Ação (tooltip) | Ícone |
|---|---|
| Atendimento | `Icons.support_agent_outlined` |
| Excluir | `Icons.delete_outline` |
| Executar | `Icons.play_circle_outline` |
| Editar | `Icons.edit_outlined` |
| Cancelar | `Icons.cancel_outlined` |
| Enviado | `Icons.local_shipping_outlined` |
| Retirado | `Icons.storefront_outlined` |
| Entregue | `Icons.check_circle_outline` |
| Devolvido | `Icons.assignment_return_outlined` |

Manter o `Wrap` com os mesmos `spacing`/`runSpacing`; ícones exatos ajustáveis livremente.

**Revisão (2026-09-14):** os ícones de ação do rodapé ficam centralizados horizontalmente no card — `Wrap(alignment: WrapAlignment.center, ...)` dentro de um `SizedBox(width: double.infinity, ...)` (necessário porque o `Column` do card usa `crossAxisAlignment.start`, então o `Wrap` por si só só ocupa a largura do seu conteúdo).

## 5. Mover a coluna `retirado_no_balcao` para o final

`PedidoStatus` (`lib/features/pedido/domain/pedido.dart`) é declarado como enum; a ordem de `PedidoStatus.values` é a mesma ordem em que as colunas aparecem no Kanban (`quadro_atendimento_screen.dart`, `PedidoStatus.values.indexed`) e a mesma usada para o escurecimento progressivo de cor das colunas (Passo 13). Não há nenhum outro lugar do código que dependa da ordem declarada do enum (checar `grep -rn "PedidoStatus.values"` antes de mexer, para confirmar que continua valendo). Basta reordenar a declaração do enum:

```dart
enum PedidoStatus {
  aguardandoAtendimento,
  emAtendimento,
  emExecucao,
  enviado,
  entregue,
  devolvido,
  retiradoNoBalcao; // movido para o final — Passo 14
  // ... resto do enum (getters value/titulo, fromValue) sem mudança de conteúdo
}
```

Isso já move a coluna (e sua cor, mais escura por ser a última) automaticamente, sem tocar em `quadro_atendimento_screen.dart` nem `quadro_atendimento_controller.dart`.

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Pedido em `aguardando_atendimento` com cadastro parcial (ex.: nome do cliente preenchido, mas sem tipo de entrega definido) mostra o nome do cliente no card.
- [ ] Nenhum campo do card (exceto o bloco de cancelamento) exibe mais um label de texto antes do valor — cada um tem um ícone (Cliente não tem ícone nem label).
- [ ] Nome do Cliente e valor de Observação aparecem em negrito.
- [ ] Endereço aparece imediatamente abaixo de Tipo de Entrega; Mesa aparece imediatamente abaixo do Nome do Cliente.
- [ ] Tocar na miniatura da imagem do pedido abre a visualização em tela cheia; o X no canto superior direito fecha e volta ao Kanban.
- [ ] Todos os botões de ação dos cards são ícones (sem texto visível), com tooltip acessível.
- [ ] A coluna "Retirado no Balcão" aparece por último (mais à direita) no Kanban, com a cor mais escura da progressão (Passo 13).

## Fora de Escopo deste Passo

- Zoom/pan na imagem em tela cheia além do `InteractiveViewer` básico (não é um requisito, apenas uma conveniência opcional já citada).
- Qualquer mudança de regra de negócio — apenas apresentação visual dos dados já existentes.
