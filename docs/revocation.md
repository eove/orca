In the event of a compromised CA/certificate, you will have to revoke the compromised item. When that compromised item was signed by an offline CA, you should invoke the offline ephemeral vault.
For this reason, we provide the script `revoke-certificate.sh` that needs to be executed during a ceremony to revoke compromised item.
Note that you cannot revoke the offline root CA itself using that script.

You should then regenerate all children of the compromised CA (but not end device certificates)

If the root CA has been compromised, then you need to contact all services that rely on it as a trusted CA so that they stop trusting it.
Then revoke all children CAs using the script `revoke-certificate.sh`.
Finally you should create a whole new PKI to replace the old one.

> [!Important]
> If the root CA is ever compromised. You **must** find how it happens and fix the problem.\
> Maybe it's a unknown weakness in O.R.CA, maybe O.R.CA is not suited for your organisation or maybe it's something completely different !\
> The important part is that if you don't fix the issue, it **will** happen again !
