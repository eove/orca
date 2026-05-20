# Exploitation repository for [O.R.CA](https://github.com/eove/orca)

This repository uses [O.R.CA v1.1.0](https://eove.github.io/orca/v1.1.0) as written in the [flake.nix](./flake.nix) file

> [!Tip]
> In order to [run in a controlled environment](https://eove.github.io/orca/v1.1.0/story/verifiable-os.html), O.R.C.A extensively uses [Nix and NixOS](https://nixos.org/). Please consult its documentation, install Nix, and make sure the `nix` command is available to you before proceeding.

The documentation is present in the `docs` folder as markdown files.

You can open it locally in a web browser on your machine by running the following command:
```bash
nix develop --command mdbook build --open
```

> [!Note]  
> The nix shell provided in the flake besides this readme automatically makes `mdbook` available to you

That documentation will guide you on how to use this repository and O.R.CA.
