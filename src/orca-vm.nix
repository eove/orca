{ nixpkgs, self, system, pkgs, ORCA_DISK_NAME, ... }:
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
(nixpkgs.lib.nixosSystem
  {
    inherit system;
    modules = [
      ({ config, ... }: {
        orca = {
          environment-target = "dev";
          has_dev_hack = true;
          latest_cvault = null;
          rotate_keys = false;
          actions_in_order = [
            #"create-root-CA"
            #"create-intermediate-CA"
            #"sign-csr"
            #"revoke-certificate"
          ];
        };
        environment.systemPackages = [
          pkgs.vim
        ] ++ (builtins.attrValues dev-scripts);
        services.openssh = {
          enable = pkgs.lib.mkForce true;
          settings.PermitRootLogin = "yes";
        };
        users.users.root = {
          openssh.authorizedKeys.keyFiles = [ ../testing/root_key.pub ];
        };
        networking = {
          useDHCP = pkgs.lib.mkForce true;
        };
        imports = [
          # We need to import that to make it work.
          "${nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
        ];
        virtualisation = {
          fileSystems = {
            "${config.services.vault.storagePath}" = {
              device = "/dev/disk/by-label/${ORCA_DISK_NAME}";
              fsType = "ext4";
            };
          };
          diskImage = null;
          forwardPorts = [{ host.port = 2222; guest.port = 22; }];
          qemu = {
            options = [
              "-bios ${pkgs.OVMF.fd}/FV/OVMF.fd"
            ];
            drives = [
              {
                file = ''''${VAULT_WRITABLE_DISK}'';
                driveExtraOpts = { format = "raw"; };
              }
            ];
          };
        };
      })
      self.nixosModules.core
    ];
  }).config.system.build.vm
