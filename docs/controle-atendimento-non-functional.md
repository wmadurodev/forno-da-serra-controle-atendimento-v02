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

Mapeamento técnico das entidades definidas em `controle-atendimento-data-structure.md` §2–§4 para tabelas SQLite. Este mapeamento é uma tradução direta dos tipos de negócio para tipos de coluna SQLite — não introduz nem altera nenhuma regra funcional.

### 4.1 Tabela `fluxo_atendimento`

| Coluna | Tipo SQLite | Constraints | Origem (data-structure.md) |
|---|---|---|---|
| `identificador` | `TEXT` | `PRIMARY KEY` | §2, atributo `identificador` |
| `status` | `TEXT` | `NOT NULL`, `CHECK (status IN ('aberto', 'fechado'))` | §2, atributo `status` / §4.1 |

- A regra "no máximo um `aberto` simultaneamente" (§2, `controle-atendimento-data-structure.md`) é uma regra de **aplicação**, não expressável como `CHECK` de coluna — deve ser validada em código antes de qualquer `INSERT`/`UPDATE` que produza `status = 'aberto'`.

### 4.2 Tabela `pedido`

| Coluna | Tipo SQLite | Constraints | Origem (data-structure.md) |
|---|---|---|---|
| `identificador` | `TEXT` | `PRIMARY KEY` | §3, `identificador` |
| `fluxo_atendimento_id` | `TEXT` | `NOT NULL`, `FOREIGN KEY → fluxo_atendimento(identificador)` | §3, `fluxo_atendimento_id` |
| `status` | `TEXT` | `NOT NULL`, `CHECK (status IN (...))` — valores de §4.2 | §3, `status` |
| `cancelado` | `INTEGER` | `NOT NULL DEFAULT 0` (booleano como `0`/`1`, convenção SQLite) | §3, `cancelado` |
| `nome_cliente` | `TEXT` | `NULL` (obrigatório apenas na transição para `em_atendimento`, validado em aplicação) | §3, `nome_cliente` |
| `tipo_entrega` | `TEXT` | `NULL`, `CHECK (tipo_entrega IN ('delivery', 'retirada_balcao'))` | §3, `tipo_entrega` |
| `tipo_pagamento` | `TEXT` | `NULL`, `CHECK (tipo_pagamento IN ('pix', 'cartao', 'dinheiro'))` | §3, `tipo_pagamento` |
| `endereco` | `TEXT` | `NULL` (obrigatoriedade condicional, validada em aplicação — DS-4) | §3, `endereco` |
| `observacao` | `TEXT` | `NULL` | §3, `observacao` |
| `restricoes` | `TEXT` | `NULL` | §3, `restricoes` |
| `valor_pix` | `REAL` | `NULL` | §3, `valor_pix` |
| `mesa` | `TEXT` | `NULL` (obrigatório ao executar, validado em aplicação) | §3, `mesa` |
| `imagem_pedido_ref` | `TEXT` | `NULL` (obrigatório ao executar, validado em aplicação) — ver §5 deste documento quanto ao formato | §3, `imagem_pedido_ref` |
| `motivo_cancelamento` | `TEXT` | `NULL` | §3, `motivo_cancelamento` |
| `motivo_devolucao` | `TEXT` | `NULL` (obrigatório na transição `enviado → devolvido`, validado em aplicação) | §3, `motivo_devolucao` |

- Todos os campos "obrigatórios condicionalmente" (marcados como `Condicional` ou "Sim, ao executar/devolver" em `controle-atendimento-data-structure.md` §3) são mapeados como `NULL`-áveis no schema SQLite: a obrigatoriedade depende do estado do Pedido (máquina de estados) e **não pode ser expressa como constraint estática de coluna** — deve ser validada pela camada de aplicação antes de cada transição, conforme `controle-atendimento-functional.md` §6.2.
- Enumerações (`status` de ambas as tabelas, `tipo_entrega`, `tipo_pagamento`) são armazenadas como `TEXT` com `CHECK` explícito, refletindo os valores fechados definidos em `controle-atendimento-data-structure.md` §4. Não são usadas tabelas de domínio separadas (over-engineering desnecessário para um app local, single-user).

### 4.3 Índices sugeridos

Para suportar a busca de pedidos descrita em `controle-atendimento-functional.md` §5.5 (nome do cliente, identificador, mesa, endereço) dentro de um fluxo de atendimento:

- Índice em `pedido(fluxo_atendimento_id)` — toda busca ocorre no escopo de um fluxo selecionado.
- Índices adicionais em `nome_cliente`, `mesa` são opcionais e dependem do volume real de dados (não especificado na origem — ver **NF-4**).

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
