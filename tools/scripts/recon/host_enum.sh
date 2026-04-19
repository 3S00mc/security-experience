#!/usr/bin/env bash
# ==============================================================
# host.enum.sh
# Recon de rede com saida JSONL estruturada
# uso: ./host.enum.sh -i IP | -r CIDR -p PORTA[s] [-d DELAY]
# stdout -> JSONL | stderr -> visual
# ==============================================================

set -uo pipefail

# --------------------------------------------------------------
# CONSTANTES
# --------------------------------------------------------------

VERSION="1.0.0"
DELAY=1

# Cores (stderr only)
G="\e[32m"  # verde
R="\e[31m"  # vermelho
Y="\e[33m"  # amarelo
C="\e[36m"  # ciano
B="\e[1m"   # bold
X="\e[0m"   # reset

# --------------------------------------------------------------
# DEPENDENCIAS
# --------------------------------------------------------------

check_deps() {
    local missing=()
    for cmd in nc curl python3 nmap host whois; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if [ ${#missing[@]} -gt 0 ]; then
        log_err "dependencias ausentes: ${missing[*]}"
        exit 1
    fi
}

# --------------------------------------------------------------
# USO
# --------------------------------------------------------------

uso() {
    echo -e "" >&2
    echo -e "${B}${C}host.enum.sh${X} ${C}v${VERSION}${X}" >&2
    echo -e "Recon stealth · stdout JSONL · stderr visual" >&2
    echo -e "" >&2
    echo -e "${B}SINTAXE${X}" >&2
    echo -e "  $(basename "$0") -i <IP>   -p <PORTAS> [-d <DELAY>]" >&2
    echo -e "  $(basename "$0") -r <CIDR> -p <PORTAS> [-d <DELAY>]" >&2
    echo -e "" >&2
    echo -e "${B}FLAGS${X}" >&2
    echo -e "  ${Y}-i${X} IP      alvo unico        ex: 10.0.0.1" >&2
    echo -e "  ${Y}-r${X} CIDR    range de rede     ex: 192.168.0.0/24" >&2
    echo -e "  ${Y}-p${X} PORTAS  porta ou range    ex: 80 | 80-443 | 22,80,443" >&2
    echo -e "  ${Y}-d${X} DELAY   segundos/request  default: 1" >&2
    echo -e "" >&2
    echo -e "${B}EXEMPLOS${X}" >&2
    echo -e "  $(basename "$0") -i 10.0.0.1 -p 80" >&2
    echo -e "  $(basename "$0") -i 10.0.0.1 -p 80-443 -d 2" >&2
    echo -e "  $(basename "$0") -r 192.168.1.0/24 -p 22,80,443" >&2
    echo -e "" >&2
    echo -e "${B}PIPELINE${X}" >&2
    echo -e "  $(basename "$0") -i 10.0.0.1 -p 80 > targets.jsonl" >&2
    echo -e "  $(basename "$0") -i 10.0.0.1 -p 80 > targets.jsonl 2> scan.log" >&2
    echo -e "  python3 web.enum.py -i targets.jsonl" >&2
    echo -e "" >&2
    echo -e "${B}SERVICOS ENUMERADOS${X}" >&2
    echo -e "  ${C}HTTP/HTTPS${X}  headers · robots · sitemap · security headers" >&2
    echo -e "  ${C}SSH${X}         banner · versao" >&2
    echo -e "  ${C}FTP${X}         login anonimo" >&2
    echo -e "  ${C}SMB${X}         shares anonimos" >&2
    echo -e "  ${C}DNS${X}         zone transfer" >&2
    echo -e "" >&2
    echo -e "${B}NOTAS${X}" >&2
    echo -e "  · range maximo: 500 hosts (acima disso use nmap direto)" >&2
    echo -e "  · ip-api.com para geo: limite 45 req/min sem chave" >&2
    echo -e "" >&2
    exit 1
}

# --------------------------------------------------------------
# SIGNAL HANDLER
# --------------------------------------------------------------

trap 'echo "" >&2; log_warn "interrompido"; exit 130' SIGINT SIGTERM

# --------------------------------------------------------------
# HELPERS DE LOG (sempre stderr)
# --------------------------------------------------------------

log()      { echo -e "$1" >&2; }
log_ok()   { echo -e "  ${G}[+]${X} $1" >&2; }
log_err()  { echo -e "  ${R}[-]${X} $1" >&2; }
log_warn() { echo -e "  ${Y}[!]${X} $1" >&2; }
log_info() { echo -e "  ${C}[$1]${X} $2" >&2; }

# --------------------------------------------------------------
# EMIT JSON (stdout - usa python3 pra escapar corretamente)
# --------------------------------------------------------------

emit_json() {
    # Recebe um dicionario bash como pares key=value
    # e serializa via python3 pra garantir JSON valido
    python3 -c "
import json, sys

pairs = sys.argv[1:]
data  = {}

for pair in pairs:
    key, _, val = pair.partition('=')
    # tenta int
    try:
        data[key] = int(val)
        continue
    except ValueError:
        pass
    # tenta bool
    if val in ('true', 'false'):
        data[key] = val == 'true'
        continue
    # tenta JSON embutido (listas/objetos de subfuncoes)
    if val.startswith('{') or val.startswith('['):
        try:
            data[key] = json.loads(val)
            continue
        except json.JSONDecodeError:
            pass
    data[key] = val

print(json.dumps(data, ensure_ascii=False))
" "$@"
}

# --------------------------------------------------------------
# RESOLVER HOSTS
# --------------------------------------------------------------

resolver_hosts() {
    local alvo_ip="$1"
    local alvo_range="$2"

    if [ -n "$alvo_ip" ]; then
        echo "$alvo_ip"
        return
    fi

    log_info "range" "expandindo $alvo_range"
    local total
    total=$(nmap -sL -n "$alvo_range" 2>/dev/null | grep -c "report for")

    log_info "range" "$total hosts"

    if [ "$total" -gt 500 ]; then
        log_warn "range > 500 hosts. Reduza o CIDR."
        exit 1
    fi

    nmap -sL -n "$alvo_range" 2>/dev/null | awk '/report for/{print $NF}'
}

# --------------------------------------------------------------
# RESOLVER PORTAS
# --------------------------------------------------------------

resolver_portas() {
    local spec="$1"
    local lista=()

    IFS=',' read -ra partes <<< "$spec"
    for parte in "${partes[@]}"; do
        if [[ "$parte" == *-* ]]; then
            local ini fin
            ini="${parte%-*}"
            fin="${parte#*-}"
            for p in $(seq "$ini" "$fin"); do lista+=("$p"); done
        else
            lista+=("$parte")
        fi
    done

    printf '%s\n' "${lista[@]}"
}

# --------------------------------------------------------------
# FASE 1 - PORT SCAN
# --------------------------------------------------------------

scan_porta() {
    local host="$1" porta="$2"
    (echo >/dev/tcp/"$host"/"$porta") 2>/dev/null
}

# --------------------------------------------------------------
# FASE 2 - BANNER GRAB
# --------------------------------------------------------------

banner_grab() {
    local host="$1" porta="$2"
    printf '' | nc -w 2 "$host" "$porta" 2>/dev/null \
        | strings \
        | head -3 \
        | tr '\n' ' ' \
        | xargs
}

# --------------------------------------------------------------
# FASE 3 - DETECCAO DE SERVICO
# --------------------------------------------------------------

detectar_servico() {
    local porta="$1"
    case "$porta" in
        21)          echo "FTP"        ;;
        22)          echo "SSH"        ;;
        23)          echo "Telnet"     ;;
        25|587|465)  echo "SMTP"       ;;
        53)          echo "DNS"        ;;
        80|8080|8000|8008) echo "HTTP" ;;
        110)         echo "POP3"       ;;
        143)         echo "IMAP"       ;;
        443|8443)    echo "HTTPS"      ;;
        445)         echo "SMB"        ;;
        3306)        echo "MySQL"      ;;
        3389)        echo "RDP"        ;;
        5432)        echo "PostgreSQL" ;;
        6379)        echo "Redis"      ;;
        27017)       echo "MongoDB"    ;;
        *)           echo "unknown"    ;;
    esac
}

# --------------------------------------------------------------
# FASE 4 - IP INFO
# --------------------------------------------------------------

enum_ip_info() {
    local host="$1"

    log_info "ip-info" "$host"

    local rdns asn org netname country city isp
    rdns=""
    asn=""
    org=""
    netname=""
    country=""
    city=""
    isp=""

    # Reverse DNS
    rdns=$(host "$host" 2>/dev/null \
        | grep "domain name pointer" \
        | awk '{print $NF}' \
        | head -1 \
        | sed 's/\.$//')

    # whois
    local whois_raw
    whois_raw=$(whois "$host" 2>/dev/null)
    asn=$(echo     "$whois_raw" | grep -iE "^origin"   | head -1 | awk '{print $NF}')
    org=$(echo     "$whois_raw" | grep -iE "^org-name|^OrgName" | head -1 | cut -d: -f2- | xargs)
    netname=$(echo "$whois_raw" | grep -iE "^netname|^NetName"  | head -1 | cut -d: -f2- | xargs)

    # Geo via ip-api.com (sem chave, 45 req/min)
    local geo_raw
    geo_raw=$(curl -s --max-time 4 \
        "http://ip-api.com/json/${host}?fields=country,city,isp,org,as" 2>/dev/null)

    if [ -n "$geo_raw" ]; then
        country=$(echo "$geo_raw" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('country',''))")
        city=$(echo    "$geo_raw" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('city',''))")
        isp=$(echo     "$geo_raw" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('isp',''))")
        [ -z "$org" ] && org=$(echo "$geo_raw" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('org',''))")
    fi

    [ -n "$rdns" ]    && log_ok "rdns:    $rdns"
    [ -n "$asn" ]     && log_ok "asn:     $asn"
    [ -n "$org" ]     && log_ok "org:     $org"
    [ -n "$netname" ] && log_ok "netname: $netname"
    [ -n "$country" ] && log_ok "geo:     $city, $country | isp: $isp"

    # Retorna JSON do bloco (capturado pelo caller)
    emit_json \
        "rdns=$rdns" \
        "asn=$asn" \
        "org=$org" \
        "netname=$netname" \
        "country=$country" \
        "city=$city" \
        "isp=$isp"
}

# --------------------------------------------------------------
# FASE 5 - ENUM WEB
# --------------------------------------------------------------

enum_web() {
    local host="$1" porta="$2"
    local proto="http"
    [ "$porta" = "443" ] || [ "$porta" = "8443" ] && proto="https"
    local url="${proto}://${host}:${porta}"

    log_info "web" "$url"
    sleep "$DELAY"

    local headers
    headers=$(curl -sk -I \
        --max-time 5 \
        --connect-timeout 3 \
        -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0" \
        "$url" 2>/dev/null)

    local status_code="" server="" powered_by="" redirect=""
    local missing_headers=()

    if [ -n "$headers" ]; then
        status_code=$(echo "$headers" | head -1 | grep -oE '[0-9]{3}')
        server=$(echo      "$headers" | grep -i "^server:"        | cut -d: -f2- | xargs)
        powered_by=$(echo  "$headers" | grep -i "^x-powered-by:" | cut -d: -f2- | xargs)
        redirect=$(echo    "$headers" | grep -i "^location:"      | cut -d: -f2- | xargs)

        [ -n "$status_code" ] && log_info "status"  "$status_code"
        [ -n "$server" ]      && log_info "server"  "$server"
        [ -n "$powered_by" ]  && log_info "powered" "$powered_by"
        [ -n "$redirect" ]    && log_warn "redirect -> $redirect"

        for hdr in "Strict-Transport-Security" "X-Frame-Options" \
                   "X-Content-Type-Options" "Content-Security-Policy" \
                   "Referrer-Policy" "Permissions-Policy"; do
            echo "$headers" | grep -qi "$hdr" \
                || missing_headers+=("$hdr")
        done
    fi

    # robots.txt
    sleep "$DELAY"
    local robots_paths=()
    local robots_raw
    robots_raw=$(curl -sk --max-time 5 \
        -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0" \
        "${url}/robots.txt" 2>/dev/null)

    if echo "$robots_raw" | grep -qi "disallow\|allow"; then
        log_info "robots" "encontrado"
        while IFS= read -r linha; do
            local path
            path=$(echo "$linha" | grep -iE "^(dis)?allow:" | awk '{print $2}')
            [ -n "$path" ] && robots_paths+=("$path")
        done <<< "$robots_raw"
    fi

    # sitemap
    sleep "$DELAY"
    local has_sitemap="false"
    local sm_code
    sm_code=$(curl -sk -o /dev/null -w "%{http_code}" --max-time 5 \
        -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0" \
        "${url}/sitemap.xml" 2>/dev/null)
    [ "$sm_code" = "200" ] && has_sitemap="true" && log_ok "sitemap.xml presente"

    # Serializa arrays pra JSON via python3
    local missing_json robots_json
    missing_json=$(python3 -c "import json,sys; print(json.dumps(sys.argv[1:]))" "${missing_headers[@]+"${missing_headers[@]}"}")
    robots_json=$(python3  -c "import json,sys; print(json.dumps(sys.argv[1:]))" "${robots_paths[@]+"${robots_paths[@]}"}")

    emit_json \
        "url=$url" \
        "proto=$proto" \
        "status_code=$status_code" \
        "server=$server" \
        "powered_by=$powered_by" \
        "redirect=$redirect" \
        "missing_security_headers=$missing_json" \
        "robots_paths=$robots_json" \
        "has_sitemap=$has_sitemap"
}

# --------------------------------------------------------------
# FASE 6 - ENUM SSH
# --------------------------------------------------------------

enum_ssh() {
    local host="$1"
    log_info "ssh" "banner grab"
    local banner
    banner=$(nc -w 3 "$host" 22 2>/dev/null | head -1 | tr -d '\r\n')
    [ -n "$banner" ] && log_ok "banner: $banner"
    emit_json "banner=$banner"
}

# --------------------------------------------------------------
# FASE 7 - ENUM FTP
# --------------------------------------------------------------

enum_ftp() {
    local host="$1"
    log_info "ftp" "testando login anonimo"
    local raw
    raw=$(printf 'USER anonymous\r\nPASS enum@recon.local\r\nQUIT\r\n' \
        | nc -w 3 "$host" 21 2>/dev/null)
    local anon="false"
    echo "$raw" | grep -q "^230" && anon="true" && log_ok "anonimo permitido"
    [ "$anon" = "false" ] && log_err "anonimo negado"
    emit_json "anonymous=$anon"
}

# --------------------------------------------------------------
# FASE 8 - ENUM SMB
# --------------------------------------------------------------

enum_smb() {
    local host="$1"
    log_info "smb" "enum de shares"
    local shares=()
    if command -v smbclient &>/dev/null; then
        while IFS= read -r share; do
            shares+=("$share")
            log_ok "share: $share"
        done < <(smbclient -L "$host" -N 2>/dev/null \
            | grep -E "Disk|IPC" \
            | awk '{print $1}')
    else
        log_warn "smbclient nao disponivel"
    fi
    local shares_json
    shares_json=$(python3 -c "import json,sys; print(json.dumps(sys.argv[1:]))" "${shares[@]+"${shares[@]}"}")
    emit_json "shares=$shares_json"
}

# --------------------------------------------------------------
# FASE 9 - ENUM DNS
# --------------------------------------------------------------

enum_dns() {
    local host="$1"
    log_info "dns" "zone transfer attempt"
    local records=()
    while IFS= read -r linha; do
        [ -n "$linha" ] && records+=("$linha")
    done < <(nslookup -type=any "$host" "$host" 2>/dev/null | tail -n +4 | head -20)
    local records_json
    records_json=$(python3 -c "import json,sys; print(json.dumps(sys.argv[1:]))" "${records[@]+"${records[@]}"}")
    emit_json "records=$records_json"
}

# --------------------------------------------------------------
# MAIN
# --------------------------------------------------------------

main() {
    local alvo_ip="" alvo_range="" porta_spec=""

    # Parsing de flags
    while getopts "i:r:p:d:" opt; do
        case "$opt" in
            i) alvo_ip="$OPTARG"    ;;
            r) alvo_range="$OPTARG" ;;
            p) porta_spec="$OPTARG" ;;
            d) DELAY="$OPTARG"      ;;
            *) uso                  ;;
        esac
    done

    # Validacao
    [ -z "$porta_spec" ]                          && { log_err "porta obrigatoria (-p)"; uso; }
    [ -z "$alvo_ip" ] && [ -z "$alvo_range" ]     && { log_err "informe -i IP ou -r CIDR"; uso; }
    [ -n "$alvo_ip" ] && [ -n "$alvo_range" ]     && { log_err "use -i ou -r, nao ambos"; uso; }

    check_deps

    log ""
    log "${B}${C}  host.enum.sh v${VERSION}${X}"
    log "${C}  stdout -> JSONL | stderr -> visual${X}"
    log ""

    # Resolve hosts e portas
    mapfile -t hosts  < <(resolver_hosts "$alvo_ip" "$alvo_range")
    mapfile -t portas < <(resolver_portas "$porta_spec")

    log "[*] hosts: ${#hosts[@]} | portas: ${#portas[@]} | delay: ${DELAY}s"
    log ""

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    for host in "${hosts[@]}"; do
        log ""
        log "${B}${G}== $host ==${X}"

        # IP info uma vez por host
        sleep "$DELAY"
        local ip_info_json
        ip_info_json=$(enum_ip_info "$host")

        for porta in "${portas[@]}"; do
            sleep "$DELAY"

            if scan_porta "$host" "$porta"; then
                local servico banner service_data_json
                servico=$(detectar_servico "$porta")
                log ""
                log_ok "${B}$host:$porta${X} | ${Y}$servico${X}"

                banner=$(banner_grab "$host" "$porta")
                [ -n "$banner" ] && log_info "banner" "$banner"

                # Enum por servico
                case "$servico" in
                    HTTP|HTTPS) service_data_json=$(enum_web  "$host" "$porta") ;;
                    SSH)        service_data_json=$(enum_ssh  "$host")           ;;
                    FTP)        service_data_json=$(enum_ftp  "$host")           ;;
                    SMB)        service_data_json=$(enum_smb  "$host")           ;;
                    DNS)        service_data_json=$(enum_dns  "$host")           ;;
                    *)          service_data_json="{}"                           ;;
                esac

                # Emite linha JSONL pra stdout
                emit_json \
                    "timestamp=$timestamp" \
                    "host=$host" \
                    "port=$porta" \
                    "service=$servico" \
                    "banner=$banner" \
                    "ip_info=$ip_info_json" \
                    "service_data=$service_data_json"

            else
                log_err "$host:$porta fechada/filtrada"
            fi
        done
    done

    log ""
    log "[*] concluido"
    log ""
}

main "$@"
