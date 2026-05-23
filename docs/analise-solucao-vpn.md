# Análise de Solução — VPN sem Senha para Substituição do Firewall Aker

**Mahikari**  
Versão: 2026-05-23

---

## 1. Cenário Atual

| Item | Detalhe |
|---|---|
| Firewall atual | Aker (descontinuado) |
| VPN atual | Secure Roaming (VPN client integrado ao Aker) |
| Experiência do usuário | Clique único para conectar (sem digitar senha) |
| Autenticação | Credenciais pré-provisionadas no client |

### Problemas do cenário atual

- Firewall Aker está **obsoleto e sem suporte**
- Dependência de tecnologia proprietária descontinuada
- Risco de segurança por falta de atualizações
- Impossibilidade de auditoria moderna

---

## 2. Requisitos para a Nova Solução

| # | Requisito | Prioridade |
|---|---|---|
| R1 | Firewall open-source com suporte ativo da comunidade | Obrigatório |
| R2 | VPN client que funcione sem digitar senha | Obrigatório |
| R3 | Sem senhas em texto claro (nem no client, nem no servidor) | Obrigatório |
| R4 | Garantia de que somente usuário legítimo feche VPN | Obrigatório |
| R5 | Revogação imediata de acesso | Obrigatório |
| R6 | Gestão centralizada de identidades (IdP) | Desejável |
| R7 | Auditoria de conexões VPN | Desejável |
| R8 | Suporte a Windows, macOS, Linux e mobile | Desejável |
| R9 | Experiência similar ao Secure Roaming (zero clique após setup) | Desejável |

---

## 3. Soluções Avaliadas

### 3.1. pfSense + OpenVPN + Certificados Digitais + Keycloak (**Recomendada**)

**Descrição:** pfSense como firewall com OpenVPN server usando autenticação exclusivamente por certificados X.509. Keycloak como IdP para gestão de identidades e ciclo de vida dos certificados.

| Critério | Avaliação |
|---|---|
| VPN sem senha | **Sim** — certificado digital substitui a senha |
| Sem texto claro | **Sim** — chaves assimétricas (RSA/ECDSA) |
| Usuário legítimo | **Sim** — certificado único por usuário, emitido pela CA do pfSense |
| Revogação | **Sim** — CRL (Certificate Revocation List) nativa do pfSense |
| Gestão centralizada | **Sim** — Keycloak gerencia identidades; portal de provisioning |
| Auditoria | **Sim** — logs do pfSense + logs do Keycloak |
| Multiplataforma | **Sim** — OpenVPN client disponível para todos os SO |
| Zero clique | **Sim** — após importar `.ovpn`, basta clicar "Conectar" |
| Maturidade | **Alta** — pfSense e OpenVPN são amplamente utilizados |

**Vantagens:**
- Solução madura e amplamente documentada
- PKI nativa do pfSense (CA, emissão, revogação)
- OpenVPN Community é open-source e multiplataforma
- Keycloak já utilizado na infraestrutura (experiência existente)
- Experiência do usuário idêntica ao Secure Roaming

**Desvantagens:**
- Setup inicial mais complexo (PKI, CA, certificados)
- Necessita processo de distribuição segura dos `.ovpn` aos usuários

---

### 3.2. pfSense + WireGuard + Keycloak

**Descrição:** pfSense com WireGuard (via package) como protocolo VPN. Keycloak para gestão de identidades.

| Critério | Avaliação |
|---|---|
| VPN sem senha | **Sim** — chaves públicas/privadas |
| Sem texto claro | **Sim** — criptografia de curva elíptica |
| Revogação | **Parcial** — não tem CRL nativo; precisa remover peer manualmente |
| Maturidade no pfSense | **Média** — WireGuard é package adicional, não nativo |

**Vantagens:**
- Protocolo moderno e performático
- Configuração simples do client

**Desvantagens:**
- No pfSense, WireGuard é via package (menos integrado)
- Sem CRL nativo — revogação requer remoção manual do peer
- Gestão de chaves mais manual
- Menos maduro no ecossistema pfSense

**Veredito:** Viável, mas inferior ao OpenVPN para este caso de uso específico (gestão de certificados e revogação).

---

### 3.3. OPNsense + OpenVPN + Certificados + Keycloak

**Descrição:** OPNsense (fork do pfSense) com a mesma arquitetura de certificados.

| Critério | Avaliação |
|---|---|
| VPN sem senha | **Sim** — mesma abordagem de certificados |
| API | **Superior** — OPNsense tem API REST melhor |
| Comunidade | **Menor** que pfSense |

**Vantagens:**
- API REST mais moderna (facilita automação)
- Interface web mais polida
- Atualizações mais frequentes

**Desvantagens:**
- Comunidade menor que pfSense
- Menos documentação e tutoriais disponíveis
- Migração de conhecimento se a equipe já conhece pfSense

**Veredito:** Alternativa válida. Se a equipe não tem preferência, OPNsense é tecnicamente equivalente. pfSense recomendado por ter comunidade e documentação maiores.

---

### 3.4. OpenVPN + OIDC (openvpn-auth-oauth2)

**Descrição:** Plugin que permite autenticação OAuth2/OIDC no momento da conexão VPN, redirecionando para o Keycloak via browser.

| Critério | Avaliação |
|---|---|
| VPN sem senha | **Parcial** — requer interação com browser a cada conexão |
| SSO nativo | **Sim** — login via Keycloak |
| Zero clique | **Não** — abre browser para autenticação |

**Vantagens:**
- SSO verdadeiro (validação de identidade a cada conexão)
- Não precisa distribuir certificados

**Desvantagens:**
- **Não é "zero clique"** — exige interação com browser
- Experiência diferente do Secure Roaming atual
- Dependência de browser funcional no momento da conexão

**Veredito:** Bom como camada adicional de segurança, mas não atende ao requisito de "VPN sem digitar senha" no sentido de zero interação. Pode ser usado como complemento (certificado + OIDC).

---

### 3.5. Firezone (WireGuard + OIDC nativo)

**Descrição:** Solução VPN dedicada baseada em WireGuard com integração nativa OIDC/SAML.

| Critério | Avaliação |
|---|---|
| VPN sem senha | **Parcial** — SSO via browser |
| Firewall completo | **Não** — é apenas VPN, não substitui o firewall |
| Open-source | **Sim** (licença Apache 2.0) |

**Vantagens:**
- Integração nativa com Keycloak (OIDC/SAML)
- Interface web moderna
- Deploy simples (Docker)

**Desvantagens:**
- **Não é firewall** — precisaria de outro firewall junto (pfSense/OPNsense)
- Complexidade adicional (dois sistemas em vez de um)
- Zero clique não garantido (depende de sessão SSO ativa)

**Veredito:** Não recomendado como solução principal. Adiciona complexidade sem resolver o requisito de firewall.

---

## 4. Matriz Comparativa

| Critério | pfSense+OpenVPN+Cert | pfSense+WireGuard | OPNsense+OpenVPN | OpenVPN+OIDC | Firezone |
|---|:---:|:---:|:---:|:---:|:---:|
| VPN sem senha (zero clique) | **Sim** | Sim | Sim | Não | Não |
| Sem texto claro | Sim | Sim | Sim | Sim | Sim |
| Revogação imediata (CRL) | **Sim** | Parcial | Sim | N/A | Parcial |
| Firewall completo | Sim | Sim | Sim | Depende | **Não** |
| Gestão centralizada (Keycloak) | Sim | Sim | Sim | **Nativo** | **Nativo** |
| Maturidade | **Alta** | Média | Alta | Média | Média |
| Documentação/Comunidade | **Alta** | Média | Média | Baixa | Média |
| Experiência similar ao Aker | **Sim** | Sim | Sim | Não | Não |

---

## 5. Recomendação Final

### Solução recomendada: **pfSense + OpenVPN + Certificados Digitais + Keycloak**

**Justificativa:**

1. **Atende a todos os requisitos obrigatórios** (R1-R5)
2. **Experiência do usuário idêntica ao Secure Roaming** — zero clique após setup inicial
3. **Segurança robusta** — PKI com certificados X.509, sem senhas, revogação via CRL
4. **Keycloak como IdP** — aproveita experiência existente da equipe
5. **Maturidade e suporte** — pfSense e OpenVPN são referências em open-source
6. **Auditabilidade** — logs completos de conexão no pfSense e autenticação no Keycloak

### Evolução futura (opcional)

Após a migração inicial, considerar adicionar **autenticação OIDC complementar** (certificado + SSO) para cenários que exijam validação de identidade a cada conexão (ex.: acesso a ambientes críticos).

---

## Referências

- [pfSense — OpenVPN](https://docs.netgate.com/pfsense/en/latest/vpn/openvpn/index.html)
- [pfSense — Certificate Management](https://docs.netgate.com/pfsense/en/latest/certificates/index.html)
- [OpenVPN — How To](https://openvpn.net/community-resources/how-to/)
- [WireGuard — Protocol](https://www.wireguard.com/)
- [openvpn-auth-oauth2](https://github.com/jkroepke/openvpn-auth-oauth2)
- [Firezone](https://www.firezone.dev/)
- [Keycloak — Documentation](https://www.keycloak.org/documentation)
