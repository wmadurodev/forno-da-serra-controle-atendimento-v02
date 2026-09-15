# Passo 31 — Foto do Pedido deixa de ser obrigatória

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-15. **Reverte uma regra de negócio já confirmada** — `docs/controle-atendimento-data-structure.md` §3 ("Imagem do Pedido... Obrigatória na transição `em_atendimento → em_execucao`") e **DS-7** *(confirmado)*: "a imagem é armazenada localmente no dispositivo; o campo guarda o caminho do arquivo" — a obrigatoriedade em si é o que muda aqui, não o mecanismo de armazenamento. Documentos `docs/*.md` não são editados (mesma convenção adotada desde o Passo 9): a reversão fica registrada neste prompt.
> **Depende de:** Passo 5 (Execução de Pedido, Tela 6), Passo 6 (Edição de Pedido em Execução, Tela 9).

## Objetivo

A foto do Pedido passa a ser **opcional** tanto na Tela 6 (Execução de Pedido) quanto na Tela 9 (Edição de Pedido em Execução) — gravar sem foto deixa de ser bloqueado.

## Levantamento

| Tela | Arquivo | Hoje exige foto para gravar? |
|---|---|---|
| 6 — Execução de Pedido | `execucao_pedido_screen.dart` | **Sim** — `_onGravar` bloqueia com `_erroFoto = 'A foto do pedido é obrigatória'` se `_foto == null` |
| 9 — Edição de Pedido em Execução | `edicao_pedido_execucao_screen.dart` | **Não** — já não bloqueia hoje; só substitui `imagemPedidoRef` se uma nova foto for tirada, senão mantém a existente (que pode ser `null`, uma vez que a Tela 6 passe a permitir isso) |

**Conclusão:** só a Tela 6 precisa de mudança de código. A Tela 9 já se comporta corretamente sem alteração — mas passa a lidar, na prática, com Pedidos que chegam com `imagemPedidoRef == null` (o que hoje nunca acontecia, já que a Tela 6 obrigava a foto).

## Alteração — `execucao_pedido_screen.dart`

Em `_onGravar`, remover o bloqueio por falta de foto:
```dart
Future<void> _onGravar() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _salvando = true);

  final foto = _foto;
  String? imagemPedidoRef;
  if (foto != null) {
    imagemPedidoRef = await ImagemPedidoStorage().salvar(widget.pedido.id!, foto);
    if (!mounted) return;
  }

  // ... resto do método sem mudança, usando `imagemPedidoRef` (agora pode ser null)
}
```
O campo `_erroFoto` (e a `Padding`/`Text` que o exibe em `_buildFoto`) deixam de ter uso — remover, já que não existe mais nenhum caminho de código que os preencha.

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Na Tela 6, preencher Mesa (obrigatória) sem tirar foto e gravar: Pedido avança para `em_execucao` normalmente, sem foto (`imagem_pedido_ref` nulo).
- [ ] Na Tela 6, tirar uma foto e gravar continua funcionando exatamente como antes.
- [ ] Card do Kanban de um Pedido sem foto não exibe a miniatura (já é o comportamento atual do `PedidoCard`, condicional a `imagemPedidoRef != null` — Passo 14) e não quebra a tela.
- [ ] Na Tela 9, editar um Pedido que não tem foto continua funcionando (mostra a área de foto vazia, permite tirar uma se quiser, ou gravar sem nenhuma).

## Fora de Escopo deste Passo

- Qualquer mudança na Home/relatórios/Busca de Pedidos por causa da ausência de imagem — nenhuma dessas telas depende da existência de imagem hoje.
- Atualizar `docs/controle-atendimento-data-structure.md`/`functional.md` (mantém a convenção deste plano de registrar reversões de regra nos prompts de passo, não nos documentos originais).
