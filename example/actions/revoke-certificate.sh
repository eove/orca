set -e
if [ -z "$AIA_FOLDER" ]; then
    echo "Expected environment variables : AIA_FOLDER" >&2
    exit -1
fi
if [ -z "$VAULT_TOKEN" ]; then
    echo "Expected environment variables : VAULT_TOKEN" >&2
    exit -1
fi


# Informations from the certificate can be read with openssl via :
# openssl x509 -noout -text -in /path/to/certificate.pem
SERIAL_NUMBER="2b:18:39:30:61:ba:39:24:19:f0:89:28:0a:8c:54:37:5a:20:c2:13"

#The issuer ID can be found in the certificate in the Authority Information Acces URL after /issuer
#
#For exemple :
# 
#Authority Information Access:
#                 CA Issuers - URI:https://dev.vault.eove.fr/devices_pki/issuer/7649c40c-b750-1bde-ad81-08da89a591b3/der
ISSUER_ID="07ecec42-286a-b68b-6338-987a8d5ad691"

PKI_SUBDOMAIN="devices"
PKI_NAME="${PKI_SUBDOMAIN}_pki"

export CERTIFICATE_FILE=${CERTIFICATE_FOLDER}/${PKI_SUBDOMAIN}-online-$(date +%F_%T).cert.pem
vault write ${PKI_NAME}/revoke \
    serial_number="${SERIAL_NUMBER}" 

CRL_DIR="$AIA_FOLDER/$PKI_NAME/issuer/$ISSUER_ID/crl"
mkdir -p $CRL_DIR
vault read -format=raw $PKI_NAME/issuer/$ISSUER_ID/crl/der > $CRL_DIR/der
