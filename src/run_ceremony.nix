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
    set -e
    source /etc/profile
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
    
    export VAULT_ADDR
    export VAULT_CACERT

    ${pkgs.lib.getExe orca_protocol.init-script}
    
    echo "Waiting for vault to be available..."
    sleep 2
    
    echo "Vault status :"
    vault status || true
    
    confirm
    
    STATUS="$($(vault status -format "json" | jq -r .initialized) || true)"
    if [ "$STATUS" == "true" ]
    then
      ${pkgs.lib.getExe orca_protocol.unseal}
    else
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
