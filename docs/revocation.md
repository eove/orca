If a CA signed by an offline CA has been compromised (excluding the offline root CA), the script `revoke-certificate.sh` should be run in a ceremony to revoke the CA's certificate.

You should then regenerate all children of the compromised CA (but not end device certificates)

If the root CA has been compromised, then you need to contact anyone relying on it and warn them to stop trusting it.
Then revoke all CAs under it using the script `revoke-certificate.sh`.
Finally you should create a whole new PKI to replace the old one.

> [!Important]
> If the root CA is ever compromised. You **must** find how it happens and fix the problem.\
> Maybe it's a unknown weakness in O.R.CA, maybe O.R.CA is not suited for your organisation or maybe it's something completely different !\
> The important part is that if you don't fix the issue, it **will** happen again !
