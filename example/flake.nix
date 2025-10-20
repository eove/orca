{
  description = "O.R.CA";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    orca = {
      url = "github:FaustXVI/orca/create-template"; # TODO replace with "github:eove/orca/v1.0" once taged
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { flake-utils, orca, ... }@inputs:
    (flake-utils.lib.eachDefaultSystem (system:
      {
        apps = {
          default = orca.lib.x86_64-linux.create-stick (import ./orca-config.nix);
        };
      }
    ));
}
