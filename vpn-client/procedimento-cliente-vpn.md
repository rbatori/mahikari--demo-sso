# Procedimento — Configuração do Client OpenVPN (Usuário Remoto)

**Mahikari — Demo VPN sem Senha**  
Versão: 2026-05-23

> Como instalar e configurar o client OpenVPN na máquina do usuário remoto para conectar à VPN sem digitar senha.

---

## Pré-requisitos

- Arquivo `.ovpn` fornecido pelo administrador (contém certificados e configuração)
- Acesso à internet
- Permissões de administrador (para instalar o client)

---

## 1. Instalação do Client OpenVPN

### Windows

1. Baixar o **OpenVPN Connect** em: https://openvpn.net/client/
   - Ou o **OpenVPN GUI** (Community): https://openvpn.net/community-downloads/
2. Executar o instalador
3. Seguir o wizard (Next > Next > Install)
4. Reiniciar se solicitado

### macOS

**Opção 1 — Tunnelblick (recomendado):**
1. Baixar em: https://tunnelblick.net/downloads.html
2. Abrir o `.dmg` e instalar
3. Conceder permissões quando solicitado

**Opção 2 — OpenVPN Connect:**
1. Baixar na App Store ou em: https://openvpn.net/client/
2. Instalar normalmente

### Linux (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install -y openvpn
```

Para interface gráfica (NetworkManager):

```bash
sudo apt install -y network-manager-openvpn network-manager-openvpn-gnome
```

### Android

1. Instalar **OpenVPN Connect** na Google Play Store
2. Abrir o app

### iOS

1. Instalar **OpenVPN Connect** na App Store
2. Abrir o app

---

## 2. Importar o Arquivo `.ovpn`

### Windows (OpenVPN GUI)

1. Copiar o arquivo `.ovpn` para:
   ```
   C:\Users\<seu_usuario>\OpenVPN\config\
   ```
   Ou:
2. Clicar com o botão direito no ícone do OpenVPN na bandeja do sistema
3. Selecionar **"Import file..."**
4. Selecionar o arquivo `.ovpn`

### Windows (OpenVPN Connect)

1. Abrir o OpenVPN Connect
2. Arrastar o arquivo `.ovpn` para a janela
   Ou: **File** → **Import Profile** → **From File** → selecionar o `.ovpn`
3. Clicar **Add**

### macOS (Tunnelblick)

1. Dar duplo clique no arquivo `.ovpn`
2. Tunnelblick pergunta: "Install for all users" ou "Only me"
3. Selecionar a opção desejada
4. Informar a senha do macOS (para instalar o perfil)

### Linux (CLI)

```bash
# Copiar o .ovpn para um local seguro
sudo cp usuario-teste-01.ovpn /etc/openvpn/client/mahikari.conf

# Proteger o arquivo
sudo chmod 600 /etc/openvpn/client/mahikari.conf
```

### Linux (NetworkManager / GNOME)

1. Settings → Network → VPN → **+** (Add VPN)
2. Selecionar **"Import from file..."**
3. Selecionar o arquivo `.ovpn`
4. Clicar **Add**

### Android / iOS

1. Transferir o arquivo `.ovpn` para o dispositivo (e-mail, cloud, USB)
2. Abrir o arquivo com o app **OpenVPN Connect**
3. Tocar em **Add** para importar o perfil

---

## 3. Conectar à VPN (Sem Senha)

### Windows (OpenVPN GUI)

1. Clicar com o botão direito no ícone do OpenVPN na bandeja do sistema
2. Selecionar o perfil importado
3. Clicar **"Connect"**
4. **Nenhuma senha será solicitada** — a conexão é autenticada pelo certificado digital
5. O ícone fica verde quando conectado

### Windows (OpenVPN Connect)

1. Abrir o OpenVPN Connect
2. Alternar o toggle do perfil para **ON**
3. Conexão estabelecida automaticamente (sem senha)

### macOS (Tunnelblick)

1. Clicar no ícone do Tunnelblick na barra de menu
2. Selecionar **"Connect [nome do perfil]"**
3. Conexão sem senha

### Linux (CLI)

```bash
# Conectar em foreground (para teste)
sudo openvpn --config /etc/openvpn/client/mahikari.conf

# Ou como serviço (background)
sudo systemctl start openvpn-client@mahikari
sudo systemctl enable openvpn-client@mahikari  # Iniciar no boot
```

### Linux (NetworkManager)

1. Clicar no ícone de rede
2. Em VPN, selecionar o perfil importado
3. Conexão estabelecida sem senha

### Android / iOS

1. Abrir o OpenVPN Connect
2. Tocar no perfil importado
3. Tocar em **"Connect"**

---

## 4. Verificar a Conexão

### Verificar IP do túnel

```bash
# Linux/macOS
ip addr show tun0
# ou
ifconfig tun0

# Windows (CMD)
ipconfig /all
# Procurar por "TAP-Windows" ou "OpenVPN"
```

Resultado esperado: IP na faixa `10.8.0.x`

### Verificar acesso à rede interna

```bash
# Ping para o gateway VPN (pfSense)
ping 10.8.0.1

# Ping para servidor na rede interna
ping 192.168.1.10    # Keycloak
ping 192.168.1.20    # Servidor de teste
```

### Verificar rota

```bash
# Linux/macOS
ip route | grep tun0
# ou
netstat -rn | grep tun0

# Windows
route print | findstr 10.8.0
```

---

## 5. Desconectar

### Windows (OpenVPN GUI)

Clicar com o botão direito no ícone → **"Disconnect"**

### Windows (OpenVPN Connect)

Alternar o toggle para **OFF**

### macOS (Tunnelblick)

Clicar no ícone → **"Disconnect [nome do perfil]"**

### Linux (CLI)

```bash
sudo systemctl stop openvpn-client@mahikari
# Ou Ctrl+C se estiver em foreground
```

---

## 6. Troubleshooting

### Erro: "TLS Error: TLS handshake failed"

- **Causa:** Certificado inválido, expirado ou revogado
- **Solução:** Solicitar novo arquivo `.ovpn` ao administrador

### Erro: "RESOLVE: Cannot resolve host address"

- **Causa:** Não consegue resolver o hostname do servidor VPN
- **Solução:** Verificar conexão com a internet; tentar usar IP direto no `.ovpn`

### Erro: "Connection timed out"

- **Causa:** Servidor VPN inacessível (firewall bloqueando, servidor offline)
- **Solução:** Verificar se o pfSense está online e a porta 1194/UDP está acessível

### Conexão cai frequentemente

- **Causa:** Keepalive timeout
- **Solução:** Verificar qualidade da conexão; ajustar `keepalive` no servidor

### Windows: "TAP adapter not found"

- **Causa:** Driver TAP não instalado
- **Solução:** Reinstalar o OpenVPN GUI (inclui o driver TAP)

---

## 7. Segurança do Arquivo `.ovpn`

> **O arquivo `.ovpn` contém sua chave privada. Trate-o como uma senha.**

- Não compartilhe o arquivo com ninguém
- Não envie por e-mail sem criptografia
- Não armazene em locais públicos (Google Drive público, USB sem criptografia)
- Se suspeitar que o arquivo foi comprometido, notifique imediatamente o administrador para revogação do certificado
- Após importar no client, o arquivo original pode ser deletado com segurança (o client armazena internamente)
