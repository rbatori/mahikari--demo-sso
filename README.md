# Mahikari — Demo SSO: VPN sem Senha com pfSense + Keycloak

## Objetivo

Demonstrar a substituição do firewall Aker (Secure Roaming) por uma solução open-source baseada em **pfSense + OpenVPN + Keycloak**, permitindo que usuários remotos estabeleçam VPN **sem digitar senha**, de forma segura e auditável.

## Problema

O firewall Aker atual está obsoleto. O principal desafio na migração é manter a experiência "VPN sem senha" do Secure Roaming, garantindo:

- Nenhuma senha em texto claro
- Somente usuários legítimos fecham VPN
- Revogação imediata de acesso quando necessário
- Gestão centralizada de identidades

## Solução

| Componente | Função |
|---|---|
| **pfSense** | Firewall open-source + servidor OpenVPN + PKI (CA interna) |
| **OpenVPN** | Protocolo VPN com autenticação por certificado digital X.509 |
| **Keycloak** | Identity Provider central — gestão de usuários e ciclo de vida dos certificados |

### Como funciona a VPN sem senha?

1. A CA interna do pfSense emite um **certificado digital único por usuário**
2. O arquivo `.ovpn` contém o certificado + chave privada (protegida pelo SO)
3. Usuário importa o `.ovpn` no client OpenVPN (Windows/Mac/Linux/Mobile)
4. Ao clicar **"Conectar"** → o client apresenta o certificado → **VPN estabelecida sem senha**
5. Para revogar acesso: adicionar certificado à CRL (Certificate Revocation List)

## Estrutura do Repositório

```
mahikari--demo-sso/
├── README.md                                   # Este arquivo
├── docs/
│   ├── analise-solucao-vpn.md                  # Análise comparativa das soluções avaliadas
│   ├── arquitetura-vpn-sem-senha.md            # Arquitetura da solução (diagramas)
│   └── plano-demo.md                           # Plano de atividades da demo (fases)
├── pfsense/
│   ├── procedimento-pfsense.md                 # Instalação e configuração base do pfSense
│   ├── openvpn-server.md                       # Configuração do servidor OpenVPN
│   ├── pki-certificados.md                     # Gestão de certificados (CA, emissão, revogação)
│   └── firewall-rules.md                       # Regras de firewall para VPN
├── keycloak/
│   ├── docker-compose.yml                      # Docker Compose do Keycloak para a demo
│   ├── procedimento-keycloak.md                # Configuração do realm, usuários e roles
│   └── realm-mahikari-export.json              # Export do realm configurado
├── vpn-client/
│   ├── procedimento-cliente-vpn.md             # Instalação e configuração do client OpenVPN
│   └── template-client.ovpn                    # Template do arquivo .ovpn
└── scripts/
    └── gerar-certificado-usuario.sh            # Script para gerar certificado + .ovpn por usuário
```

## Referências

- [pfSense — Documentação oficial](https://docs.netgate.com/pfsense/en/latest/)
- [OpenVPN — Community](https://openvpn.net/community/)
- [Keycloak — Documentação](https://www.keycloak.org/documentation)
- [Manole — Arquitetura de Controle de Acesso](https://github.com/rbatori/manole-seguranca-informacao/blob/main/infra/controle-acesso/arquitetura-solucao.md) (referência de integração Keycloak)
