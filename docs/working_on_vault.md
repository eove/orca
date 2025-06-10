# Working on the vault
Once the offline vault has been unsealed and you got a root token, we can now create the offline CA.

As a first step, you should setup your environment according to the CA you're working on:
```
export TARGET_VAULT=prod
```

or

```
export TARGET_VAULT=preprod
```

Then launch the automated CA generation from the folder where this readme is:
```
scripts/setup/001-create-offline-root-CA.sh
# The root CA's certificate is dumped on the console
scripts/setup/002-create-offline-intermediate-devices-CA.sh
```

> [!Note]  
> If you're reaching the end of this section, you are probably setting up the whole PKI.
> If so, your next step will be to [setup the online vault](./README.md#initializing-the-online-vault-from-scratch) and to sign that online vault's certificate with the offline PKI later on...

## Signing the CSR for the devices online CA

You should have CSR corresponding to the online CA for devices.
We are going to sign it with the offline CA.

As a first step, you should setup your environment according to the CA you're working on:
```
export TARGET_VAULT=prod
```

or

```
export TARGET_VAULT=preprod
```

You should have an unsealed vault with a root token. If this not the case, please follow the process detailed in the following sections (and come back here to continue the signing process afterwards):
* [Unsealing the ephemeral vault](#unsealing-the-ephemeral-vault)
* [Regenerating the root token](#regenerating-the-root-token)
* [Operator logging using the root token](#operator-logging-using-the-root-token)

Then launch the signature:
```
cd /path/to/O.R.CA/vault/
scripts/setup/005-sign-devices-CA-by-offline-CA.sh /path/to/devices-online-ca.csr
```

The path of the resulting signed pem file is dumped on the console.

Your next step will be to [apply the signed certificate to the online vault's PKI](./README.md#applying-a-signed-certificate-to-the-online-vaults-pki).

## Exporting the revocation list

Because the CA(s) we handle here is/are offline, we will need to put the revocation list online.
We will publish this on the main eove website: https://www.eove.fr/

Revoking a given certificate from its serial number can be done using, for example:
```
vault write <pki_name>/revoke serial_number=30:6e:65:c7:e9:01:1a:fd:b5:70:41:1a:cb:25:a3:79:bb:df:9e:da
```

> [!Note]  
> With `pki_name` matching the correct CA's mountpoint

Once all necessary certificates have been revoked, we will rotate the CRl:
```
vault read <pki_name>/crl/rotate
```

We can now extract the CRL in PEM format:
```
curl -k "https://${VAULT_ADDR}:8200/v1/<pki_name>/crl" -o crl.pem
```

If you want to have a look inside this CRL:
```
openssl crl -in crl.pem -text
```

This CRL file then needs to be transferred to the appropriate place on https://vault.eove.fr (for production) or https://preprod.vault.eove.fr (for preprod)

