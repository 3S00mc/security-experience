#include<stdio.h>
#include<stdlib.h> //executa comandos do sistema (versao 3), é perigoso de se ter em sistema de PROD.

int main (void){

	////VERSAO - 3
	//printf("Portas TCP   [+] ABERTAS [+]\n\n");
	//system("netstat -nltp");



	////VERSAO - 2
	//char ip[16];
	//int porta;

	//printf("Digite o IP \n");
	////scanf("%s", &ip); //scanf nao trata a quantidade de bytes esta entrando ultrapassando os 15 bytes de char. Isso abre uma brecha de seguranca, pois permite a inclusao de uma grande quantidade de dados.
	//fgets(ip,16,stdin); //limita a saida de acordo com a quantidade estipulada, porem o excedente e carregado na proxima variavel.

	//printf("Digite a PORTA \n");
	//scanf("%i", &porta);

	//printf("Varrendo HOST [ %s ] na PORTA [ %i ]\n", ip, porta);



	////VERSAO - 1
	//printf("Primeiro Programa em Linguagem C\n");

	//printf("Demonstracao de variaveis\n\n");
	//char ip[] = "172.16.1.55";
	//int porta = 1337;
	//float version = 1.1;

	//printf("Varrendo HOST [ %s ] na PORTA [ %i ]\n", ip, porta);
	//printf("Versao do Software: %.1f \n", version);

	return 0;
}