{ config, all_scripts, pkgs, ... }:
let
  inherit (config.environment.variables) AIA_FOLDER;
in
''
  set -eo pipefail
  echo 'Exporting CRLs' >&2
  PKIS=$(vault secrets list -format=json | jq -r 'to_entries[] | select(.value.type=="pki") | .key')
  
  for PKI_NAME in $PKIS
  do
      PKI_NAME=''${PKI_NAME%/}
      ISSUER_IDS=$(vault list -format=json ''${PKI_NAME}/issuers | jq -r '.[]')
      for ISSUER_ID in $ISSUER_IDS
      do
          if [ -n "$(vault read -format=json ''${PKI_NAME}/issuer/$ISSUER_ID | jq -r 'select(.data.key_id != "")')" ]
          then
              PKI_AIA_DIR="${AIA_FOLDER}/''${PKI_NAME}/issuer/$ISSUER_ID"
              CRL_DIR="$PKI_AIA_DIR/crl"
              mkdir -p $CRL_DIR
              vault read -format=raw ''${PKI_NAME}/issuer/$ISSUER_ID/der > $PKI_AIA_DIR/der
              # We use `/crl/pem` instead of `/crl/der`, as the latter seems to show inconsistent behavior in its output, see https://github.com/hashicorp/vault/issues/32018
              vault read -format=raw ''${PKI_NAME}/issuer/$ISSUER_ID/crl/pem > $CRL_DIR/pem
              openssl crl -outform der -in $CRL_DIR/pem -out $CRL_DIR/der
              rm $CRL_DIR/pem
          fi
      done
  done
''
