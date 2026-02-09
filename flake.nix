{
  description = "Development environment with Neovim";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
    opencode.url = "github:anomalyco/opencode/v1.1.53";
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

        # OpenSSL setup helper
        mkOpenSSLEnv = opensslPkg: ''
          export OPENSSL_DIR=${opensslPkg.dev}
          export OPENSSL_LIB_DIR=${opensslPkg.out}/lib
          export OPENSSL_INCLUDE_DIR=${opensslPkg.dev}/include
          export OPENSSL_STATIC=1
          export PKG_CONFIG_PATH=${opensslPkg.dev}/lib/pkgconfig:$PKG_CONFIG_PATH
        '';

        # Custom OpenCode theme to preserve terminal transparency
        opencodeThemeFile = pkgs.writeText "catppuccin-macchiato-transparent.json" ''
          {
            "$schema": "https://opencode.ai/theme.json",
            "defs": {
              "macRosewater": "#f4dbd6",
              "macFlamingo": "#f0c6c6",
              "macPink": "#f5bde6",
              "macMauve": "#c6a0f6",
              "macRed": "#ed8796",
              "macMaroon": "#ee99a0",
              "macPeach": "#f5a97f",
              "macYellow": "#eed49f",
              "macGreen": "#a6da95",
              "macTeal": "#8bd5ca",
              "macSky": "#91d7e3",
              "macSapphire": "#7dc4e4",
              "macBlue": "#8aadf4",
              "macLavender": "#b7bdf8",
              "macText": "#cad3f5",
              "macSubtext1": "#b8c0e0",
              "macSubtext0": "#a5adcb",
              "macOverlay2": "#939ab7",
              "macOverlay1": "#8087a2",
              "macOverlay0": "#6e738d",
              "macSurface2": "#5b6078",
              "macSurface1": "#494d64",
              "macSurface0": "#363a4f",
              "macBase": "#24273a",
              "macMantle": "#1e2030",
              "macCrust": "#181926"
            },
            "theme": {
              "primary": {
                "dark": "macBlue",
                "light": "macBlue"
              },
              "secondary": {
                "dark": "macMauve",
                "light": "macMauve"
              },
              "accent": {
                "dark": "macPink",
                "light": "macPink"
              },
              "error": {
                "dark": "macRed",
                "light": "macRed"
              },
              "warning": {
                "dark": "macYellow",
                "light": "macYellow"
              },
              "success": {
                "dark": "macGreen",
                "light": "macGreen"
              },
              "info": {
                "dark": "macTeal",
                "light": "macTeal"
              },
              "text": {
                "dark": "macText",
                "light": "macText"
              },
              "textMuted": {
                "dark": "macSubtext1",
                "light": "macSubtext1"
              },
              "background": {
                "dark": "none",
                "light": "none"
              },
              "backgroundPanel": {
                "dark": "none",
                "light": "none"
              },
              "backgroundElement": {
                "dark": "none",
                "light": "none"
              },
              "border": {
                "dark": "macSurface0",
                "light": "macSurface0"
              },
              "borderActive": {
                "dark": "macSurface1",
                "light": "macSurface1"
              },
              "borderSubtle": {
                "dark": "macSurface2",
                "light": "macSurface2"
              },
              "diffAdded": {
                "dark": "macGreen",
                "light": "macGreen"
              },
              "diffRemoved": {
                "dark": "macRed",
                "light": "macRed"
              },
              "diffContext": {
                "dark": "macOverlay2",
                "light": "macOverlay2"
              },
              "diffHunkHeader": {
                "dark": "macPeach",
                "light": "macPeach"
              },
              "diffHighlightAdded": {
                "dark": "macGreen",
                "light": "macGreen"
              },
              "diffHighlightRemoved": {
                "dark": "macRed",
                "light": "macRed"
              },
              "diffAddedBg": {
                "dark": "#29342b",
                "light": "#29342b"
              },
              "diffRemovedBg": {
                "dark": "#3a2a31",
                "light": "#3a2a31"
              },
              "diffContextBg": {
                "dark": "macMantle",
                "light": "macMantle"
              },
              "diffLineNumber": {
                "dark": "macSurface1",
                "light": "macSurface1"
              },
              "diffAddedLineNumberBg": {
                "dark": "#223025",
                "light": "#223025"
              },
              "diffRemovedLineNumberBg": {
                "dark": "#2f242b",
                "light": "#2f242b"
              },
              "markdownText": {
                "dark": "macText",
                "light": "macText"
              },
              "markdownHeading": {
                "dark": "macMauve",
                "light": "macMauve"
              },
              "markdownLink": {
                "dark": "macBlue",
                "light": "macBlue"
              },
              "markdownLinkText": {
                "dark": "macSky",
                "light": "macSky"
              },
              "markdownCode": {
                "dark": "macGreen",
                "light": "macGreen"
              },
              "markdownBlockQuote": {
                "dark": "macYellow",
                "light": "macYellow"
              },
              "markdownEmph": {
                "dark": "macYellow",
                "light": "macYellow"
              },
              "markdownStrong": {
                "dark": "macPeach",
                "light": "macPeach"
              },
              "markdownHorizontalRule": {
                "dark": "macSubtext0",
                "light": "macSubtext0"
              },
              "markdownListItem": {
                "dark": "macBlue",
                "light": "macBlue"
              },
              "markdownListEnumeration": {
                "dark": "macSky",
                "light": "macSky"
              },
              "markdownImage": {
                "dark": "macBlue",
                "light": "macBlue"
              },
              "markdownImageText": {
                "dark": "macSky",
                "light": "macSky"
              },
              "markdownCodeBlock": {
                "dark": "macText",
                "light": "macText"
              },
              "syntaxComment": {
                "dark": "macOverlay2",
                "light": "macOverlay2"
              },
              "syntaxKeyword": {
                "dark": "macMauve",
                "light": "macMauve"
              },
              "syntaxFunction": {
                "dark": "macBlue",
                "light": "macBlue"
              },
              "syntaxVariable": {
                "dark": "macRed",
                "light": "macRed"
              },
              "syntaxString": {
                "dark": "macGreen",
                "light": "macGreen"
              },
              "syntaxNumber": {
                "dark": "macPeach",
                "light": "macPeach"
              },
              "syntaxType": {
                "dark": "macYellow",
                "light": "macYellow"
              },
              "syntaxOperator": {
                "dark": "macSky",
                "light": "macSky"
              },
              "syntaxPunctuation": {
                "dark": "macText",
                "light": "macText"
              }
            }
          }
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

            THEME_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/opencode/themes"
            mkdir -p "$THEME_DIR"
            install -m 0644 ${opencodeThemeFile} "$THEME_DIR/catppuccin-macchiato-transparent.json"

            OPENCODE_THEME="''${OPENCODE_THEME:-catppuccin-macchiato-transparent}"
            export OPENCODE_CONFIG_CONTENT="{\"theme\":\"$OPENCODE_THEME\"}"

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

            exec ${pkgs.claude-code}/bin/claude "$@"
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
