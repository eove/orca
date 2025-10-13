{ config, all_scripts, pkgs, ... }:
let
  inherit (config.environment.variables) VAULT_STORAGE_PATH ;
in ''
  set -e
  find ${VAULT_STORAGE_PATH} -type f -exec sha256sum -b {} \; | sort -k2 | sha256sum - | cut -d " " -f 1
''

