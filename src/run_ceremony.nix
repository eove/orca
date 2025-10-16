{ config, all_scripts, pkgs, ... }:
let
  scripts_to_run_in_order = builtins.map (name: all_scripts.custom_scripts."${name}") config.orca.actions_in_order;
  orca_protocol = all_scripts.orca_scripts.orca_user;
  computeCVault = pkgs.lib.getExe all_scripts.orca_scripts.orca_user.compute_c_vault;
  count_tokens = pkgs.lib.getExe all_scripts.orca_scripts.orca_user.count-tokens;
  inherit (config.environment.variables) OUTPUT_FOLDER;
  inherit (config.orca) latest_cvault rotate_keys;
  expect_initialized = latest_cvault != null;
  has_actions = (builtins.length scripts_to_run_in_order) > 0;
  ceremony_actions = pkgs.lib.strings.concatStringsSep "\n" (builtins.map
    (script: ''
      set -e
      echo -e "Running O.R.CA custom action '${script.name}'\n"
      ${pkgs.lib.getExe script}
      confirm
    '')
    scripts_to_run_in_order);
  plan = pkgs.lib.strings.concatStringsSep "\n" (builtins.filter (l: l != "") ([
    (if expect_initialized then "- Unseal the vault" else "- Initialise the vault")
    (if rotate_keys then ''- Rotate the vault keys
    '' else "")
    (if has_actions then ''- Get a root token'' else "")
  ]
  ++ (builtins.map
    (script: ''- Run ${script.name} '')
    scripts_to_run_in_order)
  ++ [
    (if has_actions then ''- Revoke the root token'' else "")
    "- Seal the vault"
    "- Validate that no root token is left"
    "- Backup everything"
  ]));
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
          echo -e "${ if expect_initialized then ''\nA Cvault was given so the vault should be initialized\n'' else ''\nNo Cvault was given so the vault should NOT be initialized\n''}"
          exit -1
      fi

        cat << EOF

      Here is the ceremony plan :
      ${plan}
    EOF

      confirm
  
      ${pkgs.lib.getExe (with orca_protocol; if expect_initialized then unseal else initialize-vault)}

        confirm

        ${if rotate_keys then ''
              echo "Rotating the keys :"
              ${pkgs.lib.getExe orca_protocol.rotate-shares}
              confirm
            '' else ""}

        ${if has_actions then ''
                  cat << EOF
              I am going to get a root token in order to run the following scripts :
              ${pkgs.lib.strings.concatStringsSep "\n" (builtins.map
                  (script: ''- ${script.name} '')
                  scripts_to_run_in_order)}

              The root token will be revoked right after that.
    EOF

        confirm
 
        echo "Getting a root token :"
        export VAULT_TOKEN=$(${pkgs.lib.getExe all_scripts.orca_scripts.orca_user.get_root_token})

        ${ceremony_actions}

        echo "Revoking the root token :"
        vault token revoke $VAULT_TOKEN
            '' else ""}

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
''
