set -e
if [ -z "$CERTIFICATE_FOLDER" ]; then
    echo "Expected environment variables : CERTIFICATE_FOLDER" >&2
    exit -1
fi
if [ -z "$VAULT_TOKEN" ]; then
    echo "Expected environment variables : VAULT_TOKEN" >&2
    exit -1
fi


CSR="
-----BEGIN CERTIFICATE REQUEST-----
MIIBKDCB2wIBADBzMQ8wDQYDVQQGEwZGcmFuY2UxEDAOBgNVBAoTB2RldmljZXMx
DTALBgNVBAsTBEVvdmUxPzA9BgNVBAMTNkVvdmUgcHJlcHJvZCBkZXZpY2VzIE9u
bGluZSBJbnRlcm1lZGlhdGUgQ0EgMjAyNS0wNS0xMzAqMAUGAytlcAMhADuMFXZH
ukuRJUtZYn0McMvutsTwbgnb4s7B47oq9hJsoDUwMwYJKoZIhvcNAQkOMSYwJDAi
BgNVHREEGzAZghdwcmVwcm9kLmRldmljZXMuZW92ZS5mcjAFBgMrZXADQQBY/lWr
8/xW+hlK1A/28SQ758F/mRXC4T22dkVtJWr1vVt00SN7TfQZX+/tRCjqJ/QXjt6s
2XfWvBotHVkAZ3YJ
-----END CERTIFICATE REQUEST-----
"

PKI_SUBDOMAIN="devices"
TTL=$((14 * 365 * 24 ))h
PKI_NAME="${PKI_SUBDOMAIN}_pki"

export CERTIFICATE_FILE=${CERTIFICATE_FOLDER}/${PKI_SUBDOMAIN}-online-$(date +%F_%T).cert.pem
vault write -format=json ${PKI_NAME}/root/sign-intermediate \
    issuer_ref="default" \
    csr="${CSR}" \
    format=pem_bundle \
    ttl=${TTL} \
    | jq -r '.data.certificate' > $CERTIFICATE_FILE

echo "$CERTIFICATE_FILE"
