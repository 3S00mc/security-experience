#!/usr/bin/env bash
# =============================================================================
# parse_packet.sh — Decodificador de pacotes de rede (Ethernet / IP / TCP)
# =============================================================================
#
# Descrição:
#   Lê um arquivo de captura de pacote e exibe de forma legível os campos de
#   cada camada do modelo OSI, cobrindo:
#
#     Camada 2 — Ethernet II
#       MAC de origem e destino, EtherType
#
#     Camada 3 — IPv4
#       IPs de origem e destino, TTL, protocolo, flags de fragmentação,
#       checksum, ToS/DSCP, identificação, comprimento total
#
#     Camada 4 — TCP | UDP | ICMP
#       Portas, sequence/ack numbers, flags TCP (SYN/ACK/FIN/RST/PSH/URG/
#       ECE/CWR), window size, checksum, urgent pointer, header length
#
#     Payload — offset, tamanho e primeiros 32 bytes em hexadecimal
#
# Detecção automática de formato:
#   O script detecta automaticamente se o arquivo é binário puro ou um
#   arquivo de texto contendo os bytes escritos em hexadecimal (ex: "00 0c
#   29 76 43 e1 ..."). No segundo caso, a conversão para binário é feita
#   internamente via Python 3, sem necessidade de passos manuais.
#
# Dependências:
#   bash >= 4.0, dd, od, tr, sed, wc  — padrão em qualquer Linux/macOS
#   python3                            — para converter arquivo hex → binário
#                                        (apenas quando o input for texto hex)
#
# Uso:
#   ./parse_packet.sh <arquivo>
#
# Argumentos:
#   arquivo   Caminho para o arquivo de pacote. Pode ser:
#               - Binário bruto (.bin, .raw, .cap, etc.)
#               - Texto com bytes hex separados por espaços ou quebras de linha
#
# Exemplos:
#   ./parse_packet.sh captura.bin
#   ./parse_packet.sh pacote.hex
#
#   # Criando um arquivo hex de teste e parseando diretamente:
#   echo "00 0c 29 76 43 e1 d4 ab 82 45 c4 0c 08 00 45 00
#         00 28 b5 f5 40 00 31 06 ff 0b 25 3b ae e1 c0 a8
#         00 0a 23 82 8f 48 00 00 00 00 04 81 18 d0 50 14
#         00 00 4a e6 00 00 00 00 00 00 00 00" > pacote.hex
#   ./parse_packet.sh pacote.hex
#
# Saída esperada (exemplo):
#   ╔══════════════════════════════════════╗
#   ║      PACKET DECODER  —  pacote.hex  ║
#   ╚══════════════════════════════════════╝
#
#   ── ETHERNET (camada 2)
#     MAC destino:  00:0c:29:76:43:e1
#     MAC origem:   d4:ab:82:45:c4:0c
#     EtherType:    0x0800  (IPv4)
#
#   ── IPv4 (camada 3)
#     IP origem:    37.59.174.225
#     IP destino:   192.168.0.10
#     TTL:          49
#     Protocolo L4: TCP
#
#   ── TCP (camada 4)
#     Porta origem:  9090
#     Porta destino: 36680
#     [✔] ACK
#     [✔] RST
#
# Limitações:
#   - Suporta apenas EtherType 0x0800 (IPv4); ARP e IPv6 são identificados
#     mas não decodificados em profundidade
#   - Não processa opções do cabeçalho IPv4 além de calcular o IHL
#   - Não valida checksums
#
# Autor:   3S00mc  <https://github.com/3S00mc>
# Versão:  1.1.0
# Data:    2025-04-16
# Licença: MIT
# =============================================================================

set -euo pipefail

# =============================================================================
# IDENTIDADE VISUAL E MENSAGENS
# =============================================================================

# -----------------------------------------------------------------------------
# banner() — exibe cabeçalho com marca pessoal do autor
# -----------------------------------------------------------------------------
banner() {
    printf '\033[1;36m'
    printf '  ██████╗  █████╗ ██████╗ ███████╗███████╗██████╗ \n'
    printf '  ██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔════╝██╔══██╗\n'
    printf '  ██████╔╝███████║██████╔╝███████╗█████╗  ██████╔╝\n'
    printf '  ██╔═══╝ ██╔══██║██╔══██╗╚════██║██╔══╝  ██╔══██╗\n'
    printf '  ██║     ██║  ██║██║  ██║███████║███████╗██║  ██║\n'
    printf '  ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝\n'
    printf '\033[0m'
    printf '\033[90m  Decodificador de Pacotes de Rede  •  by 3S00mc  •  v1.2.0\033[0m\n'
    printf '\033[90m  Ethernet II  /  IPv4  /  TCP  /  UDP  /  ICMP\033[0m\n'
    printf '\033[90m  ──────────────────────────────────────────────────────────\033[0m\n\n'
}

# -----------------------------------------------------------------------------
# usage() — exibe ajuda formatada e sai
# -----------------------------------------------------------------------------
usage() {
    banner
    printf '\033[1;37m  USO\033[0m\n'
    printf '    %s <arquivo>\n\n' "$(basename "$0")"
    printf '\033[1;37m  ARGUMENTOS\033[0m\n'
    printf '    \033[33m<arquivo>\033[0m   Arquivo de captura. Formatos aceitos:\n'
    printf '               - Binário bruto  (.bin .raw .cap)\n'
    printf '               - Texto hex      (bytes separados por espaço ou newline)\n\n'
    printf '\033[1;37m  OPÇÕES\033[0m\n'
    printf '    \033[33m-h\033[0m          Exibe esta ajuda\n\n'
    printf '\033[1;37m  EXEMPLOS\033[0m\n'
    printf '    ./parse_packet.sh captura.bin\n'
    printf '    ./parse_packet.sh pacote.hex\n\n'
    printf '\033[1;37m  CAMADAS DECODIFICADAS\033[0m\n'
    printf '    L2  Ethernet II  — MAC src/dst, EtherType\n'
    printf '    L3  IPv4        — IP src/dst, TTL, flags, fragmentação, checksum\n'
    printf '    L4  TCP         — portas, seq/ack, todas as flags, window, checksum\n'
    printf '        UDP         — portas, comprimento, checksum\n'
    printf '        ICMP        — type, code, checksum\n'
    printf '    L7  Payload     — hex dump + decodificação HTTP/FTP/SMTP/TLS\n\n'
    printf '\033[1;37m  DICA RÁPIDA\033[0m\n'
    printf '    Para converter hex texto em binário manualmente:\n'
    printf '    \033[90mcat payload.hex | xxd -r -p > pacote.bin\033[0m\n\n'
    exit 0
}

# -----------------------------------------------------------------------------
# error() — exibe erro formatado e sai com código 1
# -----------------------------------------------------------------------------
error() {
    printf '\n\033[1;31m  [ERRO]\033[0m %s\n' "$1"
    printf '\033[90m  Use -h para ver todas as opções.\033[0m\n\n'
    exit 1
}

# =============================================================================
# FUNÇÕES AUXILIARES
# =============================================================================

# -----------------------------------------------------------------------------
# read_hex FILE OFFSET COUNT
#
# Lê COUNT bytes a partir do OFFSET (em decimal) do arquivo FILE e retorna
# a sequência hexadecimal em letras minúsculas sem espaços.
#
# Internamente:
#   dd   — extrai o trecho exato do arquivo (byte a byte)
#   od   — converte bytes para representação hex
#   tr   — remove espaços e quebras de linha da saída do od
#
# Exemplo de retorno para 2 bytes 0x08 0x00:  "0800"
# -----------------------------------------------------------------------------
read_hex() {
    local file=$1 offset=$2 count=$3
    dd if="$file" bs=1 skip="$offset" count="$count" status=none \
        | od --format=x1 --output-duplicates --address-radix=n \
        | tr -d ' \n'
}

# -----------------------------------------------------------------------------
# hex2dec HEX
#
# Converte uma string hexadecimal (sem prefixo 0x) para decimal.
# Usa printf com a notação aritmética do shell para a conversão.
#
# Exemplo: hex2dec "ff0b"  →  65291
# -----------------------------------------------------------------------------
hex2dec() { printf '%d' "0x$1"; }

# -----------------------------------------------------------------------------
# fmt_mac HEX12
#
# Formata uma string de 12 caracteres hex como endereço MAC com separador ':'.
# Entrada:  "000c297643e1"
# Saída:    "00:0c:29:76:43:e1"
# -----------------------------------------------------------------------------
fmt_mac() {
    local h=$1
    printf '%s:%s:%s:%s:%s:%s' \
        "${h:0:2}" "${h:2:2}" "${h:4:2}" "${h:6:2}" "${h:8:2}" "${h:10:2}"
}

# -----------------------------------------------------------------------------
# fmt_ip HEX8
#
# Formata uma string de 8 caracteres hex como endereço IPv4 com separador '.'.
# Converte cada octeto de hex para decimal com printf.
# Entrada:  "253bae e1"  →  "37.59.174.225"
# -----------------------------------------------------------------------------
fmt_ip() {
    local h=$1
    printf '%d.%d.%d.%d' \
        "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}" "0x${h:6:2}"
}

# -----------------------------------------------------------------------------
# Funções de formatação de saída colorida (ANSI escape codes)
#
# section TITLE  — cabeçalho de seção em ciano
# field KEY VAL  — par chave/valor com chave em amarelo, alinhada em 22 chars
# flag_on NAME   — flag ativa em verde com ícone ✔
# flag_off NAME  — flag inativa em cinza com ícone ✘
# -----------------------------------------------------------------------------
section() { printf '\n\033[1;36m── %s\033[0m\n' "$1"; }
field()   { printf '  \033[33m%-22s\033[0m %s\n' "$1" "$2"; }
flag_on() { printf '  \033[32m[✔] %s\033[0m\n' "$1"; }
flag_off(){ printf '  \033[90m[✘] %s\033[0m\n' "$1"; }

# =============================================================================
# PARSE DE ARGUMENTOS E VALIDAÇÃO
# =============================================================================

# Suporte a -h mesmo sem arquivo
for arg in "$@"; do
    [[ "$arg" == "-h" || "$arg" == "--help" ]] && usage
done

INPUT="${1:-}"
[[ -z $INPUT ]] && {
    banner
    error "Nenhum arquivo informado. Uso: $(basename "$0") <arquivo>"
}
[[ -f $INPUT ]] || error "Arquivo não encontrado: $INPUT"

# =============================================================================
# DETECÇÃO AUTOMÁTICA DE FORMATO (binário vs texto hex)
# =============================================================================

# Lê os primeiros 256 bytes, remove espaços/newlines e verifica se só há hex.
# Se sim → texto hex (converte internamente); caso contrário → binário puro.
SAMPLE=$(head -c 256 "$INPUT" | tr -d ' \t\n\r')
WORK_FILE="$INPUT"
FORMAT="binário"

if [[ "$SAMPLE" =~ ^[0-9a-fA-F]+$ ]]; then
    FORMAT="texto hex"
    TMPFILE=$(mktemp /tmp/packet_XXXXXX.bin)
    trap 'rm -f "$TMPFILE"' EXIT
    python3 - "$INPUT" "$TMPFILE" << 'PY'
import sys
raw = open(sys.argv[1]).read()
clean = "".join(c for c in raw if c in "0123456789abcdefABCDEF")
open(sys.argv[2], "wb").write(bytes.fromhex(clean))
PY
    WORK_FILE="$TMPFILE"
fi

FILE="$WORK_FILE"
SIZE=$(wc -c < "$FILE")

# =============================================================================
# BANNER + INFORMAÇÕES DO ARQUIVO
# =============================================================================

banner
printf '\033[90m  Arquivo : %s  (%s)\033[0m\n' "$INPUT" "$FORMAT"
printf '\033[90m  Tamanho : %d bytes\033[0m\n' "$SIZE"
printf '\033[90m  ──────────────────────────────────────────────────────────\033[0m\n'

[[ $SIZE -lt 34 ]] && error "Arquivo muito pequeno ($SIZE bytes). Mínimo: 34 bytes (Ethernet + IP)."

# =============================================================================
# CAMADA 2 — ETHERNET II
# Estrutura (14 bytes):
#   Offset 0–5  : MAC destino  (6 bytes)
#   Offset 6–11 : MAC origem   (6 bytes)
#   Offset 12–13: EtherType    (2 bytes)
# =============================================================================
# =============================================================================
# CAMADA 2 — ETHERNET II
# Estrutura (14 bytes):
#   Offset 0–5  : MAC destino  (6 bytes)
#   Offset 6–11 : MAC origem   (6 bytes)
#   Offset 12–13: EtherType    (2 bytes)
# =============================================================================
section "ETHERNET (camada 2)"

MAC_DST=$(read_hex "$FILE" 0 6)
MAC_SRC=$(read_hex "$FILE" 6 6)
ETHERTYPE=$(read_hex "$FILE" 12 2)

field "MAC destino:"  "$(fmt_mac "$MAC_DST")  [0x$MAC_DST]"
field "MAC origem:"   "$(fmt_mac "$MAC_SRC")  [0x$MAC_SRC]"
field "EtherType:"    "0x$ETHERTYPE"

case "${ETHERTYPE^^}" in
    0800) field "Protocolo:" "IPv4" ;;
    0806) field "Protocolo:" "ARP"  ;;
    86DD) field "Protocolo:" "IPv6" ;;
    *   ) field "Protocolo:" "Desconhecido" ;;
esac

# Este script só decodifica IPv4 em profundidade
[[ "${ETHERTYPE^^}" != "0800" ]] && {
    echo "  ⚠ Decodificação detalhada disponível apenas para IPv4 (0x0800)."
    exit 0
}

# =============================================================================
# CAMADA 3 — IPv4
# Estrutura do cabeçalho (mínimo 20 bytes, a partir do offset 14):
#   Byte  0   : Version (4 bits) + IHL (4 bits)
#   Byte  1   : ToS / DSCP
#   Bytes 2–3 : Comprimento total do pacote IP
#   Bytes 4–5 : Identificação
#   Bytes 6–7 : Flags (3 bits) + Fragment Offset (13 bits)
#   Byte  8   : TTL
#   Byte  9   : Protocolo da camada 4 (06=TCP, 11=UDP, 01=ICMP)
#   Bytes 10–11: Checksum do cabeçalho IP
#   Bytes 12–15: IP de origem
#   Bytes 16–19: IP de destino
# =============================================================================
section "IPv4 (camada 3)"

# Primeiro byte do cabeçalho IP contém versão (nibble alto) e IHL (nibble baixo)
IP_BYTE0=$(read_hex "$FILE" 14 1)
IP_VERSION=$(( 0x$IP_BYTE0 >> 4 ))
# IHL (Internet Header Length) está em unidades de 32 bits (4 bytes)
IP_IHL=$(( (0x$IP_BYTE0 & 0x0F) * 4 ))

IP_TOS=$(read_hex    "$FILE" 15 1)
IP_LEN=$(read_hex    "$FILE" 16 2)
IP_ID=$(read_hex     "$FILE" 18 2)
IP_FRAG=$(read_hex   "$FILE" 20 2)
IP_TTL=$(read_hex    "$FILE" 22 1)
IP_PROTO=$(read_hex  "$FILE" 23 1)
IP_CHKSUM=$(read_hex "$FILE" 24 2)
IP_SRC=$(read_hex    "$FILE" 26 4)
IP_DST=$(read_hex    "$FILE" 30 4)

# Extração das flags e fragment offset do campo de 16 bits:
#   Bit 15 (reservado), bit 14 = DF, bit 13 = MF, bits 12–0 = Fragment Offset
IP_FRAG_DEC=$(hex2dec "$IP_FRAG")
FLAG_DF=$(( (IP_FRAG_DEC >> 14) & 1 ))
FLAG_MF=$(( (IP_FRAG_DEC >> 13) & 1 ))
FRAG_OFFSET=$(( (IP_FRAG_DEC & 0x1FFF) * 8 ))  # offset em bytes (unidade original: 8 bytes)

field "Versão:"        "$IP_VERSION"
field "IHL:"           "${IP_IHL} bytes"
field "ToS/DSCP:"      "0x$IP_TOS"
field "Comprimento:"   "$(hex2dec "$IP_LEN") bytes"
field "Identificação:" "0x$IP_ID"
field "TTL:"           "$(hex2dec "$IP_TTL")"
field "Checksum IP:"   "0x$IP_CHKSUM"
field "IP origem:"     "$(fmt_ip "$IP_SRC")"
field "IP destino:"    "$(fmt_ip "$IP_DST")"

printf '  \033[33m%-22s\033[0m\n' "Flags IP:"
[[ $FLAG_DF -eq 1 ]] && flag_on "DF (Don't Fragment)" || flag_off "DF (Don't Fragment)"
[[ $FLAG_MF -eq 1 ]] && flag_on "MF (More Fragments)" || flag_off "MF (More Fragments)"
field "Fragment offset:" "${FRAG_OFFSET} bytes"

case "${IP_PROTO^^}" in
    06) PROTO_NAME="TCP"  ;;
    11) PROTO_NAME="UDP"  ;;
    01) PROTO_NAME="ICMP" ;;
    *)  PROTO_NAME="Desconhecido (0x$IP_PROTO)" ;;
esac
field "Protocolo L4:"  "$PROTO_NAME  [0x$IP_PROTO]"

# =============================================================================
# CAMADA 4 — TCP / UDP / ICMP
# O offset do início da camada 4 é: 14 (Ethernet) + IHL (IP)
# =============================================================================
L4_OFF=$((14 + IP_IHL))

# ---------------------------------------------------------------------------
# TCP — Transmission Control Protocol (protocolo 0x06)
# Estrutura do cabeçalho (mínimo 20 bytes):
#   Bytes 0–1 : Porta de origem
#   Bytes 2–3 : Porta de destino
#   Bytes 4–7 : Sequence Number
#   Bytes 8–11: Acknowledgment Number
#   Byte  12  : Data Offset (4 bits altos) + Reserved (3 bits) + NS flag (1 bit)
#   Byte  13  : Flags de controle (CWR ECE URG ACK PSH RST SYN FIN)
#   Bytes 14–15: Window Size
#   Bytes 16–17: Checksum
#   Bytes 18–19: Urgent Pointer
# ---------------------------------------------------------------------------
if [[ "${IP_PROTO^^}" == "06" ]]; then
    section "TCP (camada 4)"

    [[ $SIZE -lt $((L4_OFF + 20)) ]] && {
        echo "  ⚠ Arquivo truncado — cabeçalho TCP incompleto (esperado $((L4_OFF + 20)) bytes, encontrado $SIZE)."
        exit 0
    }

    TCP_SPORT=$(read_hex  "$FILE" $((L4_OFF + 0))  2)
    TCP_DPORT=$(read_hex  "$FILE" $((L4_OFF + 2))  2)
    TCP_SEQ=$(read_hex    "$FILE" $((L4_OFF + 4))  4)
    TCP_ACK=$(read_hex    "$FILE" $((L4_OFF + 8))  4)
    TCP_DO=$(read_hex     "$FILE" $((L4_OFF + 12)) 1)   # Data Offset + Reserved
    TCP_FLAGS=$(read_hex  "$FILE" $((L4_OFF + 13)) 1)   # byte de flags de controle
    TCP_WIN=$(read_hex    "$FILE" $((L4_OFF + 14)) 2)
    TCP_CHKSUM=$(read_hex "$FILE" $((L4_OFF + 16)) 2)
    TCP_URG=$(read_hex    "$FILE" $((L4_OFF + 18)) 2)

    # Data Offset indica o tamanho do cabeçalho TCP em unidades de 32 bits
    TCP_HDR_LEN=$(( (0x$TCP_DO >> 4) * 4 ))
    FLAGS_DEC=$(hex2dec "$TCP_FLAGS")

    field "Porta origem:"   "$(hex2dec "$TCP_SPORT")"
    field "Porta destino:"  "$(hex2dec "$TCP_DPORT")"
    field "Seq number:"     "$(hex2dec "$TCP_SEQ")  [0x$TCP_SEQ]"
    field "Ack number:"     "$(hex2dec "$TCP_ACK")  [0x$TCP_ACK]"
    field "Header length:"  "${TCP_HDR_LEN} bytes"
    field "Window size:"    "$(hex2dec "$TCP_WIN")"
    field "Checksum TCP:"   "0x$TCP_CHKSUM"
    field "Urgent pointer:" "$(hex2dec "$TCP_URG")"

    # Flags TCP — cada bit do byte de flags corresponde a uma flag de controle
    # Ordem dos bits (da esquerda/mais significativo para direita):
    #   bit 7: CWR  bit 6: ECE  bit 5: URG  bit 4: ACK
    #   bit 3: PSH  bit 2: RST  bit 1: SYN  bit 0: FIN
    printf '  \033[33m%-22s\033[0m\n' "Flags TCP:"
    [[ $(( (FLAGS_DEC >> 7) & 1 )) -eq 1 ]] && flag_on "CWR (Congestion Window Reduced)" || flag_off "CWR"
    [[ $(( (FLAGS_DEC >> 6) & 1 )) -eq 1 ]] && flag_on "ECE (ECN Echo)"                  || flag_off "ECE"
    [[ $(( (FLAGS_DEC >> 5) & 1 )) -eq 1 ]] && flag_on "URG (Urgent)"                    || flag_off "URG"
    [[ $(( (FLAGS_DEC >> 4) & 1 )) -eq 1 ]] && flag_on "ACK (Acknowledgment)"            || flag_off "ACK"
    [[ $(( (FLAGS_DEC >> 3) & 1 )) -eq 1 ]] && flag_on "PSH (Push)"                      || flag_off "PSH"
    [[ $(( (FLAGS_DEC >> 2) & 1 )) -eq 1 ]] && flag_on "RST (Reset)"                     || flag_off "RST"
    [[ $(( (FLAGS_DEC >> 1) & 1 )) -eq 1 ]] && flag_on "SYN (Synchronize)"               || flag_off "SYN"
    [[ $(( (FLAGS_DEC >> 0) & 1 )) -eq 1 ]] && flag_on "FIN (Finish)"                    || flag_off "FIN"

    # Payload: tudo que vem após o cabeçalho TCP
    PAYLOAD_OFF=$((L4_OFF + TCP_HDR_LEN))
    PAYLOAD_LEN=$((SIZE - PAYLOAD_OFF))

    section "PAYLOAD"
    field "Offset:"  "$PAYLOAD_OFF bytes"
    field "Tamanho:" "$PAYLOAD_LEN bytes"

    if [[ $PAYLOAD_LEN -gt 0 ]]; then

        # ── Dump hex + ASCII completo (estilo hexdump -C) ──────────────────
        printf '  \033[33mHex dump:\033[0m\n'
        dd if="$FILE" bs=1 skip="$PAYLOAD_OFF" count="$PAYLOAD_LEN" status=none \
        | od --format=x1z --output-duplicates --address-radix=x --width=16 \
        | awk '
            NF == 1 { next }
            {
                printf "    %s  ", $1
                hex = ""; for (i=2; i<=NF; i++) { if ($i ~ /^>/) break; hex = hex sprintf("%-3s",$i) }
                printf "%-50s", hex
                match($0, />.*</); ascii = substr($0, RSTART+1, RLENGTH-2)
                printf "|%s|\n", ascii
            }'

        # ── Decodificação do conteúdo como texto ───────────────────────────
        # Extrai o payload como texto, substituindo bytes não imprimíveis por '.'
        PAYLOAD_TEXT=$(dd if="$FILE" bs=1 skip="$PAYLOAD_OFF" \
            count="$PAYLOAD_LEN" status=none \
            | cat -v 2>/dev/null || true)

        # Tenta identificar o protocolo de aplicação pelo conteúdo
        PAYLOAD_RAW=$(dd if="$FILE" bs=1 skip="$PAYLOAD_OFF" \
            count="$PAYLOAD_LEN" status=none 2>/dev/null | strings -n 4)

        printf '\n  \033[33mConteúdo (texto):\033[0m\n'

        # Detecção de protocolo de aplicação e exibição formatada
        FIRST_LINE=$(dd if="$FILE" bs=1 skip="$PAYLOAD_OFF" count="$PAYLOAD_LEN" \
            status=none 2>/dev/null | head -c 128 | strings | head -1)

        # HTTP request (GET, POST, PUT, DELETE, HEAD, OPTIONS, PATCH)
        if echo "$FIRST_LINE" | grep -qE '^(GET|POST|PUT|DELETE|HEAD|OPTIONS|PATCH) '; then
            printf '  \033[32m[HTTP Request]\033[0m\n'
            dd if="$FILE" bs=1 skip="$PAYLOAD_OFF" count="$PAYLOAD_LEN" status=none \
                2>/dev/null | while IFS= read -r line || [[ -n $line ]]; do
                    printf '    \033[36m%s\033[0m\n' "$line"
                done

        # HTTP response (HTTP/1.0, HTTP/1.1, HTTP/2)
        elif echo "$FIRST_LINE" | grep -qE '^HTTP/[0-9]'; then
            printf '  \033[32m[HTTP Response]\033[0m\n'
            dd if="$FILE" bs=1 skip="$PAYLOAD_OFF" count="$PAYLOAD_LEN" status=none \
                2>/dev/null | while IFS= read -r line || [[ -n $line ]]; do
                    printf '    \033[36m%s\033[0m\n' "$line"
                done

        # DNS (porta 53 — heurística pelo destino ou origem)
        elif [[ "$(hex2dec "$TCP_DPORT")" == "53" ]] || \
             [[ "$(hex2dec "$TCP_SPORT")" == "53" ]]; then
            printf '  \033[32m[DNS]\033[0m\n'
            printf '    (use wireshark/tshark para decodificação completa de DNS)\n'
            printf '    Strings encontradas:\n'
            echo "$PAYLOAD_RAW" | while read -r s; do printf '    %s\n' "$s"; done

        # FTP
        elif echo "$FIRST_LINE" | grep -qE '^(USER|PASS|RETR|STOR|LIST|CWD|PWD|QUIT|220|230|331|530)'; then
            printf '  \033[32m[FTP]\033[0m\n'
            dd if="$FILE" bs=1 skip="$PAYLOAD_OFF" count="$PAYLOAD_LEN" status=none \
                2>/dev/null | while IFS= read -r line || [[ -n $line ]]; do
                    printf '    \033[36m%s\033[0m\n' "$line"
                done

        # SMTP
        elif echo "$FIRST_LINE" | grep -qE '^(EHLO|HELO|MAIL|RCPT|DATA|QUIT|220|250|354|550)'; then
            printf '  \033[32m[SMTP]\033[0m\n'
            dd if="$FILE" bs=1 skip="$PAYLOAD_OFF" count="$PAYLOAD_LEN" status=none \
                2>/dev/null | while IFS= read -r line || [[ -n $line ]]; do
                    printf '    \033[36m%s\033[0m\n' "$line"
                done

        # TLS/SSL — magic byte 0x16 = TLS record type "Handshake"
        elif [[ $(read_hex "$FILE" "$PAYLOAD_OFF" 1 2>/dev/null) == "16" ]]; then
            TLS_VER=$(read_hex "$FILE" $((PAYLOAD_OFF + 1)) 2)
            case "$TLS_VER" in
                0301) TLS_NAME="TLS 1.0" ;;
                0302) TLS_NAME="TLS 1.1" ;;
                0303) TLS_NAME="TLS 1.2" ;;
                0304) TLS_NAME="TLS 1.3" ;;
                *)    TLS_NAME="TLS/SSL (versão 0x$TLS_VER)" ;;
            esac
            printf '  \033[32m[%s — conteúdo cifrado]\033[0m\n' "$TLS_NAME"
            TLS_TYPE=$(read_hex "$FILE" $((PAYLOAD_OFF + 5)) 1)
            case "$(hex2dec "$TLS_TYPE")" in
                1) printf '    Handshake type: Client Hello\n' ;;
                2) printf '    Handshake type: Server Hello\n' ;;
                11) printf '    Handshake type: Certificate\n' ;;
                *) printf '    Handshake type: 0x%s\n' "$TLS_TYPE" ;;
            esac

        # Conteúdo genérico — exibe strings imprimíveis
        else
            if [[ -n "$PAYLOAD_RAW" ]]; then
                printf '  \033[32m[Dados]\033[0m\n'
                echo "$PAYLOAD_RAW" | while read -r s; do printf '    %s\n' "$s"; done
            else
                printf '  \033[90m[binário / não decodificável como texto]\033[0m\n'
            fi
        fi

    else
        echo "  (sem payload)"
    fi

# ---------------------------------------------------------------------------
# UDP — User Datagram Protocol (protocolo 0x11)
# Estrutura do cabeçalho (fixo em 8 bytes):
#   Bytes 0–1: Porta de origem
#   Bytes 2–3: Porta de destino
#   Bytes 4–5: Comprimento (cabeçalho + dados)
#   Bytes 6–7: Checksum
# ---------------------------------------------------------------------------
elif [[ "${IP_PROTO^^}" == "11" ]]; then
    section "UDP (camada 4)"

    UDP_SPORT=$(read_hex "$FILE" $((L4_OFF + 0)) 2)
    UDP_DPORT=$(read_hex "$FILE" $((L4_OFF + 2)) 2)
    UDP_LEN=$(read_hex   "$FILE" $((L4_OFF + 4)) 2)
    UDP_CHK=$(read_hex   "$FILE" $((L4_OFF + 6)) 2)

    field "Porta origem:"  "$(hex2dec "$UDP_SPORT")"
    field "Porta destino:" "$(hex2dec "$UDP_DPORT")"
    field "Comprimento:"   "$(hex2dec "$UDP_LEN") bytes"
    field "Checksum:"      "0x$UDP_CHK"

# ---------------------------------------------------------------------------
# ICMP — Internet Control Message Protocol (protocolo 0x01)
# Estrutura mínima (4 bytes comuns a todos os tipos):
#   Byte  0  : Type  (identifica a mensagem ICMP)
#   Byte  1  : Code  (sub-tipo, depende do Type)
#   Bytes 2–3: Checksum
# ---------------------------------------------------------------------------
elif [[ "${IP_PROTO^^}" == "01" ]]; then
    section "ICMP (camada 4)"

    ICMP_TYPE=$(read_hex "$FILE" $((L4_OFF + 0)) 1)
    ICMP_CODE=$(read_hex "$FILE" $((L4_OFF + 1)) 1)
    ICMP_CHK=$(read_hex  "$FILE" $((L4_OFF + 2)) 2)

    field "Type:"     "$(hex2dec "$ICMP_TYPE")"
    field "Code:"     "$(hex2dec "$ICMP_CODE")"
    field "Checksum:" "0x$ICMP_CHK"
fi

printf '\n\033[1;37m══════════════════════════════════════\033[0m\n\n'
