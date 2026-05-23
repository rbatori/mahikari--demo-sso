#!/usr/bin/env bash
# =============================================================================
# gerar-certificado-usuario.sh
#
# Gera certificado de cliente VPN e arquivo .ovpn para um usuário.
# Utiliza a CA do pfSense (exportada previamente).
#
# USO:
#   ./gerar-certificado-usuario.sh <nome_usuario> <servidor_vpn>
#
# EXEMPLO:
#   ./gerar-certificado-usuario.sh usuario.teste vpn.mahikari.com.br
#
# PRÉ-REQUISITOS:
#   - openssl instalado
#   - Arquivos da CA exportados do pfSense:
#     - ca/ca.crt          (certificado da CA)
#     - ca/ca.key          (chave privada da CA — PROTEGER!)
#   - Chave TLS-Crypt:
#     - ca/tls-crypt.key   (copiada do servidor OpenVPN)
#
# SAÍDA:
#   - certs/<nome_usuario>.crt    (certificado do cliente)
#   - certs/<nome_usuario>.key    (chave privada do cliente)
#   - ovpn/<nome_usuario>.ovpn    (arquivo de configuração completo)
# =============================================================================

set -euo pipefail

# --- Validação de argumentos ---
if [ $# -lt 2 ]; then
    echo "Uso: $0 <nome_usuario> <servidor_vpn>"
    echo "Exemplo: $0 usuario.teste vpn.mahikari.com.br"
    exit 1
fi

USUARIO="$1"
SERVIDOR="$2"

# --- Diretórios ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
CA_DIR="${BASE_DIR}/ca"
CERT_DIR="${BASE_DIR}/certs"
OVPN_DIR="${BASE_DIR}/ovpn"
TEMPLATE="${BASE_DIR}/vpn-client/template-client.ovpn"

# --- Verificações ---
if [ ! -f "${CA_DIR}/ca.crt" ]; then
    echo "ERRO: Certificado da CA não encontrado em ${CA_DIR}/ca.crt"
    echo "Exporte o certificado da CA do pfSense (System > Cert. Manager > CAs > Export CA)"
    exit 1
fi

if [ ! -f "${CA_DIR}/ca.key" ]; then
    echo "ERRO: Chave da CA não encontrada em ${CA_DIR}/ca.key"
    echo "Exporte a chave da CA do pfSense (System > Cert. Manager > CAs > Export Key)"
    exit 1
fi

if [ ! -f "${CA_DIR}/tls-crypt.key" ]; then
    echo "ERRO: Chave TLS-Crypt não encontrada em ${CA_DIR}/tls-crypt.key"
    echo "Copie a TLS Key do servidor OpenVPN (VPN > OpenVPN > Servers > Edit > TLS Key)"
    exit 1
fi

if [ ! -f "${TEMPLATE}" ]; then
    echo "ERRO: Template .ovpn não encontrado em ${TEMPLATE}"
    exit 1
fi

# --- Criar diretórios ---
mkdir -p "${CERT_DIR}" "${OVPN_DIR}"

# --- Verificar se certificado já existe ---
if [ -f "${CERT_DIR}/${USUARIO}.crt" ]; then
    echo "AVISO: Certificado para '${USUARIO}' já existe."
    read -rp "Sobrescrever? [s/N]: " resposta
    if [[ ! "$resposta" =~ ^[sS]$ ]]; then
        echo "Cancelado."
        exit 0
    fi
fi

echo "=== Gerando certificado para: ${USUARIO} ==="

# --- Gerar chave privada do cliente ---
echo "[1/4] Gerando chave privada RSA 4096..."
openssl genrsa -out "${CERT_DIR}/${USUARIO}.key" 4096 2>/dev/null

# --- Gerar CSR (Certificate Signing Request) ---
echo "[2/4] Gerando CSR..."
openssl req -new \
    -key "${CERT_DIR}/${USUARIO}.key" \
    -out "${CERT_DIR}/${USUARIO}.csr" \
    -subj "/CN=${USUARIO}/O=Mahikari/OU=VPN"

# --- Assinar certificado com a CA ---
echo "[3/4] Assinando certificado com a CA..."
openssl x509 -req \
    -in "${CERT_DIR}/${USUARIO}.csr" \
    -CA "${CA_DIR}/ca.crt" \
    -CAkey "${CA_DIR}/ca.key" \
    -CAcreateserial \
    -out "${CERT_DIR}/${USUARIO}.crt" \
    -days 365 \
    -sha256 2>/dev/null

# --- Limpar CSR (não é mais necessário) ---
rm -f "${CERT_DIR}/${USUARIO}.csr"

# --- Gerar arquivo .ovpn ---
echo "[4/4] Gerando arquivo .ovpn..."

CA_CERT=$(cat "${CA_DIR}/ca.crt")
CLIENT_CERT=$(cat "${CERT_DIR}/${USUARIO}.crt")
CLIENT_KEY=$(cat "${CERT_DIR}/${USUARIO}.key")
TLS_KEY=$(cat "${CA_DIR}/tls-crypt.key")

sed \
    -e "s|__SERVIDOR_VPN__|${SERVIDOR}|g" \
    -e "s|__CA_CERT__|${CA_CERT}|g" \
    -e "s|__CLIENT_CERT__|${CLIENT_CERT}|g" \
    -e "s|__CLIENT_KEY__|${CLIENT_KEY}|g" \
    -e "s|__TLS_CRYPT_KEY__|${TLS_KEY}|g" \
    "${TEMPLATE}" > "${OVPN_DIR}/${USUARIO}.ovpn"

# --- Proteger arquivos ---
chmod 600 "${CERT_DIR}/${USUARIO}.key"
chmod 600 "${OVPN_DIR}/${USUARIO}.ovpn"

echo ""
echo "=== Certificado gerado com sucesso ==="
echo ""
echo "  Certificado: ${CERT_DIR}/${USUARIO}.crt"
echo "  Chave:       ${CERT_DIR}/${USUARIO}.key"
echo "  .ovpn:       ${OVPN_DIR}/${USUARIO}.ovpn"
echo ""
echo "  Validade: 365 dias"
echo "  Servidor: ${SERVIDOR}:1194"
echo ""
echo "IMPORTANTE: Envie o arquivo .ovpn ao usuário por canal seguro."
echo "            O arquivo contém a chave privada — trate como senha."
