#include<stdio.h>


//VERSAO - 3
//estrutura para trabalhar com argumentos.
int main(int argc, char* argv[]) {

	char* ip;
	ip = argv[1];

	if (argc < 2) {
		printf("MODO DE USO -> ./02 192.168.0");
		return 0;
	}
	for (int i = 0; i <= 10; i++)
	{
		printf("varrendo host %s.%i \n",ip, i);
	}
}



//VERSAO - 2
////estrutura para trabalhar com argumentos.
//int main(int argc, char* argv[]) {
//
//	if (argc < 2) {
//		printf("MODO DE USO -> ./02 192.168.0");
//		return 0;
//	}
//	for (int i = 0; i <= 10; i++)
//	{
//		printf("varrendo host %s.%i \n", argv[1],i);
//	}
//}


//VERSAO - 1
////estrutura para trabalhar com argumentos.
//int main(int argc, char *argv[]) {
//
//	if(argc<2){
//		printf("MODO DE USO -> ./02 IP PORTA");
//		return 0;
//	}
//	printf("Varrendo HOST %s na PORTA %s\n\n",argv[1], argv[2]);
//}