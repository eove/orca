{
  description = "O.R.CA image configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
      {
        packages = {
          iso-offline = import ./. (inputs // { inherit system pkgs; });
        };
        apps = {
          create-usb-vault = import ./create-usb.nix { inherit pkgs; isoImage = self.packages.${system}.iso-offline; };
          default =
            let
              testScript = pkgs.writeShellScriptBin "test-iso" ''
                DISK_NAME="orca-testing-disk.raw"

                if [ ! -f "$DISK_NAME" ]; then
                  echo "Creating a new disk at $DISK_NAME"
                  ${pkgs.qemu}/bin/qemu-img create -f raw "$DISK_NAME" 500M
                  mkfs.ext4 -L "VAULT_WRITABLE" -F "$DISK_NAME"
                else
                  echo "Using existing $DISK_NAME"
                fi

                ${pkgs.qemu}/bin/qemu-system-x86_64 -bios ${pkgs.OVMF.fd}/FV/OVMF.fd -enable-kvm -m 4G -cdrom ${self.packages.${system}.iso-offline}/iso/*.iso -drive format=raw,file="$DISK_NAME" -net nic -net user,hostfwd=tcp::2222-:22 "$@"
              '';
            in
            {
              type = "app";
              program = "${pkgs.lib.getExe testScript}";
            };
        };
      }));
}
