{
  description = "Development environment with Neovim";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      flake-utils,
      rust-overlay,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgsUnstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };

        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            rust-overlay.overlays.default
            (final: prev: { neovim-unwrapped = pkgsUnstable.neovim-unwrapped; })
            (final: prev: { myNeovim = import ./packages/neovim { pkgs = final; }; })
          ];
        };

        # Cross-compilation package sets
        pkgsCrossAarch64Musl = pkgs.pkgsCross.aarch64-multiplatform-musl;
        pkgsCrossMusl64 = pkgs.pkgsCross.musl64;

        deps = import ./packages/dependencies { inherit pkgs; };

        # Rust toolchain with cross-compilation targets
        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          targets = [
            "x86_64-unknown-linux-musl"
            "aarch64-unknown-linux-musl"
          ];
        };

        # Common Rust packages for all shells
        rustPackages = [
          rustToolchain
          pkgs.cargo-nextest
          pkgs.rust-analyzer
        ];

        # OpenSSL setup helper
        mkOpenSSLEnv = openssl: ''
          export OPENSSL_DIR=${openssl.dev}
          export OPENSSL_LIB_DIR=${openssl.out}/lib
          export OPENSSL_INCLUDE_DIR=${openssl.dev}/include
          export OPENSSL_STATIC=1
          export PKG_CONFIG_PATH=${openssl.dev}/lib/pkgconfig:$PKG_CONFIG_PATH
        '';
      in
      {
        packages = {
          default = pkgs.myNeovim;
          neovim = pkgs.myNeovim;
        };

        devShells = {
          # Native x86_64 development (glibc, dynamic)
          default = pkgs.mkShell {
            packages = deps.packages ++ [ pkgs.myNeovim ] ++ rustPackages;
            shellHook = deps.shellHook;
          };

          # x86_64 musl static builds
          x86_64-musl = pkgs.mkShell {
            packages = rustPackages ++ [
              pkgsCrossMusl64.stdenv.cc
              pkgs.myNeovim
            ];

            CARGO_BUILD_TARGET = "x86_64-unknown-linux-musl";
            CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER = "${pkgsCrossMusl64.stdenv.cc}/bin/x86_64-unknown-linux-musl-cc";
            CC_x86_64_unknown_linux_musl = "${pkgsCrossMusl64.stdenv.cc}/bin/x86_64-unknown-linux-musl-cc";

            shellHook = mkOpenSSLEnv pkgsCrossMusl64.pkgsStatic.openssl;
          };

          # aarch64 musl static builds (cross-compilation)
          aarch64-musl = pkgs.mkShell {
            packages = rustPackages ++ [
              pkgsCrossAarch64Musl.stdenv.cc
              pkgs.myNeovim
            ];

            CARGO_BUILD_TARGET = "aarch64-unknown-linux-musl";
            CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_LINKER = "${pkgsCrossAarch64Musl.stdenv.cc}/bin/aarch64-unknown-linux-musl-cc";
            CC_aarch64_unknown_linux_musl = "${pkgsCrossAarch64Musl.stdenv.cc}/bin/aarch64-unknown-linux-musl-cc";

            shellHook = mkOpenSSLEnv pkgsCrossAarch64Musl.pkgsStatic.openssl;
          };
        };

        apps.default = {
          type = "app";
          program = "${pkgs.myNeovim}/bin/nvim";
        };
      }
    );
}
