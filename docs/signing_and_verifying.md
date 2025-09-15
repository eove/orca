# Signing and verifying a text-based document

This method works for text-based documents like markdown or HTML.
Even though the `--clear-sign` option of gpg could be used, it adds a bit of noise at the beginning of the document that makes HTML documents rendering very poor on a webbrowser.
This method is more manual but only adds noise **at the end** of the document, thus fixing the display of HTML documents.

The last line of the document to sign **must** be `@GPG@SIGNATURES@`.

## Signing 
In sequence, each of the signatory will run the following command and transfer the resulting signed file (which name is displayed on the console) to the next signatory.

> [!Note]  
> In the shell snippet below, we catch the hardware token public key ID from the signing key ID in the token, and store this inside variable `GPG_HW_TOKEN_KEY_ID`.  
> You might also do it manually (for example using `gpg --card-status` or `gpg --list-keys --fingerprint`) if this sed oneliner doesn't do the job properly.

```bash
export INPUT_TO_SIGN=/path/to/document # Adapt this to your path
export GPG_HW_TOKEN_KEY_ID=$(gpg --card-status |\
 sed -n -E -e 's/^[^:]*sign[^:]*:[[:blank:]]*((:?[[:xdigit:]]{4}[[:blank:]]*){10})/\1/pi')

sed -e '/^@GPG@SIGNATURES@$/q' "$INPUT_TO_SIGN" |\
 gpg --armor --output - -u "$GPG_HW_TOKEN_KEY_ID" --detach-sign > "$INPUT_TO_SIGN.sig.asc" &&\
 cat "$INPUT_TO_SIGN" "$INPUT_TO_SIGN.sig.asc" > "$INPUT_TO_SIGN".signed &&\
 rm "$INPUT_TO_SIGN.sig.asc" &&\
 command ls "$INPUT_TO_SIGN".signed >&2
```

## Verifying
The authenticity of the content of the document, must be verify via cryptographic signatures before executing it.
 * Find the public keys of the signatories. To do that, go to the commit found in the header of the document:
```bash
git checkout @ORCA@commit@
```
 * There, you can find the keys in [`src/workflow_signatory_keys/`](@ORCA@gitremote@/tree/main/src/workflow_signatory_keys).
 * Verify that these keys were added via **a valid signed commit by their owner**.
 * Use a new gpg keystore (all of the following commands will be executed with this environment variable):
```bash
export TMP_GPG_HOME=$(mktemp -d)
```
 * Import all the public keys and mark them as ultimatly trusted
```bash
gpg --home="$TMP_GPG_HOME" --import /path/to/src/workflow_signatory_keys/*
gpg --home="$TMP_GPG_HOME" --list-keys --keyid-format LONG --with-colons | sed -n -e '/^pub/{n;p}' | \
 sed -n -E 's/^fpr:([^:]*:){8}([^:]*).*$/\2:6:/p' | gpg --home="$TMP_GPG_HOME"  --import-ownertrust
```
 * Specify the filename of the document to verify:
```bash
export INPUT_TO_VERIFY=/path/to/document.signed # Adapt this to your path
```
 * Split the document in two parts (the signatures on one hand, and the document without signatures on the other hand):
```bash
sed -e '1,/^@GPG@SIGNATURES@$/ d' "$INPUT_TO_VERIFY" > /tmp/document.sig
sed -e '/^@GPG@SIGNATURES@$/q' "$INPUT_TO_VERIFY" > /tmp/document_without_signatures
```
 * Verify all signatures:
```bash
gpg --home="$TMP_GPG_HOME" --verify /tmp/document.sig /tmp/document_without_signatures && \
 echo "All signatures verified"
```
 * The validity of the signatures will be confirmed with `Good signature from xxxx` **for each signatory** and a last line `All signatures verified` must be prompted.
