# Introduction

In this document, we will explain how O.R.CA works.

> [!Warning]
> This book contains the `O.R.CA documentation` and should not be confused with the `exploitation manual` (which will be your customised user manual and workflow for your own offline CA).

In case you encounter a term that you do not understand, please refer to [the glossary](./workflow/common/glossary.md)

To create a copy of your exploitation manual, you will need to install the [nix package manager](https://nixos.org/download/) on your machine.
Make sure the [flakes](https://nix.dev/manual/nix/2.28/development/experimental-features.html#xp-feature-flakes) and [nix-command](https://nix.dev/manual/nix/2.28/development/experimental-features.html#xp-feature-nix-command) features are enabled (otherwise you'll have to explicitly enable them for each nix command).

Then fetch a brand new template for your offline CA, by creating a new folder, and running the following commands inside this folder:
```shell
nix flake init -t github:eove/orca/v0.4.0 --refresh
git init .
git add .
git commit -m "Initialisation of our O.R.CA exploitation repository"
```
Then push this folder into a new repository in your organisation.
This will be the repository where all changes to your offline root CA will be committed (containing documentation and workflows, as well as automation scripts). We will call this the `exploitation repository`.

You will now have to document your offline CA, that is to say, customise your `exploitation manual`.

> [!CAUTION]
> The parts that need the most attention are highlighted with caution alerts like this one.

To generate and display the default `exploitation manual` in a web-browser, run:
```shell
nix develop --command mdbook build --open
```
> [!Note]  
> What is displayed initially when you run the above command has directly been taken from the nix template.  
> It contains the default documentation we have prepared. You should review it and modify the relevant `.md` files to fit your needs, regenerating and browsing the updated documentation again as needed.  
> Next to that default `exploitation manual`, you will find default scripts to operate the offline CA.
Before you start doing anything on it, you'll need to understand how O.R.CA works, its threat model, its limits and how to interact with it in general.
This is the subject of the next chapters.

