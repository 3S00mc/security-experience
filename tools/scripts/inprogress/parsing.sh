#!/bin/bash
echo

echo "PARSING SCRIPT - Deteccao de IP - Versao.1.0"

if [ "$1" == "" ]
then
  echo "Modo de Uso:"
  echo "$0 businesscorp.com.br"
  echo
  exit 1
fi

wget $1 2>/dev/null

cat index.html | grep href | grep -E "https?:" | cut -d / -f3 | cut -d '"' -f1 > entrypoints

for x in $(cat entrypoints); do
  host=$(host $x 2>/dev/null | grep "has address" | awk '{print $NF}')
  [ -z "$host" ] && host="${x%%:*}"
  echo "$x - [ $host ]"
done

rm index.html entrypoints

echo
