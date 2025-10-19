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
# Creating root CA
###################################

PKI_NAME="root_pki"
TTL=$(( 30 * 365 * 24 ))h # 30 years

vault secrets enable -path=$PKI_NAME pki

vault secrets tune -max-lease-ttl=$TTL $PKI_NAME

vault write $PKI_NAME/config/cluster \
    aia_path=https://${TARGET_SUBDOMAIN}aia.eove.fr/$PKI_NAME

vault write $PKI_NAME/config/urls \
    issuing_certificates={{cluster_aia_path}}/issuer/{{issuer_id}}/der \
    crl_distribution_points={{cluster_aia_path}}/issuer/{{issuer_id}}/crl/der \
    enable_templating=true

ISSUER_ID=$(vault write -format=json $PKI_NAME/root/generate/internal \
    common_name="Eove $ENVIRONMENT_TARGET Offline Root CA $(date +%F)" \
     issuer_name="eove-${ENVIRONMENT_TARGET}-offline-root-$(date +%F)" \
     ou="Eove" \
     country="France" \
     ttl="$TTL" \
     exclude_cn_from_sans=true \
     alt_names="eove.fr" \
     key_type="ed25519" | jq -r '.data.issuer_id')


###################################
# Exporting root CA's AIA 
###################################

PKI_AIA_DIR="$AIA_FOLDER/$PKI_NAME/issuer/$ISSUER_ID"
CRL_DIR="$PKI_AIA_DIR/crl"
mkdir -p $PKI_AIA_DIR
mkdir -p $CRL_DIR
vault read -format=raw $PKI_NAME/issuer/$ISSUER_ID/der > $PKI_AIA_DIR/der
vault read -format=raw $PKI_NAME/issuer/$ISSUER_ID/crl/der > $CRL_DIR/der

