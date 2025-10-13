{ config, lib, pkgs, all_scripts, ... }@args:
let
  filterAttr = f: attrs:
    let
      names = with builtins; (filter (key: f key (getAttr key attrs)) (attrNames attrs));
    in
    with builtins;
    foldl' (set: name: set // { "${name}" = getAttr name attrs; }) { } names;
  all-files = dir: with builtins; attrNames (filterAttr (f: t: t == "regular" && f != "default.nix") (readDir dir));
  nix-files = d: builtins.filter (f: lib.strings.hasSuffix ".nix" f) (all-files d);
  shell-files = d: builtins.filter (f: lib.strings.hasSuffix ".sh" f) (all-files d);
  basename = f: with lib.strings; removeSuffix ("." + (lib.lists.last (splitString "." f))) f;
  packageScripts = dir: lib.foldAttrs (l: acc: lib.concatStrings [ l acc ]) "" [
    (builtins.foldl'
      (scripts: nix-file: scripts //
        { "${basename nix-file}" = import "${dir}/${nix-file}" args; }
      )
      { }
      (nix-files dir))

    (builtins.foldl'
      (scripts: shell-file: scripts //
        { "${basename shell-file}" = builtins.readFile "${dir}/${shell-file}"; }
      )
      { }
      (shell-files dir))
  ];
  wrapSudoerScript = scripts: builtins.mapAttrs (acc: script: ''sudo ${pkgs.lib.getExe script}'') scripts;

  packageAuthenticatedScripts = dir: builtins.mapAttrs (n: v: vaultTokenHeader + v) (packageScripts dir);

  count_tokens = lib.getExe all_scripts.orca_scripts.orca_user.count-tokens;
  get_root_token = lib.getExe all_scripts.orca_scripts.orca_user.get_root_token;
  vaultTokenHeader = ''
    export VAULT_TOKEN=$(${get_root_token})
    function revoke() {
      echo "Revoking root token..." >&2
      vault token revoke $VAULT_TOKEN
    }
    trap revoke INT QUIT TERM EXIT ABRT
  '';
in
{
  custom_scripts = builtins.mapAttrs pkgs.writeShellScriptBin (packageAuthenticatedScripts ./authenticated);
  orca_scripts = rec {
    sudoer = builtins.mapAttrs pkgs.writeShellScriptBin (packageScripts ./orca-protocol/sudoer);
    root_only = builtins.mapAttrs pkgs.writeShellScriptBin (packageScripts ./orca-protocol/root_only);
    orca_user = builtins.mapAttrs pkgs.writeShellScriptBin (
      (packageScripts ./orca-protocol/orca_user) //
      (wrapSudoerScript sudoer)
    );
  };
}
