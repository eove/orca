## Introduction

We describes how to initialise an offline CA using O.R.CA.

> [!Warning]  
> Part of this process would probably also involve working with another (online) CA as well.  
> We would want to sign that online CA using the offline CA and thus to get a fully functional chain of trust.  
> All work on the offline part of the PKI thus means using your `exploitation manual`'s workflow.

# Initialisation of the offline vault

The initialisation is done during a ceremony. Please refer to your custom `exploitation manual` to find out the workflow for your offline vault ceremony).
Creating the first shares is done automatically when needed.

To initialize a new offline CA, we will need to include the following script from the `actions/` folder depending on what we want to perform :
* [create-root-CA.sh](../example/actions/create-root-CA.sh)
* [create-intermediate-CA.sh](../example/actions/create-intermediate-CA.sh)
* [sign-csr.sh](../example/actions/sign-csr.sh)

These scripts should be customised according to your own PKI architecture. They should be included in that exact order.
When signing a CSR, you should validate it as indicated in your `exploitation manual`.
