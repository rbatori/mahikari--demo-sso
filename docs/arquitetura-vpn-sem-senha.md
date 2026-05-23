# Arquitetura — VPN sem Senha com pfSense + OpenVPN + Keycloak

**Mahikari**  
Versão: 2026-05-23

---

## 1. Visão Geral

A solução substitui o firewall Aker (Secure Roaming) por pfSense com OpenVPN, utilizando certificados digitais X.509 para autenticação sem senha. O Keycloak atua como Identity Provider central para gestão de identidades e ciclo de vida dos certificados.

---

## 2. Diagrama de Componentes

```mermaid
flowchart TB
    subgraph usuarios ["Usuários Remotos"]
        U1["Usuário Windows<br/>(OpenVPN Client)"]
        U2["Usuário macOS<br/>(Tunnelblick / OpenVPN)"]
        U3["Usuário Linux<br/>(OpenVPN CLI)"]
        U4["Usuário Mobile<br/>(OpenVPN Connect)"]
    end

    subgraph pfsense ["pfSense Firewall"]
        FW["Firewall Rules"]
        VPN["OpenVPN Server<br/>(porta 1194/UDP)"]
        CA["PKI — CA Interna<br/>(Certificados X.509)"]
        CRL["CRL<br/>(Certificate Revocation List)"]
        LOG["Logs VPN<br/>(conexões, IPs, duração)"]
    end

    subgraph keycloak ["Keycloak (IdP Central)"]
        KC["Keycloak Server"]
        REALM["Realm: mahikari"]
        USERS["Gestão de Usuários"]
        ROLES["Roles e Grupos"]
        PORTAL["Portal de Provisioning<br/>(gerar/revogar certificados)"]
    end

    subgraph rede_interna ["Rede Interna Mahikari"]
        SRV1["Servidores"]
        SRV2["Aplicações"]
        SRV3["Recursos Internos"]
    end

    U1 -->|"TLS + Certificado"| VPN
    U2 -->|"TLS + Certificado"| VPN
    U3 -->|"TLS + Certificado"| VPN
    U4 -->|"TLS + Certificado"| VPN

    VPN -->|"Valida certificado"| CA
    VPN -->|"Verifica revogação"| CRL
    VPN -->|"Registra conexão"| LOG
    VPN -->|"Tunnel estabelecido"| FW

    FW --> SRV1
    FW --> SRV2
    FW --> SRV3

    KC --> REALM
    REALM --> USERS
    REALM --> ROLES
    USERS --> PORTAL

    PORTAL -.->|"Emite certificado"| CA
    PORTAL -.->|"Revoga certificado"| CRL
```

---

## 3. Fluxo de Conexão VPN (sem senha)

```mermaid
sequenceDiagram
    actor U as "Usuário Remoto"
    participant C as "OpenVPN Client"
    participant P as "pfSense (OpenVPN Server)"
    participant CA as "CA Interna (pfSense)"
    participant CRL as "CRL (pfSense)"

    Note over U,C: Pré-requisito: .ovpn já importado no client

    U->>C: 1. Clica "Conectar"
    C->>P: 2. TLS Handshake (ClientHello)
    P->>C: 3. Envia certificado do servidor
    C->>C: 4. Valida certificado do servidor (CA)
    C->>P: 5. Envia certificado do cliente
    P->>CA: 6. Valida certificado do cliente
    CA-->>P: 7. Certificado válido (assinado pela CA)
    P->>CRL: 8. Verifica se certificado está revogado
    CRL-->>P: 9. Certificado não revogado
    P->>P: 10. Atribui IP do túnel VPN
    P-->>C: 11. Túnel VPN estabelecido
    C-->>U: 12. Conectado à rede interna

    Note over U,P: Zero interação do usuário<br/>(sem senha, sem browser, sem MFA)
```

---

## 4. Fluxo de Provisioning de Certificado

```mermaid
sequenceDiagram
    actor Admin as "Administrador"
    participant KC as "Keycloak"
    participant PF as "pfSense"
    participant CA as "CA (pfSense)"
    participant U as "Usuário"

    Admin->>KC: 1. Cria/ativa usuário no Keycloak
    Admin->>PF: 2. Acessa pfSense > Cert Manager
    Admin->>CA: 3. Emite certificado para o usuário
    CA-->>PF: 4. Certificado + chave privada gerados
    Admin->>PF: 5. Exporta arquivo .ovpn
    Admin->>U: 6. Envia .ovpn via canal seguro
    U->>U: 7. Importa .ovpn no OpenVPN Client
    Note over U: Pronto para conectar sem senha
```

---

## 5. Fluxo de Revogação de Certificado

```mermaid
sequenceDiagram
    actor Admin as "Administrador"
    participant KC as "Keycloak"
    participant PF as "pfSense"
    participant CRL as "CRL (pfSense)"
    participant U as "Usuário Revogado"

    Admin->>KC: 1. Desativa usuário no Keycloak
    Admin->>PF: 2. Acessa pfSense > Cert Manager
    Admin->>CRL: 3. Adiciona certificado à CRL
    CRL-->>PF: 4. CRL atualizada
    Note over PF: Novas conexões com este certificado serão recusadas

    U->>PF: 5. Tenta conectar VPN
    PF->>CRL: 6. Verifica CRL
    CRL-->>PF: 7. Certificado REVOGADO
    PF-->>U: 8. Conexão RECUSADA
```

---

## 6. Componentes da Arquitetura

### 6.1. pfSense — Firewall + VPN

| Item | Detalhe |
|---|---|
| Função | Firewall (stateful) + Servidor OpenVPN + PKI |
| Versão recomendada | pfSense CE 2.7+ |
| Instalação | Bare metal ou VM (mínimo 2 interfaces: WAN + LAN) |
| Portas | WAN: 1194/UDP (OpenVPN); 443/TCP (WebGUI admin) |
| PKI | CA interna para emissão de certificados X.509 |
| CRL | Certificate Revocation List para revogação imediata |
| Logs | Conexões VPN, IPs atribuídos, duração, bytes transferidos |

### 6.2. OpenVPN Server

| Item | Detalhe |
|---|---|
| Modo | Remote Access (SSL/TLS) |
| Protocolo | UDP, porta 1194 |
| Autenticação | **Certificado digital apenas** (sem user/pass) |
| Criptografia | AES-256-GCM |
| Hash | SHA256 |
| TLS Auth | tls-crypt (chave estática adicional) |
| Topologia | subnet (cada cliente recebe IP fixo do túnel) |
| Tunnel Network | 10.8.0.0/24 (configurável) |
| DNS push | DNS interno da Mahikari |
| Redirect gateway | Opcional (full tunnel ou split tunnel) |

### 6.3. PKI — Infraestrutura de Chave Pública

| Item | Detalhe |
|---|---|
| CA | CA raiz interna do pfSense (RSA 4096 bits, validade 10 anos) |
| Certificado do servidor | Emitido pela CA, tipo Server (validade 2 anos) |
| Certificado do cliente | Emitido pela CA, tipo User (validade 1 ano, renovável) |
| CRL | Atualizada automaticamente quando certificado é revogado |
| Algoritmo | RSA 4096 ou ECDSA P-384 |

### 6.4. Keycloak — Identity Provider

| Item | Detalhe |
|---|---|
| Função | Gestão centralizada de identidades |
| Realm | `mahikari` |
| Grupos | `vpn-users`, `vpn-admins` |
| Roles | `vpn-full-access`, `vpn-restricted`, `vpn-admin` |
| Integração | Portal web para provisioning de certificados VPN |
| Auditoria | Logs de criação/desativação de usuários |

### 6.5. OpenVPN Client

| Item | Detalhe |
|---|---|
| Windows | OpenVPN GUI ou OpenVPN Connect |
| macOS | Tunnelblick ou OpenVPN Connect |
| Linux | openvpn CLI ou NetworkManager |
| Android/iOS | OpenVPN Connect (app oficial) |
| Configuração | Arquivo `.ovpn` com CA cert, client cert, client key, tls-crypt |

---

## 7. Segurança

### 7.1. Proteção da chave privada

- A chave privada do certificado do cliente é armazenada no dispositivo do usuário
- No Windows: protegida pelo Windows Credential Store
- No macOS: protegida pelo Keychain
- No Linux: protegida por permissões de arquivo (chmod 600)
- **A chave privada nunca trafega pela rede** — apenas o certificado público é enviado durante o TLS handshake

### 7.2. TLS-Crypt

- Camada adicional de proteção: chave estática compartilhada (pré-shared)
- Criptografa e autentica o canal de controle do OpenVPN
- Protege contra ataques de fingerprinting e DoS no servidor VPN
- Incluída no arquivo `.ovpn`

### 7.3. Revogação

- Certificados revogados são adicionados à CRL no pfSense
- O OpenVPN Server verifica a CRL a cada nova conexão
- Revogação é **imediata para novas conexões**
- Conexões ativas não são desconectadas automaticamente (kill manual se necessário)

### 7.4. Validade dos certificados

- Certificados de cliente com validade de 1 ano (renovação anual)
- Renovação: emitir novo certificado → distribuir novo `.ovpn` → revogar antigo
- Processo de renovação gerenciado via Keycloak (tracking de validade)

---

## 8. Topologia de Rede da Demo

```mermaid
flowchart LR
    subgraph internet ["Internet"]
        USER["Usuário Remoto<br/>OpenVPN Client"]
    end

    subgraph pfsense_box ["pfSense"]
        WAN["WAN<br/>(IP público ou NAT)"]
        OVPN["OpenVPN Server<br/>10.8.0.1"]
        LAN["LAN<br/>192.168.1.1"]
    end

    subgraph lan ["Rede Interna (Demo)"]
        KC["Keycloak<br/>192.168.1.10"]
        SRV["Servidor de Teste<br/>192.168.1.20"]
    end

    USER -->|"UDP 1194"| WAN
    WAN --> OVPN
    OVPN -->|"Tunnel: 10.8.0.0/24"| LAN
    LAN --> KC
    LAN --> SRV
```

---

## 9. Comparação com o Aker Secure Roaming

| Aspecto | Aker Secure Roaming | pfSense + OpenVPN + Certificados |
|---|---|---|
| Experiência do usuário | Clique para conectar (sem senha) | **Clique para conectar (sem senha)** |
| Método de autenticação | Credenciais pré-provisionadas | Certificado digital X.509 |
| Protocolo VPN | Proprietário (Aker) | OpenVPN (open-source, padrão aberto) |
| Revogação de acesso | Via console do Aker | CRL no pfSense |
| Multiplataforma | Client Aker (limitado) | OpenVPN Client (todos os SO) |
| Auditoria | Logs do Aker | Logs do pfSense + Keycloak |
| Custo | Licença proprietária | **Gratuito** (open-source) |
| Suporte | Descontinuado | Comunidade ativa + Netgate (comercial) |
