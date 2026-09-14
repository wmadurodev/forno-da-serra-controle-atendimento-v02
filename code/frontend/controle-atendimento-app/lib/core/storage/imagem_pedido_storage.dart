import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Persiste a imagem do Pedido no diretório de dados do app
/// (`docs/controle-atendimento-non-functional.md` §5) — nunca como BLOB no
/// SQLite, nem no diretório temporário devolvido pelo `image_picker`.
class ImagemPedidoStorage {
  static const _pasta = 'pedidos_imagens';

  Future<String> salvar(String pedidoIdentificador, File imagemTemporaria) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final pastaDestino = Directory(p.join(documentsDir.path, _pasta));
    if (!await pastaDestino.exists()) {
      await pastaDestino.create(recursive: true);
    }

    final destino = File(p.join(pastaDestino.path, '$pedidoIdentificador.jpg'));
    await imagemTemporaria.copy(destino.path);
    return destino.path;
  }
}
