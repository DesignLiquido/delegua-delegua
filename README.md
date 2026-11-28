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

Compilação, a partir da raiz do repositório (o `delegua-llvm` lê `configuracao.delprops`):

```sh
delegua-llvm                                  # ou: node <delegua-llvm>/dist/ilc.js
./fontes/deldel programa.delegua              # fontes/deldel.exe no Windows
```

O módulo `criptografia` liga o OpenSSL. No Windows, o clang da distribuição oficial do LLVM (alvo MSVC) não encontra o OpenSSL; use o clang do [MSYS2](https://www.msys2.org) UCRT64 (`pacman -S mingw-w64-ucrt-x86_64-clang mingw-w64-ucrt-x86_64-openssl`) como compilador C e deixe a DLL do OpenSSL ao lado do executável (ou `C:\msys64\ucrt64\bin` no `PATH`):

```sh
node <delegua-llvm>/dist/ilc.js --compilador-c C:/msys64/ucrt64/bin/clang.exe
cp C:/msys64/ucrt64/bin/libcrypto-3-x64.dll fontes/
```

## Uso do `deldel`

`deldel <arquivo.delegua>` executa o programa. `deldel testar [diretorio] [--interpretador comando]` executa os testes `*.teste.delegua` com o executor do pacote [`testes`](https://github.com/DesignLiquido/testes-delegua), procurado como um `importar ... de "testes"` (em `pacotes/llvm/testes` ou `pacotes/node/testes`). Erros vão para a saída de erro no formato `[CODIGO] arquivo:linha mensagem` e o código de saída é 1 (2 sem argumento):

```text
[E_LEXADOR] programa.delegua:2 Texto não finalizado.
[E_SINTATICO] programa.delegua:1 Recurso ainda não suportado pelo deldel: 'classe'.
[E_EXECUCAO] programa.delegua:2 Variável não definida: 'naoExiste'.
```

Recursos suportados:

- declarações: `var`, `constante`/`const`, `funcao` (com recursão), anotações de tipo (`x: texto`, `): lógico`, `número[]` — lidas e ignoradas), `;` opcional, comentários `//` e `/* */`, identificadores e palavras reservadas acentuados (`senão`, `não`, `ação`);
- controle: `se`/`senao`, `enquanto`, `fazer { } enquanto condicao`, `escolha valor { caso a: ... caso b: caso c: ... padrao: ... }` (sem passagem para o caso seguinte; casos vazios seguidos compartilham o corpo), `para (inicio; condicao; passo)` com ou sem parênteses, `para cada x em ...` (vetor, texto, dicionário) e `para cada {chave, valor} em dicionario`, `continua`, `sustar`/`quebrar`, `retorna`;
- expressões: aritmética (`**` à direita e acima do menos unário: `-2 ** 2` é -4), lógica (`e`, `ou`, `não`/`!`), ternário `c ? a : b`, `a ?: b` (b quando a é nulo), bits (`&`, `|`, `^`, `~`, `<<`, `>>`), pertinência (`x em colecao`, `colecao contem x`), igualdade por tipo (vetores, dicionários e tuplas por referência), comparação de textos, `+=` e afins, `++`/`--` (antes e depois), `tipo de x`, `+` que junta como texto quando um lado é texto ou lógico, formatação `"%s=%d %.2f %%" % [a, b, c]`;
- tuplas: `(1, 2)`, `(5,)`, índice, `paraVetor()`;
- vetores e dicionários: literais, índice (negativo conta do fim), atribuição por índice, referência compartilhada; `dicionario.chave` (leitura, atribuição e chamada de função guardada na chave);
- textos com interpolação: `"Olá, ${nome}! ${1 + 2}"`;
- classes: `classe Nome [herda Pai] { campo: tipo  construtor(...) {...}  metodo(...) {...} }`, instanciação por chamada (`Nome(...)`), `isto`, `super(...)` e `super.metodo(...)`, propriedades lidas, atribuídas e chamadas quando guardam funções, encadeamento (`retorna isto`), modificadores (`publico`, `privado`...) aceitos e ignorados; `classe abstrata` e blocos `abstrato { metodo() }` (não instanciáveis; subclasses concretas precisam implementar os métodos); `implementa Interface1, Interface2` (verificado na declaração); `mescla Classe1, Classe2` (métodos e propriedades sem herança; os da classe têm prioridade); `objeto.eInstanciaDe(ClasseOuInterface)`; sobrecarga de operadores binários com `operador +(outro) { ... }` (também `==`, `*`, `<`...); `classe estrangeira` (sem biblioteca de FFI: funciona como classe abstrata);
- interfaces: `interface Nome [herda Outra] { propriedade: tipo  metodo(parametros): tipo }`;
- extensões: `extensão [global] de Tipo { metodo() { ... isto ... } }` para `texto`, `número`, `lógico`, `vetor`, `dicionário`, `tupla` ou classes;
- `asserção condicao`, `asserção(condicao, "mensagem")`;
- funções anônimas `funcao(x) { ... }` com captura de variáveis (fechamentos), funções em vetores, dicionários e propriedades, parâmetro variádico `...nome`, valores padrão de parâmetros (`funcao f(a, b = 1)`, avaliados na chamada);
- exceções: `tente { } pegue (erro) { } finalmente { }` (`pegue` sem variável também; várias cláusulas `pegue (erro: Tipo)`, vale a primeira cujo tipo — classe ou superclasse, ou `Excecao` — corresponde), `falhar valor` (objetos são lançados como estão; outros valores viram `Excecao` com `mensagem`); erros de execução do interpretador também são capturáveis, com `erro.mensagem`;
- primitivas de vetor: `tamanho`, `adicionar`/`empilhar`, `removerUltimo`, `removerPrimeiro`, `inclui`/`contem`, `juntar`, `fatiar`, `concatenar`, `encaixar`, `inverter` e `ordenar([comparador])` (no próprio vetor), `remover(valor)`, `filtrarPor`, `mapear`, `somar`, `paraTupla`;
- primitivas de dicionário: `tamanho`, `contem`, `remover`, `chaves`, `valores`, `itens` (tuplas), `obter(chave[, padrao])`, `mesclar`/`concatenar`;
- primitivas de número: `absoluto`, `arredondarParaBaixo`, `arredondarParaCima`;
- primitivas de texto (contam caracteres, inclusive acentuados): `tamanho`, índice, `dividir`, `aparar`, `apararInicio`, `apararFim`, `maiusculo`, `minusculo`, `concatenar`, `inclui`/`contem`, `terminaCom`, `encontrar`, `subtexto`, `fatiar`, `substituir` (primeira ocorrência), `inverter`;
- nativas: `escreva` (vários argumentos), `tamanho`, `texto`, `numero`, `inteiro`, `real`, `longo`, `tipo`, `concatenar`, `leia`, `arredondar(n, casas)`, `aleatorio`, `aleatorioEntre`, `intervalo`, `clonar` (profundo), `tupla`, `vetor`, `somar`, `maximo`, `minimo`, `ordenar`, `incluido`, `reduzir`, `mapear`, `filtrarPor`, `paraCada`, `algum`, `todos`/`todosEmCondicao`, `encontrar`/`primeiroEmCondicao`, `encontrarIndice`, `encontrarUltimo`, `encontrarUltimoIndice`;
- módulos: `importar tudo como m de "./arquivo.delegua"` (acesso `m.nome`), `importar { a, b } de "..."`, `var m = importar("...")`; caminhos relativos ao arquivo que importa (`.delegua` opcional); pacotes da Pacoteca por nome (`importar { f } de "pacote"`), procurados em `pacotes/llvm/<nome>` e `pacotes/node/<nome>` subindo a partir do arquivo, pelo `pontoDeEntrada` do `pacoteca.jsonc`. Cada módulo executa uma vez, em escopo próprio; importações circulares recebem o módulo ainda incompleto. Erros dentro de um módulo informam o arquivo e a linha do módulo.

Módulos nativos, com a interface do delegua-node: `arquivos` (`existe`, `eArquivo`, `eDiretorio`, `lerTexto` — nulo se não existir —, `escreverTexto`, `criarDiretorio`, `remover`, `renomear`, `listarDiretorio`, `juntarCaminhos`, `diretorioPai`, `nomeBase`, `caminhoAbsoluto`, `diretorioAtual`, `diretorioPessoal`), `processo` (`sair`, `escreverErro`, `variavelAmbiente` — nulo se não definida —, `definirVariavelAmbiente`, `executar`, `executarCapturando`, `ultimoCodigoSaida`, `sistemaOperacional`, `arquitetura`), `argumentos` (argumentos depois do arquivo `.delegua`, `--` inicial ignorado: `quantidade`, `argumentos`, `argumentosNomeados`, `temArgumento`, `obterArgumento` para `--nome valor`/`--nome=valor`/`-x valor`, `argumento(i)`, `quantidadeArgumentos`), `tempo` (`carimboDeTempoUnix`, `carimboDeTempoUnixMilissegundos`, `monotonicoMilissegundos`, `dormir`) e `rede` (`escutar`, `portaLocal`, `aceitar`, `conectar`, `ler`, `lerAte`, `escrever`, `escreverArquivo`, `fechar`, `ultimoErro`, `codificarComponenteUrl`, `decodificarComponenteUrl`). `rede.escreverArquivo` lê o arquivo como texto (o delegua-llvm ainda não tem a função), então não serve para arquivos com bytes nulos. `criptografia` (`codificarBase64`, `decodificarBase64`, `md5`, `sha1`, `sha256`, `sha512`, `hmacSha256`, `hmacSha512`, `gerarUuid`, `gerarTextoAleatorio` — hexadecimal de n bytes, como no delegua-node) usa o OpenSSL.

Funções executam sobre os escopos de onde foram declaradas (escopo léxico): uma função de módulo enxerga as declarações do módulo, e não as variáveis de quem a chama.

Diferenças conhecidas em relação ao núcleo de Delégua (além de mensagens de erro mais detalhadas): `tipo de` uma função é `função` (o núcleo infere o retorno, como `função<número>`); algumas nativas do núcleo têm defeitos que o deldel não reproduz (no núcleo, `todos` devolve verdadeiro mesmo com elementos que não atendem, `encontrar`/`encontrarIndice`/`primeiroEmCondicao` devolvem valores errados, `ordenar` ignora a função de comparação e `concatenar` só usa o primeiro argumento); números fracionários são mostrados com 6 algarismos significativos; tipos não são verificados.

Ainda não suportados: herança de várias classes (`herda A, B`; use `mescla`), chamadas reais por FFI em `classe estrangeira` (carregar bibliotecas nativas), membros estáticos, obtenedores/definidores, sobrecarga de operadores unários; `extensão` sem `global` vale em todos os módulos (no núcleo, só no módulo que a declara); e os demais módulos nativos (`matematica`, `json`... — erro `Módulo nativo ainda não suportado`).

## Testes

```sh
testes/executar.sh        # compara cada testes/execucao/*.delegua com .saida/.erro
```

Cada caso tem a saída esperada em `<caso>.saida` e, para casos de erro, a saída de erro esperada em `<caso>.erro` (código de saída esperado 1).

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
