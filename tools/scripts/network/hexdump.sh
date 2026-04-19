#!/usr/bin/env bash
# =============================================================================
# hexdump.sh — Inspetor de bytes em hexadecimal
# =============================================================================
#
# Descrição:
#   Lê um arquivo binário (ou stdin) e exibe seu conteúdo em três colunas:
#     - Offset em hexadecimal (posição do byte no arquivo)
#     - Bytes em hexadecimal (agrupados por colunas configuráveis)
#     - Representação ASCII (bytes não imprimíveis aparecem como '.')
#
# Dependências:
#   dd, od, awk  — presentes em qualquer Linux/macOS por padrão
#
# Uso:
#   ./hexdump.sh [opções] [arquivo]
#   echo "dados" | ./hexdump.sh [opções]
#
# Opções:
#   -n N   Lê no máximo N bytes do arquivo (padrão: arquivo inteiro)
#   -s N   Pula os primeiros N bytes antes de começar a leitura
#   -c N   Número de bytes exibidos por linha (padrão: 16)
#   -h     Exibe esta ajuda e sai
#
# Exemplos:
#   ./hexdump.sh arquivo.bin
#   ./hexdump.sh -n 64 arquivo.bin          # primeiros 64 bytes
#   ./hexdump.sh -s 128 -n 32 arquivo.bin   # 32 bytes a partir do offset 128
#   ./hexdump.sh -c 8 arquivo.bin           # 8 bytes por linha
#   echo "Hello World" | ./hexdump.sh       # via stdin
#   cat arquivo | xxd -r -p | ./hexdump.sh  # converte hex texto antes
#
# Saída esperada:
#   00000000  48 65 6c 6c 6f 20 57 6f  72 6c 64 0a              |Hello World.|
#
# Autor:   3S00mc  <https://github.com/3S00mc>
# Versão:  1.1.0
# Data:    2025-04-16
# Licença: MIT
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# banner() — exibe cabeçalho com identidade visual do script
# -----------------------------------------------------------------------------
banner() {
    printf '\033[1;32m'
    printf '  ██╗  ██╗███████╗██╗  ██╗██████╗ ██╗   ██╗███╗   ███╗██████╗ \n'
    printf '  ██║  ██║██╔════╝╚██╗██╔╝██╔══██╗██║   ██║████╗ ████║██╔══██╗\n'
    printf '  ███████║█████╗   ╚███╔╝ ██║  ██║██║   ██║██╔████╔██║██████╔╝\n'
    printf '  ██╔══██║██╔══╝   ██╔██╗ ██║  ██║██║   ██║██║╚██╔╝██║██╔═══╝ \n'
    printf '  ██║  ██║███████╗██╔╝ ██╗██████╔╝╚██████╔╝██║ ╚═╝ ██║██║     \n'
    printf '  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚═╝     ╚═╝╚═╝     \n'
    printf '\033[0m'
    printf '\033[90m  Inspetor de Bytes em Hexadecimal  •  by 3S00mc  •  v1.1.0\033[0m\n'
    printf '\033[90m  ─────────────────────────────────────────────────────────\033[0m\n\n'
}

# -----------------------------------------------------------------------------
# usage() — exibe ajuda formatada e sai
# -----------------------------------------------------------------------------
usage() {
    banner
    printf '\033[1;37m  USO\033[0m\n'
    printf '    %s [opções] [arquivo]\n' "$(basename "$0")"
    printf '    echo "dados" | %s [opções]\n\n' "$(basename "$0")"
    printf '\033[1;37m  OPÇÕES\033[0m\n'
    printf '    \033[33m-n N\033[0m   Lê no máximo N bytes (padrão: arquivo inteiro)\n'
    printf '    \033[33m-s N\033[0m   Pula os primeiros N bytes\n'
    printf '    \033[33m-c N\033[0m   Bytes por linha (padrão: 16)\n'
    printf '    \033[33m-h\033[0m     Exibe esta ajuda\n\n'
    printf '\033[1;37m  EXEMPLOS\033[0m\n'
    printf '    ./hexdump.sh arquivo.bin\n'
    printf '    ./hexdump.sh -n 64 arquivo.bin\n'
    printf '    ./hexdump.sh -s 128 -n 32 arquivo.bin\n'
    printf '    ./hexdump.sh -c 8 arquivo.bin\n'
    printf '    echo "Hello" | ./hexdump.sh\n'
    printf '    cat payload.hex | xxd -r -p | ./hexdump.sh\n\n'
    exit 0
}

# -----------------------------------------------------------------------------
# error() — exibe erro formatado, dica de uso e sai com código 1
# -----------------------------------------------------------------------------
error() {
    printf '\n\033[1;31m  [ERRO]\033[0m %s\n' "$1"
    printf '\033[90m  Use -h para ver todas as opções.\033[0m\n\n'
    exit 1
}

# -----------------------------------------------------------------------------
# Valores padrão das opções
# -----------------------------------------------------------------------------
COLS=16   # bytes por linha
LIMIT=""  # vazio = sem limite
SKIP=0    # offset de início

# -----------------------------------------------------------------------------
# Parse de opções com getopts
# -n : limite de bytes
# -s : bytes a pular (skip)
# -c : colunas por linha
# -h : ajuda
# -----------------------------------------------------------------------------
while getopts ":n:s:c:h" opt; do
    case $opt in
        n) LIMIT=$OPTARG ;;
        s) SKIP=$OPTARG  ;;
        c) COLS=$OPTARG  ;;
        h) usage         ;;
        :) error "Opção -$OPTARG requer um argumento." ;;
        *) error "Opção inválida: -$OPTARG" ;;
    esac
done
shift $((OPTIND - 1))

# Argumento posicional: arquivo (padrão: stdin)
FILE="${1:-/dev/stdin}"

# Valida arquivo se não for stdin
if [[ "$FILE" != "/dev/stdin" ]]; then
    [[ -f "$FILE" ]] || error "Arquivo não encontrado: $FILE"
fi

# Valida que -n e -s e -c são numéricos
[[ -n "$LIMIT" && ! "$LIMIT" =~ ^[0-9]+$ ]] && error "-n requer um número inteiro positivo."
[[ ! "$SKIP"  =~ ^[0-9]+$ ]]                 && error "-s requer um número inteiro positivo."
[[ ! "$COLS"  =~ ^[0-9]+$ || "$COLS" -lt 1 ]] && error "-c requer um número inteiro maior que zero."

# Exibe banner antes do dump
banner

# Mostra informações do arquivo
if [[ "$FILE" != "/dev/stdin" ]]; then
    SIZE=$(wc -c < "$FILE")
    printf '\033[90m  Arquivo : %s\033[0m\n' "$FILE"
    printf '\033[90m  Tamanho : %d bytes\033[0m\n' "$SIZE"
    [[ -n "$LIMIT" ]] && printf '\033[90m  Lendo   : %d bytes a partir do offset %d\033[0m\n' "$LIMIT" "$SKIP"
    printf '\033[90m  ─────────────────────────────────────────────────────────\033[0m\n'
fi
echo

# -----------------------------------------------------------------------------
# Monta argumentos do dd:
#   if=   : arquivo de entrada
#   bs=1  : lê byte a byte (para skip/count precisos)
#   skip= : pula N bytes iniciais
#   count=: lê no máximo N bytes (apenas se -n foi passado)
# -----------------------------------------------------------------------------
dd_args=("if=$FILE" "bs=1" "skip=$SKIP" "status=none")
[[ -n $LIMIT ]] && dd_args+=("count=$LIMIT")

# -----------------------------------------------------------------------------
# Pipeline principal:
#   dd  → lê os bytes brutos respeitando offset e limite
#   od  → converte para hex com coluna ASCII embutida
#   awk → reformata, corrige offset real e alinha colunas
# -----------------------------------------------------------------------------
dd "${dd_args[@]}" \
| od \
    --address-radix=x \
    --output-duplicates \
    --format=x1z \
    --width=$COLS \
| awk -v skip="$SKIP" -v cols="$COLS" '
    /^\*/ { print; next }

    {
        if (NF == 1) next

        cmd = "printf \047%d\047 0x" $1; cmd | getline dec; close(cmd)
        addr = dec + skip
        printf "%08x  ", addr

        hex = ""
        for (i = 2; i <= NF; i++) {
            if ($i ~ /^>/) break
            hex = hex sprintf("%-3s", $i)
        }
        printf "%-*s  ", cols * 3, hex

        match($0, />.*</)
        ascii = substr($0, RSTART + 1, RLENGTH - 2)
        printf "|%s|\n", ascii
    }
'

printf '\n\033[90m  ─────────────────────────────────────────────────────────\033[0m\n\n'
