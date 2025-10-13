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

  scriptHeader =
    ''
      set -e
      export ENVIRONMENT_TARGET=${config.orca.environment-target}
      export VAULT_STORAGE_PATH=${config.services.vault.storagePath}
      export ORCA_FOLDER="$VAULT_STORAGE_PATH/orca"
      export PUBLIC_KEYS_FOLDER="${../share_holders_keys/${config.orca.environment-target}}"
      export SHARES_FOLDER="$ORCA_FOLDER/shares/$ENVIRONMENT_TARGET"
      export AIA_FOLDER="$ORCA_FOLDER/aia/$ENVIRONMENT_TARGET"
      export CERTIFICATE_FOLDER="$ORCA_FOLDER/certificates/$ENVIRONMENT_TARGET"
    '';
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
  createScript = (n: v: pkgs.writeShellScriptBin n (scriptHeader + v));
in
{
  custom_scripts = builtins.mapAttrs createScript (
    (packageScripts ./unauthenticated) //
    (packageAuthenticatedScripts ./authenticated)
  );
  orca_scripts = rec {
    sudoer = builtins.mapAttrs pkgs.writeShellScriptBin (packageScripts ./orca-protocol/sudoer);
    root_only = builtins.mapAttrs pkgs.writeShellScriptBin (packageScripts ./orca-protocol/root_only);
    orca_user = builtins.mapAttrs createScript (
      (packageScripts ./orca-protocol/orca_user) //
      (wrapSudoerScript sudoer)
    );
  };
}
