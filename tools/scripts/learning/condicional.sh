#!/bin/bash

#Condicoes usando o IF Else
echo "Voce esta na floresta e encontra uma Onca-pintada e um Ogro, contra qual escolhe lutar?"
echo "1-Ogro"
echo "2-Onca-pintada"
echo "Selecione o número"

#declaracao da variavel
read opcao

#teste com IF Else
if [ "$opcao" = "1" ] #tem que ter espaco entre o colchete e as aspas.
then
	echo "Que pena! o Ogro te aterrorizou de medo e voce foi despedacado. Tente novamente"
elif [ "$opcao" = "2" ]
then
	echo "Parabens, a Onca era PINTADA! voce se safou dessa."
else
	echo "Opcao invalida! Tente novamente."
fi


######################################CASO QUE NAO FUNCIONA####################################
#NAO FUNCIONA PORQUE OS OPERADORES -lt, -gl, -eq, -le, -ge e -ne SO PERMITEM NUMEROS INTEIROS COMO COMPARACAO
#read opcao
#if [ "$opcao" -eq "Ogro" ] #tem que ter espaco entre o colchete e as aspas. E com string nao aceita o comparador igual tem que ser o atribuicao.
#then
#	echo "Que pena! o Ogro te aterrorizou de medo e voce foi despedacado. Tente novamente"
#elif [ "$opcao" -eq "Onca-pintada" ]
#then
#	echo "Parabens, a Onca era PINTADA! voce se safou dessa."
#else
#        echo "Opcao invalida! Tente novamente."
#fi
#
##############################################################################################

#SCRIP USANDO O CASE
echo "Agora vamos a uma enquete."
echo "Escolha sua saga favorita..."
echo "1 - Star Wars"
echo "2 - Star Trek"
read filme

case $filme in
"1")
	echo "Escolheu Certo Parabens, a força está com você."
;;
"2")
	echo "Voce escolheu a opcao: 1 - Star Wars."
	echo "Obrigado por participar desta enquete!"
;;
esac
