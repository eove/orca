{ config, all_scripts, lib, ... }:
let
  inherit (config.environment.variables) SHARES_FOLDER PUBLIC_KEYS_FOLDER;
  unseal = lib.getExe all_scripts.orca_scripts.orca_user.unseal;
  save_shares_from_json = lib.getExe all_scripts.orca_scripts.orca_user.save_shares_from_json;
in
''
  set -e
  THRESHOLD=3

  PUBLIC_KEYS_FILES=$(find ${PUBLIC_KEYS_FOLDER} -type f | grep -v '\.gitignore')
  PUBLIC_KEYS=$(echo -e $PUBLIC_KEYS_FILES | tr ' ' ',')
  NB_SHARES=$(ls -d "${PUBLIC_KEYS_FOLDER}"/* | wc -l)

  echo -n "Initializing vault..." >&2
  JSON="$(vault operator init -format "json" -key-shares $NB_SHARES -key-threshold $THRESHOLD -pgp-keys $PUBLIC_KEYS)"

  echo $JSON | jq -r ".unseal_keys_b64" | ${save_shares_from_json}
  echo " done"

  export VAULT_TOKEN=$(echo "$JSON" | jq -r ".root_token")

  function revoke() {
    echo "Revoking root token..." >&2
    vault token revoke $VAULT_TOKEN
  }

  trap revoke INT QUIT TERM EXIT ABRT

  ${unseal}

  vault audit enable file file_path=$VAULT_STORAGE_PATH/audit.log
''
