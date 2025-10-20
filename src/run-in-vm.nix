{ nixpkgs, self, system, pkgs, ORCA_DISK_NAME, orca_config, ... }:

let
  vm-system = (nixpkgs.lib.nixosSystem
    {
      inherit system;
      modules = [
        ({ config, ... }: {
          orca = orca_config;
        })
        ({ config, ... }:
          let
            dev-scripts = builtins.mapAttrs pkgs.writeShellScriptBin {
              plug-simulated-yubikey = ''
                                if test $# -ne 1; then
                                  echo "This script requires the number of the yubikey to insert as argument" >&2
                                  exit 1
                                fi
                                if ! test -e ${config.orca.vm.simulated_yubikeys_folder}/yubikey''${1}/.gnupg; then
                                  echo "Invalid yubikey number" >&2
                                  exit 1
                                fi
                                rm -rf ~/.gnupg 2> /dev/null
                                cp -r ${config.orca.vm.simulated_yubikeys_folder}/yubikey''${1}/.gnupg/ ~
                                chmod +w,og-rwx -R ~/.gnupg
              '';
            };
          in
          {
            options = with pkgs.lib; {
              orca = {
                vm = {
                  root_public_key = mkOption {
                    type = types.path;
                  };
                  simulated_yubikeys_folder = mkOption {
                    type = types.path;
                  };
                };
              };
            };
            imports = [
              # We need to import that to make it work.
              "${nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
            ];
            config = {
                assertions = [
                {
                  assertion = config.orca.environment-target == "dev";
                  message = "O.R.CA vm can only be started in dev environment";
                }
              ];
              environment.systemPackages = [
                pkgs.vim
              ] ++ (builtins.attrValues dev-scripts);
              services.openssh = {
                enable = pkgs.lib.mkForce true;
                settings.PermitRootLogin = "yes";
              };
              users.users.root = {
                openssh.authorizedKeys.keyFiles = [ config.orca.vm.root_public_key ];
              };
              networking = {
                useDHCP = pkgs.lib.mkForce true;
              };
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
            };
          })
        self.nixosModules.core
      ];
    }).config.system.build.vm;
  vmScript = pkgs.writeShellScriptBin "vmScript" ''
    export VAULT_WRITABLE_DISK="$(pwd)/orca-testing-disk.raw"
    if [ ! -f "$VAULT_WRITABLE_DISK" ]; then
      echo "Creating a new disk at $VAULT_WRITABLE_DISK"
      ${pkgs.qemu}/bin/qemu-img create -f raw "$VAULT_WRITABLE_DISK" 500M
      mkfs.ext4 -L "${ORCA_DISK_NAME}" -F "$VAULT_WRITABLE_DISK"
    else
      echo "Using existing $VAULT_WRITABLE_DISK"
    fi
    ${pkgs.lib.getExe vm-system}
  '';
in
{
  type = "app";
  program = "${pkgs.lib.getExe vmScript}";
}
