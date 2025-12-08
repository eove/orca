{ nixpkgs, self, system, pkgs, ORCA_DISK_NAME, orca_config,  nixpkgsQemu, ... }:

let
  vm-system = (nixpkgsQemu.lib.nixosSystem
    {
      inherit system;
      modules = [
        ({ config, ... }: {
          orca = orca_config;
        })
        ({ config, ... }:
          {
            options = with pkgs.lib; {
              orca = {
                vm = {
                  root_public_key = mkOption {
                    type = types.path;
                  };
                };
              };
            };
            imports = [
              # We need to import that to make it work.
              "${nixpkgsQemu}/nixos/modules/virtualisation/qemu-vm.nix"
            ];
            config = {
                assertions = [
                {
                  assertion = config.orca.environment-target == "dev";
                  message = "O.R.CA vm can only be started in dev environment";
                }
              ];
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
                    "-bios" "${pkgs.OVMF.fd}/FV/OVMF.fd"
                    "-monitor" "unix:/tmp/orca-monitor-socket,server,nowait"
                    ''-drive if=none,id=usbstick,format=raw,file=''${VAULT_WRITABLE_DISK},read-only=on''
    "-device nec-usb-xhci,id=xhci"
    "-device usb-storage,bus=xhci.0,drive=usbstick,id=vault_writable,removable=on"
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
