# AGENTS.md — Regra principal para todos os agentes

Este arquivo é a **cópia canônica** das regras obrigatórias e se aplica a **todos os
agentes** que mexerem neste projeto, em qualquer modelo, sessão ou ferramenta. Vale para
código, visual, documentação, testes e publicação. `CLAUDE.md` na raiz e as regras
globais do usuário apontam para este arquivo. Em caso de conflito, prevalece apenas o que
o autor decidir explicitamente.

## Regra principal — auditoria, correção contínua e crítica extrema

> adicione como uma regra principal de todos agentes que mexerem nesse projeto, eles devem SEMPRE auditoriar suas implementações, caçando por erros ou coisas que esqueceu e imediatamente continuar corrigindo até ficar completamente entregável, deixando sempre uma crítica extrema sobre cada implementação, recomendações e melhorias propostas pro autor decidir, nada de coisas não verificadas, deve sempre verificar cada implementação minuciosamente

## Obrigações concretas

1. **Auditar sempre.** Antes de considerar qualquer trabalho concluído, auditar a própria
   implementação contra o requisito real e contra a proposta do jogo.
2. **Caçar erros e esquecimentos.** Procurar ativamente bugs, artefatos, inconsistências,
   casos não cobertos, coisas esquecidas e desvios em relação ao que foi pedido.
3. **Corrigir até ficar entregável.** Ao encontrar algo, corrigir imediatamente e repetir
   a auditoria. Não entregar com pendências que poderiam ser resolvidas na hora.
4. **Crítica extrema com dimensões mínimas.** Toda entrega termina com crítica cobrindo,
   no mínimo: **correção, fidelidade ao design, bugs, omissões, regressões e riscos**, com
   **pelo menos um problema concreto** por implementação. Recomendações e melhorias são
   apresentadas ao autor; nenhuma se torna regra sem decisão explícita dele.
5. **Evidência anexada, não auto-declarada.** Toda alegação de verificação traz o comando
   executado, o resultado real e `git diff --stat` (ou `git status --short`); quando já
   houver commit, incluir também `git rev-parse HEAD`. "Auditei" sem evidência não conta
   como auditoria.
6. **Nada não verificado.** Nunca afirmar que algo está pronto, correto, aprovado ou
   testado sem evidência real. Verificar cada implementação minuciosamente.
7. **Validação visual pertence ao autor.** Capturas podem ser inspecionadas e
   apresentadas, mas a aprovação final do visual é exclusiva do autor.
8. **Sessões concorrentes.** Antes de qualquer commit, executar `git fetch origin --prune`,
   conferir `git status` e revelar decisões ou arquivos novos que apareceram. Nunca
   sobrescrever trabalho local ou remoto alheio; integrar por merge/rebase sem força.
9. **Parada e autoridade.** Parar somente quando não restar defeito identificável e toda
   pendência estiver explicitamente registrada para o autor. Conflito entre fontes de
   autoridade sobe ao autor antes de qualquer alteração de regra.
10. **Numeração de decisões.** Antes de registrar uma decisão nova, reservar o ID em
    `docs/DECISIONS.md` (índice canônico). Conflito com ID usado por outra sessão sobe
    ao autor; nunca renomear decisão alheia.

11. **Commit imediato ao concluir (D-120).** Concluído o trabalho de forma perfeita
    (auditado, testes passando, sem defeito identificável), commitar e dar push no mesmo
    instante, sem esperar nova autorização; seguir antes a obrigação 8 (fetch/status).

12. **Testes só na versão atual (D-130).** Testes headless e capturas rodam apenas sobre a
    árvore principal atualizada (`git fetch` + rebase em `main`). É proibido usar versões
    antigas do jogo — worktrees em `.claude/worktrees/*`, cópias como `captures/*/base`,
    branches `claude/*` atrasadas ou commits antigos — para testar, capturar ou provar algo.
    A evidência de teste cita o `git rev-parse HEAD` sobre o qual rodou.

13. **Protótipos VFX sempre com modo Aliados / 3 cartões Survival (D-137).** Todo
    protótipo visual HTML de ataque/VFX criado para aprovação do autor DEVE funcionar
    tanto com inimigos como alvo quanto nos **cartões dos aliados (3 cartões do modo
    Survival)**, exibindo o efeito diretamente sobre o(s) cartão(ões) no mesmo tamanho
    usado contra inimigos (sem recorte ao cartão), com seletor direto no protótipo.

## Evidência mínima por tipo de trabalho

- **Código:** comando de parse/teste + saída real + hash do diff antes de declarar pronto.
- **Visual:** abrir e inspecionar todas as vistas/quadros, caçar rasgos, cortes, má escala,
  elementos ausentes e desvios da referência; apresentar a captura e aguardar o autor.
- **Documentação:** conferir que só as seções afetadas mudaram e que regras não afetadas
  foram preservadas.
- **Publicação:** conferir `git status`, commit, push e o conteúdo remoto antes de afirmar
  sincronização.

> Auditoria que só prova que o código roda não prova que ele está correto ou fiel ao
> desenho. "Parece certo" não é verificação.
