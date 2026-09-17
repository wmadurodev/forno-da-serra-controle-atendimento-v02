# Passo 45 — Campo Identificador do Pedido (Tela 5) editável a qualquer momento, com destaque visual e teclado numérico inicial

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-17. Sem correspondência em `docs/`.
> **Depende de:** Passos 4 (Cadastro de Pedido), 18 (fluxo de confirmação/molde por identificador — `pedido.identificador` já não tem restrição de unicidade).

## Objetivo

No formulário de Cadastro/Alteração de Pedido (Tela 5, `cadastro_pedido_screen.dart` — usado tanto para criar um Pedido novo quanto para editar um já existente, via "Atendimento"/"Editar" na Tela 4):

1. O campo "Identificador do Pedido" deixa de ficar bloqueado (`readOnly`) após a confirmação inicial — pode ser alterado a qualquer momento, inclusive quando a tela abre com um `pedidoExistente` (edição).
2. O valor digitado nesse campo passa a usar uma fonte maior e em negrito, destacando-o dos demais campos do formulário.
3. O teclado virtual desse campo passa a abrir inicialmente no modo numérico, mas sem impedir a troca para o teclado de texto completo, caso o identificador não seja só números.

## Levantamento

`cadastro_pedido_screen.dart`, método `_buildCampoIdentificador`: o `TextFormField` do Identificador usa hoje `readOnly: _identificadorConfirmado` — antes de confirmar (botão "Confirmar", que dispara a busca de molde do Passo 18), o campo é editável; depois, vira somente leitura para sempre, mesmo quando a tela é reaberta via `pedidoExistente` (nesse caso `_identificadorConfirmado` já nasce `true` em `initState`).

Como `pedido.identificador` não tem mais nenhuma restrição de unicidade desde o Passo 18, e toda gravação (`PedidoRepository.salvar`) já opera por `id` (não por identificador), alterar o texto do identificador livremente e gravar não tem efeito colateral: `_onGravar` já lê `_identificadorController.text.trim()` como o identificador a salvar, mantendo `id: base?.id` — ou seja, editar o identificador de um Pedido existente e gravar atualiza a mesma linha (mesmo `id`) só com o identificador novo, sem duplicar nem precisar de nenhuma mudança em `PedidoRepository`.

A tela 9 (`edicao_pedido_execucao_screen.dart`) também mostra um campo "Identificador do Pedido", mas ele é somente leitura por design daquela tela (edição de dados de execução, não de cadastro) — **fora de escopo deste passo**, ver seção abaixo.

## Alteração

Em `cadastro_pedido_screen.dart`, no `TextFormField` do Identificador (`_buildCampoIdentificador`):

- Remover `readOnly: _identificadorConfirmado` (o campo fica sempre editável, antes e depois da confirmação/mesmo vindo de `pedidoExistente`). O botão "Confirmar" e a etapa de busca de molde (Passo 18) continuam existindo exatamente como hoje — só disparam antes da primeira confirmação; edições posteriores no identificador não repetem a busca, só alteram o valor que será gravado.
- Adicionar `style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)` para destacar o valor digitado (fonte maior e negrito) — só o texto digitado; o rótulo do campo ("Identificador do Pedido") segue o estilo global de rótulos do Passo 44, sem mudança aqui.
- Adicionar `keyboardType: TextInputType.number`, para o teclado abrir inicialmente no modo numérico. Nenhum `inputFormatters` é adicionado — o campo continua aceitando qualquer texto (letras, símbolos) que o usuário conseguir digitar através do próprio teclado (a maioria dos teclados Android, como o Gboard, oferece uma alternância para o modo alfabético completo mesmo partindo do modo numérico); a validação (`validator`, obrigatoriedade) não muda.

Nenhuma outra mudança de comportamento, layout ou validação no restante do formulário.

**Correção bundled:** tornar o campo sempre editável (acima) abriu uma lacuna — `_onGravar` só validava `_dadosFormKey` (os campos de `_buildCamposCadastro`), nunca `_identificadorFormKey` (o `Form` que envolve o campo Identificador), então um usuário podia apagar o identificador depois de confirmado e gravar um Pedido com identificador vazio. `_onGravar` passou a validar as duas `Form`s (sem short-circuit, para mostrar os erros das duas de uma vez) antes de prosseguir — o `validator` que já existia no campo Identificador (obrigatório) agora efetivamente bloqueia o Gravar.

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Tela 5, "Novo Pedido": teclado abre em modo numérico no campo Identificador; após confirmar, o campo continua editável (não fica cinza/bloqueado) e o texto digitado aparece maior e em negrito.
- [ ] Tela 5, "Atendimento"/"Editar" (via `pedidoExistente`): campo Identificador já abre editável (não somente leitura), com o valor existente em fonte maior/negrito; alterar o valor e gravar atualiza o mesmo Pedido (mesmo `id`) com o novo identificador.
- [ ] Campo Identificador (Tela 5) tem um ícone dentro do campo (123/ABC) que alterna o teclado entre numérico e texto completo, mesmo em teclados (como o Samsung Keyboard) sem alternância nativa própria.
- [ ] Apagar o Identificador (após confirmado) e tocar "Gravar" mostra o erro "Informe o identificador do pedido" embaixo do campo e **não** grava o Pedido.
- [ ] Nenhuma mudança na lógica de busca de molde (Passo 18), na obrigatoriedade do campo ou no restante do fluxo de gravação.

## Revisão (mesmo dia) — estende à Tela 9

Pedido do usuário: o campo Identificador do Pedido da Tela 9 (`edicao_pedido_execucao_screen.dart`, "Edição de Pedido em Execução") também passa a ser editável, usando as mesmas fontes do campo equivalente na Tela 5 (fonte maior e negrito no valor digitado — o rótulo já usa o estilo global do Passo 44), e continua obrigatório.

- Novo `_identificadorController` (antes o campo usava `initialValue: widget.pedido.identificador` direto, sem controller, por ser somente leitura), inicializado em `initState` com `pedido.identificador` e liberado em `dispose`.
- `TextFormField` do Identificador: removido `initialValue`/`readOnly: true`; adicionado `controller: _identificadorController`, `style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)` (idêntico ao da Tela 5) e `validator: _obrigatorio` (helper já existente nesta tela, reaproveitado — mesma mensagem "Campo obrigatório" usada pelos demais campos obrigatórios da tela).
- `_onGravar` passou a gravar `identificador: _identificadorController.text.trim()` em vez de `widget.pedido.identificador`. Como a tela já tem uma única `Form`/`_formKey` cobrindo todos os campos (diferente da Tela 5, que tem duas `Form`s separadas), a validação de obrigatoriedade do Identificador já é coberta pelo `_formKey.currentState!.validate()` existente no início de `_onGravar` — nenhuma mudança adicional de validação foi necessária.
- Deliberadamente **não** adicionado `keyboardType: TextInputType.number` aqui — o pedido do usuário desta revisão foi só sobre fonte e obrigatoriedade, não sobre teclado; a Tela 9 mantém o teclado padrão (texto) nesse campo.
- Título da `AppBar` ("Editar Pedido — {identificador}") continua usando `widget.pedido.identificador` (valor original, fixo) — não seria correto atualizá-lo em tempo real a cada tecla, e o usuário não pediu isso.

**Critérios de aceite desta revisão:**

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Tela 9: campo Identificador do Pedido não é mais somente leitura; o valor exibido/editado usa a mesma fonte maior/negrito da Tela 5.
- [ ] Tela 9: apagar o Identificador e tocar "Gravar" mostra "Campo obrigatório" e não grava o Pedido.
- [ ] Tela 9: alterar o Identificador e gravar atualiza o mesmo Pedido (mesmo `id`) com o novo valor.
- [ ] Tela 9: campo Identificador abre com teclado numérico e tem o mesmo ícone de troca (123/ABC) da Tela 5.

## Revisão 3 (mesmo dia) — troca manual de teclado no campo Identificador (Tela 5)

O usuário reportou que, no dispositivo de teste (Samsung, teclado Samsung Keyboard), o campo Identificador em modo `TextInputType.number` **não** oferece nenhuma forma nativa de alternar para o teclado alfabético completo — ao contrário do que a Alteração original deste passo assumia ("a maioria dos teclados... oferece uma alternância"). Como esse comportamento depende do teclado instalado e não é controlável pelo Flutter, a solução passou a ser um controle manual dentro do próprio app, escolhido com o usuário via `AskUserQuestion` (opção escolhida: "ícone que muda", 123 ↔ ABC).

- Novo estado `bool _identificadorTeclaNumerica` (`true` por padrão) e `FocusNode _identificadorFocusNode` (antes o campo não tinha `FocusNode` próprio).
- `TextFormField` do Identificador: `keyboardType` passa a ser `_identificadorTeclaNumerica ? TextInputType.number : TextInputType.text`; `focusNode: _identificadorFocusNode`; `decoration.suffixIcon` ganhou um `IconButton` dentro do campo, com `tooltip` explicando a ação. **Correção no mesmo dia:** o ícone inicialmente mostrava o modo *atual* (`Icons.numbers` enquanto numérico, `Icons.abc` enquanto texto); o usuário pediu para inverter — o ícone passa a indicar o modo *para o qual vai mudar* ao tocar (`Icons.abc` enquanto o teclado está em modo numérico, sinalizando "toque para ir a texto"; `Icons.numbers` enquanto está em modo texto, sinalizando "toque para ir a números") — mesmo sentido que o `tooltip` já tinha, só o ícone estava invertido em relação a ele.
- Novo `_alternarTecladoIdentificador()`: inverte `_identificadorTeclaNumerica` (`setState`), depois `_identificadorFocusNode.unfocus()` seguido de `requestFocus()` num `addPostFrameCallback` — necessário porque só trocar o `keyboardType` com o campo já focado nem sempre faz o Android recarregar o teclado virtual já aberto; fechar e reabrir o foco força a reabertura no novo modo.
## Revisão 4 (mesmo dia) — estende a troca manual de teclado à Tela 9

Pedido do usuário: o mesmo comportamento da Revisão 3 (teclado numérico inicial + ícone de troca manual) também no campo Identificador da Tela 9 (`edicao_pedido_execucao_screen.dart`) — implementação idêntica à da Tela 5: novo `_identificadorTeclaNumerica`/`_identificadorFocusNode`, `keyboardType` condicional, `decoration.suffixIcon` com o mesmo `IconButton` (`Icons.abc`/`Icons.numbers`, ícone já na versão "mostra o modo de destino" da correção seguinte) e o mesmo `_alternarTecladoIdentificador()`.

## Fora de Escopo deste Passo

- Estilo do rótulo ("Identificador do Pedido") e dos demais campos do formulário — coberto de forma global pelo Passo 44.
- Qualquer restrição de formato (só dígitos, máscara, tamanho máximo) no valor do Identificador.
