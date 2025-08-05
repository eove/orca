## Glossary

[Certificat](https://en.wikipedia.org/wiki/Public_key_certificate) : Digital identifier for a machine or a service. The certificat is public but can only be used when in possesion of the associated private key. 

PKI : [Public-key infrastructure](https://en.wikipedia.org/wiki/Public_key_infrastructure)

CA : [Certificate Authority](https://en.wikipedia.org/wiki/Certificate_authority)

CSR/[Certificate Signing Request](https://en.wikipedia.org/wiki/Certificate_signing_request) : Certificate offered to be signed by a CA. 

[Secret Sharing](https://en.wikipedia.org/wiki/Secret_sharing) : an algorithm to split a secret between multiple people 

SSS : [Shamir Secret Sharing](https://en.wikipedia.org/wiki/Shamir%27s_secret_sharing)

GPG/GnuPG : [GNU Privacy Guard](https://en.wikipedia.org/wiki/GNU_Privacy_Guard). This tool can sign and cypher messages and files this ensuring their authenticity, integrity and/or confidentiality.

[Digital signature](https://en.wikipedia.org/wiki/Digital_signature)/Cryptographic signature : Verifiable signature of a digital document. This ensure the authenticity and integrity of the document.

GPG keyring : GPG database containing all the known public keys, private key when known and their trustworthyness.

[Checksum](https://en.wikipedia.org/wiki/Checksum) : In this documentation, we use the sha256 [cryptographic hashing function](https://en.wikipedia.org/wiki/Cryptographic_hash_function) as a secure checksum. A secure checksum is necessary to ensure that the input is not tampered.

Hardware Token/[Security token](https://en.wikipedia.org/wiki/Security_token) : a physical device that can securely store secrets (like private keys). This is useful to securely use a secret on any computer.

[Yubikey](https://en.wikipedia.org/wiki/YubiKey) : Affordable hardware token that can be plugged on a USB port and is compatible with GPG.

Vault/[Hashicorp Vault](https://github.com/hashicorp/vault) : Web service to handle secret and use cryptographic primitives (like CA automation).

Vault Private Data : Database of Hashicorp Vault at rest. These data contains the state of the Vault and **must** be backed up to ensure the vault and the managed PKI is not lost.

Unseal share : A part of a secret that allows access to Hashicorp Vault. Multiple shares are necessary in order to unseal a vault. Reaching that threshold is called reaching a quorum.

Unseal Hashicorp Vault : A sealed vault cannot be used because it doesn't know the key to decypher the private data. To get that secret, a quorum is necessary and the vault is then unsealed.

Seal Hashicorp Vault : An unsealed vault can be sealed by anyone having the corresponding right in Vault.

Token : An access token generated after a proof of identity (via login or certifcate).

Root token : A token with **every rights** on Hashicorp Vault.

Ephemeral Vault : A Hashicorp Vault started for a one-time usage on a machine. Private data may be given when starting the vault and are saved one the vault is stopped. This is used to handle the Offline part of the PKI, thus the machine running the ephemeral vault should also be offline.

Ceremony : An event during which the offline part of the PKI is handled. This event is formalized, planned and produce an auditable report.

Ceremony report : Auditable document, cryptographically signed, describing the context, the people involved and the actions that occured during a ceremony.

Trusted commit : The sha of a git commit which has been audited and that can be trusted.

ISO/[ISO9660](https://en.wikipedia.org/wiki/ISO_9660) : file system format for optical disc (extanded for bootable USB sticks).
For an ephemeral vault, that image contains the whole operating system and script. It is thus umutable and self contained.

Bootable live media : Mass storage with a ISO9660 image loaded.

Vault writable partition : secondary partition on the ephemeral vault bootable live media.
Unlike the ISO partition, this partition is in read/write mode.
It contains everything that change during a ceremony (e.g. the vault private data, logs, certificates…)
