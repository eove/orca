{ config, pkgs, lib, all_scripts, ... }:
let
  wipe = lib.getExe pkgs.wipe;
  seal = lib.getExe all_scripts.orca_scripts.orca_user.seal;
  inherit (config.environment.variables) VAULT_STORAGE_PATH RECORDINGS_FOLDER;
in
''
  set -e
  echo "Something went wrong"

  echo "Sealing the vault"
  ${seal}

  echo "Wiping everything"
  KEPT_LOGS=/tmp/kept_logs
  mkdir -p $KEPT_LOGS/recordings
  find ${VAULT_STORAGE_PATH} -iname "audit*" -exec cp -r {} $KEPT_LOGS \;
  cp -r ${RECORDINGS_FOLDER}/* $KEPT_LOGS/recordings
  ${wipe} -r ${VAULT_STORAGE_PATH}/*
  mkdir -p ${VAULT_STORAGE_PATH} ${RECORDINGS_FOLDER}
  mv $KEPT_LOGS/recordings/* ${RECORDINGS_FOLDER}
  find $KEPT_LOGS -iname "audit*" -exec cp -r {} ${VAULT_STORAGE_PATH}  \;

  echo -e "\nPlease recreate the orca stick once the issue has been fixed\n"
''
