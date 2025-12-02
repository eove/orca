# Introduction

In this document, we will explain how to work with the Public-Key Infrastructure (PKI).

> [!Warning]
> This PKI has been built using [O.R.CA](https://github.com/eove/orca) so you should also read  [O.R.CA's documentation](https://eove.github.io/orca) before you start customizing the PKI or exploiting it.

The scripts in the `actions` folder can be embedded during a ceremony by adding them to `actions_in_order` in the `orca-config.nix` file.
We can create our own `actions` scripts or use [the templates given by `O.R.CA`](https://github.com/eove/orca/tree/main/example/actions).

Scripts should be [tested in a VM](https://eove.github.io/orca/unstable/testing/index.html) before being used during a ceremony.

During a ceremony, we must follow a [one-page html-formatted exploitation workflow](https://eove.github.io/orca/unstable/html_gen.html) that is present in this repository.

The available exploitation workflows are:
 - [Using the Offline PKI](./offline_vault_ceremony.md)
 - [Periodical checks of the PKI](./periodical_checks.md)

In case you encounter a term that you do not understand, please refer to [the O.R.CA documentation's glossary](https://eove.github.io/orca/unstable/glossary.html)
