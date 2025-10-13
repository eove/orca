{config, all_scripts, ...}:
let
  env = config.orca.environment-target;
  shares_folder = "${config.services.vault.storagePath}/orca/shares/${env}";
in ''
pkill gpg-agent || true
echo "Next share holder, please plug your hardware token and press enter" >&2
read -s
    ${ if env == "dev" then ''
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
  for share_file in ${shares_folder}/*
  do
    if cat "$share_file" | base64 -d | gpg --pinentry-mode cancel --no-default-keyring --keyid-format=0xlong --list-packets 2>&1 | grep "ID 0x$ID" > /dev/null
    then
      echo "When asked for a passphrase, please enter the PIN of your hardware token" >&2
      SHARE=$(cat "$share_file" | base64 -d | gpg -d --pinentry-mode loopback  2> /dev/null)

      if [ "$?" -eq 0 ] 
      then
          echo "Found a share unlocked by this hardware token" >&2
          echo "$SHARE"
          exit 0
      fi
    fi
  done
fi
echo "This hardware token could not unlock any share" >&2
''
