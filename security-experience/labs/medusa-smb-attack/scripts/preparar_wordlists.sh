#!/bin/bash
#
# Script: preparar_wordlists.sh
# Descrição: Cria automaticamente os arquivos de wordlists para o ataque
# Autor: Pentesting Lab
# Uso: ./preparar_wordlists.sh
#

echo "[*] Preparando wordlists para ataque de força bruta..."

# Criando lista de usuários comuns
echo -e "admin\nuser\nmsfadmin\nroot\nadministrator\nguest\ntest\npostgres\ntomcat\nservice" > ../wordlists/usuarios.txt

# Criando lista de senhas fracas para teste
echo -e "123456\npassword\nadmin\nmsfadmin\nroot\n12345678\nqwerty\nabc123\npassword123\nletmein\nwelcome\nadmin123\nPassword1\nchangeme\n123456789" > ../wordlists/senhas.txt

echo "[+] Wordlists criadas com sucesso!"
echo "[+] Arquivo: ../wordlists/usuarios.txt ($(wc -l < ../wordlists/usuarios.txt) usuários)"
echo "[+] Arquivo: ../wordlists/senhas.txt ($(wc -l < ../wordlists/senhas.txt) senhas)"
echo ""
echo "[!] Total de combinações possíveis: $(($(wc -l < ../wordlists/usuarios.txt) * $(wc -l < ../wordlists/senhas.txt)))"
