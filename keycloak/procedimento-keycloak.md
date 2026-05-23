# Procedimento — Fase 5: Instalação e Configuração do Keycloak

**Mahikari — Demo VPN sem Senha**  
Versão: 2026-05-23

> Instalar o Keycloak como Identity Provider central e configurar o realm, grupos, roles e usuários para gestão de identidades VPN.

---

## Pré-requisitos

| Item | Detalhe |
|---|---|
| Servidor | Docker e Docker Compose instalados |
| RAM | Mínimo 2 GB disponível |
| Rede | Acessível pela rede LAN do pfSense (ex.: 192.168.1.10) |

---

## 5.1. Instalar Keycloak via Docker Compose

### Criar diretório

```bash
sudo mkdir -p /opt/keycloak
```

### Copiar o Docker Compose

Copiar o arquivo `keycloak/docker-compose.yml` deste repositório para `/opt/keycloak/docker-compose.yml`.

### Criar arquivo `.env` (opcional, para customizar credenciais)

```bash
cat > /opt/keycloak/.env << 'EOF'
KC_DB_PASSWORD=senha_forte_do_banco
KC_HOSTNAME=192.168.1.10
KC_ADMIN_USER=admin
KC_ADMIN_PASSWORD=senha_forte_do_admin
EOF
```

> **Segurança:** Em produção, usar senhas fortes e não manter o arquivo `.env` com permissões abertas.

### Subir o Keycloak

```bash
cd /opt/keycloak
sudo docker compose up -d
```

### Verificar logs

```bash
sudo docker logs keycloak -f
```

Aguardar a mensagem:
```
Keycloak ... started in ...s
```

### Validar acesso

Acessar no browser:
```
http://192.168.1.10:8080
```

Login com as credenciais definidas no `.env` (padrão: `admin` / `admin`).

---

## 5.2. Criar Realm `mahikari`

1. No canto superior esquerdo, clicar no dropdown **"master"**
2. Clicar **"Create realm"**

| Campo | Valor |
|---|---|
| Realm name | `mahikari` |
| Enabled | ON |

3. Clicar **Create**

---

## 5.3. Criar Grupos

1. No realm `mahikari`, acessar **Groups** no menu lateral
2. Clicar **Create group**

### Grupo 1: `vpn-users`

| Campo | Valor |
|---|---|
| Name | `vpn-users` |

### Grupo 2: `vpn-admins`

| Campo | Valor |
|---|---|
| Name | `vpn-admins` |

---

## 5.4. Criar Roles

1. Acessar **Realm roles** no menu lateral
2. Clicar **Create role**

### Role 1: `vpn-full-access`

| Campo | Valor |
|---|---|
| Role name | `vpn-full-access` |
| Description | Acesso VPN completo à rede interna |

### Role 2: `vpn-restricted`

| Campo | Valor |
|---|---|
| Role name | `vpn-restricted` |
| Description | Acesso VPN restrito (split tunnel, serviços específicos) |

### Role 3: `vpn-admin`

| Campo | Valor |
|---|---|
| Role name | `vpn-admin` |
| Description | Administrador — pode provisionar e revogar certificados VPN |

---

## 5.5. Mapear Grupos → Roles

### Grupo `vpn-users` → Role `vpn-full-access`

1. **Groups** → selecionar `vpn-users`
2. Aba **Role mapping** → **Assign role**
3. Selecionar `vpn-full-access` → **Assign**

### Grupo `vpn-admins` → Roles `vpn-admin` + `vpn-full-access`

1. **Groups** → selecionar `vpn-admins`
2. Aba **Role mapping** → **Assign role**
3. Selecionar `vpn-admin` e `vpn-full-access` → **Assign**

---

## 5.6. Criar Usuários de Teste

### Usuário 1: `usuario.teste`

1. **Users** → **Add user**

| Campo | Valor |
|---|---|
| Username | `usuario.teste` |
| Email | `usuario.teste@mahikari.local` |
| Email verified | ON |
| First name | Usuário |
| Last name | Teste |
| Enabled | ON |

2. Clicar **Create**

3. Aba **Credentials** → **Set password**:
   - Password: (definir senha)
   - Temporary: OFF

4. Aba **Groups** → **Join group** → selecionar `vpn-users`

### Usuário 2: `admin.vpn`

| Campo | Valor |
|---|---|
| Username | `admin.vpn` |
| Email | `admin.vpn@mahikari.local` |
| Email verified | ON |
| First name | Admin |
| Last name | VPN |

- Password: (definir)
- Grupo: `vpn-admins`

### Usuário 3: `usuario.revogado`

| Campo | Valor |
|---|---|
| Username | `usuario.revogado` |
| Email | `usuario.revogado@mahikari.local` |
| Email verified | ON |
| First name | Usuário |
| Last name | Revogado |

- Password: (definir)
- Grupo: `vpn-users`

> Este usuário será usado na Fase 8 para testar revogação de certificado.

---

## 5.7. Verificação Final

### Checklist

- [ ] Keycloak acessível em `http://192.168.1.10:8080`
- [ ] Realm `mahikari` criado
- [ ] Grupos `vpn-users` e `vpn-admins` criados
- [ ] Roles `vpn-full-access`, `vpn-restricted`, `vpn-admin` criadas
- [ ] Mapeamento grupo → roles configurado
- [ ] Usuários de teste criados:
  - [ ] `usuario.teste` (vpn-users → vpn-full-access)
  - [ ] `admin.vpn` (vpn-admins → vpn-admin + vpn-full-access)
  - [ ] `usuario.revogado` (vpn-users → vpn-full-access)
- [ ] Login de cada usuário funciona no Keycloak

### Testar login

1. Acessar `http://192.168.1.10:8080/realms/mahikari/account/`
2. Login com `usuario.teste`
3. Verificar que o perfil é exibido corretamente

---

## 5.8. Exportar Realm (para reprodutibilidade)

Para salvar a configuração do realm e poder reproduzir a demo:

```bash
sudo docker exec keycloak /opt/keycloak/bin/kc.sh export \
  --dir /opt/keycloak/data/export \
  --realm mahikari \
  --users realm_file
```

Copiar o arquivo exportado:

```bash
sudo docker cp keycloak:/opt/keycloak/data/export/mahikari-realm.json \
  /opt/keycloak/realm-mahikari-export.json
```

> O arquivo `realm-mahikari-export.json` é versionado neste repositório para reprodutibilidade.

---

## Próximos Passos

- → [Fase 6: Integração Keycloak ↔ pfSense](../docs/plano-demo.md)
- → [Fase 7: Teste de VPN sem Senha](../docs/plano-demo.md)
