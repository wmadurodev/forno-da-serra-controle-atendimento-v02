# Passo 10 — Fechar Fluxo de Atendimento a partir da Home (Tela 2)

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-14. Implementa **"Finalizar Fluxo de Atendimento"** (`docs/controle-atendimento-functional.md` §5.3), regra de negócio já documentada mas sem tela/UI definida em `docs/controle-atendimento-prototype.md`.
> **Depende de:** Passo 1 (Home já implementada). Não depende dos Passos 3 a 9 nem os afeta.

## Objetivo

Permitir fechar (`status: aberto → fechado`) um Fluxo de Atendimento diretamente pela Home, sem precisar entrar na Tela 4. Regra de negócio (`functional.md` §5.3): "Um Fluxo de Atendimento `aberto` pode ser fechado pelo usuário a qualquer momento (não há pré-condição sobre o estado dos pedidos nele contidos)."

## Escopo deste Passo

**Incluído:**
- `FluxoAtendimentoRepository`: novo método `fechar(identificador)`.
- Ícone de fechamento na linha de cada fluxo `aberto` na lista da Home.
- Diálogo de confirmação por "arrastar para confirmar" (evitar fechamento acidental).
- Fechamento do diálogo por um ícone **X** no canto superior direito, sem confirmar nada.

**Não incluído:**
- Reabrir um fluxo `fechado` — não existe essa operação (`functional.md`, regra geral: no máximo um `aberto`; nada indica reabertura).
- Qualquer alteração em Pedido — fechar o fluxo não exige nenhuma pré-condição sobre os pedidos nele contidos (`functional.md` §5.3, explícito).

## `FluxoAtendimentoRepository` — Novo Método

```dart
Future<void> fechar(String identificador);
```

Atualiza `status = 'fechado'` para o fluxo com aquele `identificador`. Sem pré-condição adicional (a Home só oferece esta ação para fluxos já `aberto`).

## Home (Tela 2) — Ícone de Fechamento

Em `lib/features/fluxo_atendimento/presentation/home_screen.dart`: cada `ListTile` de um fluxo com `status = aberto` ganha um `trailing` com um `IconButton` (ícone de cadeado, ex. `Icons.lock_outline`, tooltip "Fechar Fluxo de Atendimento"). Fluxos `fechado` não exibem esse ícone (já estão fechados). O toque no ícone não deve disparar a navegação do `ListTile` (áreas de toque independentes).

Ao tocar no ícone: abre o diálogo de confirmação (`FecharFluxoDialog`, ver abaixo). Se confirmado, chama o fechamento e recarrega a lista da Home.

## Diálogo de Confirmação — "Arrastar para Confirmar"

Novo widget reutilizável: `lib/core/widgets/slide_to_confirm_button.dart` — um controle deslizante horizontal (uma "alça" circular dentro de uma trilha) que só dispara `onConfirmed` quando arrastado até o final (ex.: ≥ 90% do percurso); soltar antes disso volta a alça para o início, sem confirmar nada. Não depende de nenhum pacote externo — implementado com `GestureDetector`/`Positioned` sobre um `LayoutBuilder`.

Novo widget: `lib/features/fluxo_atendimento/presentation/fechar_fluxo_dialog.dart` (`FecharFluxoDialog`), exibido via `showDialog`:

- Um `Dialog` (não o `AlertDialog` padrão, para poder posicionar livremente o ícone de fechar) contendo:
  - Cabeçalho com o título ("Fechar Fluxo de Atendimento") e um ícone **X** no canto superior direito.
  - Texto explicativo, citando o `identificador` do fluxo, avisando que a ação não pode ser desfeita pela interface.
  - O `SlideToConfirmButton`.
- Ícone **X**: fecha o diálogo (`Navigator.pop(false)`), sem fechar o fluxo.
- Arrastar o controle até o final: fecha o diálogo confirmando (`Navigator.pop(true)`).

Na Home, após o diálogo retornar `true`: chamar `HomeController.fecharFluxo(fluxo)` (novo método, análogo a `load()`: chama o repositório e recarrega a lista).

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Fluxos `aberto` na Home exibem o ícone de fechamento; fluxos `fechado` não exibem.
- [ ] Tocar no ícone de fechamento abre o diálogo, sem disparar a navegação para a Tela 4 do fluxo correspondente.
- [ ] Arrastar o controle menos que o suficiente e soltar: a alça volta para o início, o diálogo permanece aberto, nada é alterado.
- [ ] Arrastar o controle até o final: fecha o diálogo e o fluxo passa a `fechado` na lista da Home (recarregada automaticamente).
- [ ] Ícone **X** no diálogo: fecha o diálogo sem alterar o fluxo.
- [ ] Um fluxo fechado por este mecanismo, se aberto na Tela 4 (Passo 3) depois, aparece corretamente em modo somente leitura (comportamento já existente desde o Passo 3).

## Fora de Escopo deste Passo

- Reabertura de um fluxo `fechado`.
- Qualquer alteração em `Pedido`.
- Testes automatizados de UI — não obrigatórios para a validação deste passo.
