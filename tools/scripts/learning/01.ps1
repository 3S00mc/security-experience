#PRIMEIRO CONTATO EM POWERSHELL .PS1
#COMANDOS UTEIS SHELL

#Get-Command | Select-String Test
#Get-Help comando


#Exemplo de uso de parametros e condicionais

#programa so funciona se for executado passando o parametro
param ($parUm)
if (!$parUm){
    echo "Uso do programa"
    echo ".\script01ps.ps1 [argumento]"
}else{
    echo "Meu Diretoro: $(pwd)" 
    Get-Location 
    Write-Host "Usuario: $(whoami)"
}


#VARIAVEL
$nomeUser = Read-Host "Digite seu nome"
echo "Bem Vindo ao PowerShell: $nomeUser!"

#CONDICOES E REPETICOES
$idade = Read-Host "Qual sua idade?"
if ($idade -ge "18"){
    echo "Maior de Idade!"
    }else{
    echo "Menor de Idade!"
    }

$ip = "10.0.0.1"
echo "Estamos testando a Rede $ip"
#o ping deve conter espacos entre os argumentos para rodar
$var1 = ping -n 1 $ip | Select-String "bytes=32"
$var1.Line.Split(' ')[2] -replace ":",""


#TRATAMENTO DE ERRO - Previne de mostrar erros em tela
#try {$var1 = ping -n 1 $ip | Select-String "bytes=32"
#$var1.Line.Split(' ')[2] -replace ":",""} catch {}



#CONTROLES E ITERACOES
echo "Estamos testando a Rede 37.59.174."
#a variavel 'host' é do sistema, portanto nao e possivel declara-la
foreach ($address in 1..254) {ping -n 1 37.59.174.$address | Select-String "bytes=32"}