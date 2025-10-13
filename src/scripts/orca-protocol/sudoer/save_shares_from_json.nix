
{ config, ...}:
let
  inherit (config.environment.variables) SHARES_FOLDER;
in ''
set -e
KEYS=$(cat -)
NB_SHARES=$(echo "$KEYS" | jq -r "length")
for i in $(seq 0 $(($NB_SHARES - 1)));
do
    echo "$KEYS" | jq -r ".[$i]" > ${SHARES_FOLDER}/share-$i.base64 
done
''
