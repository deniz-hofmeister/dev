{
  description = "Development environment with Neovim";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
    opencode.url = "github:anomalyco/opencode";
    nix-ai-tools.url = "github:numtide/nix-ai-tools";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      flake-utils,
      rust-overlay,
      opencode,
      nix-ai-tools,
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
          extensions = [
            "rust-src"
            "rust-analyzer"
            "rustfmt"
            "clippy"
          ];
          targets = [
            "x86_64-unknown-linux-musl"
            "aarch64-unknown-linux-musl"
            "thumbv8m.main-none-eabihf"
          ];
        };

        # Common Rust packages for all shells
        rustPackages = [
          rustToolchain
          pkgs.cargo-nextest
        ];

        # OpenSSL setup helper
        mkOpenSSLEnv = opensslPkg: ''
          export OPENSSL_DIR=${opensslPkg.dev}
          export OPENSSL_LIB_DIR=${opensslPkg.out}/lib
          export OPENSSL_INCLUDE_DIR=${opensslPkg.dev}/include
          export OPENSSL_STATIC=1
          export PKG_CONFIG_PATH=${opensslPkg.dev}/lib/pkgconfig:$PKG_CONFIG_PATH
        '';

        # Wrapped Neovim with all LSPs and tools in PATH
        neovim-with-lsps = pkgs.writeShellApplication {
          name = "nvim";
          runtimeInputs = deps.packages ++ rustPackages ++ [ pkgs.myNeovim ];
          text = ''
            # Environment variables for build tools
            export OPENSSL_DIR=${pkgs.openssl.dev}
            export OPENSSL_LIB_DIR=${pkgs.openssl.out}/lib
            export OPENSSL_INCLUDE_DIR=${pkgs.openssl.dev}/include
            export PKG_CONFIG_PATH=${pkgs.openssl.dev}/lib/pkgconfig:''${PKG_CONFIG_PATH:-}
            export LD_LIBRARY_PATH=${pkgs.spdlog}/lib:''${LD_LIBRARY_PATH:-}
            export spdlog_DIR=${pkgs.spdlog.dev}/lib/cmake/spdlog
            export fmt_DIR=${pkgs.fmt.dev}/lib/cmake/fmt

            exec ${pkgs.myNeovim}/bin/nvim "$@"
          '';
        };

        # Wrapped OpenCode with all LSPs and tools in PATH
        opencode-with-lsps = pkgs.writeShellApplication {
          name = "opencode";
          runtimeInputs = deps.packages ++ rustPackages;
          text = ''
            # Environment variables for build tools
            export OPENSSL_DIR=${pkgs.openssl.dev}
            export OPENSSL_LIB_DIR=${pkgs.openssl.out}/lib
            export OPENSSL_INCLUDE_DIR=${pkgs.openssl.dev}/include
            export PKG_CONFIG_PATH=${pkgs.openssl.dev}/lib/pkgconfig:''${PKG_CONFIG_PATH:-}
            export LD_LIBRARY_PATH=${pkgs.spdlog}/lib:''${LD_LIBRARY_PATH:-}
            export spdlog_DIR=${pkgs.spdlog.dev}/lib/cmake/spdlog
            export fmt_DIR=${pkgs.fmt.dev}/lib/cmake/fmt

            exec ${opencode.packages.${system}.default}/bin/opencode "$@"
          '';
        };

        # Wrapped crush with all LSPs and tools in PATH
        crush-with-lsps = pkgs.writeShellApplication {
          name = "crush";
          runtimeInputs = deps.packages ++ rustPackages;
          text = ''
            # Environment variables for build tools
            export OPENSSL_DIR=${pkgs.openssl.dev}
            export OPENSSL_LIB_DIR=${pkgs.openssl.out}/lib
            export OPENSSL_INCLUDE_DIR=${pkgs.openssl.dev}/include
            export PKG_CONFIG_PATH=${pkgs.openssl.dev}/lib/pkgconfig:''${PKG_CONFIG_PATH:-}
            export LD_LIBRARY_PATH=${pkgs.spdlog}/lib:''${LD_LIBRARY_PATH:-}
            export spdlog_DIR=${pkgs.spdlog.dev}/lib/cmake/spdlog
            export fmt_DIR=${pkgs.fmt.dev}/lib/cmake/fmt

            exec ${nix-ai-tools.packages.${system}.crush}/bin/crush "$@"
          '';
        };

        # Wrapped Claude Code with all LSPs and tools in PATH
        claude-with-deps = pkgs.writeShellApplication {
          name = "claude";
          runtimeInputs = deps.packages ++ rustPackages;
          text = ''
            # Environment variables for build tools
            export OPENSSL_DIR=${pkgs.openssl.dev}
            export OPENSSL_LIB_DIR=${pkgs.openssl.out}/lib
            export OPENSSL_INCLUDE_DIR=${pkgs.openssl.dev}/include
            export PKG_CONFIG_PATH=${pkgs.openssl.dev}/lib/pkgconfig:''${PKG_CONFIG_PATH:-}
            export LD_LIBRARY_PATH=${pkgs.spdlog}/lib:''${LD_LIBRARY_PATH:-}
            export spdlog_DIR=${pkgs.spdlog.dev}/lib/cmake/spdlog
            export fmt_DIR=${pkgs.fmt.dev}/lib/cmake/fmt

            exec ${pkgsUnstable.claude-code}/bin/claude "$@"
          '';
        };
      in
      {
        packages = {
          default = neovim-with-lsps;
          neovim = neovim-with-lsps;
          opencode = opencode-with-lsps;
          crush = crush-with-lsps;
          claude = claude-with-deps;
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

        apps = {
          default = {
            type = "app";
            program = "${neovim-with-lsps}/bin/nvim";
          };
          opencode = {
            type = "app";
            program = "${opencode-with-lsps}/bin/opencode";
          };
          crush = {
            type = "app";
            program = "${crush-with-lsps}/bin/crush";
          };
          claude = {
            type = "app";
            program = "${claude-with-deps}/bin/claude";
          };
        };
      }
    );
}
