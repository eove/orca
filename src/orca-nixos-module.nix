{ self, nixpkgs, ... }:
{
  core = { config, pkgs, ... }@args:
    let
      inherit (config.environment.variables) RECORDINGS_FOLDER VAULT_STORAGE_PATH;
      orca_user = config.users.users.orca;
      all_scripts = import ./scripts (args // { inherit orca_user pkgs all_scripts; });
      user_scripts_names = builtins.map (s: s.name) (builtins.attrValues all_scripts.custom_scripts);
      sudoer_scripts = builtins.attrValues all_scripts.orca_scripts.sudoer;

      run_ceremony = pkgs.writeShellScriptBin "run_ceremony" (import ./run_ceremony.nix (args // { inherit (pkgs) lib; inherit orca_user pkgs all_scripts; }));
      inherit (config.orca) latest_cvault;
      # record everything that happens on the terminal
      record_session = pkgs.writeShellScriptBin "record_session" ''
            mkdir -p ~/.gnupg
            echo "disable-ccid" > ~/.gnupg/scdaemon.conf
            chmod 600 ~/.gnupg
            C_VAULT=$(${pkgs.lib.getExe all_scripts.orca_scripts.orca_user.compute_c_vault})
            echo "Cvault : "
            ${ if latest_cvault != null then ''
            if [ "$C_VAULT" != "${latest_cvault}" ]
            then
              cat << EOF
              The expected Cvault was ${latest_cvault}
              Please fix it and start over.
              Press enter to poweroff
        EOF
              read -s
              poweroff
            else
              echo "A Cvault of ${latest_cvault} was found. Everything is fine, we can continue the ceremony"
            fi
            '' else ''
            echo "This is the first time O.R.CA is started so no Cvault needs to be checked"
            ''}
              
            if ! test -w ${VAULT_STORAGE_PATH}
            then
              cat << EOF
              You successfully booted O.R.CA for the ${config.orca.environment-target} environment in read-only mode.
        EOF
            else

              cat << EOF
              The stick is not in read-only mode.
              Please fix re-check the stick and start over in read-only.
              Press enter to poweroff
        EOF
              read -s
              poweroff
            fi

            DEVICE=$(df  ${VAULT_STORAGE_PATH} | tail -1 | cut -d " " -f 1 | xargs basename)
            umount ${VAULT_STORAGE_PATH}
            echo "Switch the stick to read-write to start the ceremony"
            RO_FILE="/sys/class/block/''${DEVICE}/ro"
            until [ -e $RO_FILE ] && [ $(cat $RO_FILE 2> /dev/null || echo 1) -eq  0 ]
            do
              sleep 1
            done
              
            mount /dev/''${DEVICE} ${VAULT_STORAGE_PATH}
            systemctl start ${config.systemd.services.vault.name}

            mkdir -p ${RECORDINGS_FOLDER}

            ${pkgs.lib.getExe pkgs.asciinema} rec -q -t "Ceremony for ${config.orca.environment-target} on $(date +'%F at %T') using $(tty)" -i 1 ${RECORDINGS_FOLDER}/ceremony-${config.orca.environment-target}-$(date +"%F_%T")$(tty | tr '/' '-').cast -c "sudo -u ${orca_user.name} ${pkgs.lib.getExe run_ceremony}"

            systemctl stop ${config.systemd.services.vault.name}
            DEVICE=$(df  ${VAULT_STORAGE_PATH} | tail -1 | cut -d " " -f 1 | xargs basename)
            umount ${VAULT_STORAGE_PATH}
            echo "Switch the stick to read-only to finish the ceremony"
            RO_FILE="/sys/class/block/''${DEVICE}/ro"
            until [ -e $RO_FILE ] && [ $(cat $RO_FILE 2> /dev/null || echo 0) -eq  1 ]
            do
              sleep 1
            done
            poweroff
      '';
      sudo_record_session = pkgs.writeShellScriptBin "sudo_record_session" ''
        sudo ${pkgs.lib.getExe record_session}
      '';
    in
    {
      options = with pkgs.lib; {
        orca = {
          environment-target = mkOption {
            type = with types; enum [ "dev" "preprod" "prod" ];
          };
          latest_cvault = mkOption {
            type = with types; nullOr (strMatching "[0-9a-f]{64}");
          };
          actions_in_order = mkOption {
            type = with types; listOf (enum user_scripts_names);
          };
          rotate_keys = mkOption {
            type = types.bool;
          };
          keys_threshold = mkOption {
            type = types.ints.positive;
            default = 3;
          };
          xkb = {
            layout = mkOption {
              type = types.str;
              default = "us";
            };
            variant = mkOption {
              type = types.str;
              default = "";
            };
          };
          actions_folder = mkOption {
            type = types.path;
          };
          share_holder_keys_folder = mkOption {
            type = types.path;
          };
          writable_partition_name = mkOption {
            type = types.str;
            default = "VAULT_WRITABLE";
          };
        };
      };
      config = {
        assertions =
          let
            script_names = builtins.map (p: p.name) sudoer_scripts;
            allowed_scripts = [ "backup" "count-tokens" "seal" "wipe_everything" "init-script" "rotate-shares" "unseal" "compute_c_vault" "initialize-vault" ];
            unknown_scripts = pkgs.lib.lists.subtractLists allowed_scripts script_names;
          in
          [
            {
              assertion = unknown_scripts == [ ];
              message = ''These scripts are not confirmed as scripts that can be ran with sudo : ${pkgs.lib.strings.concatStringsSep ", " unknown_scripts}

It is possible that they were saved in the wrong folder.

If it should indeed be allowed to run as root, please double check them for security risk and then add it's name to the allowed_scripts above.
              '';
            }
          ];
        environment = {
          variables =
            let
              ENVIRONMENT_TARGET = config.orca.environment-target;
              VAULT_STORAGE_PATH = config.services.vault.storagePath;
              ORCA_FOLDER = "${VAULT_STORAGE_PATH}/orca";
              OUTPUT_FOLDER = "${ORCA_FOLDER}/output";
            in
            {
              inherit ENVIRONMENT_TARGET VAULT_STORAGE_PATH ORCA_FOLDER OUTPUT_FOLDER;
              RECORDINGS_FOLDER = "${ORCA_FOLDER}/recordings";
              VAULT_ADDR = "https://localhost:8200";
              VAULT_CACERT = "${orca_user.home}/cert.pem";
              PUBLIC_KEYS_FOLDER = "${config.orca.share_holder_keys_folder}/${config.orca.environment-target}";
              SHARES_FOLDER = "${ORCA_FOLDER}/shares/${ENVIRONMENT_TARGET}";
              AIA_FOLDER = "${OUTPUT_FOLDER}/aia/${ENVIRONMENT_TARGET}";
              CERTIFICATE_FOLDER = "${OUTPUT_FOLDER}/certificates/${ENVIRONMENT_TARGET}";
            };
          systemPackages = [
            pkgs.vault
            pkgs.jq
            pkgs.gnupg
            pkgs.coreutils
            pkgs.qrencode
          ];
        };
        system.stateVersion = pkgs.lib.trivial.release;
        users = {
          # Use less privileged orca user
          users.orca = {
            isNormalUser = true;
            initialHashedPassword = "";
            ignoreShellProgramCheck = true;
            shell = pkgs.lib.getExe sudo_record_session;
          };
          # Allow the user to log in as root without a password.
          users.root.initialHashedPassword = "";
        };

        hardware.gpgSmartcards.enable = true;
        services = {
          pcscd = {
            enable = true;
          };
        };

        security = {
          # Don't require sudo/root to `reboot` or `poweroff`.
          polkit.enable = true;
          # Allow passwordless sudo from orca user for the prepared and reviewed scripts
          sudo =
            {
              enable = true;
              extraConfig = ''
                Defaults env_keep += "VAULT_ADDR VAULT_CACERT"
              '';
              extraRules = [
                {
                  users = [ orca_user.name ];
                  commands = (builtins.map
                    (script: {
                      command = "${pkgs.lib.getExe script}";
                      options = [ "NOPASSWD" ];
                    })
                    sudoer_scripts) ++ [
                    {
                      command = "${pkgs.lib.getExe record_session}";
                      options = [ "NOPASSWD" ];
                    }
                  ];
                }
              ];
            };
          acme = ({
            acceptTerms = true;
            defaults.email = "it@orca.com";
            certs = {
              "${config.networking.hostName}" = {
                group = config.users.groups.vault.name;
                listenHTTP = ":80";
                reloadServices = [ config.systemd.services.vault.name ];
                extraDomainNames = [
                  "localhost"
                ];
              };
            };
          });
        };



        services = {
          # Automatically log in at the virtual consoles.
          getty = {
            autologinUser = orca_user.name;
            autologinOnce = true;
          };
          xserver.xkb = config.orca.xkb // ({
            options = "grp:menu_toggle";
          });
          # Configure vault
          vault = {
            enable = true;
            address = "127.0.0.1:8200";
            tlsCertFile = "/var/lib/acme/${config.networking.hostName}/fullchain.pem";
            tlsKeyFile = "/var/lib/acme/${config.networking.hostName}/key.pem";
            storageBackend = "file";
          };

        };
        systemd.services.vault.wantedBy = pkgs.lib.mkForce [ ];

        console = {
          earlySetup = true;
          useXkbConfig = true;
        };

        nix = {
          settings = {
            experimental-features = [ "nix-command" "flakes" ];
          };
        };
        networking = {
          hostName = "orca-${config.orca.environment-target}";
          useDHCP = false;
        };
        nixpkgs.config.allowUnfree = true;
      };
    };
}
