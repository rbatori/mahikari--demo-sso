# Procedimento — Fase 3: Configuração do Servidor OpenVPN

**Mahikari — Demo VPN sem Senha**  
Versão: 2026-05-23

> Configurar o servidor OpenVPN no pfSense com autenticação exclusivamente por certificado digital (sem senha).

---

## Pré-requisitos

- pfSense operacional (Fase 1 concluída)
- CA `Mahikari-VPN-CA` e certificado `vpn-server` criados (Fase 2 concluída)
- Acesso à WebGUI do pfSense

---

## 3.1. Criar Servidor OpenVPN

1. Acessar **VPN > OpenVPN > Servers**
2. Clicar **+ Add**

### General Information

| Campo | Valor |
|---|---|
| Description | `VPN-Mahikari-RemoteAccess` |
| Disabled | (desmarcado) |

### Mode Configuration

| Campo | Valor |
|---|---|
| Server mode | **Remote Access (SSL/TLS)** |
| Backend for authentication | **Local Database** |
| Device mode | tun — Layer 3 Tunnel Mode |

> **Importante:** O modo **Remote Access (SSL/TLS)** utiliza apenas certificados para autenticação. Não há campo de usuário/senha no client.

### Endpoint Configuration

| Campo | Valor |
|---|---|
| Protocol | **UDP on IPv4 only** |
| Interface | **WAN** |
| Local port | **1194** |

### Cryptographic Settings

| Campo | Valor |
|---|---|
| TLS Configuration | Marcar **"Use a TLS Key"** |
| TLS Key Usage Mode | **TLS Encryption and Authentication (tls-crypt)** |
| TLS Key | **Automatically generate a TLS Key** |
| Peer Certificate Authority | **Mahikari-VPN-CA** |
| Peer Certificate Revocation list | **Mahikari-VPN-CRL** |
| Server certificate | **vpn-server** |
| DH Parameter Length | **ECDH Only** |
| ECDH Curve | **Use Default** |
| Data Encryption Algorithms | **AES-256-GCM** (mover para "Allowed") |
| Fallback Data Encryption Algorithm | **AES-256-CBC** |
| Auth digest algorithm | **SHA256 (256-bit)** |

> **CRL associada:** A seleção da CRL `Mahikari-VPN-CRL` garante que certificados revogados sejam automaticamente recusados.

### Tunnel Settings

| Campo | Valor |
|---|---|
| IPv4 Tunnel Network | **10.8.0.0/24** |
| IPv6 Tunnel Network | (deixar em branco) |
| Redirect IPv4 Gateway | **Desmarcar** (split tunnel — apenas tráfego para rede interna vai pela VPN) |
| IPv4 Local Network(s) | **192.168.1.0/24** |
| Concurrent connections | **10** (ajustar conforme necessidade) |
| Compression | **Omit Preference (Use OpenVPN Default)** |
| Topology | **Subnet — One IP address per client in a common subnet** |

> **Split tunnel vs Full tunnel:**
> - **Split tunnel** (recomendado): apenas tráfego para a rede interna (192.168.1.0/24) passa pela VPN. Internet vai direto.
> - **Full tunnel**: marcar "Redirect IPv4 Gateway" — todo o tráfego do cliente passa pela VPN.

### Client Settings

| Campo | Valor |
|---|---|
| Dynamic IP | Marcado |
| DNS Default Domain | `mahikari.local` |
| DNS Server 1 | **192.168.1.1** (pfSense como DNS) ou IP do DNS interno |
| DNS Server 2 | (opcional) |
| Block Outside DNS | **Desmarcar** (para split tunnel) |

### Advanced Configuration

No campo **Advanced**:

```
# Garantir que o cliente reconecte automaticamente
keepalive 10 60

# Log de verbosidade (3 = normal, 5 = debug)
verb 3
```

### Salvar

3. Clicar **Save**

---

## 3.2. Verificar Status do Servidor

1. Acessar **Status > OpenVPN**

Verificar que o servidor `VPN-Mahikari-RemoteAccess` aparece com status:
- **Status:** up
- **Port:** 1194

2. Acessar **Status > System Logs > OpenVPN**

Verificar nos logs a mensagem de inicialização sem erros:
```
openvpn[...]: Initialization Sequence Completed
```

---

## 3.3. Verificar TLS Key

A chave TLS-Crypt gerada automaticamente pode ser visualizada editando o servidor:

1. VPN > OpenVPN > Servers > Editar `VPN-Mahikari-RemoteAccess`
2. No campo **TLS Key**, copiar o conteúdo

Esta chave será incluída no arquivo `.ovpn` do cliente.

---

## 3.4. Instalar Client Export Utility (Opcional)

O pacote **openvpn-client-export** facilita a geração de arquivos `.ovpn`:

1. Acessar **System > Package Manager > Available Packages**
2. Buscar por `openvpn-client-export`
3. Clicar **Install** e confirmar

Após instalar:
1. Acessar **VPN > OpenVPN > Client Export**
2. Selecionar o servidor `VPN-Mahikari-RemoteAccess`
3. Na lista de certificados, clicar no ícone de download ao lado do certificado do usuário
4. Selecionar o formato:
   - **Inline Configurations** > **Most Clients** — gera `.ovpn` com tudo inline

> **Nota:** Se o pacote não estiver disponível, use o template manual em [vpn-client/template-client.ovpn](../vpn-client/template-client.ovpn) ou o script [scripts/gerar-certificado-usuario.sh](../scripts/gerar-certificado-usuario.sh).

---

## 3.5. Parâmetros de Segurança Adicionais

### Limitar tamanho de renegociação

No campo **Advanced** do servidor:

```
reneg-sec 3600
```

Força renegociação TLS a cada hora (segurança adicional).

### Habilitar log de conexões

Por padrão, o pfSense já loga conexões OpenVPN em **Status > System Logs > OpenVPN**. Para logs mais detalhados:

```
verb 4
```

---

## Resumo da Configuração

| Parâmetro | Valor |
|---|---|
| Modo | Remote Access (SSL/TLS) — apenas certificado |
| Protocolo | UDP 1194 |
| Criptografia | AES-256-GCM + SHA256 |
| TLS | tls-crypt (criptografia do canal de controle) |
| CA | Mahikari-VPN-CA |
| CRL | Mahikari-VPN-CRL |
| Certificado do servidor | vpn-server |
| Rede do túnel | 10.8.0.0/24 |
| Rede local | 192.168.1.0/24 |
| Topologia | Subnet |
| Autenticação por senha | **Não** (apenas certificado) |

---

## Próximos Passos

- → [Fase 4: Regras de Firewall](firewall-rules.md)
- → [Fase 5: Instalação do Keycloak](../keycloak/procedimento-keycloak.md)
