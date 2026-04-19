#!/bin/bash

#SEQUENCIAS BASICAS DE ITERACAO
echo {1..50}
echo {a..z}

seq 1 3

for ip in $(seq 165 168);do echo "HOST" 192.168.0.$ip;done

for user in $(cat /home/ptrlcosta/Desktop/list/smtpuserslist.txt);do echo "USUARIOS	"$user;done

