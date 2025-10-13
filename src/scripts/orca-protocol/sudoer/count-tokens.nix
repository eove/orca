{ config, ... }:
let
  inherit (config.environment.variables) VAULT_STORAGE_PATH;
in
''
  set -e
  ls ${VAULT_STORAGE_PATH}/sys/token/id/ | wc -l
''
