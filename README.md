# 🛡️ Security Experience Portfolio

> **Portfólio Técnico de Segurança da Informação** - Projetos práticos, laboratórios documentados e experiências em Ethical Hacking, Pentest e Segurança Ofensiva.

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Pedro_Luiz_Costa-0077B5?style=flat&logo=linkedin)](https://www.linkedin.com/in/ptrcosta/)
[![GitHub](https://img.shields.io/badge/GitHub-3S00mc-181717?style=flat&logo=github)](https://github.com/3S00mc)
[![Security](https://img.shields.io/badge/Focus-Cybersecurity-red.svg)](https://github.com/3S00mc/security-experience)
[![License](https://img.shields.io/badge/License-Educational-blue.svg)](LICENSE)

---

## 👨‍💻 Sobre Mim

Profissional em desenvolvimento na área de **Segurança da Informação**, com foco em **Pentest Web e API**, **Cloud Security** e fundamentos de **Blue Team**. Este repositório documenta minha jornada através de laboratórios práticos, projetos reais e estudos aprofundados em vulnerabilidades e técnicas de exploração ética.

### 🎯 Áreas de Especialização

- 🔴 **Offensive Security**: Pentest Web, API Testing, Network Penetration
- ☁️ **Cloud Security**: AWS, Azure Security Assessments
- 🌐 **Web Application Security**: OWASP Top 10, SQL Injection, XSS, CSRF
- 🔍 **Vulnerability Assessment**: Análise de vulnerabilidades, exploração controlada
- 📝 **Technical Documentation**: Relatórios profissionais, write-ups técnicos

---

## 📂 Estrutura do Repositório

```
security-experience/
│
├── labs/                           # Laboratórios práticos documentados
│   ├── medusa-smb-attack/          # Ataque de força bruta SMB com Medusa
│   ├── web-vulnerabilities/        # Exploração de vulnerabilidades web
│   ├── api-security/               # Testes de segurança em APIs
│   └── cloud-security/             # Segurança em ambientes cloud
│
├── tools/                          # Ferramentas e scripts personalizados
│   ├── scripts/                    # Scripts customizados, para os mais diversos fins
│   ├── exploits/                   # PoCs de exploits para fins educacionais
│   └── automation/                 # Automação de tarefas de pentest
│
├── writeups/                       # Write-ups detalhados de CTFs e labs
│   ├── hackthebox/                 # Máquinas do HackTheBox
│   ├── tryhackme/                  # Salas do TryHackMe
│   └── vulnhub/                    # VMs do VulnHub
│
├── resources/                      # Recursos e referências
│   ├── checklists/                 # Checklists de pentest
│   ├── templates/                  # Templates de relatórios
│   └── notes/                      # Anotações de estudo
│
└── README.md                       # Este arquivo
```

---

## 🧪 Laboratórios Práticos

### 1. [Medusa SMB Brute Force Attack](./labs/medusa-smb-attack/)
**Status**: ✅ Concluído | **Categoria**: Network Security | **Dificuldade**: Iniciante

Demonstração de ataque de força bruta paralelo contra serviços SMB utilizando Medusa em ambiente Metasploitable 2.

**Técnicas Aplicadas**:
- Força bruta paralela com wordlists customizadas
- Validação de credenciais via protocolo SMB
- Exploração de credenciais padrão/fracas

**Ferramentas**:
- Medusa (brute force)
- smbclient (validação SMB)
- Kali Linux + Metasploitable 2

**Aprendizados**:
- Importância de políticas de senha forte
- Configuração de bloqueio de conta
- Monitoramento de tentativas de login

[📖 Ver documentação completa →](./labs/medusa-smb-attack/)

---

### 2. [Web Application Vulnerabilities] *(Em desenvolvimento)*
**Status**: 🔄 Em Progresso | **Categoria**: Web Security | **Dificuldade**: Intermediário

Exploração sistemática das vulnerabilidades do OWASP Top 10 em aplicações web reais.

**Vulnerabilidades Cobertas**:
- SQL Injection (SQLi)
- Cross-Site Scripting (XSS)
- Cross-Site Request Forgery (CSRF)
- Insecure Direct Object References (IDOR)
- Security Misconfiguration

---

### 3. [API Security Testing] *(Planejado)*
**Status**: 📋 Planejado | **Categoria**: API Security | **Dificuldade**: Intermediário

Testes de segurança em APIs REST/GraphQL com foco em autenticação, autorização e validação de dados.

---

## 📊 Estatísticas de Progresso

| Categoria | Labs Concluídos | Em Desenvolvimento | Planejados |
|-----------|-----------------|-------------------|-----------|
| Network Security | 1 | 0 | 2 |
| Web Security | 0 | 1 | 3 |
| API Security | 0 | 0 | 2 |
| Cloud Security | 0 | 0 | 2 |
| **Total** | **1** | **1** | **9** |

---

## 🎓 Metodologias e Frameworks

Este portfólio segue as melhores práticas e metodologias reconhecidas pela indústria:

### 🔐 Offensive Security
- **OWASP Top 10**: Framework para segurança de aplicações web
- **OWASP API Security Top 10**: Vulnerabilidades específicas de APIs
- **MITRE ATT&CK**: Táticas, técnicas e procedimentos (TTPs) de adversários
- **PTES**: Penetration Testing Execution Standard

### 📝 Documentação
- **Structured Reports**: Relatórios técnicos profissionais
- **Executive Summaries**: Resumos executivos para stakeholders
- **Technical Write-ups**: Documentação detalhada para auditores técnicos

### 🧰 Ferramentas Principais
- **Reconnaissance**: Nmap, Masscan, Amass, Subfinder
- **Web Application**: Burp Suite, OWASP ZAP, Nikto
- **Exploitation**: Metasploit, SQLMap, XSStrike
- **Brute Force**: Hydra, Medusa, John the Ripper
- **Cloud Security**: ScoutSuite, Prowler, CloudMapper

---

## 🏆 Certificações e Objetivos

### 🎯 Certificações Planejadas (2026-2027)
- [ ] **DCPT** (Desec Certified Penetration Tester)
- [ ] **CompTIA Security+**
- [ ] **CSIRT** (CSIRT - Hackers do Bem)
- [ ] **OSCP** (Offensive Security Certified Professional)
- [ ] **CEH** (Certified Ethical Hacker)

### 📚 Plataformas de Aprendizado
- [x] **TryHackMe**: Offensive Pentesting Path
- [x] **HackTheBox**: Active machines
- [ ] **PortSwigger Web Security Academy**: Web vulnerabilities
- [ ] **PentesterLab**: Web penetration testing

---

## ⚠️ Aviso Legal e Ética

**IMPORTANTE: Uso Exclusivamente Educacional**

Todo o conteúdo deste repositório é disponibilizado para fins **educacionais e de pesquisa** em segurança da informação.

### ✅ Práticas Éticas
- Todos os laboratórios são executados em **ambientes controlados** (VMs, laboratórios pessoais)
- **Nunca** realizo testes em sistemas de produção sem autorização explícita por escrito
- Sigo o **código de ética** de hacking ético e responsible disclosure
- Respeito todas as leis locais e internacionais sobre segurança cibernética

### ❌ Proibições
- **Nunca** utilize estas técnicas em sistemas que você não possui ou não tem autorização
- O uso não autorizado é **ILEGAL** e passível de punição criminal
- Não me responsabilizo por uso indevido deste material

### 📜 Leis Relevantes
- **Computer Fraud and Abuse Act (CFAA)** - EUA
- **Marco Civil da Internet (Lei 12.965/2014)** - Brasil
- **Lei Geral de Proteção de Dados (LGPD)** - Brasil
- **Council of Europe Convention on Cybercrime**

---

## 🤝 Contribuições e Contato

### 💬 Contribuições
Sinta-se livre para contribuir com:
- Sugestões de melhorias nos laboratórios
- Correções de bugs nos scripts
- Novas ideias de projetos
- Feedback sobre documentação

### 📧 Contato
- **LinkedIn**: [Pedro Luiz Costa](https://www.linkedin.com/in/ptrcosta/)
- **GitHub**: [@3S00mc](https://github.com/3S00mc)
- **Email**: [ptrcosta@proton.me](ptrcosta@proton.me)

---

## 📚 Recursos Úteis

### 📖 Documentação e Referências
- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)
- [PTES Technical Guidelines](http://www.pentest-standard.org/)
- [MITRE ATT&CK Framework](https://attack.mitre.org/)
- [PortSwigger Web Security Academy](https://portswigger.net/web-security)

### 🎥 Canais Educacionais
- [IppSec](https://www.youtube.com/c/ippsec) - HackTheBox Walkthroughs
- [LiveOverflow](https://www.youtube.com/c/LiveOverflow) - Security Research
- [John Hammond](https://www.youtube.com/c/JohnHammond010) - CTF & Malware Analysis
- [NetworkChuck](https://www.youtube.com/c/NetworkChuck) - Networking & Security

### 📚 Livros Recomendados
- **"The Web Application Hacker's Handbook"** - Dafydd Stuttard, Marcus Pinto
- **"Metasploit: The Penetration Tester's Guide"** - David Kennedy et al.
- **"Black Hat Python"** - Justin Seitz
- **"Hacking: The Art of Exploitation"** - Jon Erickson

---

## 📈 Roadmap 2026

### Q1 2026 (Janeiro - Março)
- [x] Setup inicial do repositório
- [x] Lab: Medusa SMB Brute Force Attack
- [ ] Lab: SQL Injection (DVWA/bWAPP)
- [ ] Lab: XSS Attacks (Reflected, Stored, DOM)

### Q2 2026 (Abril - Junho)
- [ ] Lab: CSRF Exploitation
- [ ] Lab: File Upload Vulnerabilities
- [ ] Lab: IDOR & Broken Access Control
- [ ] Certificação: eJPT

### Q3 2026 (Julho - Setembro)
- [ ] Lab: API Security Testing (REST/GraphQL)
- [ ] Lab: AWS Cloud Security Assessment
- [ ] Lab: Active Directory Enumeration
- [ ] 10 máquinas HackTheBox completas

### Q4 2026 (Outubro - Dezembro)
- [ ] Lab: Buffer Overflow (Windows/Linux)
- [ ] Lab: Privilege Escalation Techniques
- [ ] Preparação OSCP
- [ ] Certificação: OSCP (objetivo)

---

## 🌟 Projetos em Destaque

### 🔥 Mais Recente
**[Medusa SMB Brute Force Attack](./labs/medusa-smb-attack/)** - Demonstração completa de ataque de força bruta paralelo contra serviços SMB com scripts automatizados, wordlists customizadas e documentação profissional.

---

## 📊 Métricas do Repositório

![GitHub Stars](https://img.shields.io/github/stars/3S00mc/security-experience?style=social)
![GitHub Forks](https://img.shields.io/github/forks/3S00mc/security-experience?style=social)
![GitHub Issues](https://img.shields.io/github/issues/3S00mc/security-experience)
![Last Commit](https://img.shields.io/github/last-commit/3S00mc/security-experience)

---

## 🔖 Tags e Tópicos

`security` `hacking` `owasp` `cybersecurity` `pentest` `ethical-hacking` `webhacking` `pentesting-tools` `whitehacking` `offensive-security` `vulnerability-research` `infosec` `kali-linux` `metasploit` `bug-bounty`

---

<div align="center">

**⚔️ Hack The Planet | 🛡️ Protect The Systems | 🎓 Learn Ethically**

*"Security is not a product, but a process."* - Bruce Schneier

---

📅 **Última Atualização**: Fevereiro 2026  
🔄 **Status do Portfólio**: Ativamente Mantido  
⭐ **Se este repositório foi útil, considere dar uma estrela!**

Made with 💙 for the Cybersecurity Community

</div>
