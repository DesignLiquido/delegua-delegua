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

Projeto sem Node/npm (não há `package.json`). Compilação via toolchain LLVM de Delégua, orientada por `configuracao.delprops`:

```properties
compilacao.arquivoSaida=deldel
compilacao.pontoEntrada=fontes/execucao.delegua
compilacao.emitirDebug=verdadeiro
```

Comando exato do compilador ainda não documentado neste repositório.

## Pacote Pacoteca

Este repositório também é o pacote `delegua` da Pacoteca, descrito em `pacoteca.jsonc`. O ponto de entrada do pacote é `fontes/delegua.delegua`, que não tem efeitos colaterais; o executável `deldel` continua sendo gerado a partir de `fontes/execucao.delegua`.

API pública:

- `interpretar_codigo(codigo_fonte)`: executa um trecho de código Delégua.
- Classes `Lexador`, `AvaliadorSintatico` e `Interpretador`, para usar cada etapa separadamente.

Exemplo:

```delegua
importar { interpretar_codigo } de "delegua"

interpretar_codigo("var x = 10; escreva(x * 3);")
```

Uso das etapas separadamente:

```delegua
importar { Lexador, AvaliadorSintatico, Interpretador } de "delegua"

var lexador: Lexador = Lexador()
var retornoLexador = lexador.mapear("escreva(\"olá\");", 0)
var avaliadorSintatico: AvaliadorSintatico = AvaliadorSintatico()
var interpretador: Interpretador = Interpretador()
interpretador.interpretar(avaliadorSintatico.analisar(retornoLexador.simbolos).declaracoes)
```
