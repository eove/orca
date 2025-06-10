# Description

This readme describes the use of the offline vault.

This process applies to all top certificate authorities that are offline.

If you are looking for information about the Eove Internet-accessible vault service instead, please see [the associated readme here](../online/README.md).

# Introduction

In the Eove chain of trust, the topmost CAs (long-living) are to be stored offline.

These CAs are thus not hosted on a Internet-accessible vault service, but rather are manipulated using an ephemeral vault instance, powered-on on demand when maintenance on the CA is required.
