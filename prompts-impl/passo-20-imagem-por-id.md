# Passo 20 — Nomear o arquivo de imagem do Pedido pelo `id`, não pelo `identificador`

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** correção de bug identificada e solicitada diretamente pelo usuário desta iniciativa de implementação, em 2026-09-15 — consequência direta do Passo 18 (remoção da constraint de unicidade de `pedido.identificador`).
> **Depende de:** Passo 17 (`Pedido.id`), Passo 18 (motivo do bug: `identificador` não é mais único).

## Bug

`ImagemPedidoStorage.salvar(pedidoIdentificador, imagemTemporaria)` (`lib/core/storage/imagem_pedido_storage.dart`) grava a imagem em `<documentos>/pedidos_imagens/<identificador>.jpg` — o nome do arquivo usa o `identificador` do Pedido. Desde o Passo 18, `identificador` não é mais único: **dois Pedidos diferentes podem ter o mesmo identificador**, e a imagem do segundo sobrescreveria silenciosamente a do primeiro (mesmo nome de arquivo). É preciso usar a chave primária (`Pedido.id`, sequencial e sempre única, Passo 17) para nomear o arquivo.

## Correção

**`ImagemPedidoStorage.salvar`**: trocar o parâmetro de `String pedidoIdentificador` para `int pedidoId`, usando-o no nome do arquivo:
```dart
class ImagemPedidoStorage {
  static const _pasta = 'pedidos_imagens';

  Future<String> salvar(int pedidoId, File imagemTemporaria) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final pastaDestino = Directory(p.join(documentsDir.path, _pasta));
    if (!await pastaDestino.exists()) {
      await pastaDestino.create(recursive: true);
    }

    final destino = File(p.join(pastaDestino.path, '$pedidoId.jpg'));
    await imagemTemporaria.copy(destino.path);
    return destino.path;
  }
}
```

**Chamadores** (os 2 únicos pontos que chamam `ImagemPedidoStorage().salvar(...)`):
- `lib/features/pedido/presentation/execucao_pedido_screen.dart`: `ImagemPedidoStorage().salvar(widget.pedido.identificador, foto)` → `ImagemPedidoStorage().salvar(widget.pedido.id!, foto)`.
- `lib/features/pedido/presentation/edicao_pedido_execucao_screen.dart`: `ImagemPedidoStorage().salvar(widget.pedido.identificador, novaFoto)` → `ImagemPedidoStorage().salvar(widget.pedido.id!, novaFoto)`.

Em ambos os pontos, `widget.pedido` já veio do banco (`Pedido.fromMap`), então `id` sempre está preenchido nesse momento (`!` é seguro) — só é `null` para um `Pedido` recém-construído em memória, antes do primeiro `INSERT`, o que nunca é o caso nessas duas telas (só operam sobre Pedidos já existentes, em `em_atendimento` ou além).

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Executar um Pedido (Tela 6) grava a imagem como `<id>.jpg` (não mais `<identificador>.jpg`) em `pedidos_imagens/`.
- [ ] Editar a imagem de um Pedido em execução (Tela 9) grava/sobrescreve o mesmo arquivo `<id>.jpg` daquele Pedido especificamente.
- [ ] Dois Pedidos diferentes com o mesmo identificador, cada um com sua própria imagem, não colidem mais no armazenamento — cada um mantém seu próprio arquivo.

## Fora de Escopo deste Passo

- Migrar/renomear arquivos de imagem já gravados com o nome antigo (`<identificador>.jpg`) para o novo padrão (`<id>.jpg`) — pedidos já existentes com imagem ficam com a referência antiga em `imagem_pedido_ref` (caminho completo já gravado no banco), que continua funcionando normalmente; só as gravações novas usam o novo padrão de nome.
