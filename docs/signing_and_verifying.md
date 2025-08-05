# Signing and verifying a text-based document

This method works for text-based documents like markdown or HTML.

## Verifying
> [!Tip]  
> The authenticity of the content of the document, must be verify via cryptographic signatures before executing it.
> * Find the public keys of the signatories. To do that, go to the commit found in the header of the document :
> `git checkout @ORCA@commit@`
> * There, you can find the keys in [`src/workflow_signatory_keys/`](@ORCA@gitremote@/tree/main/src/workflow_signatory_keys).
> * Verify that these keys were added via **a valid signed commit by their owner**.
> * Use a new gpg keystore (all of the following commands will be executed with this environment variable) :
> `export TMP_GPG_HOME=$(mktemp -d)`
> * Import all the public keys :
> `gpg --home="$TMP_GPG_HOME" --import /path/to/src/workflow_signatory_keys/*`
> * Mark all keys as ultimatly trusted :
> `gpg --home="$TMP_GPG_HOME" --list-keys --keyid-format LONG --with-colons | sed -n -e '/^pub/{n;p}' | sed -n -E 's/^fpr:([^:]*:){8}([^:]*).*$/\2:6:/p' | gpg --home="$TMP_GPG_HOME"  --import-ownertrust`
> * Extract the signature at the end of the document :
> `sed -e '1,/^<!-- @GPG@SIGNATURES@ --><pre>$/ d' /chemin/vers/document_signed > /tmp/document.sig`
> * Extract the document without the signatures :
> `sed -e '/^<!-- @GPG@SIGNATURES@ --><pre>$/q' /chemin/vers/document_signed > /tmp/document_without_signatures`
> * Verify all signatures :  
> `gpg --home="$TMP_GPG_HOME" --verify /tmp/document.sig /tmp/document_without_signatures && echo "All signatures verified"`
> * The validity of the signatures will be confirmed with `Good signature from xxxx` **for each signatory** and a last line `All signatures verified` must be prompted.

