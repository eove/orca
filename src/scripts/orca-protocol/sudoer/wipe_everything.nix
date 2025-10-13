{ config, pkgs, lib, all_scripts, ...}:
let
  wipe = lib.getExe pkgs.wipe;
  seal = lib.getExe all_scripts.orca_scripts.orca_user.seal;
in ''
    echo "Something went wrong"

    echo "Sealing the vault"
    ${seal}

    echo "Wiping everything"
    ${wipe} -r ${config.services.vault.storagePath}/*

    echo -e "\nPlease recreate the orca stick once the issue has been fixed\n"
''
