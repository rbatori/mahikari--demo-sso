# Procedimento — Fase 2: Configuração da PKI (CA + Certificados)

**Mahikari — Demo VPN sem Senha**  
Versão: 2026-05-23

> Passo a passo para criar a CA interna, certificados do servidor e dos clientes VPN no pfSense.

---

## Pré-requisitos

- pfSense operacional (Fase 1 concluída)
- Acesso à WebGUI do pfSense (https://192.168.1.1)

---

## 2.1. Criar CA Interna (Certificate Authority)

1. Acessar **System > Cert. Manager > CAs**
2. Clicar **+ Add**

| Campo | Valor |
|---|---|
| Descriptive name | `Mahikari-VPN-CA` |
| Method | Create an internal Certificate Authority |
| Key type | RSA |
| Key length | 4096 |
| Digest Algorithm | SHA256 |
| Lifetime (days) | 3650 (10 anos) |
| Common Name | `Mahikari VPN CA` |
| Country Code | BR |
| State/Province | SP |
| City | (cidade da organização) |
| Organization | Mahikari |
| Organizational Unit | TI |

3. Clicar **Save**

### Verificação

Após salvar, a CA deve aparecer na lista com:
- Nome: `Mahikari-VPN-CA`
- Internal: Yes
- Certificates: 0 (ainda não emitiu nenhum)

---

## 2.2. Criar Certificado do Servidor OpenVPN

1. Acessar **System > Cert. Manager > Certificates**
2. Clicar **+ Add/Sign**

| Campo | Valor |
|---|---|
| Method | Create an internal Certificate |
| Descriptive name | `vpn-server` |
| Certificate authority | `Mahikari-VPN-CA` |
| Key type | RSA |
| Key length | 4096 |
| Digest Algorithm | SHA256 |
| Lifetime (days) | 730 (2 anos) |
| Common Name | `vpn-server.mahikari.local` |
| Certificate Type | **Server Certificate** |

> **Importante:** O tipo deve ser **Server Certificate** para que o OpenVPN aceite este certificado como certificado do servidor.

3. Clicar **Save**

### Verificação

O certificado `vpn-server` deve aparecer na lista com:
- CA: `Mahikari-VPN-CA`
- Type: Server

---

## 2.3. Criar Certificate Revocation List (CRL)

1. Acessar **System > Cert. Manager > Certificate Revocation**
2. Clicar **+ Add** (ao lado da CA `Mahikari-VPN-CA`)

| Campo | Valor |
|---|---|
| Certificate Authority | `Mahikari-VPN-CA` |
| Method | Create an internal Certificate Revocation List |
| Descriptive name | `Mahikari-VPN-CRL` |
| Lifetime | 3650 (mesmo tempo da CA) |

3. Clicar **Save**

### Verificação

A CRL `Mahikari-VPN-CRL` deve aparecer na lista, associada à CA `Mahikari-VPN-CA`, com 0 certificados revogados.

---

## 2.4. Criar Certificado de Usuário (Teste)

Para cada usuário que terá acesso VPN, é necessário emitir um certificado individual.

### Criar usuário no pfSense (opcional, mas recomendado)

Se desejar vincular certificados a usuários do pfSense:

1. Acessar **System > User Manager > Users**
2. Clicar **+ Add**

| Campo | Valor |
|---|---|
| Username | `usuario-teste-01` |
| Password | (definir — não será usado para VPN, apenas para gestão) |
| Full name | `Usuário Teste 01` |
| Certificate | Marcar **"Click to create a user certificate"** |

Se marcou a opção de certificado:

| Campo | Valor |
|---|---|
| Descriptive name | `usuario-teste-01` |
| Certificate authority | `Mahikari-VPN-CA` |
| Key type | RSA |
| Key length | 4096 |
| Lifetime | 365 (1 ano) |

3. Clicar **Save**

### Criar certificado diretamente (sem vincular a usuário)

Alternativamente, criar certificado em **System > Cert. Manager > Certificates**:

1. Clicar **+ Add/Sign**

| Campo | Valor |
|---|---|
| Method | Create an internal Certificate |
| Descriptive name | `usuario-teste-01` |
| Certificate authority | `Mahikari-VPN-CA` |
| Key type | RSA |
| Key length | 4096 |
| Digest Algorithm | SHA256 |
| Lifetime (days) | 365 (1 ano) |
| Common Name | `usuario-teste-01` |
| Certificate Type | **User Certificate** |

2. Clicar **Save**

### Verificação

O certificado `usuario-teste-01` deve aparecer na lista com:
- CA: `Mahikari-VPN-CA`
- Type: User

---

## 2.5. Exportar Certificado do Usuário

Para gerar o arquivo `.ovpn`, será necessário exportar:

1. **Certificado da CA** (para incluir no .ovpn):
   - System > Cert. Manager > CAs > `Mahikari-VPN-CA` > Export CA (PEM)

2. **Certificado do cliente** (para incluir no .ovpn):
   - System > Cert. Manager > Certificates > `usuario-teste-01` > Export Certificate (PEM)

3. **Chave privada do cliente** (para incluir no .ovpn):
   - System > Cert. Manager > Certificates > `usuario-teste-01` > Export Key (PEM)

> **Segurança:** A chave privada deve ser transmitida ao usuário por canal seguro e nunca armazenada no servidor após a distribuição.

---

## 2.6. Revogar Certificado (Procedimento)

Quando um usuário precisar ter o acesso VPN revogado:

1. Acessar **System > Cert. Manager > Certificate Revocation**
2. Clicar no botão **Edit** (ícone de lápis) ao lado da CRL `Mahikari-VPN-CRL`
3. Na seção **"Choose a Certificate to Revoke"**:
   - Selecionar o certificado do usuário (ex.: `usuario-teste-01`)
   - Reason: **Key Compromise** ou **Cessation of Operation**
4. Clicar **Add**
5. Clicar **Save**

### Verificação

- O certificado revogado aparece na lista da CRL
- O usuário não consegue mais conectar via VPN (próxima tentativa é recusada)
- Log do pfSense mostra: `VERIFY ERROR: depth=0, error=certificate revoked`

---

## Resumo de Certificados Criados

| Certificado | Tipo | CA | Validade | Propósito |
|---|---|---|---|---|
| `Mahikari-VPN-CA` | CA (raiz) | — | 10 anos | Assinar todos os certificados |
| `vpn-server` | Server | Mahikari-VPN-CA | 2 anos | Certificado do servidor OpenVPN |
| `Mahikari-VPN-CRL` | CRL | Mahikari-VPN-CA | 10 anos | Lista de certificados revogados |
| `usuario-teste-01` | User | Mahikari-VPN-CA | 1 ano | Certificado de teste do cliente VPN |

---

## Próximos Passos

- → [Fase 3: Configuração do Servidor OpenVPN](openvpn-server.md)
- → [Fase 4: Regras de Firewall](firewall-rules.md)
