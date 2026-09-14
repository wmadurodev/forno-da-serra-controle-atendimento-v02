# Controle de Atendimento — Plano de Implementação

> **Escopo deste documento:** controlar a execução faseada da implementação do app "Controle de Atendimento", garantindo rastreabilidade entre as decisões documentadas em `docs/*.md` e o código gerado.
> Cada passo tem um prompt de implementação dedicado em `prompts-impl/passo-NN-<slug>.md`. Um novo prompt só é criado depois que o passo anterior estiver implementado e validado manualmente.

## 1. Visão Geral

| Aspecto | Definição |
|---|---|
| Nome de exibição do app | **Controle de Atendimento** |
| Plataforma | Flutter, **Android** exclusivamente, 100% offline, sem autenticação (`docs/controle-atendimento-non-functional.md`) |
| Persistência | SQLite local (`docs/controle-atendimento-non-functional.md` §4) |
| Código-fonte final | `code/frontend/controle-atendimento-app` |
| Gerenciamento de estado | **Provider** — decisão técnica desta iniciativa de implementação, ver **IT-1** |

## 2. Documentos de Referência

| Documento | Conteúdo relevante para a implementação |
|---|---|
| `docs/controle-atendimento-functional.md` | Regras de negócio, máquina de estados do Pedido, critérios de validação. |
| `docs/controle-atendimento-data-structure.md` | Entidades, atributos, nomes técnicos (`snake_case`), enumerações. |
| `docs/controle-atendimento-non-functional.md` | Plataforma, mapeamento SQLite, ambiente de desenvolvimento (asdf, Android SDK). |
| `docs/controle-atendimento-prototype.md` | Telas, navegação, campos de UI, cards do quadro Kanban. |

## 3. Decisões Técnicas de Implementação (IT-*)

Decisões que não vêm da documentação funcional/não funcional, tomadas para viabilizar a implementação. Servem de referência para todos os passos — não devem ser repetidas em cada prompt de passo.

| ID | Decisão |
|---|---|
| IT-1 | Gerenciamento de estado: **Provider**. |
| IT-2 | Acesso ao SQLite: pacote **sqflite** (+ `path`/`path_provider` para localizar o arquivo do banco e as imagens). |
| IT-3 | Navegação: **Navigator 1.0** (`MaterialPageRoute`, push/pop) — sem roteamento declarativo, dado o número reduzido de telas e a ausência de deep-linking (app 100% offline, single-user). |
| IT-4 | Estrutura de pastas **feature-first**: `lib/features/<feature>/{data,domain,presentation}`, com `lib/core` para itens compartilhados (banco de dados, tema, widgets comuns). |
| IT-5 | Nome técnico do pacote Flutter (`pubspec.yaml`): `controle_atendimento_app`. Android `applicationId`: `com.fornodaserra.controleatendimento` (ajustável, sem impacto no domínio funcional). |
| IT-6 | SDK do Flutter fixado via `asdf` em `code/frontend/controle-atendimento-app/.tool-versions` (já commitado). |

## 4. Passos do Plano

| Passo | Nome | Depende de | Status | Prompt |
|---|---|---|---|---|
| 1 | Aplicação base, banco de dados, Splash e Home | — | **Concluído e validado** (2026-09-14) | `prompts-impl/passo-01-app-base-splash-home.md` |
| 2 | Cadastro do Fluxo de Atendimento (Tela 3) | Passo 1 | **Concluído e validado** (2026-09-14) | `prompts-impl/passo-02-cadastro-fluxo-atendimento.md` |
| 3 | Execução do Fluxo de Atendimento — quadro Kanban (Tela 4) | Passos 1, 2 | **Concluído e validado** (2026-09-14) | `prompts-impl/passo-03-quadro-atendimento.md` |
| 4 | Cadastro de Pedido (Tela 5), integrado ao Kanban do Passo 3 | Passo 3 | **Concluído e validado** (2026-09-14) | `prompts-impl/passo-04-cadastro-pedido.md` |
| 5 | Execução de Pedido (Tela 6), integrado ao Kanban do Passo 3 | Passos 3, 4 | **Concluído e validado** (2026-09-14) | `prompts-impl/passo-05-execucao-pedido.md` |
| 6 | Edição de Pedido em Execução (Tela 9), integrado ao Kanban do Passo 3 | Passos 3, 5 | **Concluído e validado** (2026-09-14) | `prompts-impl/passo-06-edicao-pedido-execucao.md` |
| 7 | Cancelamento de Pedido (Tela 7), integrado ao Kanban do Passo 3 | Passo 3 | **Concluído e validado** (2026-09-14) | `prompts-impl/passo-07-cancelamento-pedido.md` |
| 8 | Devolução de Entrega (Tela 8), integrado ao Kanban do Passo 3 | Passos 3, 5 | **Em especificação** | `prompts-impl/passo-08-devolucao-entrega.md` |
| 9 | Botão "Sair" no header da Tela 4 (Execução do Fluxo de Atendimento) | Passo 3 | **Em especificação** | `prompts-impl/passo-09-sair-quadro-atendimento.md` |
| 10 | Fechar Fluxo de Atendimento a partir da Home (Tela 2) | Passo 1 | **Em especificação** | `prompts-impl/passo-10-fechar-fluxo-atendimento.md` |
| 11 | Melhorias na Home (Tela 2): nova chave sequencial de ordenação, layout em cards, novo ícone de fechamento, cor de fundo dos fluxos fechados, exclusão total de fluxo + pedidos | Passos 1, 10 | **Em especificação** | `prompts-impl/passo-11-melhorias-home.md` |

> Numeração de telas conforme `docs/controle-atendimento-prototype.md` §1 (Telas 1–9). Os Passos 9, 10 e 11 são acréscimos de UI solicitados diretamente pelo usuário desta iniciativa de implementação — o Passo 9 não corresponde a nenhuma tela numerada do protótipo; o Passo 10 implementa "Finalizar Fluxo de Atendimento" (`docs/controle-atendimento-functional.md` §5.3), que nunca teve uma tela definida no protótipo original; o Passo 11 introduz melhorias de UI e uma nova chave técnica de ordenação na Home, sem correspondência prévia em nenhum dos documentos de `docs/` (ver os respectivos prompts de passo).

## 5. Fluxo de Trabalho por Passo

1. Este documento é atualizado com o status **"Em especificação"** para o passo.
2. É criado `prompts-impl/passo-NN-<slug>.md` com o prompt de implementação detalhado do passo.
3. O prompt é executado — implementação em `code/frontend/controle-atendimento-app`.
4. O usuário valida manualmente o resultado (dispositivo/emulador Android).
5. Status atualizado para **"Concluído e validado"** neste documento, com a data da validação.
6. O próximo passo é especificado (volta ao item 1).

## 6. Status Atual

- **Passo 1:** concluído e validado em 2026-09-14 — implementado em `code/frontend/controle-atendimento-app`, testado em dispositivo Android real.
- **Passo 2:** concluído e validado em 2026-09-14.
- **Passo 3:** concluído e validado em 2026-09-14.
- **Passo 4:** concluído e validado em 2026-09-14.
- **Passo 5:** concluído e validado em 2026-09-14.
- **Passo 6:** concluído e validado em 2026-09-14.
- **Passo 7:** concluído e validado em 2026-09-14.
- **Passo 8:** em especificação — prompt criado em `prompts-impl/passo-08-devolucao-entrega.md`, aguardando implementação e validação. Último passo do plano original (telas do protótipo).
- **Passo 9:** em especificação — prompt criado em `prompts-impl/passo-09-sair-quadro-atendimento.md`, aguardando implementação e validação. Acréscimo solicitado pelo usuário em 2026-09-14, fora da numeração original de telas.
- **Passo 10:** em especificação — prompt criado em `prompts-impl/passo-10-fechar-fluxo-atendimento.md`, aguardando implementação e validação. Acréscimo solicitado pelo usuário em 2026-09-14: implementa "Finalizar Fluxo de Atendimento" (`functional.md` §5.3) a partir da Home, algo que não tinha tela nem UI definida até então.
- **Passo 11:** em especificação — prompt criado em `prompts-impl/passo-11-melhorias-home.md`, aguardando implementação e validação. Acréscimo solicitado pelo usuário em 2026-09-14: nova chave sequencial `id` em `fluxo_atendimento` para ordenação real por criação (substitui a ordenação por `identificador`, que é texto livre editável), layout em cards com novo background, troca do ícone de fechamento, cor de fundo diferenciada para fluxos fechados, e exclusão total (hard delete em cascata) de um Fluxo de Atendimento e seus Pedidos.
