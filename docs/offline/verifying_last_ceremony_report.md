Get the last report for the corresponding environment and verify the signatures following your organisation's way of verifying a document.
A gpg-based one can be found at the [signing and verifying annex](../signing_and_verifying.md)

> [!Warning]  
> All signatures should be valid. The check above should be valid for at least the 3 👥`team members` of the previous ceremony.
>
> Only **one** invalid/missing signature is enough to **stop the ceremony**. In such a case, the issue should be analysed.

Once all signatures has been verified, to get ready for subsequent steps, extract from the `previous ceremony report`:
 - the `trusted commit` that was used back then (that we will refer to as `previous trusted commit`)
 - the checksum *C<sub>vault</sub>* of the previous vault private data that was computed when closing down the ceremony back then.
