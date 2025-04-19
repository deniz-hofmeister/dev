{
  description = "My own Neovim flake";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs";
    };
    nixpkgs-unstable = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgsUnstable = import nixpkgs-unstable {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };
        
        overlayFlakeInputs = prev: final: {
          neovim-unwrapped = pkgsUnstable.neovim-unwrapped;
        };

        overlayNeovim = prev: final: {
          myNeovim = import ./packages/neovim {
            pkgs = final;
          };
        };

        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
          overlays = [
            overlayFlakeInputs
            overlayNeovim
          ];
        };

        deps = import ./packages/dependencies { inherit pkgs; };

        # Create a zshrc that sets up environment variables
        customZshrc = pkgs.writeText "zshrc" ''
          # Set OpenSSL environment variables - this runs for every zsh instance
          export OPENSSL_ROOT_DIR=${pkgs.openssl.dev}
          export OPENSSL_LIBRARIES=${pkgs.openssl.out}/lib
          export OPENSSL_INCLUDE_DIR=${pkgs.openssl.dev}/include
          export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:${pkgs.openssl.dev}/lib/pkgconfig
          
          # Add host system libraries to search paths
          export NIX_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$NIX_LIBRARY_PATH
          export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH

          # Source user's zshrc if it exists
          if [[ -f ~/.zshrc ]]; then
            source ~/.zshrc
          fi
        '';

        myZsh = pkgs.symlinkJoin {
          name = "zsh-with-dependencies";
          paths = [ pkgs.zsh ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/zsh \
              --prefix PATH : ${pkgs.lib.makeBinPath deps.packages} \
              --add-flags "-i" \
              --set ZDOTDIR ${
                pkgs.stdenv.mkDerivation {
                  name = "zsh-dotdir";
                  phases = [ "installPhase" ];
                  installPhase = ''
                    mkdir -p $out
                    cp ${customZshrc} $out/.zshrc
                  '';
                }
              }
          '';
        };
      in
      {
        packages = {
          default = pkgs.myNeovim;
          zsh = myZsh;
        };
        apps = {
          neovim = {
            type = "app";
            program = "${pkgs.myNeovim}/bin/nvim";
          };
          zsh = {
            type = "app";
            program = "${myZsh}/bin/zsh";
          };
        };
      }
    );
}
