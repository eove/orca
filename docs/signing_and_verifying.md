# Signing and verifying a text-based document

This method works for text-based documents like markdown or HTML.
The last line of these document **must** be `@GPG@SIGNATURES@`.

## Signing 
In sequence, each of the signatory will run the following command and transfer the resulting signed file (which name is displayed on the console) to the next person:
```bash
export REPORT=/path/to/document
export GPG_HW_TOKEN_KEY_ID=$(gpg --card-status |\
 sed -n -E -e 's/^[^:]*sign[^:]*:[[:blank:]]*((:?[[:xdigit:]]{4}[[:blank:]]*){10})/\1/pi')
sed -e '/^@GPG@SIGNATURES@$/q' "$REPORT" |\
 gpg --armor --output - -u "$GPG_HW_TOKEN_KEY_ID" --detach-sign > "$REPORT.sig.asc" &&\
 cat "$REPORT" "$REPORT.sig.asc" > "$REPORT".signed &&\
 rm "$REPORT.sig.asc" &&\
 command ls "$REPORT".signed >&2
```
> [!Note]  
> In the shell snippet above, we catch the hardware token public key ID from the signing key ID in the token, and store this inside variable `GPG_HW_TOKEN_KEY_ID`.  
> You might also do it manually (for example using `gpg --card-status` or `gpg --list-keys --fingerprint`) if this sed oneliner doesn't do the job properly

## Verifying
The authenticity of the content of the document, must be verify via cryptographic signatures before executing it.
 * Find the public keys of the signatories. To do that, go to the commit found in the header of the document :
 `git checkout @ORCA@commit@`
 * There, you can find the keys in [`src/workflow_signatory_keys/`](@ORCA@gitremote@/tree/main/src/workflow_signatory_keys).
 * Verify that these keys were added via **a valid signed commit by their owner**.
 * Use a new gpg keystore (all of the following commands will be executed with this environment variable) :
 `export TMP_GPG_HOME=$(mktemp -d)`
 * Import all the public keys :
 `gpg --home="$TMP_GPG_HOME" --import /path/to/src/workflow_signatory_keys/*`
 * Mark all keys as ultimatly trusted :
 `gpg --home="$TMP_GPG_HOME" --list-keys --keyid-format LONG --with-colons | sed -n -e '/^pub/{n;p}' | sed -n -E 's/^fpr:([^:]*:){8}([^:]*).*$/\2:6:/p' | gpg --home="$TMP_GPG_HOME"  --import-ownertrust`
 * Extract the signature at the end of the document :
 `sed -e '1,/^@GPG@SIGNATURES@$/ d' /path/to/document_signed > /tmp/document.sig`
 * Extract the document without the signatures :
 `sed -e '/^@GPG@SIGNATURES@$/q' /path/to/document_signed > /tmp/document_without_signatures`
 * Verify all signatures :  
 `gpg --home="$TMP_GPG_HOME" --verify /tmp/document.sig /tmp/document_without_signatures && echo "All signatures verified"`
 * The validity of the signatures will be confirmed with `Good signature from xxxx` **for each signatory** and a last line `All signatures verified` must be prompted.

