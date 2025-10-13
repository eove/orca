{ all_scripts, pkgs, ...}:
''
if [ -z "$ENVIRONMENT_TARGET" ]; then
    echo "Expected environment variables : ENVIRONMENT_TARGET" >&2
    exit -1
fi
if [ -z "$PUBLIC_KEYS_FOLDER" ]; then
    echo "Expected environment variables : PUBLIC_KEYS_FOLDER" >&2
    exit -1
fi
if [ -z "$SHARES_FOLDER" ]; then
    echo "Expected environment variables : SHARES_FOLDER" >&2
    exit -1
fi

THRESHOLD=3

PUBLIC_KEYS_FILES=$(find $PUBLIC_KEYS_FOLDER -type f | grep -v '\.gitignore')
PUBLIC_KEYS=$(echo -e $PUBLIC_KEYS_FILES | tr ' ' ',')
NB_SHARES=$(ls -d "$PUBLIC_KEYS_FOLDER"/* | wc -l)

echo -n "Initializing vault..."
JSON="$(vault operator init -format "json" -key-shares $NB_SHARES -key-threshold $THRESHOLD -pgp-keys $PUBLIC_KEYS)"

for i in $(seq 0 $(($NB_SHARES - 1)));
do
    echo "$JSON" | jq -r ".unseal_keys_b64[$i]" > $SHARES_FOLDER/share-$i.base64 
done
echo " done"

export VAULT_TOKEN=$(echo "$JSON" | jq -r ".root_token")

function revoke() {
  echo "Revoking root token..." >&2
  vault token revoke $VAULT_TOKEN
}

trap revoke INT QUIT TERM EXIT ABRT

${pkgs.lib.getExe all_scripts.orca_scripts.orca_user.unseal}

vault audit enable file file_path=$VAULT_STORAGE_PATH/audit.log
''
