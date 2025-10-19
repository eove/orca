{self, ...}@args:
rec {
  create-iso = orca_config: import ./orca-iso.nix (args // {inherit orca_config;});
  create-stick = orca_config: import ./create-usb.nix (args // {isoImage = create-iso orca_config;});
}
