#!/usr/bin/env bash
set -e
set -o pipefail

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
if ! type -t get_share 2>/dev/null; then
    echo "get_share() not found" >&2
    echo "It is usually inserted by nix at build when creating images, but you will also find this function definition in the O.R.CA repository" >&2
    exit -1
fi

THRESHOLD=3

PUBLIC_KEYS_FILES=$(find $PUBLIC_KEYS_FOLDER -type f | grep -v '\.gitignore')
PUBLIC_KEYS=$(echo -e $PUBLIC_KEYS_FILES | tr ' ' ',')
NB_SHARES=$(ls "$PUBLIC_KEYS_FOLDER" | wc -l)

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
    SHARE=$(get_share)
    if [ -n "$SHARE" ]
    then
        REKEY_JSON=$(vault operator rekey -format=json $VERIFY -nonce="$NONCE" "$SHARE")
        if [ $(echo $REKEY_JSON | jq -r '.complete') == "true" ]
        then
            VERIFY_NONCE=$(echo "$REKEY_JSON" | jq -r ".verification_nonce")
            mv $SHARES_FOLDER ${SHARES_FOLDER}.bak
            mkdir -p $SHARES_FOLDER
            for i in $(seq 0 $(($NB_SHARES - 1)));
            do
                echo "$REKEY_JSON" | jq -r ".keys_base64[$i]" > $SHARES_FOLDER/share-$i.base64 
            done
        fi
    fi
done

echo "Rekeying done, we are going to validate ${NB_SHARES} keys." >&2

while [ $(vault operator rekey -status -format=json | jq -r '.started') == "true" ]
do
    STATUS=$(vault operator rekey -verify -status -format=json)
    echo "Root rekey verification status: $(echo $STATUS | jq -r '.progress') / $(echo $STATUS | jq -r '.t')" >&2
    SHARE=$(get_share)
    if [ -n "$SHARE" ]
    then
        REKEY_JSON=$(vault operator rekey -format=json -verify -nonce="$VERIFY_NONCE" "$SHARE")
    fi
done

rm -rf ${SHARES_FOLDER}.bak
echo "Rotation done"
