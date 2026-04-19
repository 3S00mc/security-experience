#!/bin/bash

# ============================================================
# DS_ENUM - Stealth Enumeration Framework
# Saida: visual (stderr) + JSONL estruturado (arquivo)
# Pipeline: ds_enum.sh -> targets.jsonl -> enum_web.py
# ============================================================

VERDE="\e[32m"
VERMELHO="\e[31m"
AMARELO="\e[33m"
CIANO="\e[36m"
RESET="\e[0m"
BOLD="\e[1m"

echo "" >&2
echo -e "${BOLD}${CIANO}  DS_ENUM // STEALTH ENUMERATION FRAMEWORK${RESET}" >&2
echo -e "${CIANO}  Porta > Banner > Servico > IP-Info > JSONL out${RESET}" >&2
echo "" >&2

# -------- Uso
uso() {
    echo -e "Uso: $0 [-i IP | -r CIDR] -p PORTA[ou INICIO-FIM] [opcoes]" >&2
    echo "" >&2
    echo "Flags:" >&2
    echo "  -i IP          alvo unico" >&2
    echo "  -r CIDR        range CIDR (ex: 192.168.0.0/24)" >&2
    echo "  -p PORTA       porta unica, range ou lista (ex: 80 | 80-443 | 22,80,443)" >&2
    echo "  -d DELAY       delay em segundos entre requests (default: 1)" >&2
    echo "  -o OUTPUT      arquivo JSONL de saida (default: targets.jsonl)" >&2
    echo "" >&2
    echo "Exemplos:" >&2
    echo "  $0 -i 10.0.0.1 -p 80" >&2
    echo "  $0 -i 37.59.174.225 -p 80-443 -d 2 -o alvos.jsonl" >&2
    echo "  $0 -r 192.168.1.0/24 -p 22,80,443" >&2
    exit 1
}

# -------- Defaults
DELAY=1
OUTPUT="targets.jsonl"

# -------- Parsing de flags
while getopts "r:i:p:d:o:" opt; do
    case $opt in
        r) range=$OPTARG ;;
        i) ip=$OPTARG ;;
        p) porta=$OPTARG ;;
        d) DELAY=$OPTARG ;;
        o) OUTPUT=$OPTARG ;;
        *) uso ;;
    esac
done

[ -z "$porta" ] && { echo "[!] Porta obrigatoria" >&2; uso; }
[ -z "$range" ] && [ -z "$ip" ] && { echo "[!] Informe IP (-i) ou CIDR (-r)" >&2; uso; }

# -------- Helpers de log (sempre pra stderr, nao suja o JSONL)
log()  { echo -e "$1" >&2; }
info() { log "  ${CIANO}[$1]${RESET} $2"; }
ok()   { log "  ${VERDE}[+]${RESET} $1"; }
warn() { log "  ${AMARELO}[!]${RESET} $1"; }
err()  { log "  ${VERMELHO}[-]${RESET} $1"; }

# -------- Emite linha JSONL (append no arquivo de saida)
emit() {
    echo "$1" >> "$OUTPUT"
}

# -------- Escapa string pra JSON sem jq
json_str() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/}"
    echo "$s"
}

# -------- Resolve lista de hosts
if [ -n "$ip" ]; then
    hosts=("$ip")
else
    log "[*] Expandindo $range..."
    total=$(nmap -sL -n "$range" | grep "report for" | wc -l)
    log "[*] Hosts no range: $total"
    if [ "$total" -gt 500 ]; then
        log "[!] Range grande (>500 hosts). Reduza o CIDR ou use nmap diretamente."
        exit 1
    fi
    mapfile -t hosts < <(nmap -sL -n "$range" | awk '/report for/{print $NF}')
fi

# -------- Resolve portas (range e lista por virgula)
resolver_portas() {
    local p="$1"
    local lista=()
    IFS=',' read -ra partes <<< "$p"
    for parte in "${partes[@]}"; do
        if [[ "$parte" == *-* ]]; then
            inicio=${parte%-*}
            fim=${parte#*-}
            for n in $(seq "$inicio" "$fim"); do lista+=("$n"); done
        else
            lista+=("$parte")
        fi
    done
    echo "${lista[@]}"
}

mapfile -t portas < <(resolver_portas "$porta" | tr ' ' '\n')

# ============================================================
# FASE 1 - PORT SCAN via /dev/tcp
# ============================================================
scan_porta() {
    (echo >/dev/tcp/$1/$2) 2>/dev/null
}

# ============================================================
# FASE 2 - BANNER GRAB
# ============================================================
banner_grab() {
    local h=$1 p=$2
    echo "" | nc -w 2 "$h" "$p" 2>/dev/null | strings | head -3
}

# ============================================================
# FASE 3 - DETECCAO DE SERVICO
# ============================================================
detectar_servico() {
    case $2 in
        21)        echo "FTP" ;;
        22)        echo "SSH" ;;
        23)        echo "Telnet" ;;
        25|587|465) echo "SMTP" ;;
        53)        echo "DNS" ;;
        80|8080|8000|8008) echo "HTTP" ;;
        110)       echo "POP3" ;;
        143)       echo "IMAP" ;;
        443|8443)  echo "HTTPS" ;;
        445)       echo "SMB" ;;
        3306)      echo "MySQL" ;;
        3389)      echo "RDP" ;;
        5432)      echo "PostgreSQL" ;;
        6379)      echo "Redis" ;;
        27017)     echo "MongoDB" ;;
        *)         echo "unknown" ;;
    esac
}

# ============================================================
# FASE 4 - IP INFO (whois + rdns + geo)
# ============================================================
enum_ip_info() {
    local h=$1
    local rdns asn org netname country city isp

    # Reverse DNS
    rdns=$(host "$h" 2>/dev/null | grep "domain name pointer" | awk '{print $NF}' | head -1 | sed 's/\.$//')

    # whois
    local whois_raw
    whois_raw=$(whois "$h" 2>/dev/null)
    asn=$(echo "$whois_raw"     | grep -iE "^origin-as|^originas|^origin" | head -1 | awk '{print $NF}')
    org=$(echo "$whois_raw"     | grep -iE "^org-name|^OrgName"           | head -1 | cut -d: -f2- | xargs)
    netname=$(echo "$whois_raw" | grep -iE "^netname|^NetName"            | head -1 | cut -d: -f2- | xargs)

    # Geo via ip-api.com (free, sem chave, limite 45req/min)
    local geo_raw
    geo_raw=$(curl -s --max-time 4 "http://ip-api.com/json/${h}?fields=country,regionName,city,isp,org,as" 2>/dev/null)
    if [ -n "$geo_raw" ]; then
        country=$(echo "$geo_raw" | grep -o '"country":"[^"]*"'    | cut -d: -f2 | tr -d '"')
        city=$(echo "$geo_raw"    | grep -o '"city":"[^"]*"'       | cut -d: -f2 | tr -d '"')
        isp=$(echo "$geo_raw"     | grep -o '"isp":"[^"]*"'        | cut -d: -f2 | tr -d '"')
        [ -z "$org" ] && org=$(echo "$geo_raw" | grep -o '"org":"[^"]*"' | cut -d: -f2 | tr -d '"')
    fi

    info "ip-info" "$h"
    [ -n "$rdns" ]    && ok "rdns: $rdns"
    [ -n "$asn" ]     && ok "asn: $asn"
    [ -n "$org" ]     && ok "org: $org"
    [ -n "$netname" ] && ok "netname: $netname"
    [ -n "$country" ] && ok "geo: $city, $country | isp: $isp"

    # Retorna JSON parcial pra ser usado no emit principal
    printf '{"rdns":"%s","asn":"%s","org":"%s","netname":"%s","country":"%s","city":"%s","isp":"%s"}' \
        "$(json_str "$rdns")" \
        "$(json_str "$asn")" \
        "$(json_str "$org")" \
        "$(json_str "$netname")" \
        "$(json_str "$country")" \
        "$(json_str "$city")" \
        "$(json_str "$isp")"
}

# ============================================================
# FASE 5 - ENUM WEB (headers + robots + sitemap)
# ============================================================
enum_web_basic() {
    local h=$1 p=$2
    local proto="http"
    [ "$p" == "443" ] || [ "$p" == "8443" ] && proto="https"
    local url="${proto}://${h}:${p}"

    info "web" "$url"
    sleep "$DELAY"

    local headers
    headers=$(curl -sk -I --max-time 5 --connect-timeout 3 \
        -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0" \
        "$url" 2>/dev/null)

    local status_code server powered_by cookies_raw redirect_location
    local sec_headers=()
    local missing_headers=()

    if [ -n "$headers" ]; then
        status_code=$(echo "$headers"       | head -1 | grep -o '[0-9]\{3\}')
        server=$(echo "$headers"            | grep -i "^server:"         | cut -d: -f2- | xargs)
        powered_by=$(echo "$headers"        | grep -i "^x-powered-by:"  | cut -d: -f2- | xargs)
        redirect_location=$(echo "$headers" | grep -i "^location:"      | cut -d: -f2- | xargs)
        cookies_raw=$(echo "$headers"       | grep -i "^set-cookie:"    | head -5)

        [ -n "$server" ]    && info "server"     "$server"
        [ -n "$powered_by" ] && info "powered-by" "$powered_by"
        [ -n "$status_code" ] && info "status"   "$status_code"
        [ -n "$redirect_location" ] && warn "redirect -> $redirect_location"

        for hdr in "Strict-Transport-Security" "X-Frame-Options" "X-Content-Type-Options" \
                   "Content-Security-Policy" "Referrer-Policy" "Permissions-Policy"; do
            if echo "$headers" | grep -qi "$hdr"; then
                sec_headers+=("$hdr")
            else
                missing_headers+=("$hdr")
                warn "missing: $hdr"
            fi
        done
    fi

    # robots.txt
    sleep "$DELAY"
    local robots_entries=()
    local robots
    robots=$(curl -sk --max-time 5 \
        -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0" \
        "${url}/robots.txt" 2>/dev/null)
    if echo "$robots" | grep -qi "disallow\|allow"; then
        info "robots.txt" "encontrado"
        while IFS= read -r linha; do
            local path
            path=$(echo "$linha" | grep -iE "disallow:|allow:" | awk '{print $2}')
            [ -n "$path" ] && robots_entries+=("$path") && ok "$linha"
        done <<< "$robots"
    fi

    # sitemap
    sleep "$DELAY"
    local has_sitemap="false"
    local sitemap_code
    sitemap_code=$(curl -sk -o /dev/null -w "%{http_code}" --max-time 5 \
        -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0" \
        "${url}/sitemap.xml" 2>/dev/null)
    [ "$sitemap_code" == "200" ] && has_sitemap="true" && ok "sitemap.xml presente"

    # Monta JSON de resultado web
    local cookies_json="[]"
    if [ -n "$cookies_raw" ]; then
        local cookie_list
        cookie_list=$(echo "$cookies_raw" | while IFS= read -r c; do
            local name
            name=$(echo "$c" | sed 's/set-cookie: //i' | cut -d= -f1 | xargs)
            local flags=""
            echo "$c" | grep -qi "httponly" && flags="${flags}httponly,"
            echo "$c" | grep -qi "secure"   && flags="${flags}secure,"
            echo "$c" | grep -qi "samesite" && flags="${flags}samesite,"
            flags="${flags%,}"
            printf '{"name":"%s","flags":"%s"},' "$(json_str "$name")" "$(json_str "$flags")"
        done)
        cookies_json="[${cookie_list%,}]"
    fi

    local robots_json="[]"
    if [ ${#robots_entries[@]} -gt 0 ]; then
        local r_list=""
        for entry in "${robots_entries[@]}"; do r_list+="\"$(json_str "$entry")\","; done
        robots_json="[${r_list%,}]"
    fi

    local sec_json="[]"
    if [ ${#missing_headers[@]} -gt 0 ]; then
        local s_list=""
        for h in "${missing_headers[@]}"; do s_list+="\"$(json_str "$h")\","; done
        sec_json="[${s_list%,}]"
    fi

    printf '{"url":"%s","proto":"%s","status_code":"%s","server":"%s","powered_by":"%s","redirect":"%s","cookies":%s,"robots_paths":%s,"missing_security_headers":%s,"has_sitemap":%s}' \
        "$(json_str "$url")" \
        "$(json_str "$proto")" \
        "$(json_str "$status_code")" \
        "$(json_str "$server")" \
        "$(json_str "$powered_by")" \
        "$(json_str "$redirect_location")" \
        "$cookies_json" \
        "$robots_json" \
        "$sec_json" \
        "$has_sitemap"
}

# ============================================================
# FASE 6 - ENUM SSH
# ============================================================
enum_ssh_basic() {
    local h=$1
    local banner
    banner=$(nc -w 3 "$h" 22 2>/dev/null | head -1 | tr -d '\r')
    info "ssh" "banner: $banner"
    printf '{"banner":"%s"}' "$(json_str "$banner")"
}

# ============================================================
# FASE 7 - ENUM FTP
# ============================================================
enum_ftp_basic() {
    local h=$1
    local raw
    raw=$(echo -e "USER anonymous\nPASS enum@ds.local\nLIST\nQUIT" | nc -w 3 "$h" 21 2>/dev/null)
    local anon="false"
    if echo "$raw" | grep -q "230"; then
        anon="true"
        ok "FTP anonimo PERMITIDO"
    else
        err "FTP anonimo negado"
    fi
    printf '{"anonymous_allowed":%s}' "$anon"
}

# ============================================================
# FASE 8 - ENUM SMB
# ============================================================
enum_smb_basic() {
    local h=$1
    local shares=()
    if command -v smbclient &>/dev/null; then
        while IFS= read -r linha; do
            shares+=("$linha")
            ok "share: $linha"
        done < <(smbclient -L "$h" -N 2>/dev/null | grep -E "Disk|IPC" | awk '{print $1}')
    fi
    local s_list=""
    for s in "${shares[@]}"; do s_list+="\"$(json_str "$s")\","; done
    printf '{"shares":[%s]}' "${s_list%,}"
}

# ============================================================
# LOOP PRINCIPAL
# ============================================================

# Inicializa arquivo de saida
echo "" > "$OUTPUT"
# Remove linha vazia inicial
> "$OUTPUT"

log ""
log "[*] Hosts: ${#hosts[@]} | Portas: ${#portas[@]} | Delay: ${DELAY}s"
log "[*] JSONL output: $OUTPUT"
log ""

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

for h in "${hosts[@]}"; do
    log ""
    log "${BOLD}${VERDE}============================================================${RESET}"
    log "${BOLD}${VERDE}  ALVO: $h${RESET}"
    log "${BOLD}${VERDE}============================================================${RESET}"

    # IP info uma vez por host
    sleep "$DELAY"
    ip_info_json=$(enum_ip_info "$h")

    for p in "${portas[@]}"; do
        sleep "$DELAY"

        if scan_porta "$h" "$p"; then
            servico=$(detectar_servico "$h" "$p")
            log ""
            log "${VERDE}[+] ABERTA${RESET} $h:$p | ${AMARELO}$servico${RESET}"

            # Banner
            banner=$(banner_grab "$h" "$p")
            [ -n "$banner" ] && info "banner" "$banner"

            # Enum por servico
            service_json="{}"
            case $servico in
                HTTP|HTTPS)
                    service_json=$(enum_web_basic "$h" "$p")
                    ;;
                SSH)
                    service_json=$(enum_ssh_basic "$h")
                    ;;
                FTP)
                    service_json=$(enum_ftp_basic "$h")
                    ;;
                SMB)
                    service_json=$(enum_smb_basic "$h")
                    ;;
            esac

            # Emite linha JSONL com tudo consolidado
            emit "{\"timestamp\":\"${TIMESTAMP}\",\"host\":\"$(json_str "$h")\",\"port\":${p},\"service\":\"$(json_str "$servico")\",\"banner\":\"$(json_str "$banner")\",\"ip_info\":${ip_info_json},\"service_data\":${service_json}}"

        else
            err "$h:$p fechada/filtrada"
        fi
    done
done

log ""
log "[*] Concluido. ${OUTPUT} pronto pra enum_web.py"
log ""
