set -e
seal
cd $VAULT_STORAGE_PATH
sudo mv audit.log audit_$(date +%F_%T).log

VAULT_BACKUP=/tmp/ORCA_backup.tar
sudo tar --numeric-owner -c -f $VAULT_BACKUP .

TMP_DIR="$(mktemp -d)"
cd "$TMP_DIR"
sudo tar --same-owner -xf "$VAULT_BACKUP" -C .

sudo mv $VAULT_BACKUP $ORCA_FOLDER

C_VAULT=$(sudo find . -type f -exec sha256sum -b {} \; | sort -k2 | sha256sum - | cut -d " " -f 1)
echo "Cvault: $C_VAULT" | qrencode -t utf8 -i
echo "Cvault: $C_VAULT"

