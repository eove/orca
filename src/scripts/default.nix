{ config, lib, pkgs, ... }@args:
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
      mkdir -p $SHARES_FOLDER
      export AIA_FOLDER="$ORCA_FOLDER/aia/$ENVIRONMENT_TARGET"
      mkdir -p $AIA_FOLDER
      export CERTIFICATE_FOLDER="$ORCA_FOLDER/certificates/$ENVIRONMENT_TARGET"
      mkdir -p $CERTIFICATE_FOLDER
      chown -R ${config.users.users.orca.name} $ORCA_FOLDER

      function revoke() {
        echo "Revoking root token..." >&2
        if [ -n "$VAULT_TOKEN" ]
        then
          vault token revoke $VAULT_TOKEN
        fi
      }

      function get_share() {
          pkill gpg-agent || true
          echo "Next share holder, please plug your hardware token and press enter" >&2
          read -s
              ${ if config.orca.environment-target == "dev" then ''
          ID=$(gpg --list-keys --keyid-format 0xlong | grep "cv25519/" | sed -E -e 's|.*cv25519/0x([^ ]+).*|\1|')
              '' else ''
          while ! gpg --card-status &> /dev/null
          do
            pkill gpg-agent || true
            sleep 1
          done
          ID=$(gpg --card-status --keyid-format 0xlong | grep "cv25519/" | sed -E -e 's|.*cv25519/0x([^ ]+).*|\1|')
            ''}

          if [ -n "$ID" ]
          then
            for share_file in $SHARES_FOLDER/*
            do
              if cat "$share_file" | base64 -d | gpg --pinentry-mode cancel --no-default-keyring --keyid-format=0xlong --list-packets 2>&1 | grep "ID 0x$ID" > /dev/null
              then
                echo "When asked for a passphrase, please enter the PIN of your hardware token" >&2
                SHARE=$(cat "$share_file" | base64 -d | gpg -d --pinentry-mode loopback  2> /dev/null)

                if [ "$?" -eq 0 ] 
                then
                    echo "Found a share unlocked by this hardware token" >&2
                    echo "$SHARE"
                    return 0
                fi
              fi
            done
          fi
          echo "This hardware token could not unlock any share" >&2
      }
    '';
  vaultTokenHeader = ''
    if [ "$(count-tokens 2> /dev/null)" != "0" ]
    then
      echo "Warning: there are $(count-tokens) non-revoked tokens" >&2
    fi

    function get_root_token() {
      INIT_JSON=$(vault operator generate-root -init -format=json)
      OTP=$(echo $INIT_JSON | jq -r '.otp')
      NONCE=$(echo $INIT_JSON | jq -r '.nonce')
      while [ $(vault operator generate-root -status -format=json | jq -r '.started') == "true" ]
      do
       STATUS=$(vault operator generate-root -status -format=json)
       echo "Root token generation status: $(echo $STATUS | jq -r '.progress') / $(echo $STATUS | jq -r '.required')" >&2
       SHARE=$(get_share)
       if [ -n "$SHARE" ]
       then
         GENERATE_JSON=$(vault operator generate-root -format=json -nonce="$NONCE" "$SHARE")
         if [ "$(echo $GENERATE_JSON | jq -r '.complete')" == "true" ]
         then
             echo $GENERATE_JSON | jq -r '.encoded_root_token' | vault operator generate-root -otp="$OTP" -decode -
         fi
       fi
      done
    }
    export VAULT_TOKEN=$(get_root_token)
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
    orca_user = builtins.mapAttrs createScript (
      (packageScripts ./orca-protocol/orca_user) //
      (wrapSudoerScript sudoer)
    );
  };
}
