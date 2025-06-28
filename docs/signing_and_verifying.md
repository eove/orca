# Signing and verifying a document

## Protocole de vérification

> [!Tip]  
> L'authenticité du contenu de ce document IN65 (au format HTML), doit être vérifié à l'aide de signature cryptographiques avant d'entamer son déroulement.
> * Retrouver les identités publiques gpg des signataires (éditeur et vérificateur). Pour cela, se placer au commit signalé dans l'entête :
> `git checkout @ORCA@commit@`
> * À ce commit, les clés publiques se trouvent dans le répertoire [`src/workflow_signatory_keys/`](@ORCA@gitremote@/tree/main/src/workflow_signatory_keys).
> * Vérifier que ces clés ont bien été insérées par un **commit signé par leur propriétaire**.
> * Utiliser un nouveau trousseau gpg vide (toutes les commandes ci-dessous seront ensuite exécutées avec la variable d'environnement) :  
> `export TMP_GPG_HOME=$(mktemp -d)`
> * Importer toutes les clés publiques dans ce nouveau trousseau :  
> `gpg --home="$TMP_GPG_HOME" --import /path/to/src/workflow_signatory_keys/*`
> * Marquer toutes les clés comme de confiance ultime :  
> `gpg --home="$TMP_GPG_HOME" --list-keys --keyid-format LONG --with-colons | sed -n -e '/^pub/{n;p}' | sed -n -E 's/^fpr:([^:]*:){8}([^:]*).*$/\2:6:/p' | gpg --home="$TMP_GPG_HOME"  --import-ownertrust`
> * Extraire les signatures de la fin du document html :  
> `sed -e '1,/^<!-- @GPG@SIGNATURES@ --><pre>$/ d' /chemin/vers/IN65_signed.html > /tmp/IN65.sig`
> * Extraire la vestion html d'origine du document (sans signatures) :  
> `sed -e '/^<!-- @GPG@SIGNATURES@ --><pre>$/q' /chemin/vers/IN65_signed.html > /tmp/IN65_without_signatures.html`
> * Vérifier toutes les signatures :  
> `gpg --home="$TMP_GPG_HOME" --verify /tmp/IN65.sig /tmp/IN65_without_signatures.html && echo "All signatures verified"`
> * La validité des signatures est confirmée par l'affichage de la ligne `Good signature from xxxx` **autant de fois que de signataires du document** et qu'une dernière ligne `All signatures verified` s'affiche.

