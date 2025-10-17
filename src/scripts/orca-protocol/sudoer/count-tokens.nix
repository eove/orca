{ config, ... }:
let
  inherit (config.environment.variables) VAULT_STORAGE_PATH;
  token_folder = "${VAULT_STORAGE_PATH}/sys/token/id";
in
''
  set -e
  if [ -d ${token_folder} ]
  then
    ls ${token_folder} | wc -l
  else
    echo 0
  fi
''
