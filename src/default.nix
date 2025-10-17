{ self, system, nixpkgs, pkgs, ... }:
(nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"
    # orca configuration
    ({ config, ... }: {
      orca = {
        environment-target = "dev";
        latest_cvault = null;
        rotate_keys = false;
        actions_in_order = [
          #"create-root-CA"
          #"create-intermediate-CA"
          #"sign-csr"
          #"revoke-certificate"
        ];
      };
    })
    # Dev specific scripts
    ({ config, ... }: pkgs.lib.mkIf (config.orca.environment-target == "dev") (
      let
        dev-scripts = builtins.mapAttrs pkgs.writeShellScriptBin {
          plug-simulated-yubikey = ''
            if test $# -ne 1; then
              echo "This script requires the number of the yubikey to insert as argument" >&2
              exit 1
            fi
            if ! test -e ${./simulated-yubikeys}/yubikey''${1}@eove.fr/.gnupg; then
              echo "Invalid yubikey number" >&2
              exit 1
            fi
            rm -rf ~/.gnupg 2> /dev/null
            cp -r ${./simulated-yubikeys}/yubikey''${1}@eove.fr/.gnupg/ ~
            chmod +w,og-rwx -R ~/.gnupg
          '';
        };
      in
      {
        orca.has_dev_hack = true;
        environment.systemPackages = [
          pkgs.vim
        ] ++ (builtins.attrValues dev-scripts);
        services.openssh.enable = pkgs.lib.mkForce true;
        services.openssh.settings.PermitRootLogin = "yes";
        users.users.root = {
          openssh.authorizedKeys.keyFiles = [ ../testing/root_key.pub ];
        };
        networking = {
          useDHCP = pkgs.lib.mkForce true;
        };
      }
    ))
    # orca vault setup
    # This should probably only evolve when the orca setup evolves as well
    ({ config, ... }@args:
      let
        inherit (config.environment.variables) RECORDINGS_FOLDER VAULT_STORAGE_PATH;
        orca_user = config.users.users.orca;
        all_scripts = import ./scripts (args // { inherit orca_user pkgs all_scripts; });
        user_scripts_names = builtins.map (s: s.name) (builtins.attrValues all_scripts.custom_scripts);
        sudoer_scripts = builtins.attrValues all_scripts.orca_scripts.sudoer;

        run_ceremony = pkgs.writeShellScriptBin "run_ceremony" (import ./run_ceremony.nix (args // { inherit (pkgs) lib; inherit orca_user pkgs all_scripts; }));
        inherit (config.orca) latest_cvault;
        has_dev_hack = config.orca.has_dev_hack;
        # record everything that happens on the terminal
        record_session = pkgs.writeShellScriptBin "record_session" ''
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
              fi
              '' else ''
              echo "This is the first time O.R.CA is started so no Cvault needs to be checked"
              ''}
              
              ${if has_dev_hack then
               ''
               echo -e "\n Testing hack : You can mount ${VAULT_STORAGE_PATH} as read-only now then press enter\n"
              read -s
              '' else ""}

              if ! sudo test -w ${VAULT_STORAGE_PATH}
              then
                cat << EOF
                You successfully booted O.R.CA for the ${config.orca.environment-target} environment in read-only mode.
                To start the ceremony, please switch the stick so read/write.
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

              while ! test -w ${VAULT_STORAGE_PATH}
              do
                sleep 1
              ${if has_dev_hack then ""
              else "mount -o remount ${VAULT_STORAGE_PATH} 2> /dev/null"}
              done
              systemctl start ${config.systemd.services.vault.name}

              mkdir -p ${RECORDINGS_FOLDER}
              ${pkgs.lib.getExe pkgs.asciinema} rec -q -t "Ceremony for ${config.orca.environment-target} on $(date +'%F at %T') using $(tty)" -i 1 ${RECORDINGS_FOLDER}/ceremony-${config.orca.environment-target}-$(date +"%F_%T")$(tty | tr '/' '-').cast -c "sudo -u ${orca_user.name} ${pkgs.lib.getExe run_ceremony}"

              echo "Switch the stick to read-only to finish the ceremony"
              while test -w ${VAULT_STORAGE_PATH}
              do
                sleep 1
              ${if has_dev_hack then ""
              else "mount -o remount ${VAULT_STORAGE_PATH} || mount -o remount,ro ${VAULT_STORAGE_PATH}"}
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
            has_dev_hack = mkOption {
              type = types.bool;
              default = false;
            };
          };
        };
        config = {
          assertions =
            let
              script_names = builtins.map (p: p.name) sudoer_scripts;
              allowed_scripts = [ "backup" "count-tokens" "seal" "wipe_everything" "init-script" "rotate-shares" "unseal" "compute_c_vault" "initialize-vault"];
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
              {
                assertion = config.orca.environment-target == "dev" || config.orca.has_dev_hack == false;
                message = "Dev hack cannot be active on non dev envirnment";
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
                PUBLIC_KEYS_FOLDER = "${./share_holders_keys/${config.orca.environment-target}}";
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
            getty.autologinUser = orca_user.name;
            xserver.xkb = {
              layout = "fr,fr,us";
              variant = "oss,bepo,";
              options = "grp:menu_toggle";
            };
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

          fileSystems = pkgs.lib.mkForce
            (config.lib.isoFileSystems // {
              "${config.services.vault.storagePath}" = {
                device = "/dev/disk/by-label/VAULT_WRITABLE";
                fsType = "ext4";
              };
            });
          isoImage = {
            squashfsCompression = "gzip -Xcompression-level 1";
            volumeID = "${config.isoImage.isoBaseName}";
            isoBaseName = pkgs.lib.mkForce "orca-${config.orca.environment-target}";
            makeEfiBootable = true;
            makeUsbBootable = true;
            appendToMenuLabel = "";
            prependToMenuLabel = "O.R.CA ${config.orca.environment-target} ";
          };
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
      })
  ];
}).config.system.build.isoImage.overrideAttrs (oldAttrs: {
  squashfsCommand = "SOURCE_DATE_EPOCH=0 " + (oldAttrs.squashfsCommand or "");
})

