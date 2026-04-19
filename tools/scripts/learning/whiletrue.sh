#!/bin/bash

echo "MODO DE USO"

while true
do
	echo "exibe mensagem"
	echo "S ou N"
	read var

if [ "$var" = "n" ]
then
break;
fi
done
