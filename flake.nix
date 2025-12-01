{
  description = "O.R.CA";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    ({
      nixosModules = import ./src/orca-nixos-module.nix inputs;
      templates = {
        default = {
          path = ./example;
          description = "O.R.CA exploitation repository template";
        };
      };
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
          in-vm = self.lib."${system}".run-in-vm (import ./testing/orca-config.nix);
        };
        packages = {
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
          patch-links-for-release = pkgs.writeShellScriptBin "patch-links-for-release" ''
            if [ "$#" -ne 1 ]; then
              echo "We need a version number" >&2
              exit -1
            fi
            VERSION="$1"
            for file in $(grep -lR 'https://eove.github.io/orca/unstable' * | grep -v flake.nix)
            do
             sed -i s@https://eove.github.io/orca/unstable@https://eove.github.io/orca/$VERSION@g $file
            done
            sed -i s@github:eove/orca@github:eove/orca/$VERSION@g example/flake.nix
            '';

        };
        devShells = {
          default = pkgs.mkShell (
            let
              to-qemu = "${pkgs.lib.getExe pkgs.socat} - unix-connect:/tmp/orca-monitor-socket";
              switch-usb-rw = value: ''
                echo device_del vault_writable | ${to-qemu}
                sleep 1
                echo drive_add 42 if=none,id=usbstick,format=raw,file=$(pwd)/orca-testing-disk.raw,read-only=${value} | ${to-qemu}
                sleep 1
                echo device_add usb-storage,bus=xhci.0,drive=usbstick,removable=on,id=vault_writable | ${to-qemu}
              '';
              switch-to-readwrite = pkgs.writeShellScriptBin "switch-to-readwrite" ''
                ${switch-usb-rw "off"}
              '';
              switch-to-readonly = pkgs.writeShellScriptBin "switch-to-readonly" ''
                ${switch-usb-rw "on"}
              '';
              plug-simulated-hardware-token = pkgs.writeShellScriptBin "plug-simulated-hardware-token" ''
                  if test $# -ne 1; then
                    echo "This script requires the number of the hardware token to insert as argument" >&2
                    exit 1
                  fi
                echo device_del canokey | ${to-qemu}
                sleep 1
                echo device_add canokey,file=$(pwd)/testing/simulated-hardware-tokens/canokey''${1},id=canokey | ${to-qemu}
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
                self.packages."${system}".md-to-html
                asciinema
                switch-to-readwrite
                switch-to-readonly
                plug-simulated-hardware-token
                socat
              ];
            }
          );
          ci = pkgs.mkShell {
            packages = with pkgs; [
              mdbook
              mdbook-alerts
              mdbook-mermaid
              self.packages."${system}".patch-links-for-release
            ];
          };
        };
      }));
}
