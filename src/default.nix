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
        dev-scripts = builtins.mapAttrs pkgs.writeShellScriptBin {
          plug-simulated-yubikey = ''
            rm -rf ~/.gnupg 2> /dev/null
            cp -r ${./simulated-yubikeys}/yubikey''${1}@eove.fr/.gnupg/ ~/
            chmod +w,og-rwx -R ~/.gnupg
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
        recordDir = ''${config.services.vault.storagePath}/orca/recordings'';
        orca_user = config.users.users.orca;
        scripts = builtins.attrValues (builtins.mapAttrs pkgs.writeShellScriptBin (import ./scripts (args // { inherit (pkgs) lib; inherit recordDir orca_user; })));
        init-script = pkgs.writeShellScriptBin "init-script" ''
RECORD_DIR=${recordDir}
cp /var/lib/acme/.minica/cert.pem ${orca_user.home}/cert.pem
chown ${orca_user.name} ${orca_user.home}/cert.pem
mkdir -p $RECORD_DIR
chown -R ${orca_user.name} ${config.services.vault.storagePath}/orca

echo "Cvault : "
find ${config.services.vault.storagePath} -type f -exec sha256sum -b {} \; | sort -k2 | sha256sum - | cut -d " " -f 1
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
          environment = {
            systemPackages = [
              pkgs.vault
              pkgs.jq
              pkgs.gnupg
              pkgs.coreutils
              pkgs.qrencode
            ]
            ++ scripts;
          };
          system.stateVersion = pkgs.lib.trivial.release;
          users = {
            # Use less privileged orca user
            users.orca = {
              isNormalUser = true;
              initialHashedPassword = "";
            };
            # Allow the user to log in as root without a password.
            users.root.initialHashedPassword = "";
          };


          security = {
            # Don't require sudo/root to `reboot` or `poweroff`.
            polkit.enable = true;
            # Allow passwordless sudo from orca user for the prepared and reviewed scripts
            sudo = let
              system_path = "/run/current-system/sw/bin";
            in {
              enable = true;
                extraConfig = with pkgs; ''
    Defaults secure_path="${system_path}"
  '';
              extraRules = [
                {
                  users = [ orca_user.name ];
                  commands = (builtins.map
                    (script: {
                      command = "${system_path}/${script}";
                      options = [ "NOPASSWD" ];
                    })
                    [ "seal" "count-tokens" "backup"]) ++ [
                      {
                      command = "${pkgs.lib.getExe init-script}";
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
            getty.autologinUser = "orca";
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

          # record everything that happens on the terminal
          programs.bash.loginShellInit = ''
            RECORD_DIR=${recordDir}
            gpg --import ${./share_holders_keys/${config.orca.environment-target}}/* &> /dev/null


            export VAULT_ADDR="https://localhost:8200"
            export VAULT_CACERT=~/cert.pem

            if [ ! -e /tmp/cvault-displayed ]
            then
              sudo ${pkgs.lib.getExe init-script}

              echo "Count tokens : "
              sudo count-tokens 2> /dev/null

              echo "Waiting for vault to be available..."
              sleep 2

              echo "Vault status :"
              vault status

              touch /tmp/cvault-displayed
            fi

            ${pkgs.lib.getExe pkgs.asciinema} rec -q -t "Ceremony for ${config.orca.environment-target} on $(date +'%F at %T') using $(tty)" -i 1 $RECORD_DIR/ceremony-${config.orca.environment-target}-$(date +"%F_%T")$(tty | tr '/' '-').cast
            exit
          '';

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

