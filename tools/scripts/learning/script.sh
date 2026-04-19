#!/bin/bash

#Testando o nvim, ate acostumar vai ser doloroso, mas parece daora demais pro dia a dia.

echo "Testando as config do maravilhoso NVIM"
echo
echo "Script de Treino - DESEC SECURITY" " " $(uptime -p)

if ["$1" == ""] or if ["$2" == ""]
then
  echo "Utilizacao: $0 IP PORTA"
  echo "Varrendo Host: [ $1 ] [ $2 ]"
