set -e
if [ -z "$ENVIRONMENT_TARGET" ]; then
    echo "Expected environment variables : ENVIRONMENT_TARGET" >&2
    exit -1
fi
if [ -z "$AIA_FOLDER" ]; then
    echo "Expected environment variables : AIA_FOLDER" >&2
    exit -1
fi
if [ -z "$VAULT_TOKEN" ]; then
    echo "Expected environment variables : VAULT_TOKEN" >&2
    exit -1
fi

if [ $ENVIRONMENT_TARGET != "prod" ]
then
TARGET_SUBDOMAIN="${ENVIRONMENT_TARGET}."
fi

###################################
# Creating devices intermediate CA
###################################

PKI_SUBDOMAIN="devices"
PKI_NAME="${PKI_SUBDOMAIN}_pki"
TTL=$(( 30 * 365 * 24 ))h 

vault secrets enable -path=$PKI_NAME pki

vault secrets tune -max-lease-ttl=$TTL $PKI_NAME

vault write $PKI_NAME/config/cluster \
    aia_path=https://${TARGET_SUBDOMAIN}vault.eove.fr/$PKI_NAME

vault write $PKI_NAME/config/urls \
    issuing_certificates={{cluster_aia_path}}/issuer/{{issuer_id}}/der \
    crl_distribution_points={{cluster_aia_path}}/issuer/{{issuer_id}}/crl/der \
    enable_templating=true

CSR_FILE=$(mktemp -t ${PKI_SUBDOMAIN}-offline-XXXX.csr)

vault write -format=json $PKI_NAME/intermediate/generate/internal \
    common_name="Eove $ENVIRONMENT_TARGET $PKI_SUBDOMAIN Offline Intermediate CA $(date +%F)" \
    issuer_name="eove-${ENVIRONMENT_TARGET}-${PKI_SUBDOMAIN}-offline-intermediate-$(date +%F)" \
    ou="Eove" \
    organization=$PKI_SUBDOMAIN \
    country="France" \
    ttl="$TTL" \
    exclude_cn_from_sans=true \
    alt_names="${PKI_SUBDOMAIN}.eove.fr" \
    key_type="ed25519" \
    | jq -r '.data.csr' > $CSR_FILE

CERTIFICATE_FILE=$(mktemp -t ${PKI_SUBDOMAIN}-offline-XXXX.cert.pem)

vault write -format=json root_pki/root/sign-intermediate \
    issuer_ref="default" \
    csr=@${CSR_FILE} \
    format=pem_bundle \
    ttl=$TTL \
    | jq -r '.data.certificate' > $CERTIFICATE_FILE


vault write $PKI_NAME/intermediate/set-signed certificate=@${CERTIFICATE_FILE}
ISSUER_ID=$(vault read -format=json $PKI_NAME/config/issuers | jq -r '.data.default')

###################################
# Exporting devices CA's AIA 
###################################

PKI_AIA_DIR="$AIA_FOLDER/$PKI_NAME/issuer/$ISSUER_ID"
CRL_DIR="$PKI_AIA_DIR/crl"
mkdir -p $PKI_AIA_DIR
mkdir -p $CRL_DIR
vault read -format=raw $PKI_NAME/issuer/$ISSUER_ID/der > $PKI_AIA_DIR/der
vault read -format=raw $PKI_NAME/issuer/$ISSUER_ID/crl/der > $CRL_DIR/der
