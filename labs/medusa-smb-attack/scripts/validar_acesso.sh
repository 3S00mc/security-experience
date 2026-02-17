#!/bin/bash
#
# Script: validar_acesso.sh
# Descrição: Valida credenciais descobertas usando smbclient
# Autor: Pentesting Lab
# Uso: ./validar_acesso.sh [IP_ALVO] [USUARIO] [SENHA]
#

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar parâmetros
if [ $# -lt 3 ]; then
    echo -e "${YELLOW}[!] Uso: $0 [IP_ALVO] [USUARIO] [SENHA]${NC}"
    echo -e "${YELLOW}[!] Exemplo: $0 192.168.56.101 msfadmin msfadmin${NC}"
    exit 1
fi

TARGET_IP=$1
USERNAME=$2
PASSWORD=$3

# Verificar se smbclient está instalado
if ! command -v smbclient &> /dev/null; then
    echo -e "${RED}[x] Erro: smbclient não está instalado!${NC}"
    echo -e "${YELLOW}[!] Instale com: sudo apt install smbclient${NC}"
    exit 1
fi

echo -e "${GREEN}[*] Validando credenciais...${NC}"
echo -e "${GREEN}[*] Alvo: $TARGET_IP${NC}"
echo -e "${GREEN}[*] Usuário: $USERNAME${NC}"
echo ""

# Listar compartilhamentos
echo -e "${YELLOW}[*] Listando compartilhamentos SMB...${NC}"
echo ""
smbclient -L //$TARGET_IP/ -U $USERNAME%$PASSWORD

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}[+] ✓ Credenciais válidas! Acesso confirmado.${NC}"
    echo ""
    echo -e "${YELLOW}[*] Para acessar um compartilhamento específico, use:${NC}"
    echo -e "${YELLOW}    smbclient //$TARGET_IP/[COMPARTILHAMENTO] -U $USERNAME%$PASSWORD${NC}"
else
    echo ""
    echo -e "${RED}[x] Falha na validação. Credenciais inválidas.${NC}"
fi
