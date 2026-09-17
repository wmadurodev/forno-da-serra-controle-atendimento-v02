# Passo 46 — Footer de navegação (Tela 4): esconder a contagem quando for zero

> Prompt de implementação. Parte do plano em `prompts-impl/00-plano-geral.md` (ver ali as decisões técnicas **IT-1** a **IT-6**, válidas para todos os passos).
> **Origem:** acréscimo solicitado diretamente pelo usuário desta iniciativa de implementação, em 2026-09-17. Sem correspondência em `docs/`.
> **Depende de:** Passo 25 (navegador de fases do footer), Passo 40 (selo de contagem sobreposto ao ícone, round 3).

## Objetivo

No footer de navegação da Tela 4 (os 7 ícones de fase, um por status do Pedido — não confundir com o footer de ação, ver nomenclatura do Passo 42), cada ícone mostra um selo com a quantidade de Pedidos naquele status. Esse selo deve aparecer **somente** quando a quantidade for maior que zero — hoje ele aparece sempre, inclusive mostrando "0".

## Levantamento

`quadro_atendimento_screen.dart`, método `_iconeFase(status, icone, quantidade)`: o `Stack` que desenha o ícone tem, como segundo filho, um `Positioned` incondicional com o `Container` do selo (círculo laranja com o número em branco) — ver a partir da declaração `Positioned(right: -4, top: -4, ...)`. Não há hoje nenhuma condição sobre `quantidade`.

## Alteração

Em `_iconeFase`, envolver esse `Positioned` num `if (quantidade > 0) ...` dentro da lista de filhos do `Stack` — quando a quantidade for zero, o `Stack` simplesmente não desenha o selo, mostrando só o círculo do ícone. Nenhuma outra mudança (cor, tamanho, animação, destaque do ícone ativo) é afetada.

## Critérios de Aceite

- [ ] `flutter analyze` sem problemas; app compila e roda em dispositivo/emulador Android.
- [ ] Na Tela 4, uma fase sem nenhum Pedido (quantidade zero) não mostra selo de contagem no ícone do footer de navegação.
- [ ] Uma fase com um ou mais Pedidos continua mostrando o selo normalmente, com o número correto.
- [ ] Nenhuma mudança no footer de ação (Passo 40/42) nem no destaque do ícone ativo (Passo 28/40).

## Fora de Escopo deste Passo

- Contagens em qualquer outro lugar do app (cabeçalho de coluna do Kanban, Busca de Pedidos) — só o selo do footer de navegação é afetado.
