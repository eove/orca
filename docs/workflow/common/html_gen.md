# How to generate an html-formatted OR.C.A workflow document

At first, before selecting the commit at which the OR.C.A document is signed, **please make sure both the author and verifier's hardware token's public GPG keys** are in this repo's directory `/src/signatory_keys`. These will be required when verifying the signatures in the future.

First, we need to select the document we want to generate:
* For IN65:
```bash
export ORCA_WF_AS_MD="book/markdown/workflow/offline_vault_ceremony.md"
export ORCA_WF_TITLE="ceremony_workflow"
```

* For IN69:
```bash
export ORCA_WF_AS_MD="book/markdown/workflow/periodical_checks.md"
export ORCA_WF_TITLE="periodical_checks"
```

Next, let's setup our environment:
```bash
cd /path/to/orca # Please adapt to the path where you cloned OR.C.A
git checkout <commit> # Replace with the commit or branch you want to use
export ORCA_WF_REV=<rev> # Set this variable correctly, eg: 'A' or '1.1'
```

And finally, let's generate the workflow document as a self-standing file for the subsequent signature process.
```bash
export GIT_REMOTE_URL=$(git remote -v | sed -n -E -e 's|^.*git@(.+):(.+)\.git.*|https://\1/\2|p' -e '1q')
export GIT_CURRENT_HASH=$(git log --pretty=format:'%H' -n 1)

unset SANITY_CHECKS_OK

if test -z $ORCA_WF_REV; then echo "ERROR: no ORCA_WF_REV set">&2; false; else\
 if test -z $ORCA_WF_TITLE; then echo "ERROR: no ORCA_WF_TITLE set">&2; false; else\
 if test -z $ORCA_WF_AS_MD; then echo "ERROR: no ORCA_WF_AS_MD set">&2; false; else\
 if test -z $GIT_CURRENT_HASH; then echo "ERROR: no GIT_CURRENT_HASH set">&2; false; else\
 if test -z $GIT_REMOTE_URL; then echo "ERROR: no GIT_REMOTE_URL set">&2; false; else\
  SANITY_CHECKS_OK=true; fi; fi; fi; fi; fi

unset TMP_OUTPUT_DIR;TMP_OUTPUT_DIR=$(mktemp -p ~ -d)

nix develop --command mdbook build
test -n $SANITY_CHECKS_OK &&\
 sed -e "s|\@ORCA\@commit\@|${GIT_CURRENT_HASH}|g"\
     -e "s|\@ORCA\@gitremote\@|${GIT_REMOTE_URL}|g"\
     -e "s|\@ORCA\@rev\@|${ORCA_WF_REV}|g"\
   "$ORCA_WF_AS_MD" > "${TMP_OUTPUT_DIR}/${ORCA_WF_TITLE}_with_commit.md"

nix develop --command md-to-html "${TMP_OUTPUT_DIR}/${ORCA_WF_TITLE}_with_commit.md" "${ORCA_WF_TITLE} rev${ORCA_WF_REV}" |\
 sed -e '$a<hr>\n<!-- @GPG@SIGNATURES@ --><pre>' > "${TMP_OUTPUT_DIR}/${ORCA_WF_TITLE}.html" &&\
 rm "${TMP_OUTPUT_DIR}/${ORCA_WF_TITLE}_with_commit.md"

command mv "${TMP_OUTPUT_DIR}/${ORCA_WF_TITLE}.html" "/tmp/${ORCA_WF_TITLE}.html" &&\
 command ls "/tmp/${ORCA_WF_TITLE}.html" &&\
 rm -rf "${TMP_OUTPUT_DIR}" && unset TMP_OUTPUT_DIR
```

You can then sign the html document following your organisation's way of signing documents or via the gpg-based way you can find at the [signing and verifying annex](../../signing_and_verifying.md)
