{ config, all_scripts, pkgs,... }:
let
  scripts_to_run_in_order = with (all_scripts.custom_scripts); [ 
    create-root-CA
  ];
  orca_protocol = all_scripts.orca_scripts.orca_user;
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
    
    # TODO the script header is creating issues here. Should be fixed with a root only getShare script
    sudo ${pkgs.lib.getExe all_scripts.orca_scripts.sudoer.init-script}
    
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
${pkgs.lib.getExe ceremony} || ${pkgs.lib.getExe orca_protocol.wipe_everything}

echo Press enter to poweroff
read -s
poweroff
  ''
