{ self, system, nixpkgs, pkgs, ... }:
(nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"
    # orca configuration
    ({ config, ... }: {
      orca = {
        environment-target = "dev";
      };
    })
    # Dev specific scripts
    ({ config, ... }: pkgs.lib.mkIf (config.orca.environment-target == "dev") (
      let
        orca_user = config.users.users.orca;
        dev-scripts = builtins.mapAttrs pkgs.writeShellScriptBin {
          plug-simulated-yubikey = ''
            rm -rf ${orca_user.home}/.gnupg 2> /dev/null
            cp -r ${./simulated-yubikeys}/yubikey''${1}@eove.fr/.gnupg/ ${orca_user.home}/
            chown -R ${orca_user.name}:${orca_user.group} ${orca_user.home}/.gnupg
            chmod +w,og-rwx -R ${orca_user.home}/.gnupg
          '';
        };
      in
      {
        environment.systemPackages = [
          pkgs.vim
        ] ++ (builtins.attrValues dev-scripts);
        services.openssh.enable = pkgs.lib.mkForce true;
        services.openssh.settings.PermitRootLogin = "yes";
        users.users.root = {
          initialPassword = pkgs.lib.mkForce "root";
          initialHashedPassword = pkgs.lib.mkForce null;
        };
        users.users.orca = {
          initialPassword = pkgs.lib.mkForce "orca";
          initialHashedPassword = pkgs.lib.mkForce null;
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
        recordDir = ''${config.services.vault.storagePath}/recordings'';
        orcaDir = ''${config.services.vault.storagePath}/orca'';
        orca_user = config.users.users.orca;
        all_scripts = import ./scripts (args // { inherit recordDir orca_user pkgs; });
        custom_scripts = builtins.attrValues all_scripts.custom_scripts;
        orca_user_scripts = builtins.attrValues all_scripts.orca_scripts.orca_user;
        sudoer_scripts = builtins.attrValues all_scripts.orca_scripts.sudoer;
        init-script = pkgs.writeShellScriptBin "init-script" ''
          cp /var/lib/acme/.minica/cert.pem ${orca_user.home}/cert.pem
          chown ${orca_user.name} ${orca_user.home}/cert.pem
          mkdir -p ${orcaDir}
          chown -R ${orca_user.name} ${orcaDir}

          echo "Cvault : "
          find ${config.services.vault.storagePath} -type f -exec sha256sum -b {} \; | sort -k2 | sha256sum - | cut -d " " -f 1
        '';
  wipe_everything = pkgs.writeShellScriptBin "wipe_everything" ''
    echo "Something went wrong"

    echo "Sealing the vault"
    seal

    echo "Wiping everything"
    ${pkgs.lib.getExe pkgs.wipe} -r ${config.services.vault.storagePath}/*

    echo -e "\nPlease recreate the orca stick once the issue has been fixed\n"
    '';

        run_ceremony = pkgs.writeShellScriptBin "run_ceremony" (import ./run_ceremony.nix (args // { inherit (pkgs) lib; inherit orca_user pkgs all_scripts init-script wipe_everything; }));
        # record everything that happens on the terminal
        su_record_session = pkgs.writeShellScriptBin "su_record_session" ''
          mkdir -p ${recordDir}
          ${pkgs.lib.getExe pkgs.asciinema} rec -q -t "Ceremony for ${config.orca.environment-target} on $(date +'%F at %T') using $(tty)" -i 1 ${recordDir}/ceremony-${config.orca.environment-target}-$(date +"%F_%T")$(tty | tr '/' '-').cast -c "sudo -u ${orca_user.name} ${pkgs.lib.getExe run_ceremony}"
        '';
        record_session = pkgs.writeShellScriptBin "record_session" ''
          sudo ${pkgs.lib.getExe su_record_session}
          '';
      in
      {
        options = with pkgs.lib; {
          orca = {
            environment-target = mkOption {
              type = with types; enum [ "dev" "preprod" "prod" ];
            };
          };
        };
        config = {
          assertions = 
            let
              script_names = builtins.map (p: p.name) sudoer_scripts;
              allowed_scripts = [ "backup" "count-tokens" "seal" ];
              unknown_scripts = pkgs.lib.lists.subtractLists allowed_scripts script_names;
            in 
          [
            {
              assertion = unknown_scripts == [];
              message = ''These scripts are not confirmed as scripts that can be ran with sudo : ${pkgs.lib.strings.concatStringsSep ", " unknown_scripts}

It is possible that they were saved in the wrong folder.

If it should indeed be allowed to run as root, please double check them for security risk and then add it's name to the allowed_scripts above.
              '';
            }
          ];
          environment = {
            systemPackages = [
              pkgs.vault
              pkgs.jq
              pkgs.gnupg
              pkgs.coreutils
              pkgs.qrencode
            ]
            ++ custom_scripts
            ++ orca_user_scripts
            ;
          };
          system.stateVersion = pkgs.lib.trivial.release;
          users = {
            # Use less privileged orca user
            users.orca = {
              isNormalUser = true;
              initialHashedPassword = "";
              ignoreShellProgramCheck = true;
              shell = pkgs.lib.getExe record_session;
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
                        command = "${pkgs.lib.getExe init-script}";
                        options = [ "NOPASSWD" ];
                      }
                      {
                        command = "${pkgs.lib.getExe su_record_session}";
                        options = [ "NOPASSWD" ];
                      }
                      {
                        command = "${pkgs.lib.getExe wipe_everything}";
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
            isoBaseName = "orca-${config.orca.environment-target}";
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

