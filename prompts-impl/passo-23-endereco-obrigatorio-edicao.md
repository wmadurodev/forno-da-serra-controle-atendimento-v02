# Passo 23 — Endereço obrigatório ao editar Cadastro de um Pedido já além de `aguardando_atendimento`

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-15.
> **Depende de:** Passo 4 (Tela 5), Passo 22 (mesmo padrão de obrigatoriedade condicional a `tipo_entrega`).

## Objetivo

Na Tela 5 (Cadastro de Pedido), quando o Pedido sendo editado **já está além de `aguardando_atendimento`** (ex.: aberto via "Editar" no card `em_atendimento`), o campo Endereço passa a ser **obrigatório** (bloqueia o `Gravar`) se o Tipo de Entrega for `delivery`.

**Não muda** o comportamento para um Pedido em `aguardando_atendimento` (criação via "Novo Pedido", ou edição de um Pedido ainda incompleto): nesse caso, Endereço continua opcional — se faltar, o Pedido simplesmente permanece `aguardando_atendimento` em vez de avançar (comportamento já existente).

## Situação atual (levantamento)

- `CadastroPedidoScreen` (Tela 5) declara um `_dadosFormKey`, mas **nunca chama `_dadosFormKey.currentState!.validate()`** em `_onGravar()` — nenhum campo desse formulário é validado hoje, incluindo Endereço (sem `validator` algum). A obrigatoriedade de Endereço para `delivery` só afeta se o Pedido novo alcança `em_atendimento` ou fica em `aguardando_atendimento` (`cadastroCompleto`), nunca bloqueia a gravação.
- `EdicaoPedidoExecucaoScreen` (Tela 9, edição de Pedido já em `em_execucao`+) **já** faz exatamente o que está sendo pedido: o campo Endereço (mostrado só quando `delivery`) tem `validator: _obrigatorio`, e `_onGravar` chama `_formKey.currentState!.validate()` antes de gravar. **Nenhuma mudança necessária na Tela 9.**

## Alteração — só na Tela 5 (`cadastro_pedido_screen.dart`)

1. Adicionar `validator` ao `TextFormField` do Endereço, condicionado a **estar editando um Pedido que já passou de `aguardando_atendimento`** (`_pedidoBase != null && _pedidoBase!.status != PedidoStatus.aguardandoAtendimento` — único caso possível é a entrada via `pedidoExistente` no card `em_atendimento`, "Editar"; no fluxo "Novo Pedido" via busca de identificador, `_pedidoBase` é sempre `null` desde o Passo 18):
```dart
if (_tipoEntrega == TipoEntrega.delivery) ...[
  const SizedBox(height: 16),
  TextFormField(
    controller: _enderecoController,
    decoration: const InputDecoration(labelText: 'Endereço'),
    validator: (value) {
      final editandoPedidoAvancado =
          _pedidoBase != null && _pedidoBase!.status != PedidoStatus.aguardandoAtendimento;
      if (editandoPedidoAvancado && (value == null || value.trim().isEmpty)) {
        return 'Informe o endereço';
      }
      return null;
    },
  ),
],
```
2. Em `_onGravar()`, validar o formulário antes de prosseguir (hoje não valida nada):
```dart
Future<void> _onGravar() async {
  if (!_dadosFormKey.currentState!.validate()) return;

  setState(() => _salvando = true);
  // ... resto do método sem mudança
}
```

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Criar um Pedido novo (`aguardando_atendimento`), selecionar `delivery` e deixar Endereço em branco: grava normalmente, Pedido permanece `aguardando_atendimento` (comportamento já existente, sem bloqueio).
- [ ] Abrir "Editar" em um card `em_atendimento` com `delivery`, apagar o Endereço e tentar gravar: bloqueado com "Informe o endereço".
- [ ] Mesmo cenário de edição com `retirada_balcao` (campo Endereço nem aparece): grava normalmente.
- [ ] Tela 9 (Execução) já se comporta assim hoje — nenhuma mudança necessária, só confirmar que continua funcionando.

## Fora de Escopo deste Passo

- Qualquer outro campo da Tela 5 (Nome do Cliente, Tipo de Entrega, Tipo de Pagamento, Observação) — só o Endereço ganha essa validação condicional.
