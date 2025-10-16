{ config, pkgs, lib, all_scripts, ... }:
let
  wipe = lib.getExe pkgs.wipe;
  seal = lib.getExe all_scripts.orca_scripts.orca_user.seal;
  inherit (config.environment.variables) OUTPUT_FOLDER;
in
''
  echo "Something went wrong"

  echo "Sealing the vault"
  ${seal}

  echo "Wiping outputs"
  ${wipe} -r ${OUTPUT_FOLDER}/*

  echo -e "\nPlease recreate the orca stick once the issue has been fixed\n"
''
