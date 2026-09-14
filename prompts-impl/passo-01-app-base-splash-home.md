# Passo 1 — Aplicação Base, Banco de Dados, Splash e Home

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Referências obrigatórias:** `docs/controle-atendimento-non-functional.md` (plataforma, persistência, ambiente de dev), `docs/controle-atendimento-data-structure.md` (entidades/atributos), `docs/controle-atendimento-functional.md` §5.1 (comportamento da inicialização), `docs/controle-atendimento-prototype.md` §2 (mapa de navegação), §3.1 (Tela 1 — Splash) e §3.2 (Tela 2 — Home).

## Objetivo

Criar o esqueleto funcional do app Flutter "Controle de Atendimento": projeto Android configurado, banco de dados SQLite com o schema completo, Tela 1 (Splash) com a lógica real de verificação de fluxo aberto, e Tela 2 (Home) com listagem real dos Fluxos de Atendimento — navegação ponta a ponta funcionando, usando uma tela de destino provisória (placeholder) para a Tela 4 (Execução do Fluxo de Atendimento), que será implementada de fato no Passo 3.

## Escopo deste Passo

**Incluído:**
- Estrutura do projeto Flutter em `code/frontend/controle-atendimento-app` (Android exclusivamente).
- Banco de dados SQLite completo — as duas tabelas (`fluxo_atendimento` e `pedido`), mesmo que a tabela `pedido` só passe a ser manipulada pela UI a partir do Passo 4.
- Tela 1 — Splash, completa.
- Tela 2 — Home, completa, exceto a navegação real para a Tela 3 (ver §"Tela 2 — Home" abaixo).
- Uma Tela 4 placeholder, apenas para permitir a navegação ponta a ponta.

**Não incluído (fica para passos seguintes):**
- Tela 3 (Cadastro do Fluxo de Atendimento) — Passo 2.
- Tela 4 completa (quadro Kanban) — Passo 3.
- Telas 5 a 9 e qualquer operação sobre Pedido — Passos 4 a 8.

## Estrutura do Projeto (IT-4)

```
lib/
  core/
    database/          # abertura do banco, criação do schema, helpers
    theme/              # ThemeData do app
    widgets/            # widgets compartilhados (ex.: loading indicator)
  features/
    fluxo_atendimento/
      data/              # repository (CRUD de fluxo_atendimento via sqflite)
      domain/            # modelo FluxoAtendimento
      presentation/
        splash_screen.dart
        home_screen.dart
        fluxo_atendimento_placeholder_screen.dart   # Tela 4 provisória
  main.dart
```

## Configuração do Projeto

- Nome de exibição do app (label do launcher): **"Controle de Atendimento"**.
- Nome técnico do pacote Flutter (`pubspec.yaml` → `name`): `controle_atendimento_app` (**IT-5**).
- Android `applicationId`: `com.fornodaserra.controleatendimento` (**IT-5**, ajustável).
- Gerar o projeto apenas para **Android** — remover os diretórios `ios/`, `web/`, `linux/`, `macos/`, `windows/` criados por padrão pelo `flutter create` (`docs/controle-atendimento-non-functional.md` **NF-1**, confirmado).
- SDK do Flutter gerenciado via `asdf`, usando a versão já fixada em `code/frontend/controle-atendimento-app/.tool-versions` (Flutter `3.47.4-stable`).
- Dependências principais a adicionar no `pubspec.yaml`:
  - `sqflite` e `path` — acesso ao banco SQLite local (**IT-2**).
  - `provider` — gerenciamento de estado (**IT-1**).

## Banco de Dados

Implementar o schema completo definido em `docs/controle-atendimento-non-functional.md` §4, com os nomes técnicos de `docs/controle-atendimento-data-structure.md`:

```sql
CREATE TABLE fluxo_atendimento (
  identificador TEXT PRIMARY KEY,
  status TEXT NOT NULL CHECK (status IN ('aberto', 'fechado'))
);

CREATE TABLE pedido (
  identificador TEXT PRIMARY KEY,
  fluxo_atendimento_id TEXT NOT NULL REFERENCES fluxo_atendimento(identificador),
  status TEXT NOT NULL CHECK (status IN (
    'aguardando_atendimento', 'em_atendimento', 'em_execucao',
    'retirado_no_balcao', 'enviado', 'entregue', 'devolvido'
  )),
  cancelado INTEGER NOT NULL DEFAULT 0,
  nome_cliente TEXT,
  tipo_entrega TEXT CHECK (tipo_entrega IN ('delivery', 'retirada_balcao')),
  tipo_pagamento TEXT CHECK (tipo_pagamento IN ('pix', 'cartao', 'dinheiro')),
  endereco TEXT,
  observacao TEXT,
  restricoes TEXT,
  valor_pagamento REAL,
  mesa TEXT,
  imagem_pedido_ref TEXT,
  motivo_cancelamento TEXT,
  motivo_devolucao TEXT
);

CREATE INDEX idx_pedido_fluxo_atendimento_id ON pedido(fluxo_atendimento_id);
```

Regra de aplicação a implementar já nesta etapa, no repositório de `fluxo_atendimento` (mesmo que só essa tabela seja manipulada pela UI neste passo):

- Antes de qualquer `INSERT`/`UPDATE` que resulte em `fluxo_atendimento.status = 'aberto'`, verificar em código que não existe outro registro com `status = 'aberto'` — regra de unicidade de `docs/controle-atendimento-data-structure.md` §2 (não expressável como constraint de coluna).

## Tela 1 — Splash

Comportamento (`docs/controle-atendimento-functional.md` §5.1, `docs/controle-atendimento-prototype.md` §3.1):

1. Ao iniciar, exibir indicação de carregamento (ex.: `CircularProgressIndicator`) com o nome do app.
2. Consultar o banco: existe `fluxo_atendimento` com `status = 'aberto'`?
3. **Se existir:** navegar (substituindo a rota, sem permitir "voltar" para a Splash) para a Tela 4 placeholder, passando o `identificador` desse fluxo.
4. **Se não existir:** navegar (substituindo a rota) para a Tela 2 (Home).

## Tela 2 — Home

Comportamento (`docs/controle-atendimento-prototype.md` §3.2):

- Listar todos os Fluxos de Atendimento (`aberto` e `fechado`), ordenados por `identificador` decrescente.
- Estado vazio: se não houver nenhum fluxo cadastrado, exibir uma mensagem simples (ex.: "Nenhum fluxo de atendimento cadastrado ainda").
- Botão **"Novo Fluxo"** visível (AppBar ou `FloatingActionButton`).

Ações:

| Ação | Operação nesta etapa |
|---|---|
| Clique em "Novo Fluxo" | A Tela 3 ainda não existe (Passo 2). Exibir um `SnackBar` com o texto "Disponível a partir do Passo 2" — o botão permanece visível, sem navegar. |
| Clique em um fluxo da lista | Navega para a Tela 4 placeholder, passando o `identificador` e o `status` do fluxo selecionado. |

## Tela 4 — Placeholder (Execução do Fluxo de Atendimento)

Implementação mínima nesta etapa, apenas para fechar a navegação ponta a ponta:

- `AppBar` mostrando o `identificador` do fluxo recebido por parâmetro.
- Corpo com um texto indicativo: "Quadro de pedidos — implementação prevista para o Passo 3".
- Sem nenhuma outra funcionalidade (sem botões, sem leitura da tabela `pedido`).

## Critérios de Aceite

- [ ] `flutter run` compila e executa em um dispositivo/emulador Android.
- [ ] O banco SQLite é criado na primeira execução, com as tabelas `fluxo_atendimento` e `pedido` e as constraints acima.
- [ ] Com o banco vazio: Splash → Home, exibindo o estado vazio.
- [ ] Inserindo manualmente um `fluxo_atendimento` com `status = 'aberto'` (ex.: via um teste automatizado do repositório, ou diretamente no arquivo do banco) e reiniciando o app: a Splash navega direto para a Tela 4 placeholder, com o `identificador` correto exibido.
- [ ] Com múltiplos fluxos cadastrados: a Home lista todos, ordenados por `identificador` decrescente.
- [ ] Clique em um item da lista da Home abre a Tela 4 placeholder com o `identificador` e o `status` corretos.
- [ ] Clique em "Novo Fluxo" exibe o `SnackBar` informativo, sem navegar nem quebrar o app.

## Fora de Escopo deste Passo

- Criação de novos Fluxos de Atendimento pela UI (Tela 3) — Passo 2.
- Qualquer leitura/escrita na tabela `pedido` pela UI — Passos 4 a 8.
- Quadro Kanban real (Tela 4 completa) — Passo 3.
- Testes automatizados de UI (widget/integration tests) — não solicitados nesta fase; testes unitários do repositório do banco são recomendados, mas não obrigatórios para a validação deste passo.
