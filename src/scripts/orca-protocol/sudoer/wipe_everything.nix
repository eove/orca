{ config, pkgs, ...}:
''
    echo "Something went wrong"

    echo "Sealing the vault"
    seal

    echo "Wiping everything"
    ${pkgs.lib.getExe pkgs.wipe} -r ${config.services.vault.storagePath}/*

    echo -e "\nPlease recreate the orca stick once the issue has been fixed\n"
''
