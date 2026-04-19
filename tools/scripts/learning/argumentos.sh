#!/bin/bash

echo "Argumentos - Pedro Luiz Costa"

if [ "$1" = "" ]
then
	echo "MODO DE USO - $0 [IP] [PORTA]"
	echo "$0 192.168.0.1 80"
else
	echo "nc -vn $1 $2"
fi
