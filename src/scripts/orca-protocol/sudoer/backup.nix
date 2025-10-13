{ config, all_scripts, pkgs, ... }:
let
  inherit (config.environment.variables) VAULT_STORAGE_PATH ORCA_FOLDER;
  seal = pkgs.lib.getExe all_scripts.orca_scripts.orca_user.seal;
in
''
  set -e
  ${seal}
  cd ${VAULT_STORAGE_PATH}
  mv audit.log audit_$(date +%F_%T).log

  VAULT_BACKUP=/tmp/ORCA_backup.tar
  tar --numeric-owner -c -f $VAULT_BACKUP .

  C_VAULT=$(find . -type f -exec sha256sum -b {} \; | sort -k2 | sha256sum - | cut -d " " -f 1)
  echo "Cvault: $C_VAULT" | qrencode -t utf8 -i
  echo "Cvault: $C_VAULT"

  mv $VAULT_BACKUP ${ORCA_FOLDER}
''
