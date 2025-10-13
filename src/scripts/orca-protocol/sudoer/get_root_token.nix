{config, all_scripts, lib, ...}:
let
  count_tokens = lib.getExe all_scripts.orca_scripts.orca_user.count-tokens;
  get_share = lib.getExe all_scripts.orca_scripts.root_only.get_share;
in ''
set -e
if [ "$(${count_tokens} 2> /dev/null)" != "0" ]
then
  echo "Warning: there are $(${count_tokens}) non-revoked tokens" >&2
fi

INIT_JSON=$(vault operator generate-root -init -format=json)
OTP=$(echo $INIT_JSON | jq -r '.otp')
NONCE=$(echo $INIT_JSON | jq -r '.nonce')
while [ $(vault operator generate-root -status -format=json | jq -r '.started') == "true" ]
do
 STATUS=$(vault operator generate-root -status -format=json)
 echo "Root token generation status: $(echo $STATUS | jq -r '.progress') / $(echo $STATUS | jq -r '.required')" >&2
 SHARE=$(${get_share})
 if [ -n "$SHARE" ]
 then
   GENERATE_JSON=$(vault operator generate-root -format=json -nonce="$NONCE" "$SHARE")
   if [ "$(echo $GENERATE_JSON | jq -r '.complete')" == "true" ]
   then
       echo $GENERATE_JSON | jq -r '.encoded_root_token' | vault operator generate-root -otp="$OTP" -decode -
   fi
 fi
done
''
