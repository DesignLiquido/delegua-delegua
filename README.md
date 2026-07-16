# delegua-delegua

Repositório para construir um interpretador de Delégua escrito na própria linguagem Delégua.

## Objetivo

Este projeto organiza o caminho para:

1. Produzir um interpretador auto-hospedado (Delégua interpretando Delégua).
2. Provar cobertura semântica da linguagem com suíte de conformidade.
3. Reutilizar os mesmos programas de teste para validar o compilador em LLVM.

## Princípios

- Uma única fonte de verdade para semântica: AST + regras de execução + suíte de testes.
- Primeiro corretude, depois desempenho.
- Cada etapa deve deixar artefatos reproduzíveis e auditáveis.

## Configuração inicial

```bash
npm install
npm run desenvolver
npm run verificar
```

## Documentação

- Estratégia geral: `docs/roteiro-auto-hospedagem.md`
- Arquitetura alvo: `docs/arquitetura-autointerpretador.md`
- Pendências de execução: `docs/pendencias-mvp.md`

## Primeiras entregas esperadas

1. Definir gramática e AST mínima para um subconjunto executável.
2. Criar suíte de conformidade em Delégua.
3. Implementar motor de execução e interpretador de AST no próprio Delégua.
4. Executar auto-hospedagem em múltiplos estágios.
