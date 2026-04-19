#!/bin/bash
#Primeiro script em bash

var=$(date) #declaracao de variavel fixa usando um comando linux.

ip=10.0.0.1 #declaracao de variavel fixa pre definida pelo programador. imutavel.


#lista de exibicao na tela

echo "\nSYSADMIN: Pedro Luiz Costa\n" #Exibe o sysadmin na tela.

echo "Sistema Online: " $(uptime -p) #Comando uptime mostra o tempo que o sistema esta ligado.E a variavel $ permite mostrar o resultado na mesma linha do texto echo.

echo "Data:" $var #chamando a variavel fixa.

echo "Diretorio:" $(pwd) #comando simples mostrando o diretorio atual.

echo "IP" $ip #chamando a variavel fixa.


echo "Digite -> QUALQUER COMANDO DO SHELL -> ENTER" #testando variavel com dados inseridos pelo usuario.
read variavel #declarando a variavel que sera lida do usuario.
echo "\n"$($variavel) #adaptando o aprendizado anterior para chamar a variavel.

echo "\n\n##AVISO CASO TENHA ALGUM ERRO, REVISAR OS DADOS INSERIDOS. ESTE SCRIPT NAO TEM TRATAMENTO DE EXCECAO.##"
