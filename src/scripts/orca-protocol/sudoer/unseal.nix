{ lib, all_scripts, ... }:
let
  count_tokens = lib.getExe all_scripts.orca_scripts.orca_user.count-tokens;
  get_share = lib.getExe all_scripts.orca_scripts.root_only.get_share;
in
''
  set -e

  if [ "$(${count_tokens} 2> /dev/null)" != "0" ]
  then
    echo "Warning: there are $(${count_tokens}) non-revoked tokens" >&2
  fi

  ALL_SHARES=()
  echo "Unsealing the vault !" >&2
  while [ $(vault status -format=json | jq -r '.sealed') == "true" ]
  do
      STATUS=$(vault status -format=json || true)
      echo "Vault unseal status : $(echo $STATUS | jq -r '.progress') / $(echo $STATUS | jq -r '.t')" >&2
      SHARE=$(${get_share})
      if [ -n "$SHARE" ]
      then
          ALL_SHARES+=($SHARE)
          vault operator unseal $SHARE > /dev/null
      fi
  done
  echo "Vault is unsealed" >&2

  INIT_JSON=$(vault operator generate-root -init -format=json)
  OTP=$(echo $INIT_JSON | jq -r '.otp')
  NONCE=$(echo $INIT_JSON | jq -r '.nonce')
   for SHARE in ''${ALL_SHARES[@]}; do
     GENERATE_JSON=$(vault operator generate-root -format=json -nonce="$NONCE" "$SHARE")
     if [ "$(echo $GENERATE_JSON | jq -r '.complete')" == "true" ]
     then
         echo $GENERATE_JSON | jq -r '.encoded_root_token' | vault operator generate-root -otp="$OTP" -decode -
     fi
   done
''
