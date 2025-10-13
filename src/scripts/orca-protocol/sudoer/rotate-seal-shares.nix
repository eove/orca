{ config, lib, all_scripts, ... }:
let
  get_share = lib.getExe all_scripts.orca_scripts.root_only.get_share;
  save_shares_from_json = lib.getExe all_scripts.orca_scripts.orca_user.save_shares_from_json;
  inherit (config.environment.variables) SHARES_FOLDER PUBLIC_KEYS_FOLDER;
in
''
  set -e
  set -o pipefail

  THRESHOLD=3

  PUBLIC_KEYS_FILES=$(find ${PUBLIC_KEYS_FOLDER} -type f | grep -v '\.gitignore')
  PUBLIC_KEYS=$(echo -e $PUBLIC_KEYS_FILES | tr ' ' ',')
  NB_SHARES=$(ls "${PUBLIC_KEYS_FOLDER}" | wc -l)

  if [ x"$(vault status -format json | jq -r '.sealed')" != x"false" ]; then
      echo "Error: cannot work on vault while it is sealed" >&2
      exit -4
  fi

  INIT_JSON=$(vault operator rekey -init -key-shares $NB_SHARES -key-threshold $THRESHOLD -pgp-keys "$PUBLIC_KEYS" -backup -verify --format=json)
  NONCE=$(echo $INIT_JSON | jq -r '.nonce')

  while [ $(vault operator rekey -status -format=json | jq -r '.started') == "true" ] && [ -z $(vault operator rekey -status -format=json | jq -r '.verification_nonce') ]
  do
      STATUS=$(vault operator rekey -status -format=json)
      echo "Root rekey status: $(echo $STATUS | jq -r '.progress') / $(echo $STATUS | jq -r '.required')" >&2
      SHARE=$(${get_share})
      if [ -n "$SHARE" ]
      then
          REKEY_JSON=$(vault operator rekey -format=json $VERIFY -nonce="$NONCE" "$SHARE")
          if [ $(echo $REKEY_JSON | jq -r '.complete') == "true" ]
          then
              VERIFY_NONCE=$(echo "$REKEY_JSON" | jq -r ".verification_nonce")
              rm -rf ${SHARES_FOLDER}
              mkdir -p ${SHARES_FOLDER}
              echo $REKEY_JSON | jq -r ".keys_base64" | ${save_shares_from_json}
          fi
      fi
  done

  echo "Rekeying done, we are going to validate $NB_SHARES keys." >&2

  while [ $(vault operator rekey -status -format=json | jq -r '.started') == "true" ]
  do
      STATUS=$(vault operator rekey -verify -status -format=json)
      echo "Root rekey verification status: $(echo $STATUS | jq -r '.progress') / $(echo $STATUS | jq -r '.t')" >&2
      SHARE=$(${get_share})
      if [ -n "$SHARE" ]
      then
          REKEY_JSON=$(vault operator rekey -format=json -verify -nonce="$VERIFY_NONCE" "$SHARE")
      fi
  done

  echo "Rotation done"
''
