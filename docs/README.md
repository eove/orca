# Introduction

In this document, we will explain how O.R.CA works.

> [!Warning]
> This document is known as the `O.R.CA documentation` and is not to be confused with the `exploitation manual` that you will have your own copy of and will have to customize.

In case you encounter a term that you do not understand, please refer to [the glossary](./workflow/common/glossary.md)

To initialise your own `exploitation repository`, in an empty folder, use:
```shell
nix flake init -t github:eove/orca/v1.0 --refresh
```
You can then commit and push this folder into your own organisation's repository.
This will be the repository where all changes to your offline root CA will be commited, thus the name `exploitation repository`.

You will now have to customize you `Exploitation manual`.

> [!CAUTION]
> The parts that need the most attention are highlighted with caution alerts like this one.

To create your `Exploitation manual` run :
```shell
mdbook build --open
```

Before you start doing anything on it, you'll need to understand how O.R.CA works, its threat model, its limits and how to interact with it in general.
This is the subject of the next chapters.

