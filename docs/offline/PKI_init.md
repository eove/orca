## Introduction

This document describes how to initialise an offline CA using the O.R.CA scripts.

> [!Warning]  
> Part of this process would probably also involve working with another (online) CA as well.  
> We would want to sign that online CA using the offline CA and thus to get a fully functional chain of trust.  
> All work on the offline part of the PKI thus means using the O.R.CA workflow.

# Shortcut initialisation of the offline vault

This section details the process to create a new offline CA, doing it fast, in one operation (for testing). If instead, you want to re-open an existing CA, following the safe process, please see [the O.R.CA workflow document](workflow/offline_vault_ceremony.md).

As a first step, we will select the CA we're working on (`dev`, `preprod` or `prod`). This will have an impact before building the ISO as explained in [the O.R.CA workflow](workflow/offline_vault_ceremony.md#selecting-the-vault-environment). The value of `orca.environment-target` in [src/default.nix](../src/default.nix) should thus be updated if needed.
To initialize a new offline CA, we will also need to include the following script from the `templates/` folder under `src/scripts/*/` (and `git add` this script):\
* [templates/unauthenticated/initialize-vault.sh](../templates/unauthenticated/initialize-vault.sh)
Depending on what we also want to perform during the same maintenance session, we may also include the following scripts from `templates/`:
* [templates/authenticated/create-root-CA.sh](../templates/authenticated/create-root-CA.sh)
* [templates/authenticated/create-intermediate-CA.sh](../templates/authenticated/create-intermediate-CA.sh)
* [templates/authenticated/sign-csr.sh](../templates/authenticated/sign-csr.sh)

We can now start the *ephemeral vault* by following the [instructions of the O.R.CA workflow](workflow/offline_vault_ceremony.md).
When the vault is started, we can check that it is not initialized yet by running:
```bash
vault status
```

This should output the following line:
```
Initialized     false
Sealed          true
```

During the ceremony, we initialise a brand new vault for the offline CA by running (on the *ephemeral vault*):
```bash
initialize-vault
```

> [!Tip]  
> If you're testing (in `dev` environments), you can simulate hardware tokens (yubikeys) during that stage.  
> For more information on how to do this, please see [here](./testing/README.md#simulating-yubikeys)

This will result in *n* encrypted shares to be output the env-specific directory located under `/var/lib/vault/orca/shares/`.

> [!Note]  
> This data can be sent across any communication media, it is not sensitive as it is encrypted only for the recipient

The *ephemeral vault* is now initialised, which can be verified by running once more:
```bash
vault status
```

This should output the following line:
```
Initialized     true
```

You may stop here, or continue executing the next steps (if the corresponding scripts were included into the ISO image).

Let's now create the offline CA chain on the *ephemeral vault*:
```bash
create-root-CA
```

Then:
```bash
create-intermediate-CA
```

On the online CA, generate a CSR to be signed and bring it into a new ISO image to boot on the offline vault (or in dev mode, just copy over the CSR file).

> [!Important]  
> This step is mandatory if you want to finish signing the whole chain of trust from the offline to the online vault.

Now sign the online CA with the offline CA:
```bash
sign-csr
```

TODO: improve this part
