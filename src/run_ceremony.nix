{ config, init-script, all_scripts, pkgs, wipe_everything,... }:
let
  scripts_to_run_in_order = with (all_scripts.custom_scripts); [ 
    create-root-CA
  ];
  ceremony_actions = pkgs.lib.strings.concatStringsSep "\n" (builtins.map (script: ''
    echo -e "Running O.R.CA custom action '${script.name}'\n"
    ${pkgs.lib.getExe script}
    confirm
    '') scripts_to_run_in_order);
  ceremony = pkgs.writeShellScriptBin "ceremony" ''
      function confirm(){
        echo ""
        while true ; do
          read -p "Is everything ok so far ?(y/n)" choice
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
    
    sudo ${pkgs.lib.getExe init-script}
    
    echo "Waiting for vault to be available..."
    sleep 2
    
    echo "Vault status :"
    vault status
    
    confirm
    
    STATUS="$(vault status -format "json" | jq -r .initialized)"
    if [ "$STATUS" == "true" ]
    then
      echo "Unsealing the vault :"
      unseal 
    else
      echo "Initializing the vault :"
      initialize-vault 
    fi
    
    confirm

    ${ceremony_actions}

    echo "Sealing the vault :"
    seal

    echo "Counting left over tokens :"
    count-tokens

    confirm

    echo "Creating backup :"
    backup

    confirm
'';

in 
  ''
${pkgs.lib.getExe ceremony} || sudo ${pkgs.lib.getExe wipe_everything}

echo Press enter to poweroff
read -s
poweroff
  ''
