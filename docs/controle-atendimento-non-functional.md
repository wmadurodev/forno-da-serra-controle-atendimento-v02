# Controle de Atendimento — Especificação Não Funcional

> **Fonte:** `docs/lixo-non-functional.txt` (requisitos brutos, reestruturados abaixo).
> **Escopo deste documento:** plataforma-alvo, modelo de persistência, mapeamento técnico das entidades para o banco local e implicações arquiteturais decorrentes da ausência de autenticação e da operação 100% offline.
> **Ver também:** `controle-atendimento-functional.md` (regras de negócio e máquina de estados) e `controle-atendimento-data-structure.md` (entidades e atributos referenciados aqui).

## 1. Visão Geral

A aplicação será um **app mobile** desenvolvido em **Flutter**, operando **100% offline**, sem nenhuma dependência de conectividade de rede para suas funcionalidades. Não haverá processo de **autenticação/autorização** — o app é de usuário único, sem tela de login e sem controle de identidade.

## 2. Plataforma e Stack Tecnológica

| Aspecto | Definição | Observações |
|---|---|---|
| Framework | Flutter | Aplicação mobile multiplataforma (ver **NF-1** quanto a quais SOs-alvo). |
| Persistência | SQLite (local, embarcado no dispositivo) | Único mecanismo de armazenamento de dados da aplicação. |
| Conectividade | Nenhuma exigida | A aplicação não deve depender de rede para nenhuma operação funcional descrita em `controle-atendimento-functional.md`. |
| Autenticação/Autorização | Inexistente | Não há login, usuários, papéis ou permissões. Ver §5. |
| Sincronização remota / backend | Inexistente | Não há API, backend ou sincronização entre dispositivos (ver **NF-2**). |

## 3. Operação Offline

- Todas as funcionalidades descritas em `controle-atendimento-functional.md` (criação, transição e consulta de Fluxos de Atendimento e Pedidos) devem funcionar **integralmente sem conexão de rede**, em qualquer momento.
- Não há tela ou fluxo de sincronização, upload remoto ou verificação de conectividade — a origem não menciona nenhum desses conceitos, portanto são tratados como **inexistentes**, não como "opcionais".
- Toda a persistência (Fluxo de Atendimento, Pedido, imagem do pedido) é local ao dispositivo. Não há backup automático nem exportação de dados especificados na origem (ver **NF-3**).

## 4. Modelo de Persistência (SQLite)

Este documento **não repete** a lista de entidades/atributos — a fonte única para nomes técnicos, tamanhos e obrigatoriedade de cada campo é `controle-atendimento-data-structure.md` §2 (Fluxo de Atendimento) e §3 (Pedido). Aqui está apenas a regra de tradução desses atributos para SQLite e as decisões específicas de persistência que a origem funcional não cobre.

### 4.1 Regra de Mapeamento de Tipos

| Tipo de negócio (`data-structure.md`) | Tipo SQLite | Observações |
|---|---|---|
| Texto | `TEXT` | Tamanho máximo (ex.: "50 caracteres") não é imposto pelo SQLite (tipagem dinâmica); validação de tamanho é responsabilidade da camada de aplicação. |
| Enumeração | `TEXT` + `CHECK (coluna IN (...))` | Valores fechados de cada enum vêm de `data-structure.md` §4 — não redefinidos aqui. |
| Booleano | `INTEGER` | Convenção SQLite: `0` = false, `1` = true. |
| Numérico monetário | `REAL` | Único caso: `valor_pix`. |
| Referência → outra entidade | `TEXT` + `FOREIGN KEY` | Único caso: `fluxo_atendimento_id` → `fluxo_atendimento(identificador)`. |
| Referência a imagem | `TEXT` | Caminho de arquivo local, não BLOB — ver §5. |
| Identificador (chave de negócio) | `TEXT` + `PRIMARY KEY` | Aplica-se a `fluxo_atendimento.identificador` e `pedido.identificador`. |

### 4.2 Regras Estruturais

- Uma tabela por entidade (`fluxo_atendimento`, `pedido`), sem tabelas de domínio separadas para as enumerações — resolvidas via `CHECK`, conforme §4.1. Introduzir tabelas de domínio seria over-engineering desnecessário para um app local, single-user.
- Todo atributo listado em `data-structure.md` §3 como `Condicional` ou "Sim, ao executar/devolver" (obrigatoriedade depende do estado do Pedido) é mapeado como coluna **nullable** — a obrigatoriedade não é uma constraint estática de coluna, e sim uma regra de transição de estado (`controle-atendimento-functional.md` §6.2), validada pela camada de aplicação antes de cada escrita.
- A regra "no máximo um Fluxo de Atendimento com `status = aberto`" (`data-structure.md` §2) também não é expressável como `CHECK`/`UNIQUE` de coluna — é validada em aplicação antes de qualquer `INSERT`/`UPDATE` que produza esse estado.

### 4.3 Índices sugeridos

Para suportar a busca de pedidos descrita em `controle-atendimento-functional.md` §5.5 (nome do cliente, identificador, mesa, endereço) dentro de um fluxo de atendimento:

- Índice em `pedido(fluxo_atendimento_id)` — toda busca ocorre no escopo de um fluxo selecionado.
- Índices adicionais nos demais campos de busca são opcionais e dependem do volume real de dados (não especificado na origem — ver **NF-4**).

## 5. Armazenamento da Imagem do Pedido

Resolve a pendência **DS-7** de `controle-atendimento-data-structure.md` à luz do requisito não funcional de operação 100% offline com SQLite:

- `imagem_pedido_ref` é armazenado como **caminho de arquivo local** (`TEXT`) apontando para um arquivo de imagem persistido no armazenamento do próprio dispositivo (diretório de dados da aplicação), **não** como BLOB dentro do SQLite e **não** como URL remota (não há backend — §2).
- A responsabilidade de gerenciar o ciclo de vida desse arquivo (gravação ao capturar/selecionar a imagem, remoção caso o pedido seja excluído) é da camada de aplicação; não é imposta pelo schema.

## 6. Ausência de Autenticação/Autorização

- A aplicação não implementa login, cadastro de usuários, sessões, papéis ou permissões diferenciadas.
- Todo ator descrito em `controle-atendimento-functional.md` §2 ("Atendente/Usuário do sistema") corresponde, na prática, a **qualquer pessoa com acesso físico ao dispositivo** — não há distinção de identidade em nenhuma camada da aplicação.
- Não há, portanto, nenhum requisito de controle de acesso, trilha de auditoria por usuário, ou log de "quem fez o quê" — a origem não menciona nenhum desses conceitos (ver **NF-5**).
- Consequência direta para o schema: nenhuma tabela ou coluna de auditoria por usuário é definida em §4.

## 7. Pendências / Assunções a validar com o negócio

| ID | Descrição | Interpretação adotada neste documento |
|---|---|---|
| NF-1 | A origem não especifica quais sistemas operacionais mobile são alvo (Android, iOS, ambos). | Não assumido; Flutter suporta ambos nativamente — definir antes da implementação/build. |
| NF-2 | A origem não menciona sincronização entre múltiplos dispositivos, nem se o app rodará em mais de um aparelho por estabelecimento. | Assumido como single-device, sem sincronização — cada instalação tem seu próprio banco SQLite isolado. |
| NF-3 | A origem não menciona backup, exportação ou recuperação de dados em caso de perda/troca de dispositivo. | Não assumido; dado o caráter 100% offline e sem backend, perda do dispositivo implica perda de dados salvo mecanismo a definir (ex.: backup nativo do SO). |
| NF-4 | A origem não especifica volume esperado de Fluxos de Atendimento/Pedidos, nem requisitos de performance (tempo de resposta, volume de dados no SQLite). | Não assumido; tratado como fora de escopo até definição do negócio. |
| NF-5 | A origem não menciona necessidade de log/auditoria de ações, apesar de o app permitir múltiplos usuários físicos sem distinção. | Assumido como não necessário, por ausência de qualquer menção na origem — revisar se auditoria mínima (ex.: por dispositivo) é desejável. |
| NF-6 | A origem não especifica o que ocorre com `imagem_pedido_ref` em caso de desinstalação do app ou limpeza de dados do SO. | Não assumido; comportamento padrão do SO (perda de dados do app) é o esperado, salvo indicação em contrário. |

## 8. Fora de Escopo deste Documento

- Regras de negócio, máquina de estados e validações funcionais: ver `controle-atendimento-functional.md`.
- Entidades, atributos e enumerações de domínio: ver `controle-atendimento-data-structure.md`.
- Layout de telas e protótipo de interface: ver `controle-atendimento-prototype.md` (pendente de elaboração).
