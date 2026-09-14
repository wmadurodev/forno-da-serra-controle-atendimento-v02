# Passo 5 — Execução de Pedido (Tela 6)

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Referências obrigatórias:** `docs/controle-atendimento-prototype.md` §3.6 (Tela 6); `docs/controle-atendimento-functional.md` §6.2 (transição 3.4), §8; `docs/controle-atendimento-data-structure.md` §3 (`mesa`, `imagem_pedido_ref`, `restricoes`, `valor_pagamento`); `docs/controle-atendimento-non-functional.md` §5 (armazenamento da imagem).
> **Depende de:** Passos 1 a 4, concluídos e validados.

## Objetivo

Implementar a Tela 6 (Execução de Pedido), acionada pelo botão **"Executar"** do card `em_atendimento` na Tela 4. Permite informar `mesa` (obrigatória) e capturar a foto do pedido pela câmera (`imagem_pedido_ref`, obrigatória), além de `restricoes` e `valor_pagamento` (opcionais), e grava a transição `em_atendimento → em_execucao` (`functional.md` §6.2, 3.4).

## Escopo deste Passo

**Incluído:**
- Novas dependências: `image_picker` (captura de foto pela câmera) e `path_provider` (localizar o diretório de dados do app para persistir a imagem — `non-functional.md` §5).
- Permissão `android.permission.CAMERA` no `AndroidManifest.xml`.
- Tela 6 — Execução de Pedido, completa.
- Botão "Executar" do card `em_atendimento` (Tela 4): troca o placeholder "Disponível a partir do Passo 5" pela navegação real.
- `PedidoCard`: exibir uma miniatura real da imagem (`Image.file`) no lugar do caminho em texto, para os cards que carregam `imagem_pedido_ref` (`em_execucao` em diante).

**Não incluído (fica para passos seguintes):**
- Edição dos campos de Execução após o pedido já estar em `em_execucao` (Tela 9) — Passo 6.
- Qualquer outra transição de estado (Cancelar, Devolvido etc.) — Passos 7 e 8.

## Armazenamento da Imagem (`non-functional.md` §5)

- A imagem é capturada via `image_picker` (`ImageSource.camera`) e, **somente ao gravar** (não ao apenas tirar a foto — permitindo repetir a captura sem deixar arquivos órfãos), copiada para um arquivo permanente dentro do diretório de dados do app (`path_provider`, `getApplicationDocumentsDirectory()`), em uma subpasta dedicada (ex.: `pedidos_imagens/<identificador_do_pedido>.jpg`, sobrescrevendo se já existir).
- `imagem_pedido_ref` grava o caminho absoluto desse arquivo permanente — nunca o caminho temporário devolvido pelo `image_picker`.
- Não é necessário nenhum código de limpeza automática do arquivo: a remoção ao desinstalar o app ou limpar dados é feita pelo próprio sistema operacional (**NF-6**), por estar no diretório privado do app.

## Tela 6 — Execução de Pedido

Local: `lib/features/pedido/presentation/execucao_pedido_screen.dart`. Recebe o `Pedido` (sempre pré-selecionado — só é aberta a partir do botão "Executar" do card `em_atendimento`).

Campos (`prototype.md` §3.6):

| Campo (UI) | Nome técnico | Obrigatório | Observações |
|---|---|---|---|
| Imagem (capturada pela câmera) | `imagem_pedido_ref` | Sim | Botão "Tirar Foto"; exibe uma prévia após a captura; permite repetir a captura antes de gravar. |
| Mesa | `mesa` | Sim | Texto livre. |
| Restrições | `restricoes` | Não | Texto livre. |
| Valor Pagamento | `valor_pagamento` | Não | Numérico monetário. |

Footer: botões **Gravar** e **Cancelar**.

| Ação | Comportamento |
|---|---|
| Tirar Foto | Aciona `image_picker` (câmera); ao retornar uma imagem, exibe a prévia na tela (arquivo temporário, ainda não persistido). |
| Gravar, sem `mesa` preenchida ou sem foto capturada | Não grava; erro de validação inline (mesa) e/ou mensagem indicando que a foto é obrigatória. |
| Gravar, `mesa` e foto presentes | Copia a foto para o armazenamento permanente do app; grava o Pedido com `mesa`, `imagem_pedido_ref` (caminho permanente), `restricoes` e `valor_pagamento` (se informados) e `status = em_execucao`. Retorna (`pop`) para a Tela 4. |
| Cancelar | Descarta tudo (inclusive a foto temporária, se houver) e retorna (`pop`) para a Tela 4, sem gravar. |

## Tela 4 — Ajuste

Em `pedido_card.dart` / `quadro_atendimento_screen.dart`: botão "Executar" do card `em_atendimento` abre `ExecucaoPedidoScreen(pedido: pedido)` via `Navigator.push`; ao retornar, recarregar o quadro (`controller.load()`).

`PedidoCard._campos()`: quando `imagem_pedido_ref` não for nulo, renderizar `Image.file(File(caminho))` (com altura limitada, ex. 120) no lugar da linha de texto "Imagem: ...".

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo Android real (câmera não funciona em todos os emuladores).
- [ ] Card `em_atendimento`, botão "Executar": abre a Tela 6.
- [ ] Botão "Tirar Foto": abre a câmera do dispositivo e, ao voltar com uma foto, exibe a prévia na tela.
- [ ] Gravar sem foto ou sem mesa: não grava, exibe indicação de erro.
- [ ] Gravar com mesa e foto: o pedido aparece na coluna `em_execucao` ao voltar para a Tela 4, com a miniatura da imagem visível no card.
- [ ] O arquivo de imagem persiste no diretório de dados do app (não no cache temporário do `image_picker`) — reabrir o app não invalida a miniatura exibida no card.
- [ ] Botão "Cancelar": retorna à Tela 4 sem alterar o pedido (mesmo tendo tirado uma foto antes).

## Fora de Escopo deste Passo

- Tela 9 (edição de campos de Execução após `em_execucao`) — Passo 6.
- Telas 7 e 8 — Passos 7 e 8.
- Testes automatizados de UI — não obrigatórios para a validação deste passo.
