# 🧪 Laboratórios Práticos

Esta pasta contém laboratórios práticos de segurança da informação, organizados por categoria e nível de dificuldade.

---

## 📂 Estrutura

```
labs/
├── medusa-smb-attack/          # Network Security - Brute Force SMB
├── web-vulnerabilities/        # Web Application Security
├── api-security/               # API Security Testing
└── cloud-security/             # Cloud Security Assessments
```

---

## 🎯 Laboratórios Disponíveis

### ✅ Concluídos

#### 1. [Medusa SMB Brute Force Attack](./medusa-smb-attack/)
- **Categoria**: Network Security
- **Dificuldade**: ⭐ Iniciante
- **Duração**: ~30 minutos
- **Ambiente**: Kali Linux + Metasploitable 2

**Descrição**: Demonstração de ataque de força bruta paralelo contra serviços SMB usando Medusa.

**O que você aprenderá**:
- Técnicas de brute force paralelo
- Validação de credenciais SMB
- Importância de políticas de senha forte
- Mitigações contra ataques de força bruta

[📖 Acessar Lab →](./medusa-smb-attack/)

---

### 🔄 Em Desenvolvimento

#### 2. [Web Application Vulnerabilities] *(Em breve)*
- **Categoria**: Web Security
- **Dificuldade**: ⭐⭐ Intermediário
- **Ambiente**: DVWA / bWAPP

**Descrição**: Exploração das vulnerabilidades do OWASP Top 10.

**Tópicos**:
- SQL Injection (SQLi)
- Cross-Site Scripting (XSS)
- Cross-Site Request Forgery (CSRF)
- Insecure Direct Object References (IDOR)

---

### 📋 Planejados

#### 3. [API Security Testing]
- **Categoria**: API Security
- **Dificuldade**: ⭐⭐ Intermediário
- **Ambiente**: Custom API / Postman

**Descrição**: Testes de segurança em APIs REST e GraphQL.

---

#### 4. [Cloud Security Assessment]
- **Categoria**: Cloud Security
- **Dificuldade**: ⭐⭐⭐ Avançado
- **Ambiente**: AWS Free Tier

**Descrição**: Avaliação de segurança em ambientes cloud.

---

## 📊 Estatísticas

| Categoria | Concluídos | Em Progresso | Planejados |
|-----------|------------|--------------|------------|
| Network Security | 1 | 0 | 2 |
| Web Security | 0 | 1 | 3 |
| API Security | 0 | 0 | 2 |
| Cloud Security | 0 | 0 | 2 |
| **Total** | **1** | **1** | **9** |

---

## 🎓 Como Usar os Labs

### Pré-requisitos Gerais
- Conhecimento básico de Linux
- Kali Linux ou VM equivalente
- VirtualBox ou VMware
- Acesso a VMs vulneráveis (Metasploitable, DVWA, etc.)

### Estrutura Padrão de Cada Lab
```
lab-name/
├── README.md           # Documentação completa
├── scripts/            # Scripts automatizados
├── wordlists/          # Listas de palavras (se aplicável)
├── config.conf         # Configurações
└── QUICK_START.txt     # Guia rápido
```

### Fluxo de Trabalho Recomendado
1. Ler o README completo
2. Configurar o ambiente conforme instruções
3. Seguir o guia passo a passo
4. Experimentar variações
5. Documentar descobertas

---

## ⚠️ Avisos Importantes

### Uso Ético
- ✅ Use apenas em ambientes controlados
- ✅ Obtenha autorização por escrito
- ❌ Nunca teste sistemas de produção sem permissão
- ❌ Uso não autorizado é ILEGAL

### Segurança
- Mantenha suas VMs isoladas (Host-Only Network)
- Não exponha ambientes vulneráveis à internet
- Faça snapshots antes de experimentos destrutivos
- Mantenha logs para aprendizado

---

## 🤝 Contribuições

Quer adicionar um lab? Siga estas diretrizes:

1. **Estrutura Padrão**: Use a estrutura de diretórios acima
2. **Documentação Completa**: README detalhado com prints/evidências
3. **Scripts Funcionais**: Teste todos os scripts antes de submeter
4. **Mitigações**: Sempre inclua recomendações de segurança
5. **Ética**: Foco educacional e uso responsável

---

## 📚 Recursos Adicionais

- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)
- [HackTheBox](https://www.hackthebox.com/)
- [TryHackMe](https://tryhackme.com/)
- [VulnHub](https://www.vulnhub.com/)

---

<div align="center">

[⬅️ Voltar ao README Principal](../README.md)

**🎓 Aprenda | 🔒 Proteja | ⚡ Evolua**

</div>
