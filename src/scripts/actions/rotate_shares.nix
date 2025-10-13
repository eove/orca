{ config, all_scripts, pkgs,... }:
let
  rotate = all_scripts.orca_scripts.orca_user.rotate-seal-shares;
in ''
 ${pkgs.lib.getExe rotate}
''
