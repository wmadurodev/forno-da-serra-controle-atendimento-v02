# Passo 2 — Cadastro do Fluxo de Atendimento (Tela 3)

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Referências obrigatórias:** `docs/controle-atendimento-functional.md` §5.2 (criar novo fluxo), regra geral 1; `docs/controle-atendimento-data-structure.md` §2 (atributo `identificador`, **DS-1**); `docs/controle-atendimento-prototype.md` §3.3 (Tela 3).
> **Depende de:** Passo 1 (`prompts-impl/passo-01-app-base-splash-home.md`), concluído e validado.

## Objetivo

Implementar a Tela 3 (Cadastro do Fluxo de Atendimento), conectando-a de fato ao botão "Novo Fluxo" da Home (Tela 2), que hoje apenas exibe um `SnackBar` provisório. Ao confirmar o cadastro, um novo `fluxo_atendimento` com `status = aberto` é criado e o usuário é levado à Tela 4 (ainda a placeholder do Passo 1).

## Escopo deste Passo

**Incluído:**
- Tela 3 — Cadastro do Fluxo de Atendimento, completa.
- Repositório: uso do método `insert` já existente em `FluxoAtendimentoRepository` (`lib/features/fluxo_atendimento/data/fluxo_atendimento_repository.dart`), que já implementa a regra de unicidade de fluxo aberto (lança `StateError` se já existir um).
- Tratamento de erro de `identificador` duplicado (conflito de chave primária) ao inserir.
- Home (Tela 2): botão "Novo Fluxo" passa a navegar de verdade para a Tela 3, no lugar do `SnackBar` "Disponível a partir do Passo 2".

**Não incluído (fica para passos seguintes):**
- Edição do `identificador` de um fluxo já `aberto` fora da criação (**FN-3** permite alterar a qualquer momento enquanto `aberto`, não somente na criação — essa edição ocorre a partir da Tela 4 e será tratada no Passo 3, junto com o restante da Tela 4).
- Finalização (fechamento) de um Fluxo de Atendimento (`functional.md` §5.3) — sem passo definido ainda no plano; não faz parte deste passo.
- Quadro Kanban real da Tela 4 — Passo 3.

## Tela 3 — Cadastro do Fluxo de Atendimento

Local: `lib/features/fluxo_atendimento/presentation/cadastro_fluxo_screen.dart`.

Campo (`docs/controle-atendimento-prototype.md` §3.3, `data-structure.md` §2):

| Campo (UI) | Nome técnico | Tipo/Regras |
|---|---|---|
| Identificador | `identificador` | Texto, até 15 caracteres, obrigatório (não vazio). Pré-preenchido com sugestão da data corrente (formato livre — sem exigência específica, **DS-1**; usar um formato legível, ex. `dd/MM/yyyy`). Editável pelo usuário. |

Footer com dois botões: **Confirmar** e **Cancelar**.

| Ação | Comportamento |
|---|---|
| Cancelar | Descarta o formulário e volta para a Home (`Navigator.pop`), sem gravar nada. |
| Confirmar, campo vazio | Não envia; exibe erro de validação inline no campo (`TextFormField` + `Form`/`validator`), sem chamar o repositório. |
| Confirmar, campo preenchido, sem fluxo `aberto` existente | Cria o `fluxo_atendimento` (`status = aberto`, `identificador` informado) e navega (substituindo a rota, sem permitir "voltar" para a Tela 3) para a Tela 4 placeholder, passando o fluxo recém-criado. |
| Confirmar, já existe fluxo `aberto` (repositório lança `StateError`) | Exibe mensagem de erro ao usuário (ex. `SnackBar` ou texto inline: "Já existe um Fluxo de Atendimento aberto") — **FN-5**. Permanece na Tela 3, sem navegar. |
| Confirmar, `identificador` já usado por outro fluxo (conflito de chave primária no `insert`) | Captura a exceção do `sqflite` e exibe mensagem de erro (ex. "Já existe um Fluxo de Atendimento com este identificador"). Permanece na Tela 3, sem navegar. |

Durante a gravação (chamada ao repositório), desabilitar o botão **Confirmar** para evitar duplo clique.

## Home (Tela 2) — Ajuste

Em `lib/features/fluxo_atendimento/presentation/home_screen.dart`, substituir `_onNovoFluxo` (que hoje só mostra o `SnackBar`) por uma navegação real para a Tela 3:

```dart
void _onNovoFluxo(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const CadastroFluxoScreen()),
  );
}
```

Ao voltar da Tela 3 para a Home (via "Cancelar"), a lista de fluxos deve continuar refletindo o estado do banco (o `HomeController` já recarrega a lista no `initState`/criação — se o retorno da Tela 3 não disparar reload automático, adicionar um recarregamento em `didPopNext` ou recriando o `HomeController` ao voltar, o que for mais simples dado o Navigator 1.0 em uso, **IT-3**).

## Critérios de Aceite

- [ ] Na Home, clique em "Novo Fluxo" abre a Tela 3 (não exibe mais o `SnackBar` "Disponível a partir do Passo 2").
- [ ] Tela 3 abre com o campo Identificador pré-preenchido com a data corrente.
- [ ] Confirmar com o campo vazio (ex. apagando o valor sugerido) exibe erro de validação, sem navegar e sem gravar no banco.
- [ ] Confirmar com um identificador válido, banco sem fluxo aberto: cria o registro (`status = aberto`) e abre a Tela 4 placeholder com o identificador correto; voltar (botão do sistema) na Tela 4 não retorna à Tela 3.
- [ ] Com um fluxo `aberto` já existente no banco, abrir a Tela 3 e confirmar exibe a mensagem de erro de fluxo já aberto, permanecendo na Tela 3.
- [ ] Tentar criar um fluxo com um `identificador` já usado por outro fluxo (aberto ou fechado) exibe mensagem de erro de identificador duplicado, permanecendo na Tela 3.
- [ ] Ao voltar da Tela 3 para a Home via "Cancelar", a Home reflete corretamente o estado atual do banco (sem duplicar nem esconder itens).

## Fora de Escopo deste Passo

- Edição do `identificador` de um fluxo já `aberto` a partir da Tela 4 — Passo 3.
- Fechar (`status = fechado`) um Fluxo de Atendimento.
- Quadro Kanban real da Tela 4 (segue placeholder do Passo 1) — Passo 3.
- Testes automatizados de UI — não obrigatórios para a validação deste passo.
