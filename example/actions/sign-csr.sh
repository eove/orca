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
MIGsMGACAQAwLTErMCkGA1UEAxMiT25saW5lIGludGVybWVkaWF0ZSBkZXYgZGV2
aWNlcyBDQTAqMAUGAytlcAMhAFzrgrqd4/V5Wph3MK4ke4JM/Kr14N2E697t+PbP
WItaoAAwBQYDK2VwA0EAdaF22q0ageNQhq4NBZcxbGaxYoIc+ji9vYg68VCbxJz6
5FqAbV0kDiTMzNI57alkienpHlw9Ivo0MZMCvNA/BA==
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

echo -e "\nSigned certificate can be found at $CERTIFICATE_FILE\n"
