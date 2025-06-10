One of the key feature of the vault system is to handle Eove's Public-Key Infrastructure (PKI).

The whole chain of trust starts with Eove's root Certificate Authority (CA). That's why it must be kept as secured as possible.

To achieve this, Eove's PKI (and thus the vault system) is split in two parts:
 - the offline CAs, that contain multiple CAs, one of them is the root CA (topmost root of trust).  
   All of these offline CAs are manipulated using the offline vault.  
   The offline vault is not a machine, it is a database (a set of backup files) fetched into an ephemeral machine when manipulating the online CAs.
 - the online CAs which are used on a daily basis.  
   All of these online CAs are handled by the online vault, that is publicly accessible at `vault.eove.fr` (or `preprod.vault.eove.fr` for preprod testing purposes).

In the offline vault, the root CA delegates its signing rights to offline intermediate CAs that are restricted to a given subdomain.
This offline intermediate CA will then delegate its signing rights to an online intermediate CA that is valid for a short amount of time.
It is up to the online intermediate CA to sign certificates on a day to day basis.

Here is a graphical representation of the chain of trust:

```mermaid
flowchart TD

    subgraph Offline vault
        EOVE_ROOT_CA>"<b>ROOT CA</b>
*.eove.fr
fa:fa-hourglass 30yrs"]
        EOVE_INTERMEDIATE_CA>"<b>Offline intermediate CA</b>
*.subdomain.eove.fr
fa:fa-hourglass 30yrs"]
    end
    EOVE_ROOT_CA --> |delegates| EOVE_INTERMEDIATE_CA

    EOVE_INTERMEDIATE_CA --> |delegates| VAULT_PKI

    subgraph Online vault
        VAULT_PKI>"<b>Online intermediate CA</b>
*.subdomain.eove.fr
fa:fa-hourglass 14yrs"]
        VAULT_PKI -->|signs| EOCON1("fa:fa-barcode XXX.subdomain.eove.fr
fa:fa-hourglass 12yrs")
        VAULT_PKI -->|signs| EOCON2("fa:fa-barcode YYY.subdomain.eove.fr
fa:fa-hourglass 12yrs")
    end
```
