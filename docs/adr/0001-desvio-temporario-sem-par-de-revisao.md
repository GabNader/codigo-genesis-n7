# 0001 — Desvio temporário: merge sem par de revisão

- Status: aceito (temporário)
- Data: 27/10/2026

## Contexto

O PGCS (3.3 e 5.2) exige que todo Pull Request para a `main` seja aprovado por outro
integrante antes do merge. A `main` está protegida com PR obrigatório, 1 aprovação e
*Do not allow bypassing*, valendo inclusive para administradores.

Na data da Aula 1 o projeto ainda **não tem par de revisão** com acesso de escrita. Como o
GitHub não permite aprovar o próprio PR, nenhum PR poderia entrar na `main`, inclusive o
que publica o próprio PGCS como item de configuração, exigido pela atividade.

## Decisão

1. Para o PR #1 (publicação do PGCS e da evidência da Aula 1), a regra da `main` passa
   **temporariamente** para 0 aprovações. Continuam valendo: PR obrigatório, histórico
   linear, *dismiss stale reviews* e sem exceção para administradores.
2. Logo após o merge, a regra volta para **1 aprovação**.
3. Assim que houver um par (preferencialmente um integrante da equipe do PAC), ele será
   adicionado como colaborador com permissão *write* e este ADR passa a "substituído".

## Alternativas consideradas

- **Segunda conta própria como revisor.** Descartada: os Termos do GitHub permitem só uma
  conta gratuita por pessoa e a "revisão" violaria a separação de funções do PGCS.
- **Push direto desativando *enforce admins*.** Descartada: além de pular a revisão,
  pularia também a exigência de Pull Request e não deixaria registro no fluxo.
- **Esperar um par.** Descartada para este PR porque o PGCS precisa estar publicado para a
  avaliação da Aula 1.

## Consequências

- O PR #1 entra sem revisão humana. O risco é baixo: a mudança é só documentação.
- O desvio fica registrado aqui, e não escondido numa configuração.

## Histórico de aplicações

| Data | PR | Mudança | Risco | Mitigação |
|---|---|---|---|---|
| 27/10/2026 | #1 | Publicação do PGCS e da evidência da Aula 1 | baixo (só documentação) | — |
| 23/11/2026 | #3 | Jogo completo conforme o GDD e GDD v2 (issue #2) | **alto**: reestrutura cenas e a mecânica central, o que pela seção 8.2 do PGCS aciona o CCM | 44 testes GUT, incluindo partidas completas por piloto automático (100 sementes sem travamento). Revisão humana pendente: assim que houver par, ele revisa o código já integrado e os ajustes entram por novo PR |
| 23/11/2026 | #5 | Feedback da professora: tutorial, custos gerados dos efeitos, história e áudio sintetizado (issue #4) | médio: não altera regras de economia nem a estrutura das cenas, mas muda a HUD e o áudio | 54 testes GUT, incluindo regressão do custo anunciado × descontado. Áudio ainda não ouvido por uma pessoa; o roteiro de teste de usabilidade fica pendente com a equipe |

Cada nova aplicação deste desvio deve ser acrescentada a esta tabela no próprio PR.
