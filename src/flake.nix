{
  description = "O.R.CA image configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    ({
      nixosModules = import ./orca-nixos-module.nix inputs;
    }) //
    (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        ORCA_DISK_NAME = "VAULT_WRITABLE";
      in
      {
        packages = {
          iso-offline = import ./orca-iso.nix (inputs // { inherit system pkgs ORCA_DISK_NAME; });
        };
        apps = {
          create-usb-vault = import ./create-usb.nix { inherit pkgs ORCA_DISK_NAME; isoImage = self.packages.${system}.iso-offline; };
          default =
            let
              vmScript = pkgs.writeShellScriptBin "vmScript" ''
                export VAULT_WRITABLE_DISK="$(pwd)/orca-testing-disk.raw"
                if [ ! -f "$VAULT_WRITABLE_DISK" ]; then
                  echo "Creating a new disk at $VAULT_WRITABLE_DISK"
                  ${pkgs.qemu}/bin/qemu-img create -f raw "$VAULT_WRITABLE_DISK" 500M
                  mkfs.ext4 -L "${ORCA_DISK_NAME}" -F "$VAULT_WRITABLE_DISK"
                else
                  echo "Using existing $VAULT_WRITABLE_DISK"
                fi
                ${pkgs.lib.getExe (import ./orca-vm.nix (inputs // { inherit system pkgs ORCA_DISK_NAME;}))}
              '';
            in
            {
              type = "app";
              program = "${pkgs.lib.getExe vmScript}";
            };
        };
      }));
}
