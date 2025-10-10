{ config, all_scripts, pkgs,... }:
let
  scripts_to_run_in_order = with (all_scripts.custom_scripts); [ 
    create-root-CA
  ];
  orca_protocol = all_scripts.orca_scripts.orca_user;
  ceremony_actions = pkgs.lib.strings.concatStringsSep "\n" (builtins.map (script: ''
    set -e
    echo -e "Running O.R.CA custom action '${script.name}'\n"
    ${pkgs.lib.getExe script}
    confirm
    '') scripts_to_run_in_order);
  ceremony = pkgs.writeShellScriptBin "ceremony" ''
      function confirm(){
        echo ""
        while true ; do
          read -p "Is everything ok so far ? (y/n) " choice
          case "$choice" in
            y|Y ) break;;
            n|N ) exit -1;;
            * ) ;;
          esac
        done
        echo ""
      }
    gpg --import ${./share_holders_keys/${config.orca.environment-target}}/* &> /dev/null
    
    export VAULT_ADDR="https://localhost:8200"
    export VAULT_CACERT=~/cert.pem
    
    ${pkgs.lib.getExe orca_protocol.init-script}
    
    echo "Waiting for vault to be available..."
    sleep 2
    
    echo "Vault status :"
    vault status
    
    confirm
    
    STATUS="$(vault status -format "json" | jq -r .initialized)"
    if [ "$STATUS" == "true" ]
    then
      echo "Unsealing the vault :"
      ${pkgs.lib.getExe orca_protocol.unseal}
    else
      echo "Initializing the vault :"
      ${pkgs.lib.getExe orca_protocol.initialize-vault}
    fi
    
    confirm

    ${ceremony_actions}

    echo "Sealing the vault :"
    ${pkgs.lib.getExe orca_protocol.seal}
    echo "Done"

    echo "Counting left over tokens :"
    ${pkgs.lib.getExe orca_protocol.count-tokens}

    confirm

    echo "Creating backup :"
    ${pkgs.lib.getExe orca_protocol.backup}

    confirm
'';

in 
  ''
${pkgs.lib.getExe ceremony} || ${pkgs.lib.getExe orca_protocol.wipe_everything}

echo Press enter to poweroff
read -s
poweroff
  ''
