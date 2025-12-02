{
  description = "O.R.CA";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    orca = {
      url = "github:eove/orca";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { flake-utils, orca, ... }@inputs:
    (flake-utils.lib.eachDefaultSystem (system:
      let
        orca-config = import ./orca-config.nix;
      in
      {
        packages = {
          default = orca.lib."${system}".create-iso orca-config;
        };
        apps = {
          default = orca.lib."${system}".create-stick orca-config;
          in-vm = orca.lib."${system}".run-in-vm (orca-config // import ./testing/vm-config.nix);
        };
        devShells.default = orca.devShells."${system}".default;
      }
    ));
}
