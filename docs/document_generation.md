# How to generate an O.R.CA workflow document

At first, before selecting the commit at which the O.R.CA document is signed, **please make sure the prerequisites for the signing method you are going to use are fulfilled** (this might involve identifying signatories, publishing public keys etc.)

First, we need to select the document we want to generate:
* For the ceremony to use the Offline Root CA:
```bash
export ORCA_WF_AS_MD="book/markdown/offline_vault_ceremony.md"
export ORCA_WF_TITLE="ceremony_workflow"
```

* For the periodical checks of the PKI:
```bash
export ORCA_WF_AS_MD="book/markdown/periodical_checks.md"
export ORCA_WF_TITLE="periodical_checks"
```

Next, let's setup our environment:
```bash
cd /path/to/exploitation/repository # Please adapt to the path where your exploitation repository is
git checkout <commit> # Replace with the commit or branch you want to use
export ORCA_WF_REV=<rev> # Set this variable correctly, eg: 'A' or '1.1'
```

And finally, let's generate the workflow document as a self-standing file for the subsequent signature process.
```bash
export GIT_REMOTE_URL=$(git config --get remote.origin.url | sed -E -e 's|^.*git@(.+):(.+)|https://\1/\2|')
export GIT_CURRENT_HASH=$(git log --pretty=format:'%H' -n 1)

unset SANITY_CHECKS_OK

if test -z "$ORCA_WF_REV"; then echo "ERROR: no ORCA_WF_REV set">&2; false; else\
 if test -z "$ORCA_WF_TITLE"; then echo "ERROR: no ORCA_WF_TITLE set">&2; false; else\
 if test -z "$ORCA_WF_AS_MD"; then echo "ERROR: no ORCA_WF_AS_MD set">&2; false; else\
 if test -z "$GIT_CURRENT_HASH"; then echo "ERROR: no GIT_CURRENT_HASH set">&2; false; else\
 if test -z "$GIT_REMOTE_URL"; then echo "ERROR: no GIT_REMOTE_URL set">&2; false; else\
  SANITY_CHECKS_OK=true; fi; fi; fi; fi; fi

unset TMP_OUTPUT_DIR;TMP_OUTPUT_DIR=$(mktemp -p ~ -d)

nix develop --command mdbook build
test -n $SANITY_CHECKS_OK &&\
 sed -e "s|\@ORCA\@commit\@|${GIT_CURRENT_HASH}|g"\
     -e "s|\@ORCA\@gitremote\@|${GIT_REMOTE_URL}|g"\
     -e "s|\@ORCA\@rev\@|${ORCA_WF_REV}|g"\
   "$ORCA_WF_AS_MD" > "${TMP_OUTPUT_DIR}/${ORCA_WF_TITLE}_with_commit.md"

nix develop --command md-to-html "${TMP_OUTPUT_DIR}/${ORCA_WF_TITLE}_with_commit.md" "${ORCA_WF_TITLE} rev${ORCA_WF_REV}" > "${TMP_OUTPUT_DIR}/${ORCA_WF_TITLE}.html" &&\
 rm "${TMP_OUTPUT_DIR}/${ORCA_WF_TITLE}_with_commit.md"

command mv "${TMP_OUTPUT_DIR}/${ORCA_WF_TITLE}.html" "/tmp/${ORCA_WF_TITLE}.html" &&\
 command ls "/tmp/${ORCA_WF_TITLE}.html" &&\
 rm -rf "${TMP_OUTPUT_DIR}" && unset TMP_OUTPUT_DIR
```

You can then sign the html document following your organisation's way of signing documents, or if you don't have any, by following the [gpg-based process](./signing_and_verifying.md).

> [!Tip]
> If your organisation prefer to use PDFs documents, you can transform the HTML to a PDFs with :
> ```bash
> nix develop --command html-to-pdf /tmp/${ORCA_WF_TITLE}.html /tmp/${ORCA_WF_TITLE}.pdf
> ```
