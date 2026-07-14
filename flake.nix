{
  description = "Development environment with Neovim";

  inputs = {
    # Tools/shells base. Tracks nixos-unstable (hydra-built, fully in the
    # binary cache) — master revs are not guaranteed cached.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # claude-code pin — update ONLY via `nix flake update nixpkgs-claude`.
    # Deliberately tracks master: updates should get the newest claude-code
    # immediately. Only the package definition is taken from this input
    # (callPackage below); its dependencies resolve from the cached `nixpkgs`
    # above, so the uncached master rev never pulls builds in.
    nixpkgs-claude.url = "github:NixOS/nixpkgs";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      # Reuse our nixpkgs instead of locking a second copy.
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-claude,
      rust-overlay,
    }:
    let
      inherit (nixpkgs) lib;
      # Linux-only flake (alsa/pipewire/X11 tools); darwin was never buildable.
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      outputsFor =
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [
              rust-overlay.overlays.default
              (final: prev: {
                # Full tessdata is >1 GiB (every language); keep a small set.
                # pytesseract resolves pkgs.tesseract, so it follows this too.
                tesseract = prev.tesseract.override {
                  enableLanguages = [
                    "eng"
                    "deu"
                    "fra" # pytesseract's test suite requires it
                    "nld"
                    "tur"
                    "osd"
                  ];
                };
              })
            ];
          };

          # Cross-compilation package sets
          pkgsCrossAarch64Musl = pkgs.pkgsCross.aarch64-multiplatform-musl;
          pkgsCrossMusl64 = pkgs.pkgsCross.musl64;

          myNeovim = import ./packages/neovim { inherit pkgs; };
          deps = import ./packages/dependencies { inherit pkgs; };

          # Newest claude-code definition from the master pin, dependencies
          # from the cached main nixpkgs (see inputs comment).
          claude-code = pkgs.callPackage "${nixpkgs-claude}/pkgs/by-name/cl/claude-code/package.nix" { };

          # Rust toolchain with cross-compilation targets. `minimal` base
          # profile: `default` would add rust-docs (~700 MiB of offline HTML)
          # on top of the components below.
          rustToolchain = pkgs.rust-bin.nightly.latest.minimal.override {
            extensions = [
              "rust-src"
              "rust-analyzer"
              "rustfmt"
              "clippy"
              "llvm-tools-preview"
            ];
            targets = [
              "x86_64-unknown-linux-musl"
              "aarch64-unknown-linux-musl"
              # Embedded ARM Cortex-M targets
              "thumbv6m-none-eabi" # Cortex-M0/M0+
              "thumbv7m-none-eabi" # Cortex-M3
              "thumbv7em-none-eabi" # Cortex-M4/M7 (soft float)
              "thumbv7em-none-eabihf" # Cortex-M4F/M7F (hard float) - STM32F4/F7/H7
              "thumbv8m.main-none-eabihf" # Cortex-M33/M55
              # WebAssembly target
              "wasm32-unknown-unknown" # WASM for web apps (Leptos, Yew, etc.)
            ];
          };

          # Common Rust packages for all shells
          rustPackages = [
            rustToolchain
            pkgs.cargo-nextest
          ];

          commonShellPackages = deps.packages ++ [ myNeovim ] ++ rustPackages;

          # OpenSSL setup helper
          mkOpenSSLEnv = opensslPkg: ''
            export OPENSSL_DIR=${opensslPkg.dev}
            export OPENSSL_LIB_DIR=${opensslPkg.out}/lib
            export OPENSSL_INCLUDE_DIR=${opensslPkg.dev}/include
            export OPENSSL_STATIC=1
            export PKG_CONFIG_PATH=${opensslPkg.dev}/lib/pkgconfig:$PKG_CONFIG_PATH
          '';

          # Wrapped Neovim: editor tooling only (LSPs, formatters, debuggers,
          # build essentials) — not the full dev-shell payload.
          neovim-with-lsps = pkgs.writeShellApplication {
            name = "nvim";
            runtimeInputs = deps.editorPackages ++ rustPackages;
            text = ''
              ${deps.editorHook}
              exec ${myNeovim}/bin/nvim "$@"
            '';
          };

          # Declarative Claude Code plugin: LSP servers (resolved from the
          # wrapper's PATH) and MCP servers (absolute store paths).
          claudePlugin = import ./packages/claude-plugin { inherit pkgs; };

          # Wrapped Claude Code: editor tooling + headless CLI tools. GUI and
          # interactive-only packages stay in the dev shells.
          claude-with-deps = pkgs.writeShellApplication {
            name = "claude";
            runtimeInputs = deps.claudePackages ++ rustPackages;
            text = ''
              ${deps.shellHook}
              export ENABLE_LSP_TOOL=1
              exec ${claude-code}/bin/claude --plugin-dir ${claudePlugin} "$@"
            '';
          };
        in
        {
          packages = {
            default = neovim-with-lsps;
            neovim = neovim-with-lsps;
            claude = claude-with-deps;
          };

          devShells = {
            # Native x86_64 development (glibc, dynamic)
            default = pkgs.mkShell {
              packages = commonShellPackages;
              shellHook = deps.shellHook;
            };

            # x86_64 musl static builds
            x86_64-musl = pkgs.mkShell {
              packages = commonShellPackages ++ [
                pkgsCrossMusl64.stdenv.cc
              ];

              CARGO_BUILD_TARGET = "x86_64-unknown-linux-musl";
              CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER = "${pkgsCrossMusl64.stdenv.cc}/bin/x86_64-unknown-linux-musl-cc";
              CC_x86_64_unknown_linux_musl = "${pkgsCrossMusl64.stdenv.cc}/bin/x86_64-unknown-linux-musl-cc";

              shellHook = mkOpenSSLEnv pkgsCrossMusl64.pkgsStatic.openssl;
            };

            # aarch64 musl static builds (cross-compilation)
            aarch64-musl = pkgs.mkShell {
              packages = commonShellPackages ++ [
                pkgsCrossAarch64Musl.stdenv.cc
              ];

              CARGO_BUILD_TARGET = "aarch64-unknown-linux-musl";
              CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_LINKER = "${pkgsCrossAarch64Musl.stdenv.cc}/bin/aarch64-unknown-linux-musl-cc";
              CC_aarch64_unknown_linux_musl = "${pkgsCrossAarch64Musl.stdenv.cc}/bin/aarch64-unknown-linux-musl-cc";

              shellHook = mkOpenSSLEnv pkgsCrossAarch64Musl.pkgsStatic.openssl;
            };
          };

          checks = {
            neovim = neovim-with-lsps;
            claude = claude-with-deps;
          };

          formatter = pkgs.nixfmt-tree;
        };

      perSystem = lib.genAttrs systems outputsFor;
      transpose = attr: lib.mapAttrs (_: v: v.${attr}) perSystem;
    in
    {
      packages = transpose "packages";
      devShells = transpose "devShells";
      checks = transpose "checks";
      formatter = transpose "formatter";
    };
}
