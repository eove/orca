# Exploitation repository for [O.R.CA](https://github.com/eove/orca)

This repository uses [O.R.CA v0.4.0](https://eove.github.io/orca/v0.4.0) as written in the [flake.nix](./flake.nix) file

The documentation is present in the `docs` folder as markdown files.

You can open it locally in a web browser on your machine by running the following command:
```bash
nix develop --command mdbook build --open
```

> [!Note]  
> The nix shell provided in the flake besides this readme automatically makes `mdbook` available to you

That documentation will guide you on how to use this repository and O.R.CA.
