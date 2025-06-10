In order to make sure that the root token will only be known by the 💻`operator`, the token will be encrypted using the operator's public GPG key.

On the 💻`operator`'s machine, run the following script:
```bash
./scripts/maintenance/regenerate_offline_root_token.sh /path/to/operator_public_key.gpg
```

Ask enough share holders to make the root token generation progress by running the following command on each machine:
```bash
vault operator generate-root
```

> [!Tip]  
> Ideally, the 💻`operator` will enter the share last, to directly get the encrypted token.

When the last share has been entered, a field `Encoded Token` will be returned, it is a base64 string and must be sent to the 💻`operator`, that is the only one to be able to decode it.
Let's stay the 💻`operator` stores this base64 string in the following variable:
```bash
export ENCODED_ROOT_TOKEN=xxxxx
```

The 💻`operator` now records the decoded token in the environnement variable `VAULT_TOKEN` by running:
```bash
export VAULT_TOKEN=$(echo "$ENCODED_ROOT_TOKEN" | base64 -d | gpg -d)
```

> [!Warning]  
> This token should never be displayed in clear text on the screen. Just keep it safe in your environment variable.
