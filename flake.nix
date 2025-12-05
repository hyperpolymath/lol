# SPDX-License-Identifier: MIT AND LicenseRef-Palimpsest-0.8
# SPDX-FileCopyrightText: 2024-2025 Ehsaneddin Asgari and Contributors
#
# 1000Langs Nix Flake
# ===================
# Reproducible development environment for RSR Gold compliance
{
  description = "1000Langs - Super-parallel corpus crawler for 1500+ languages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        # Rust toolchain for any native extensions
        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rust-analyzer" ];
        };

      in {
        devShells.default = pkgs.mkShell {
          name = "1000langs-dev";

          buildInputs = with pkgs; [
            # Node.js and npm
            nodejs_20
            nodePackages.npm

            # ReScript
            nodePackages.rescript

            # Rust (for native modules if needed)
            rustToolchain

            # Nickel configuration
            nickel

            # Just command runner
            just

            # Container runtime (Podman, not Docker!)
            podman
            buildah
            skopeo

            # Documentation
            asciidoctor

            # Git and version control
            git
            git-lfs

            # Code quality
            nodePackages.prettier

            # Utilities
            jq
            yq
            tokei
            tree
            ripgrep
            fd

            # Shell utilities
            bash
            coreutils

            # Security scanning
            trivy
            grype
          ];

          shellHook = ''
            echo "🌍 1000Langs Development Environment"
            echo "======================================"
            echo ""
            echo "Node.js: $(node --version)"
            echo "npm: $(npm --version)"
            echo "Rust: $(rustc --version)"
            echo "Podman: $(podman --version)"
            echo "Just: $(just --version)"
            echo "Nickel: $(nickel --version)"
            echo ""
            echo "Run 'just help' for available commands"
            echo ""

            # Set up environment
            export PATH="$PWD/node_modules/.bin:$PATH"

            # Podman settings
            export CONTAINER_RUNTIME=podman

            # Install npm dependencies if not present
            if [ ! -d "node_modules" ]; then
              echo "Installing npm dependencies..."
              npm install
            fi
          '';

          # Environment variables
          LANG = "en_US.UTF-8";
          LC_ALL = "en_US.UTF-8";
        };

        # Package definition
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "1000langs";
          version = "0.1.0";
          src = ./.;

          buildInputs = with pkgs; [
            nodejs_20
            nodePackages.npm
          ];

          buildPhase = ''
            export HOME=$(mktemp -d)
            npm ci
            npm run build
          '';

          installPhase = ''
            mkdir -p $out/lib/1000langs
            cp -r dist/* $out/lib/1000langs/
            cp package.json $out/lib/1000langs/

            mkdir -p $out/bin
            cat > $out/bin/1000langs <<EOF
            #!/usr/bin/env bash
            exec ${pkgs.nodejs_20}/bin/node $out/lib/1000langs/Lang1000.res.mjs "\$@"
            EOF
            chmod +x $out/bin/1000langs
          '';

          meta = with pkgs.lib; {
            description = "Super-parallel corpus crawler for multilingual NLP research";
            homepage = "https://github.com/Hyperpolymath/1000Langs";
            license = with licenses; [ mit ];
            maintainers = [ ];
            platforms = platforms.unix;
          };
        };

        # Container image (using Podman-compatible format)
        packages.container = pkgs.dockerTools.buildLayeredImage {
          name = "1000langs";
          tag = "latest";

          contents = with pkgs; [
            self.packages.${system}.default
            nodejs_20
            coreutils
            bash
          ];

          config = {
            Cmd = [ "/bin/1000langs" ];
            Env = [
              "NODE_ENV=production"
            ];
            Labels = {
              "org.opencontainers.image.title" = "1000Langs";
              "org.opencontainers.image.description" = "Super-parallel corpus crawler";
              "org.opencontainers.image.source" = "https://github.com/Hyperpolymath/1000Langs";
              "org.opencontainers.image.licenses" = "MIT AND LicenseRef-Palimpsest-0.8";
            };
          };
        };
      }
    );
}
