# Procedimento — Fase 4: Regras de Firewall para VPN

**Mahikari — Demo VPN sem Senha**  
Versão: 2026-05-23

> Configurar as regras de firewall no pfSense para permitir conexões VPN e tráfego dos clientes remotos.

---

## Pré-requisitos

- pfSense operacional com OpenVPN server configurado (Fases 1-3 concluídas)
- Acesso à WebGUI do pfSense

---

## 4.1. Regra na Interface WAN — Permitir OpenVPN

Permitir que conexões OpenVPN cheguem ao pfSense pela internet.

1. Acessar **Firewall > Rules > WAN**
2. Clicar **+ Add** (seta para cima — adicionar no topo)

| Campo | Valor |
|---|---|
| Action | **Pass** |
| Interface | WAN |
| Address Family | IPv4 |
| Protocol | **UDP** |
| Source | Any |
| Destination | **WAN address** |
| Destination Port Range | From: **1194** To: **1194** |
| Description | `Permitir OpenVPN (UDP 1194)` |
| Log | Marcar (opcional — para auditoria) |

3. Clicar **Save**
4. Clicar **Apply Changes**

---

## 4.2. Regras na Interface OpenVPN — Tráfego dos Clientes VPN

Após o túnel VPN ser estabelecido, o tráfego dos clientes chega na interface virtual `OpenVPN`. É necessário criar regras para permitir acesso à rede interna.

### Regra 1 — VPN acessa rede LAN

1. Acessar **Firewall > Rules > OpenVPN**
2. Clicar **+ Add**

| Campo | Valor |
|---|---|
| Action | **Pass** |
| Interface | OpenVPN |
| Address Family | IPv4 |
| Protocol | **Any** |
| Source | **Network** — `10.8.0.0/24` (rede do túnel VPN) |
| Destination | **Network** — `192.168.1.0/24` (rede LAN) |
| Description | `VPN clients acessam rede LAN` |
| Log | Marcar (recomendado para auditoria) |

3. Clicar **Save**

### Regra 2 — VPN acessa internet (opcional, para full tunnel)

Somente necessário se estiver usando **full tunnel** (redirect gateway):

1. Clicar **+ Add**

| Campo | Valor |
|---|---|
| Action | **Pass** |
| Interface | OpenVPN |
| Address Family | IPv4 |
| Protocol | **Any** |
| Source | **Network** — `10.8.0.0/24` |
| Destination | **Any** |
| Description | `VPN clients acessam internet (full tunnel)` |

2. Clicar **Save**

### Regra 3 — Bloquear tudo o mais (implícita)

O pfSense tem uma regra implícita de **deny all** no final de cada interface. Não é necessário criar regra de bloqueio — qualquer tráfego que não corresponda às regras acima será automaticamente bloqueado.

3. Clicar **Apply Changes**

---

## 4.3. Verificar Outbound NAT (se necessário)

Se os clientes VPN precisam acessar a internet (full tunnel) ou recursos fora da LAN:

1. Acessar **Firewall > NAT > Outbound**
2. Verificar o modo:
   - **Automatic outbound NAT** — geralmente funciona sem alterações
   - Se estiver em **Manual**, adicionar regra:

| Campo | Valor |
|---|---|
| Interface | WAN |
| Source | **Network** — `10.8.0.0/24` |
| Translation | **Interface Address** |
| Description | `NAT para clientes VPN` |

3. Clicar **Save** e **Apply Changes**

---

## 4.4. Resumo das Regras

### Interface WAN

| # | Action | Protocol | Source | Destination | Port | Descrição |
|---|---|---|---|---|---|---|
| 1 | Pass | UDP | Any | WAN address | 1194 | Permitir OpenVPN |

### Interface OpenVPN

| # | Action | Protocol | Source | Destination | Descrição |
|---|---|---|---|---|---|
| 1 | Pass | Any | 10.8.0.0/24 | 192.168.1.0/24 | VPN acessa LAN |
| 2 | Pass | Any | 10.8.0.0/24 | Any | VPN acessa internet (opcional) |
| — | Deny | Any | Any | Any | (implícita — bloqueia o resto) |

---

## 4.5. Validação

### Teste de conectividade

1. Conectar um cliente VPN (ver [Fase 7 do plano](../docs/plano-demo.md))
2. Após conectar, verificar:

```bash
# No cliente VPN, verificar IP do túnel
ip addr show tun0   # Linux
ipconfig             # Windows

# Ping para o pfSense (gateway do túnel)
ping 10.8.0.1

# Ping para servidor na LAN
ping 192.168.1.10    # Keycloak (se estiver na LAN)
ping 192.168.1.20    # Servidor de teste
```

### Verificar logs de firewall

1. **Status > System Logs > Firewall**
2. Filtrar por interface **OpenVPN**
3. Verificar que o tráfego está sendo permitido (Pass) conforme as regras

---

## Próximos Passos

- → [Fase 5: Instalação do Keycloak](../keycloak/procedimento-keycloak.md)
- → [Fase 7: Teste de VPN sem Senha](../docs/plano-demo.md)
