while [ $(vault status -format=json | jq -r '.sealed') == "true" ]
do
    STATUS=$(vault status -format=json || true)
    echo "Vault unseal status : $(echo $STATUS | jq -r '.progress') / $(echo $STATUS | jq -r '.t')" >&2
    SHARE=$(get_share)
    if [ -n "$SHARE" ]
    then
        vault operator unseal $SHARE > /dev/null
    fi
done
echo "Vault is unsealed" >&2
