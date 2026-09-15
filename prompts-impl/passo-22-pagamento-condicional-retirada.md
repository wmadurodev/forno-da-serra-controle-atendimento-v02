# Passo 22 — Tipo de Pagamento obrigatório só para Delivery

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-15. Revê a leitura de `docs/controle-atendimento-data-structure.md` §3 ("Tipo de Pagamento... Exigido para `em_atendimento`") — a partir deste passo, essa exigência passa a valer só quando `tipo_entrega = delivery`.

## Objetivo

O Tipo de Pagamento só é obrigatório para o Pedido alcançar `em_atendimento` quando o Tipo de Entrega é `delivery`. Quando é `retirada_balcao`, o Tipo de Pagamento pode ficar em branco nesta fase (Cadastro) sem impedir a transição para `em_atendimento`.

## Onde essa regra se aplica (levantamento nos formulários de Pedido)

| Tela | Arquivo | Tem campo Tipo de Pagamento? | Precisa mudar? |
|---|---|---|---|
| 5 — Cadastro de Pedido | `cadastro_pedido_screen.dart` | Sim | Sim — `cadastroCompleto` exige `_tipoPagamento != null` incondicionalmente |
| 6 — Execução de Pedido | `execucao_pedido_screen.dart` | Não (só Mesa, Restrições, Valor Pagamento, Imagem) | Não |
| 9 — Edição de Pedido em Execução | `edicao_pedido_execucao_screen.dart` | Sim | Sim — `validator` do dropdown exige valor incondicionalmente |
| 7 — Cancelamento de Pedido | `cancelamento_pedido_screen.dart` | Não | Não |
| 8 — Devolução de Entrega | `devolucao_entrega_screen.dart` | Não | Não |

## Alterações

### `CadastroPedidoScreen._onGravar` (Tela 5)

Hoje:
```dart
final cadastroCompleto = nomeCliente.isNotEmpty &&
    _tipoEntrega != null &&
    _tipoPagamento != null &&
    (_tipoEntrega != TipoEntrega.delivery || endereco.isNotEmpty);
```
Passa a:
```dart
final pagamentoObrigatorio = _tipoEntrega == TipoEntrega.delivery;
final cadastroCompleto = nomeCliente.isNotEmpty &&
    _tipoEntrega != null &&
    (!pagamentoObrigatorio || _tipoPagamento != null) &&
    (_tipoEntrega != TipoEntrega.delivery || endereco.isNotEmpty);
```
(Esta tela não bloqueia a gravação com erro de formulário — quando incompleto, o Pedido simplesmente permanece `aguardando_atendimento` em vez de avançar para `em_atendimento`. O campo do dropdown de Tipo de Pagamento continua visível e preenchível independentemente do Tipo de Entrega, só deixa de ser obrigatório para retirada no balcão.)

### `EdicaoPedidoExecucaoScreen` (Tela 9)

Hoje, o `DropdownButtonFormField<TipoPagamento>` tem:
```dart
validator: (value) => value == null ? 'Selecione o tipo de pagamento' : null,
```
Passa a:
```dart
validator: (value) {
  if (_tipoEntrega == TipoEntrega.delivery && value == null) {
    return 'Selecione o tipo de pagamento';
  }
  return null;
},
```
(Esta tela **bloqueia** o `Gravar` via `Form.validate()` — a diferença aqui é que a validação passa a ser condicional ao Tipo de Entrega selecionado no momento, igual ao padrão já usado para o campo Endereço nesta mesma tela.)

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Tela 5: preencher Nome do Cliente + Tipo de Entrega `retirada_balcao`, sem selecionar Tipo de Pagamento, e gravar: Pedido alcança `em_atendimento`.
- [ ] Tela 5: mesmo cenário com Tipo de Entrega `delivery` (e endereço preenchido), sem Tipo de Pagamento: Pedido permanece `aguardando_atendimento`.
- [ ] Tela 9: com Tipo de Entrega `retirada_balcao`, gravar sem selecionar Tipo de Pagamento não gera erro de validação.
- [ ] Tela 9: com Tipo de Entrega `delivery`, gravar sem selecionar Tipo de Pagamento continua bloqueado com a mensagem "Selecione o tipo de pagamento".

## Fora de Escopo deste Passo

- Qualquer mudança nos campos Nome do Cliente, Tipo de Entrega ou Endereço — continuam com as mesmas regras de obrigatoriedade de antes.
- Telas 6, 7 e 8 — não têm campo de Tipo de Pagamento, regra não se aplica.
