# Passo 9 — Botão "Sair" no Header da Tela 4 (Execução do Fluxo de Atendimento)

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-14 — **não** corresponde a nenhuma tela numerada de `docs/controle-atendimento-prototype.md` nem a uma regra de `docs/controle-atendimento-functional.md`. É uma conveniência de navegação: fechar a Tela 4 e voltar para a Home, sem nenhum efeito sobre os dados.
> **Depende de:** Passo 3 (Tela 4 já implementada). Não depende dos Passos 4 a 8 nem os afeta.

## Objetivo

Adicionar um botão **"Sair"** no header (`AppBar`) da Tela 4 (`quadro_atendimento_screen.dart`). Ao ser clicado, exibe um diálogo de confirmação nativo; se o usuário confirmar, fecha a Tela 4 e navega para a Tela 2 (Home).

## Escopo deste Passo

**Incluído:**
- Botão "Sair" na `AppBar` da Tela 4 (junto aos botões já existentes: "Novo Pedido" e "Busca de Pedidos").
- Diálogo de confirmação nativo (`AlertDialog`) ao clicar em "Sair".
- Ao confirmar: navega para a Home, **limpando a pilha de navegação** (`Navigator.pushAndRemoveUntil`) — necessário porque a Tela 4 pode ter sido aberta de formas diferentes:
  - A partir da Splash, quando já existe um Fluxo de Atendimento `aberto` (`splash_screen.dart`, `pushReplacement`) — nesse caso **não há Home na pilha** para simplesmente "voltar".
  - A partir da Home, ao selecionar um fluxo da lista, ou a partir da Tela 3 após criar um novo fluxo (nesses casos a Home já está na pilha, mas o mesmo mecanismo de navegação funciona igual, sem duplicar a Home).

**Explicitamente fora de escopo (evitar confusão com `functional.md` §5.3):**
- Este botão **não** altera `fluxo_atendimento.status` — não fecha (`status = fechado`) o Fluxo de Atendimento, apenas fecha a **tela**. "Finalizar Fluxo de Atendimento" (mudar o status para `fechado`) continua sem tela definida no plano atual.
- Nenhuma alteração em `Pedido` ou no comportamento das colunas do quadro.

## Botão "Sair" — Comportamento

Local: `lib/features/fluxo_atendimento/presentation/quadro_atendimento_screen.dart`, `AppBar.actions` de `_QuadroView`.

| Ação | Comportamento |
|---|---|
| Clique em "Sair" | Exibe `AlertDialog` de confirmação (ex.: título "Sair", mensagem "Deseja sair da execução deste fluxo de atendimento?"), com botões **Cancelar** e **Sair**. |
| Diálogo — Cancelar | Fecha o diálogo, permanece na Tela 4, sem nenhuma alteração. |
| Diálogo — Sair (confirmado) | Fecha o diálogo e navega para a Home (`HomeScreen`), substituindo toda a pilha de navegação (`Navigator.pushAndRemoveUntil(..., (route) => false)`), de forma que a Home sempre reflita o estado atual do banco (ela já recarrega a lista ao ser criada) e não haja como "voltar" para a Tela 4 pelo botão do sistema. |

O botão "Sair" é exibido sempre (independentemente de `fluxo.status` ser `aberto` ou `fechado`) — sair da tela não é uma operação de escrita, então não é afetado pela regra geral 2 (somente leitura quando `fechado`).

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] A Tela 4 exibe um botão "Sair" na `AppBar`, junto aos demais botões do header.
- [ ] Clique em "Sair" exibe o diálogo de confirmação.
- [ ] Diálogo — Cancelar: fecha o diálogo, permanece na Tela 4.
- [ ] Diálogo — Sair: fecha a Tela 4 e abre a Home, exibindo a lista de fluxos atualizada.
- [ ] Cenário 1 (Tela 4 aberta a partir da Splash, com um fluxo `aberto`, sem Home na pilha original): confirmar "Sair" ainda assim abre a Home corretamente, sem crash.
- [ ] Cenário 2 (Tela 4 aberta a partir da Home, clicando em um fluxo da lista): confirmar "Sair" volta para a Home sem duplicar a tela na pilha (botão de voltar do sistema, a partir da Home, sai do app — comportamento padrão de tela raiz).
- [ ] Sair de um fluxo `fechado` (somente leitura) também funciona normalmente.

## Fora de Escopo deste Passo

- Qualquer alteração em `fluxo_atendimento.status` ou nas regras de negócio de Pedido.
- Testes automatizados de UI — não obrigatórios para a validação deste passo.
