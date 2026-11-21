# AGENTS.md — Regra principal para todos os agentes

Este arquivo é a **regra principal** e se aplica a **todos os agentes** que mexerem neste
projeto, em qualquer modelo, sessão ou ferramenta. Vale também para trabalhos visuais,
código, documentação, testes e publicação. Em caso de conflito, prevalece apenas o que o
autor decidir explicitamente.

## Regra principal — auditoria, correção contínua e crítica extrema

> adicione como uma regra principal de todos agentes que mexerem nesse projeto, eles devem SEMPRE auditoriar suas implementações, caçando por erros ou coisas que esqueceu e imediatamente continuar corrigindo até ficar completamente entregável, deixando sempre uma crítica extrema sobre cada implementação, recomendações e melhorias propostas pro autor decidir, nada de coisas não verificadas, deve sempre verificar cada implementação minuciosamente

### Obrigações concretas

1. **Auditar sempre.** Antes de considerar qualquer trabalho concluído, auditar a
   própria implementação contra o requisito real e contra a proposta do jogo.
2. **Caçar erros e esquecimentos.** Procurar ativamente bugs, artefatos, inconsistências,
   casos não cobertos, coisas esquecidas e desvios em relação ao que foi pedido.
3. **Corrigir até ficar entregável.** Ao encontrar algo, corrigir imediatamente e repetir
   a auditoria. Não entregar com pendências que poderiam ser resolvidas na hora.
4. **Crítica extrema e recomendações.** Ao final de toda entrega, deixar uma crítica
   extrema da implementação, com recomendações e melhorias para o autor decidir. Nenhuma
   recomendação se torna regra sem decisão explícita do autor.
5. **Nada não verificado.** Nunca afirmar que algo está pronto, correto, aprovado ou
   testado sem evidência real. Verificar cada implementação minuciosamente.
6. **Validação visual pertence ao autor.** Capturas podem ser inspecionadas e
   apresentadas, mas a aprovação final do visual é exclusiva do autor.

## Evidência mínima antes de declarar pronto

- **Código:** executar parse/testes relevantes e conferir o diff antes de declarar pronto.
- **Visual:** abrir e inspecionar todas as vistas/quadros, caçar rasgos, cortes, má
  escala, elementos ausentes e desvios da referência; apresentar a captura e aguardar o
  julgamento do autor.
- **Documentação:** conferir que só as seções afetadas mudaram e que regras não afetadas
  foram preservadas.
- **Publicação:** conferir `git status`, commit, push e o conteúdo remoto antes de
  afirmar sincronização.

> Auditoria que só prova que o código roda não prova que ele está correto ou fiel ao
> desenho. "Parece certo" não é verificação.
