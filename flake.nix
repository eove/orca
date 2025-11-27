{
  description = "O.R.CA";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    ({
      nixosModules = import ./src/orca-nixos-module.nix inputs;
    }) //
    (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        ORCA_DISK_NAME = "VAULT_WRITABLE";
      in
      {
        lib = import ./src/lib.nix (inputs // { inherit system pkgs ORCA_DISK_NAME; });
        apps = {
          default =
            let
              vmScript = pkgs.writeShellScriptBin "vmScript" ''
                export VAULT_WRITABLE_DISK="$(pwd)/orca-testing-disk.raw"
                if [ ! -f "$VAULT_WRITABLE_DISK" ]; then
                  echo "Creating a new disk at $VAULT_WRITABLE_DISK"
                  ${pkgs.qemu}/bin/qemu-img create -f raw "$VAULT_WRITABLE_DISK" 500M
                  mkfs.ext4 -L "${ORCA_DISK_NAME}" -F "$VAULT_WRITABLE_DISK"
                else
                  echo "Using existing $VAULT_WRITABLE_DISK"
                fi
                ${pkgs.lib.getExe (import ./testing/orca-vm.nix (inputs // { inherit system pkgs ORCA_DISK_NAME;}))}
              '';
            in
            {
              type = "app";
              program = "${pkgs.lib.getExe vmScript}";
            };
        };
        devShells = {
          default = pkgs.mkShell (
            let
              md-to-html = pkgs.writeShellScriptBin "md-to-html" ''
                if [ "$#" -eq 0 ]; then
                  echo "Usage : $0 /path/to/file.md [title]" >&2
                  exit -1
                fi
                echo "$0" >&2
                DIR="$(mktemp -d)"
                mkdir -p "$DIR"
                MD="$1"
                FILE=$(basename "$MD")
                TITLE="$FILE"
                if [ "$#" -ge 2 ]; then
                  TITLE=$(echo "$2" | tr '[]"<>' '_')
                fi

                cp -r ${./.}/docs/.style "$DIR"/.style >/dev/null
                chmod +w -R "$DIR"/.style
                cp "$MD" "$DIR/$FILE"
                cat <<EOF > "$DIR/book.toml"
                [book]
                language = "en"
                src = "."
                title = "$TITLE"
                
                [preprocessor.index]
                
                [preprocessor.links]
                
                [preprocessor.alerts]
                
                [preprocessor.mermaid]
                command = "mdbook-mermaid"
                
                [output.html]
                additional-js = [".style/mermaid.min.js", ".style/mermaid-init.js"]
                additional-css = [".style/custom.css"]

                [output.html.search]
                enable = false
                
                EOF

                cat <<EOF > "$DIR/SUMMARY.md"
                [$TITLE](./$FILE)
                EOF

                mdbook build "$DIR" >&2

                PATH="$PATH:${pkgs.nodejs}/bin" npx --yes inliner -m "$DIR/book/index.html"

                rm -rf "$DIR/"
              '';
            in
            {
              packages = with pkgs; [
                vault-bin
                jq
                openssl
                mdbook
                mdbook-alerts
                mdbook-mermaid
                md-to-html
                asciinema
              ];
            }
          );
          ci = pkgs.mkShell {
            packages = with pkgs; [
              mdbook
              mdbook-alerts
              mdbook-mermaid
            ];
          };
        };
      }));
}
