{ config, all_scripts, pkgs, ... }:
let
  inherit (config.environment.variables) VAULT_STORAGE_PATH ORCA_FOLDER;
  seal = pkgs.lib.getExe all_scripts.orca_scripts.orca_user.seal;
  computeCVault = pkgs.lib.getExe all_scripts.orca_scripts.orca_user.compute_c_vault;
in
''
  set -e
  ${seal}
  cd ${VAULT_STORAGE_PATH}
  if [ -e audit.log ]
  then
    mv audit.log audit_$(date +%F_%T).log
  fi

  VAULT_BACKUP=/tmp/ORCA_backup.tar
  tar --numeric-owner -c -f $VAULT_BACKUP .

  C_VAULT=$(${computeCVault})
  echo "Cvault: $C_VAULT" | qrencode -t utf8 -i
  echo "Cvault: $C_VAULT"

  mv $VAULT_BACKUP ${ORCA_FOLDER}
''
