{ self, system, nixpkgs, pkgs, ORCA_DISK_NAME, ... }:
(nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
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
    ({ config, pkgs, ... }: {
      imports = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"
      ];
      isoImage = {
        squashfsCompression = "gzip -Xcompression-level 1";
        volumeID = "${config.isoImage.isoBaseName}";
        isoBaseName = pkgs.lib.mkForce "orca-${config.orca.environment-target}";
        makeEfiBootable = true;
        makeUsbBootable = true;
        appendToMenuLabel = "";
        prependToMenuLabel = "O.R.CA ${config.orca.environment-target} ";
      };
      fileSystems = pkgs.lib.mkForce
        (config.lib.isoFileSystems // {
          "${config.services.vault.storagePath}" = {
            device = "/dev/disk/by-label/${ORCA_DISK_NAME}";
            fsType = "ext4";
          };
        });
    })
    self.nixosModules.core
  ];
}).config.system.build.isoImage.overrideAttrs (oldAttrs: {
  squashfsCommand = "SOURCE_DATE_EPOCH=0 " + (oldAttrs.squashfsCommand or "");
})

