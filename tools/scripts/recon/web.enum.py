#!/usr/bin/env python3
# ==============================================================
# web.enum.py
# Parsing profundo de surface web
# entrada:  targets.jsonl (stdout do host.enum.sh)
# stdout -> JSONL | stderr -> visual
# uso: python3 web.enum.py -i targets.jsonl [-d DELAY] [-w WORDLIST]
# ==============================================================

import sys
import json
import time
import re
import socket
import argparse
import ipaddress
from datetime import datetime, timezone
from urllib.parse import urlparse, urljoin

# --------------------------------------------------------------
# DEPENDENCIAS
# --------------------------------------------------------------

try:
    import requests
    from urllib3.exceptions import InsecureRequestWarning
    requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
except ImportError:
    print("[!] requests ausente. instale: pip install requests", file=sys.stderr)
    sys.exit(1)

try:
    from bs4 import BeautifulSoup, Comment
except ImportError:
    print("[!] beautifulsoup4 ausente. instale: pip install beautifulsoup4", file=sys.stderr)
    sys.exit(1)

# --------------------------------------------------------------
# CONSTANTES
# --------------------------------------------------------------

VERSION = "1.0.0"

UA = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/120.0.0.0 Safari/537.36"
)

HEADERS_BASE = {
    "User-Agent":      UA,
    "Accept":          "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.5",
    "Accept-Encoding": "gzip, deflate",
    "Connection":      "close",
}

# Cores (stderr only)
G = "\033[32m"
R = "\033[31m"
Y = "\033[33m"
C = "\033[36m"
B = "\033[1m"
X = "\033[0m"

# --------------------------------------------------------------
# FINGERPRINTS DE TECNOLOGIA
# --------------------------------------------------------------

TECH_SIGS = {
    "WordPress":    {"html": ["wp-content", "wp-includes", "wp-json"],        "header": [],                          "cookie": []},
    "Joomla":       {"html": ["/components/com_", "Joomla!"],                 "header": [],                          "cookie": []},
    "Drupal":       {"html": ["Drupal.settings", "/sites/default/"],          "header": ["x-generator: drupal"],     "cookie": []},
    "Laravel":      {"html": [],                                               "header": [],                          "cookie": ["laravel_session"]},
    "Django":       {"html": [],                                               "header": [],                          "cookie": ["csrftoken", "sessionid"]},
    "Rails":        {"html": [],                                               "header": [],                          "cookie": ["_rails_session"]},
    "Express":      {"html": [],                                               "header": ["x-powered-by: express"],   "cookie": []},
    "PHP":          {"html": [],                                               "header": ["x-powered-by: php"],       "cookie": ["PHPSESSID"]},
    "ASP.NET":      {"html": [],                                               "header": ["x-powered-by: asp.net"],   "cookie": ["ASP.NET_SessionId", ".ASPXAUTH"]},
    "Apache":       {"html": [],                                               "header": ["server: apache"],          "cookie": []},
    "Nginx":        {"html": [],                                               "header": ["server: nginx"],           "cookie": []},
    "IIS":          {"html": [],                                               "header": ["server: microsoft-iis"],   "cookie": []},
    "Cloudflare":   {"html": [],                                               "header": ["cf-ray", "server: cloudflare"], "cookie": ["__cflb", "__cf_bm"]},
    "Varnish":      {"html": [],                                               "header": ["x-varnish"],               "cookie": []},
    "React":        {"html": ["__REACT_DEVTOOLS", "react-root", "_react"],    "header": [],                          "cookie": []},
    "Vue":          {"html": ["__vue__", "data-v-"],                          "header": [],                          "cookie": []},
    "Angular":      {"html": ["ng-version", "ng-app"],                        "header": [],                          "cookie": []},
    "jQuery":       {"html": ["jquery.min.js", "jquery-"],                    "header": [],                          "cookie": []},
    "Bootstrap":    {"html": ["bootstrap.min.css", "bootstrap.min.js"],       "header": [],                          "cookie": []},
    "Swagger":      {"html": ["swagger-ui", "openapi"],                       "header": [],                          "cookie": []},
    "Grafana":      {"html": ["grafana", "GrafanaBootData"],                  "header": [],                          "cookie": []},
    "Jenkins":      {"html": ["Jenkins", "jnlpJars"],                         "header": ["x-jenkins"],               "cookie": []},
    "phpMyAdmin":   {"html": ["phpMyAdmin", "pma_"],                          "header": [],                          "cookie": []},
    "Tomcat":       {"html": ["Apache Tomcat"],                               "header": ["server: apache-coyote"],   "cookie": []},
}

# Paths sensiveis pra probe
SENSITIVE_PATHS = [
    # admin
    "/admin", "/administrator", "/wp-admin", "/wp-login.php",
    "/login", "/signin", "/dashboard", "/panel", "/control",
    # apis
    "/api", "/api/v1", "/api/v2", "/graphql",
    "/swagger", "/swagger-ui", "/swagger-ui.html",
    "/openapi.json", "/api-docs",
    # leaks
    "/.env", "/.git", "/.git/config",
    "/phpinfo.php", "/info.php",
    "/server-status", "/server-info",
    "/.htaccess", "/web.config",
    # monitoramento
    "/metrics", "/actuator", "/actuator/health",
    "/actuator/env", "/health", "/status", "/_health",
    # backup/debug
    "/backup", "/debug", "/test", "/tmp",
    # descoberta
    "/robots.txt", "/sitemap.xml", "/crossdomain.xml",
]

# --------------------------------------------------------------
# HELPERS DE LOG (stderr)
# --------------------------------------------------------------

def log(msg=""):            print(msg, file=sys.stderr)
def log_ok(msg):            print(f"  {G}[+]{X} {msg}", file=sys.stderr)
def log_err(msg):           print(f"  {R}[-]{X} {msg}", file=sys.stderr)
def log_warn(msg):          print(f"  {Y}[!]{X} {msg}", file=sys.stderr)
def log_info(tag, msg):     print(f"  {C}[{tag}]{X} {msg}", file=sys.stderr)

# --------------------------------------------------------------
# EMIT JSON (stdout)
# --------------------------------------------------------------

def emit_json(data: dict):
    print(json.dumps(data, ensure_ascii=False))
    sys.stdout.flush()

# --------------------------------------------------------------
# USO
# --------------------------------------------------------------

def uso():
    print(file=sys.stderr)
    print(f"{B}{C}web.enum.py{X} {C}v{VERSION}{X}", file=sys.stderr)
    print("Parsing profundo de surface web", file=sys.stderr)
    print(file=sys.stderr)
    print(f"{B}SINTAXE{X}", file=sys.stderr)
    print( "  web.enum.py -i <JSONL> [-d <DELAY>] [-w <WORDLIST>]", file=sys.stderr)
    print(file=sys.stderr)
    print(f"{B}FLAGS{X}", file=sys.stderr)
    print(f"  {Y}-i{X} JSONL      entrada do host.enum.sh    default: targets.jsonl", file=sys.stderr)
    print(f"  {Y}-d{X} DELAY      segundos entre requests    default: 1", file=sys.stderr)
    print(f"  {Y}-w{X} WORDLIST   wordlist pra fuzzing dirs  opcional", file=sys.stderr)
    print(file=sys.stderr)
    print(f"{B}EXEMPLOS{X}", file=sys.stderr)
    print( "  web.enum.py -i targets.jsonl", file=sys.stderr)
    print( "  web.enum.py -i targets.jsonl -d 2", file=sys.stderr)
    print( "  web.enum.py -i targets.jsonl -w /usr/share/wordlists/dirb/common.txt", file=sys.stderr)
    print(file=sys.stderr)
    print(f"{B}PIPELINE{X}", file=sys.stderr)
    print( "  host.enum.sh -i 10.0.0.1 -p 80 > targets.jsonl", file=sys.stderr)
    print( "  web.enum.py  -i targets.jsonl   > surface.jsonl", file=sys.stderr)
    print( "  web.enum.py  -i surface_new_targets.jsonl > surface2.jsonl", file=sys.stderr)
    print(file=sys.stderr)
    print(f"{B}FASES{X}", file=sys.stderr)
    print(f"  {C}1{X}  deteccao de tecnologias via header, HTML, cookie", file=sys.stderr)
    print(f"  {C}2{X}  extracao de links, forms, JS, API hints, emails, comentarios", file=sys.stderr)
    print(f"  {C}3{X}  probe de paths sensiveis", file=sys.stderr)
    print(f"  {C}4{X}  resolucao e teste de subdominios encontrados no HTML", file=sys.stderr)
    print(f"  {C}5{X}  novos alvos emitidos no JSONL de saida", file=sys.stderr)
    print(file=sys.stderr)
    print(f"{B}NOTAS{X}", file=sys.stderr)
    print( "  · so processa entradas com service HTTP ou HTTPS", file=sys.stderr)
    print( "  · novos alvos sao emitidos com origin: subdomain | internal_link", file=sys.stderr)
    print(file=sys.stderr)
    sys.exit(1)

# --------------------------------------------------------------
# DEPENDENCIAS PYTHON
# --------------------------------------------------------------

def check_deps():
    pass  # já tratado nos imports acima com mensagens claras

# --------------------------------------------------------------
# HTTP SESSION
# --------------------------------------------------------------

def make_session() -> requests.Session:
    s = requests.Session()
    s.headers.update(HEADERS_BASE)
    s.verify = False
    return s

def safe_get(session, url, timeout=6, allow_redirects=False, delay=1):
    try:
        time.sleep(delay)
        return session.get(url, timeout=timeout, allow_redirects=allow_redirects)
    except (
        requests.exceptions.ConnectionError,
        requests.exceptions.Timeout,
        requests.exceptions.TooManyRedirects,
        requests.exceptions.RequestException,
    ):
        return None

# --------------------------------------------------------------
# FASE 1 - DETECCAO DE TECNOLOGIAS
# --------------------------------------------------------------

def detect_technologies(html: str, headers: dict, cookies: dict) -> list[str]:
    detected  = []
    hdrs_str  = " ".join(f"{k}: {v}".lower() for k, v in headers.items())
    cook_str  = " ".join(cookies.keys()).lower()
    html_low  = html.lower()

    for tech, sigs in TECH_SIGS.items():
        found = (
            any(s.lower() in html_low  for s in sigs["html"])   or
            any(s.lower() in hdrs_str  for s in sigs["header"]) or
            any(s.lower() in cook_str  for s in sigs["cookie"])
        )
        if found:
            detected.append(tech)

    return detected

# --------------------------------------------------------------
# FASE 2 - EXTRACAO DE SURFACE
# --------------------------------------------------------------

def extract_surface(html: str, base_url: str) -> dict:
    soup       = BeautifulSoup(html, "html.parser")
    base       = urlparse(base_url)
    base_host  = base.netloc
    root_domain = ".".join(base_host.split(".")[-2:])

    links      = set()
    external   = set()
    subdomains = set()
    forms      = []
    js_files   = set()
    api_hints  = set()
    emails     = set()
    comments   = []
    meta       = {}

    # Links <a href>
    for tag in soup.find_all("a", href=True):
        href = tag["href"].strip()
        if not href or href.startswith(("#", "javascript:", "mailto:", "tel:")):
            continue
        full   = urljoin(base_url, href)
        parsed = urlparse(full)
        if not parsed.scheme.startswith("http"):
            continue
        if parsed.netloc == base_host:
            links.add(full)
        elif parsed.netloc:
            external.add(full)
            if root_domain in parsed.netloc and parsed.netloc != base_host:
                subdomains.add(parsed.netloc)

    # Forms
    for form in soup.find_all("form"):
        action = form.get("action", "")
        method = form.get("method", "GET").upper()
        fields = [
            {"name": i.get("name", ""), "type": i.get("type", "text")}
            for i in form.find_all(["input", "select", "textarea"])
            if i.get("name")
        ]
        forms.append({
            "action": urljoin(base_url, action) if action else base_url,
            "method": method,
            "fields": fields,
        })

    # Scripts externos + API hints
    for tag in soup.find_all("script", src=True):
        src  = tag["src"].strip()
        full = urljoin(base_url, src)
        js_files.add(full)
        if any(k in src.lower() for k in ["/api/", "graphql", "endpoint", "service"]):
            api_hints.add(full)

    # Scripts inline - API paths e emails
    for tag in soup.find_all("script"):
        if not tag.string:
            continue
        content = tag.string
        for m in re.finditer(r'["\'](/api/[^"\']+|/v\d+/[^"\']+|/graphql[^"\']*)["\']', content):
            api_hints.add(urljoin(base_url, m.group(1)))
        for m in re.finditer(r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}', content):
            emails.add(m.group(0))

    # Emails no HTML geral
    for m in re.finditer(r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}', html):
        emails.add(m.group(0))

    # Comentarios HTML
    for c in soup.find_all(string=lambda t: isinstance(t, Comment)):
        stripped = c.strip()
        if len(stripped) > 3:
            comments.append(stripped[:200])

    # Meta tags
    for tag in soup.find_all("meta"):
        name    = tag.get("name", tag.get("property", "")).lower()
        content = tag.get("content", "")
        if name in {"generator", "author", "description", "keywords", "robots"}:
            meta[name] = content

    return {
        "internal_links":  sorted(links),
        "external_links":  sorted(external),
        "subdomains":      sorted(subdomains),
        "forms":           forms,
        "js_files":        sorted(js_files),
        "api_hints":       sorted(api_hints),
        "emails":          sorted(emails),
        "html_comments":   comments,
        "meta":            meta,
    }

# --------------------------------------------------------------
# FASE 3 - PROBE DE PATHS SENSIVEIS
# --------------------------------------------------------------

def probe_paths(session, base_url: str, delay: float, wordlist: str | None) -> list[dict]:
    paths = list(SENSITIVE_PATHS)

    if wordlist:
        try:
            with open(wordlist) as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith("#"):
                        paths.append(f"/{line}" if not line.startswith("/") else line)
        except FileNotFoundError:
            log_warn(f"wordlist nao encontrada: {wordlist}")

    # Deduplica mantendo ordem
    seen  = set()
    paths = [p for p in paths if not (p in seen or seen.add(p))]

    log_info("probe", f"{len(paths)} paths | delay: {delay}s")

    findings = []
    for path in paths:
        url = base_url.rstrip("/") + path
        r   = safe_get(session, url, delay=delay)
        if r is None:
            continue

        entry = {
            "path":     path,
            "url":      url,
            "status":   r.status_code,
            "size":     len(r.content),
            "redirect": r.headers.get("Location", ""),
        }

        if r.status_code == 200:
            log_ok(f"[200] {url}  ({len(r.content)}b)")
            findings.append(entry)
        elif r.status_code in (301, 302):
            log_warn(f"[{r.status_code}] {url}  -> {r.headers.get('Location', '?')}")
            findings.append(entry)
        elif r.status_code == 401:
            log_warn(f"[401] {url}  (auth required)")
            findings.append(entry)
        elif r.status_code == 403:
            log_warn(f"[403] {url}  (forbidden - existe)")
            findings.append(entry)

    return findings

# --------------------------------------------------------------
# FASE 4 - RESOLUCAO DE SUBDOMINIOS
# --------------------------------------------------------------

def resolve_host(hostname: str) -> str | None:
    try:
        return socket.gethostbyname(hostname)
    except socket.gaierror:
        return None

def probe_subdomains(subdomains: list[str], session, delay: float) -> list[dict]:
    resolved = []
    for sub in subdomains:
        ip = resolve_host(sub)
        if not ip:
            log_err(f"nao resolveu: {sub}")
            continue
        for proto in ("https", "http"):
            r = safe_get(session, f"{proto}://{sub}", delay=delay)
            if r:
                entry = {
                    "hostname": sub,
                    "ip":       ip,
                    "proto":    proto,
                    "url":      f"{proto}://{sub}",
                    "status":   r.status_code,
                    "server":   r.headers.get("Server", ""),
                }
                log_ok(f"{proto}://{sub}  [{r.status_code}]  ip: {ip}  server: {entry['server']}")
                resolved.append(entry)
                break
    return resolved

# --------------------------------------------------------------
# PROCESSADOR POR HOST
# --------------------------------------------------------------

def process_entry(entry: dict, delay: float, wordlist: str | None) -> dict:
    host    = entry["host"]
    port    = entry["port"]
    service = entry["service"]
    ip_info = entry.get("ip_info", {})
    svc     = entry.get("service_data", {})

    proto = svc.get("proto", "http")
    url   = svc.get("url", f"{proto}://{host}:{port}")

    log()
    log(f"{B}{C}{'=' * 60}{X}")
    log(f"{B}{C}  {host}:{port}  [{service}]{X}")
    if ip_info.get("rdns"):  log(f"{C}  rdns: {ip_info['rdns']}{X}")
    if ip_info.get("org"):   log(f"{C}  org:  {ip_info['org']}{X}")
    log(f"{B}{C}{'=' * 60}{X}")

    session = make_session()

    result = {
        "timestamp":   datetime.now(timezone.utc).isoformat(),
        "host":        host,
        "port":        port,
        "service":     service,
        "url":         url,
        "ip_info":     ip_info,
        "host_enum":   svc,
        "final_url":   "",
        "technologies": [],
        "surface":     {},
        "sensitive":   [],
        "subdomains":  [],
        "new_targets": [],
    }

    # Request principal com redirect
    log_info("fetch", url)
    r = safe_get(session, url, allow_redirects=True, delay=delay)

    if r is None:
        log_err(f"sem resposta de {url}")
        return result

    final_url    = r.url
    result["final_url"] = final_url

    if final_url != url:
        log_warn(f"redirect -> {final_url}")

    # FASE 1 - Tecnologias
    techs = detect_technologies(r.text, dict(r.headers), dict(r.cookies))
    if techs:
        log_info("tech", ", ".join(techs))
    result["technologies"] = techs

    # FASE 2 - Surface
    log_info("parse", "links · forms · scripts · comentarios · emails")
    surface = extract_surface(r.text, final_url)
    result["surface"] = surface

    if surface["forms"]:
        log_info("forms", f"{len(surface['forms'])} encontrado(s)")
        for form in surface["forms"]:
            fields_str = ", ".join(f"{f['name']}({f['type']})" for f in form["fields"])
            log_ok(f"{form['method']}  {form['action']}  |  {fields_str}")

    if surface["api_hints"]:
        log_info("api", f"{len(surface['api_hints'])} endpoint(s) inferido(s)")
        for hint in surface["api_hints"]:
            log_ok(hint)

    if surface["html_comments"]:
        log_info("comments", f"{len(surface['html_comments'])} comentario(s)")
        for c in surface["html_comments"][:5]:
            log_warn(c[:120])

    if surface["emails"]:
        log_info("emails", "  ".join(surface["emails"]))

    if surface["meta"].get("generator"):
        log_info("generator", surface["meta"]["generator"])

    # FASE 3 - Probe de paths
    log()
    sensitive = probe_paths(session, final_url, delay, wordlist)
    result["sensitive"] = sensitive

    # FASE 4 - Subdominios
    if surface["subdomains"]:
        log()
        log_info("subdomains", f"{len(surface['subdomains'])} encontrado(s) no HTML")
        resolved = probe_subdomains(surface["subdomains"], session, delay)
        result["subdomains"] = resolved

        for sub in resolved:
            result["new_targets"].append({
                "host":    sub["hostname"],
                "port":    443 if sub["proto"] == "https" else 80,
                "service": "HTTPS" if sub["proto"] == "https" else "HTTP",
                "url":     sub["url"],
                "ip_info": {"rdns": "", "asn": "", "org": "", "netname": "",
                             "country": "", "city": "", "isp": ""},
                "service_data": {"proto": sub["proto"], "url": sub["url"]},
                "origin":  "subdomain",
            })

    # FASE 5 - Links internos com host diferente
    base_netloc = urlparse(final_url).netloc
    seen_hosts  = {t["host"] for t in result["new_targets"]}

    for link in surface["internal_links"]:
        parsed = urlparse(link)
        if parsed.netloc and parsed.netloc != base_netloc and parsed.netloc not in seen_hosts:
            seen_hosts.add(parsed.netloc)
            result["new_targets"].append({
                "host":    parsed.hostname or "",
                "port":    parsed.port or (443 if parsed.scheme == "https" else 80),
                "service": "HTTPS" if parsed.scheme == "https" else "HTTP",
                "url":     link,
                "ip_info": {"rdns": "", "asn": "", "org": "", "netname": "",
                             "country": "", "city": "", "isp": ""},
                "service_data": {"proto": parsed.scheme, "url": link},
                "origin":  "internal_link",
            })

    if result["new_targets"]:
        log()
        log_info("expand", f"{len(result['new_targets'])} novo(s) alvo(s)")
        for t in result["new_targets"]:
            log_ok(f"{t['url']}  [{t['origin']}]")

    return result

# --------------------------------------------------------------
# MAIN
# --------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("-i", "--input",    default="targets.jsonl")
    parser.add_argument("-d", "--delay",    type=float, default=1.0)
    parser.add_argument("-w", "--wordlist", default=None)
    parser.add_argument("-h", "--help",     action="store_true")
    args = parser.parse_args()

    if args.help:
        uso()

    log()
    log(f"{B}{C}  web.enum.py v{VERSION}{X}")
    log(f"{C}  stdout -> JSONL | stderr -> visual{X}")
    log()

    # Carrega JSONL
    try:
        with open(args.input) as f:
            entries = [json.loads(line) for line in f if line.strip()]
    except FileNotFoundError:
        log_err(f"arquivo nao encontrado: {args.input}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        log_err(f"JSONL invalido: {e}")
        sys.exit(1)

    web_entries = [e for e in entries if e.get("service") in ("HTTP", "HTTPS")]

    log(f"[*] {len(entries)} entradas  |  {len(web_entries)} HTTP/HTTPS  |  delay: {args.delay}s")
    log()

    all_new_targets = []

    for entry in web_entries:
        result = process_entry(entry, args.delay, args.wordlist)
        emit_json(result)
        all_new_targets.extend(result.get("new_targets", []))

    # Sumario
    log()
    log(f"{B}{G}{'=' * 60}{X}")
    log(f"{B}{G}  SUMARIO{X}")
    log(f"{G}{'=' * 60}{X}")
    log(f"  hosts processados:   {len(web_entries)}")
    log(f"  novos alvos:         {len(all_new_targets)}")

    if all_new_targets:
        log()
        log(f"  {Y}novos alvos descobertos:{X}")
        seen = set()
        for t in all_new_targets:
            key = f"{t.get('host')}:{t.get('port')}"
            if key not in seen:
                seen.add(key)
                log(f"    {G}[+]{X} {t.get('url')}  [{t.get('origin')}]")

        # Emite novos alvos como JSONL separado via stderr (nao polui stdout)
        log()
        log(f"  {C}para expandir a surface:{X}")
        log(f"  web.enum.py -i <(grep new_targets surface.jsonl) -d {args.delay}")

    log()

if __name__ == "__main__":
    main()
