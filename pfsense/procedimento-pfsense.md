# Procedimento — Fase 1: Instalação e Configuração Base do pfSense

**Mahikari — Demo VPN sem Senha**  
Versão: 2026-05-23

---

## Pré-requisitos

| Item | Detalhe |
|---|---|
| Hardware/VM | Mínimo: 2 interfaces de rede, 2 GB RAM, 20 GB disco |
| ISO | pfSense CE 2.7+ (download em https://www.pfsense.org/download/) |
| Rede WAN | Interface com acesso à internet (DHCP ou IP estático) |
| Rede LAN | Interface para a rede interna (ex.: 192.168.1.0/24) |

---

## 1.1. Download e Instalação

### Download da ISO

1. Acessar https://www.pfsense.org/download/
2. Selecionar:
   - Architecture: **AMD64 (64-bit)**
   - Installer: **DVD Image (ISO) Installer**
   - Mirror: mais próximo
3. Baixar e verificar o checksum (SHA-256)

### Instalação em VM (VirtualBox/Proxmox/VMware)

1. Criar VM com:
   - 2 interfaces de rede:
     - **Adaptador 1 (WAN):** Bridged Adapter ou NAT (acesso à internet)
     - **Adaptador 2 (LAN):** Host-Only ou Internal Network
   - 2 GB RAM
   - 20 GB disco (VDI/QCOW2)
   - Boot: CD/DVD → ISO do pfSense

2. Iniciar a VM e seguir o instalador:
   - Accept copyright notice
   - Install pfSense
   - Partitioning: Auto (ZFS) — recomendado
   - Select disk → confirmar
   - Aguardar instalação → **Reboot**

3. Remover a ISO do drive virtual após reboot

### Instalação em Bare Metal

1. Gravar ISO em USB (usando Rufus, Etcher ou `dd`)
2. Boot pelo USB
3. Seguir o mesmo processo de instalação acima

---

## 1.2. Configuração Inicial (Console)

Após o primeiro boot, o pfSense apresenta o menu de console:

### Atribuir interfaces

```
Should VLANs be set up now? [y|n]: n

Enter the WAN interface name: <nome da interface WAN> (ex.: em0, vtnet0, igb0)
Enter the LAN interface name: <nome da interface LAN> (ex.: em1, vtnet1, igb1)

Do you want to proceed? [y|n]: y
```

> **Dica:** Para identificar interfaces, use a opção `1) Assign Interfaces` no menu e observe os nomes detectados.

### Configurar IP da LAN (se não houver DHCP)

No menu do console, selecionar:

```
2) Set interface(s) IP address
```

Configurar a LAN:

| Campo | Valor |
|---|---|
| Interface | LAN |
| IPv4 address | 192.168.1.1 |
| Subnet bit count | 24 |
| IPv4 upstream gateway | (deixar em branco para LAN) |
| IPv6 | (deixar em branco) |
| Enable DHCP server on LAN? | yes |
| DHCP range start | 192.168.1.100 |
| DHCP range end | 192.168.1.200 |
| Revert to HTTP? | no (manter HTTPS) |

---

## 1.3. Acesso à WebGUI

1. Conectar um computador à rede LAN do pfSense (ou acessar via IP LAN se já estiver na rede)

2. Abrir o browser e acessar:
   ```
   https://192.168.1.1
   ```

3. Aceitar o aviso de certificado auto-assinado

4. Login padrão:
   - **Username:** `admin`
   - **Password:** `pfsense`

---

## 1.4. Wizard Inicial

Ao fazer o primeiro login, o pfSense exibe o Setup Wizard:

### Step 1 — General Information

| Campo | Valor |
|---|---|
| Hostname | `pfsense` |
| Domain | `mahikari.local` |
| Primary DNS Server | `8.8.8.8` (ou DNS interno) |
| Secondary DNS Server | `8.8.4.4` |

### Step 2 — Time Server

| Campo | Valor |
|---|---|
| Time server hostname | `a.ntp.br` |
| Timezone | `America/Sao_Paulo` |

### Step 3 — WAN Interface

- Se WAN usa DHCP: selecionar **DHCP**
- Se WAN usa IP estático: configurar IP, gateway e DNS

> **Desmarcar:** "Block RFC1918 Private Networks" se WAN estiver em rede privada (ex.: NAT do provedor, lab de teste)

### Step 4 — LAN Interface

| Campo | Valor |
|---|---|
| LAN IP Address | 192.168.1.1 |
| Subnet Mask | 24 |

### Step 5 — Admin Password

**Alterar a senha padrão do admin** (obrigatório para segurança):

| Campo | Valor |
|---|---|
| Admin Password | (definir senha forte) |
| Admin Password Confirm | (repetir) |

### Step 6 — Reload

Clicar **Reload** para aplicar as configurações.

---

## 1.5. Validação

### Conectividade WAN

No menu **Diagnostics > Ping**:

| Campo | Valor |
|---|---|
| Hostname | `8.8.8.8` |
| Source Address | WAN |

Resultado esperado: resposta com sucesso.

### Acesso à WebGUI

Confirmar que `https://192.168.1.1` carrega o dashboard do pfSense.

### Dashboard

Verificar no dashboard:

- [ ] **System Information:** versão do pfSense
- [ ] **Interfaces:** WAN com IP atribuído, LAN com 192.168.1.1
- [ ] **Gateways:** gateway WAN "online"

---

## 1.6. Configurações Recomendadas (Pós-Wizard)

### Desabilitar DNS Resolver (se usar DNS externo)

Se não for usar o pfSense como DNS resolver:
1. Services > DNS Resolver
2. Desmarcar "Enable DNS Resolver"
3. Salvar

### Habilitar SSH (opcional, para administração remota)

1. System > Advanced > Admin Access
2. Secure Shell: **Enable Secure Shell**
3. SSH Port: 22 (ou porta customizada)
4. Salvar

### Atualizar pfSense

1. System > Update
2. Verificar se há atualizações disponíveis
3. Aplicar se houver

---

## Próximos Passos

Após concluir a Fase 1:
- → [Fase 2: Configuração da PKI (CA + Certificados)](pki-certificados.md)
- → [Fase 3: Configuração do Servidor OpenVPN](openvpn-server.md)
