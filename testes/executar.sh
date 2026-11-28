#!/usr/bin/env sh
# Executa cada testes/execucao/*.delegua com o deldel e compara com o esperado:
#   <caso>.saida  saída padrão esperada (opcional; ausente = vazia)
#   <caso>.erro   saída de erro esperada; se existir, o código de saída esperado é 1 (senão, 0)
#
# Uso, a partir da raiz do repositório:
#   testes/executar.sh                 # usa fontes/deldel(.exe), já compilado
#   DELDEL=/caminho/deldel testes/executar.sh
#
# Para compilar antes: node <delegua-llvm>/dist/ilc.js  (lê configuracao.delprops)

cd "$(dirname "$0")/.." || exit 2

if [ -z "$DELDEL" ]; then
    if [ -x fontes/deldel.exe ]; then DELDEL=fontes/deldel.exe; else DELDEL=fontes/deldel; fi
fi
if [ ! -x "$DELDEL" ]; then
    echo "deldel não encontrado em $DELDEL. Compile com o delegua-llvm antes." >&2
    exit 2
fi

temporario=$(mktemp -d)
trap 'rm -rf "$temporario"' EXIT

total=0
falhas=0
for caso in testes/execucao/*.delegua; do
    base=${caso%.delegua}
    nome=$(basename "$base")
    total=$((total + 1))

    "$DELDEL" "$caso" > "$temporario/saida" 2> "$temporario/erro"
    codigo=$?

    codigoEsperado=0
    [ -f "$base.erro" ] && codigoEsperado=1

    saidaObtida=$(tr -d '\r' < "$temporario/saida")
    saidaEsperada=""
    [ -f "$base.saida" ] && saidaEsperada=$(tr -d '\r' < "$base.saida")
    erroObtido=$(tr -d '\r' < "$temporario/erro")
    erroEsperado=""
    [ -f "$base.erro" ] && erroEsperado=$(tr -d '\r' < "$base.erro")

    if [ "$codigo" -ne "$codigoEsperado" ] || [ "$saidaObtida" != "$saidaEsperada" ] || [ "$erroObtido" != "$erroEsperado" ]; then
        falhas=$((falhas + 1))
        echo "FALHOU: $nome (código $codigo, esperado $codigoEsperado)"
        if [ "$saidaObtida" != "$saidaEsperada" ]; then
            echo "  saída esperada:"; echo "$saidaEsperada" | sed 's/^/    /'
            echo "  saída obtida:"; echo "$saidaObtida" | sed 's/^/    /'
        fi
        if [ "$erroObtido" != "$erroEsperado" ]; then
            echo "  erro esperado:"; echo "$erroEsperado" | sed 's/^/    /'
            echo "  erro obtido:"; echo "$erroObtido" | sed 's/^/    /'
        fi
    else
        echo "ok: $nome"
    fi
done

echo "$((total - falhas))/$total casos passaram."
[ "$falhas" -eq 0 ]
