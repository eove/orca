# IN65 Cérémonie d'ouverture de la PKI Offline d'entreprise










Révision @ORCA@rev@

| Edité par                             | Vérifié par                           | Approuvé par                    |
| ------------------------------------- | ------------------------------------- | ------------------------------- |
| L. Ains                               | X. Detant                             |                                 |
| Date 28/05/2025                       | Date 28/05/2025                       |                                 |
| Signature digitale en fin de document | Signature digitale en fin de document | Visa                            |

Document généré depuis les sources du dépôt [@ORCA@gitremote@](@ORCA@gitremote@) au commit :  
`@ORCA@commit@`

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

## Introduction

Ce document décrit le déroulement de la cérémonie d'ouverture de la PKI Offline d'Eove (chaîne de confiance basée sur des certificats digitaux).
Cette ouverture de la PKI constitue l'étape préliminaire à toute opération de manipulation de la partie offline de la chaîne de confiance.

## Historique des révisions

| Révision |    Date    |   Auteur       | Description |
| -------- | :--------: | :------------: | ----------: |
| A        | 12/05/2025 | Lionel Ains    | Création    |

{{#include ../common/glossary.md}}

### Objectif

Le protocole détaillé ci-dessous indique les étapes à suivre pour exploiter les CAs offlines.

L'événement consistant à exécuter ce protocole est appelé *cérémonie* dans ce document.

Les rapports seront archivés dans le drive Eove_RnD, dans le répertoire PKI. Ces rapports sont protégés contre la modification par des signatures cryptographiques.

Les rapports de la cérémonie de vérification de la PKI sont un enregistrement au format markdown signé (en ligne), avec date, par exemple :  
*IN65-ceremonie-d-ouverture-de-la-pki-offline-preprod-d-entreprise-2025-03-17.signed.txt*

Les commandes fournies sont applicables sous Linux en bash.

Le reste de ce document est rédigé en anglais.

Les sections suivantes donnent une vue d'ensemble de la PKI, le lecteur averti pourra donc directement passer aux chapitres :
* [Planning a ceremony](#planning-a-ceremony) pour préparer une future cérémonie de vérification
* [Executing the ceremony](#executing-the-ceremony) pour la liste des actions, étape par étape, à dérouler le jour de la cérémonie
* [Closing down the ceremony](#closing-down-the-ceremony) pour la liste des actions pour clôturer une cérémonie

{{#include ../../workflow/offline_vault_ceremony.md}}
