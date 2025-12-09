{ config, all_scripts, lib, ... }:
let
  inherit (config.environment.variables) SHARES_FOLDER PUBLIC_KEYS_FOLDER VAULT_STORAGE_PATH;
  unseal = lib.getExe all_scripts.orca_scripts.orca_user.unseal;
  save_shares_from_json = lib.getExe all_scripts.orca_scripts.root_only.save_shares_from_json;
in
''
  set -e
  THRESHOLD=${builtins.toString config.orca.keys_threshold}

  PUBLIC_KEYS_FILES=$(find ${PUBLIC_KEYS_FOLDER} -type f | grep -v '\.git.*')
  PUBLIC_KEYS=$(echo -e $PUBLIC_KEYS_FILES | tr ' ' ',')
  NB_SHARES=$(ls -d "${PUBLIC_KEYS_FOLDER}"/* | wc -l)

  echo -n "Initializing vault..." >&2
  JSON="$(vault operator init -format "json" -key-shares $NB_SHARES -key-threshold $THRESHOLD -pgp-keys $PUBLIC_KEYS)"

  echo $JSON | jq -r ".unseal_keys_b64" | ${save_shares_from_json} 
  echo " done" >&2

  export VAULT_TOKEN=$(echo "$JSON" | jq -r ".root_token")

  function revoke() {
    echo "Revoking initialisation root token..." >&2
    vault token revoke $VAULT_TOKEN >&2
  }

  trap revoke INT QUIT TERM EXIT ABRT

  ${unseal}

  vault audit enable file file_path=${VAULT_STORAGE_PATH}/audit.log >&2
''
