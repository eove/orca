{ config, all_scripts, pkgs, ... }:
let
  scripts_to_run_in_order = builtins.map (name: all_scripts.custom_scripts."${name}") config.orca.actions_in_order;
  orca_protocol = all_scripts.orca_scripts.orca_user;
  computeCVault = pkgs.lib.getExe all_scripts.orca_scripts.orca_user.compute_c_vault;
  count_tokens = pkgs.lib.getExe all_scripts.orca_scripts.orca_user.count-tokens;
  inherit (config.environment.variables) OUTPUT_FOLDER;
  inherit (config.orca) latest_cvault rotate_keys;
  expect_initialized = latest_cvault != null;
  ceremony_actions = pkgs.lib.strings.concatStringsSep "\n" (builtins.map
    (script: ''
      set -e
      echo -e "Running O.R.CA custom action '${script.name}'\n"
      ${pkgs.lib.getExe script}
      confirm
    '')
    scripts_to_run_in_order);
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

    
    echo "Cvault : "
    C_VAULT=$(${computeCVault})
    echo $C_VAULT

    ${ if latest_cvault != null then ''
    if [ "$C_VAULT" != "${latest_cvault}" ]
    then
      echo -e "\nThe expected Cvault was ${latest_cvault}\n"
      exit -1
    fi
    '' else ""}

    ${if !expect_initialized then ''
    if [ -d ${OUTPUT_FOLDER} ]
    then
      echo -e "\nO.R.CA was never initialized but its output folder already exists\n";
      exit -1
    fi
    '' else ""}

    ${pkgs.lib.getExe orca_protocol.init-script}

    echo -e "\nExisting tokens : "
    ${count_tokens}

    echo -e "\nWaiting for vault to be available..."
    sleep 2
    
    echo "Vault status :"
    vault status || true
    
    STATUS=$(vault status -format "json" | jq -r .initialized)

    if [ "$STATUS" != "${if expect_initialized then "true" else "false"}" ]
    then
      echo -e ${ if expect_initialized then ''\nA Cvault was given so the vault should be initialized\n'' else ''\nNo Cvault was given so the vault should NOT be initialized\n''}
      exit -1
    fi

    confirm
    
    ${pkgs.lib.getExe (with orca_protocol; if expect_initialized then unseal else initialize-vault)}

    confirm

    ${if rotate_keys then ''
      echo "Rotating the keys :"
      ${pkgs.lib.getExe orca_protocol.rotate-seal-shares}
      confirm
    '' else ""}

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
