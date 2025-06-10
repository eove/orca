Get the last IN65 report from:
* Google Drive's `Eove_RnD/PKI/Eove_offline_prod_CAs/` for prod offline CAs
* Google Drive's `Eove_RnD/PKI/Eove_offline_preprod_CAs/` for preprod offline CAs

In that document, search for the value of the `trusted commit` that was used during the last IN65 ceremony. We'll call this the `previous IN65 trusted commit`.

Checkout [O.R.CA](@IN@gitremote@) at that commit.

Get the name of the reporter, observer and operator that were running the last ceremony, and retrieve the public key of their hardware token.

> [!Tip]  
> At the `previous trusted commit`, the env-specific directory located under [`src/share_holders_keys/`] in this repositorywas containing the public keys of all hardware token in use, these three people's public keys were in this list.
> Create a new temporary keyring with these share holders' keys imported as they where at the trusted commit:
```bash
export TMP_GPG_HOME=$(mktemp -d)
gpg --home="$TMP_GPG_HOME" --import /path/to/src/share_holders_keys/env/*
gpg --home="$TMP_GPG_HOME" --list-keys --keyid-format LONG --with-colons | sed -n -e '/^pub/{n;p}' | sed -n -E 's/^fpr:([^:]*:){8}([^:]*).*$/\2:6:/p' | gpg --home="$TMP_GPG_HOME" --import-ownertrust
```

With the environment variable `TMP_GPG_HOME` set above, verify each detached signature of the previous IN65 with:
```bash
export REPORT=/path/to/IN65_report.txt.signed
export REPORT_UNSIGNED=$(mktemp -u)
export REPORT_SIGNATURES=$(mktemp -u)
sed -e '1,/^@GPG@SIGNATURES@$/ d' "$REPORT" > "$REPORT_SIGNATURES"
sed -e '/^@GPG@SIGNATURES@$/q' "$REPORT" > "$REPORT_UNSIGNED"
gpg --home="$TMP_GPG_HOME" --verify "$REPORT_SIGNATURES" "$REPORT_UNSIGNED" && echo "All signatures verified"
```

An example of what you should get (correct signature):
```
gpg: Signature made Fri 04 Apr 2025 04:24:16 PM CEST
gpg:                using EDDSA key B6A7C35F432BABBE92CDA22E81860727618985C4
gpg: Good signature from "One user's Yubikey <first.user@github.com>" [ultimate]
gpg: Signature made Fri 04 Apr 2025 04:34:14 PM CEST
gpg:                using EDDSA key AD84CAAF671D3CF59332D158D4008E4C11FB8362
gpg: Good signature from "Second user's Yubikey <second.user@github.com>" [ultimate]
All signatures verified
```

> [!Warning]  
> All signatures should be valid. The check above should be repeated for at least the 3 👥`team members` of the previous IN65 ceremony.
>
> Only **one** invalid/missing signature is enough to **stop the ceremony**. In such a case, the issue should be analysed.

Once all signatures has been verified, to get ready for subsequent steps, extract from the `previous IN65`:
 - the `trusted commit` that was used back then (that we will refer to as `previous trusted commit`)
 - the checksum *C<sub>vault</sub>* of the previous vault private data that was computed when closing down the ceremony back then.
