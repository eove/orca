Since the vault system protects highly sensitive data (like the root CA), it must be impossible for a single person to manipulate it.
Hashicorp vault encrypts (aka seals) every secret it stores. Thus, even if you have access to vault's database's files, you cannot read or change any data in that database without the encryption key.

The encryption key is never stored anywhere. Instead, it is split into multiple parts called "shares".
Each share is securely given to a different human being that *must* keep it secret. We call these people "share holders".
To decrypt (aka unseal) vault's database, a number of shares higher than a threshold is necessary.
This is called a quorum.

A good starting point is to be split among at least 5 share holders (the more the merrier) and a quorum of at least 3 people.

The downside of that technique is that we *must* verify regularly that we can reach a quorum.
If we lose our ability to reach a quorum, then the whole PKI is lost forever.
Here are some events that may impact our ability to reach a quorum:
 - people may lose their share
 - people may leave the company

Thus it is important to:
 - regularly check that all share holders still have access to their share
 - revoke the shares owned by people leaving the company
 - keep the number of shares high by regularly creating shares for people entering the company
 - make sure that share holders can keep their share securely (in a safe encrypted storage)

The first 3 items are taken care of by running the periodical check workflow.
THe 4th item is garanteed by the fact shares are only stored encrypted, by the fact the decryption process uses secure hardware token (Yubikeys) and by the fact the cleartext share is never disclosed, and only input to the vault unseal process by an automated process (scripts).
