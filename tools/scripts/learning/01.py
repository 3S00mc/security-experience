#!/usr/bin/python3

#VERSAO - 4
import sys

if len(sys.argv) <= 1:
    print ("MODO DE USO - python 01.py [URI] [PORTA]")
else:
    print ("PLC Offensive Security\n")
    for porta in range(1,10):
        print ("varrendo host",sys.argv[1],"na porta",porta)


##VERSAO - 3
#import sys #habilita o sys para pegar dados de entrada
#import os #executa comandos do sistema operacional

#print "varrendo host",sys.argv[1],"na porta",sys.argv[2]
#print "\nServicos Rodando:"
#os.system("netstat -nltp")



##versao - 2
#ip = raw_input("digite o endereco ip: ") #captura os dados no formato string
#porta = input("digite a porta: ")

#print "ip - %s porta - %d" %(ip,porta)



##VERSAO - 1
#ip = "172.16.1.55"
#porta = 1337

#print "programar em python e mais facil do que c, a linguagem entende qual o tipo de codigo tem que tratar."
#print "alem disso, e mais user friendly."
#print "IP -",ip, "Porta -",porta

