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
            sudo rm -rf ~/.gnupg 2> /dev/null
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
        users.users.orca = {
          initialPassword = pkgs.lib.mkForce "orca";
          initialHashedPassword = pkgs.lib.mkForce null;
        };
        networking= {
          useDHCP = pkgs.lib.mkForce true;
        };
      }
    ))
    # orca vault setup
    # This should probably only evolve when the orca setup evolves as well
    ({ config, ... }@args:
      let
        scripts = builtins.mapAttrs pkgs.writeShellScriptBin (import ./scripts (args // {inherit (pkgs) lib;}));
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
          environment={
            systemPackages = [
            pkgs.vault
            pkgs.jq
            pkgs.gnupg
            pkgs.coreutils
            pkgs.qrencode
          ]
          ++ (builtins.attrValues scripts);
        };
          system.stateVersion = pkgs.lib.trivial.release;
          users = {
            # Use less privileged orca user
            users.orca = {
              isNormalUser = true;
              extraGroups = [ "wheel" ];
              initialHashedPassword = "";
            };
            # Allow the user to log in as root without a password.
            users.root.initialHashedPassword = "";
          };


          security = {
            # Don't require sudo/root to `reboot` or `poweroff`.
            polkit.enable = true;
            # Allow passwordless sudo from orca user
            sudo = {
              enable = true;
              wheelNeedsPassword = false;
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
            if ! sudo test -w ${config.services.vault.storagePath}
            then
              cat << EOF
              You successfully booted O.R.CA for the ${config.orca.environment-target} environment in read-only mode.
              Since nothing can be done, you won't have access to a shell.
              When you'll want have access to a shell, please boot in read/write mode.
              Press enter to poweroff the computer.
EOF
              read -s
              poweroff
            fi
            RECORD_DIR=${config.services.vault.storagePath}/orca/recordings
            gpg --import ${./share_holders_keys/${config.orca.environment-target}}/* &> /dev/null

            sudo cp /var/lib/acme/.minica/cert.pem ~/cert.pem
            sudo chown orca ~/cert.pem

            export VAULT_ADDR="https://localhost:8200"
            export VAULT_CACERT=~/cert.pem

            sudo mkdir -p $RECORD_DIR
            sudo chown -R orca ${config.services.vault.storagePath}/orca
            if [ ! -e /tmp/cvault-displayed ]
            then
              cd ${config.services.vault.storagePath}
              echo "Cvault:"
              sudo find . -type f -exec sha256sum -b {} \; | sort -k2 | sha256sum -
              cd

              echo "Count tokens : "
              count-tokens 2> /dev/null

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
          networking= {
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

