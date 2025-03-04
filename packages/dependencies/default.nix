{ pkgs }:
with pkgs;
let
  # Setup shell hook to configure paths for pkg-config
  opensslEnv = pkgs.symlinkJoin {
    name = "openssl-with-paths";
    paths = [
      openssl
      openssl.dev
      openssl.out
    ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/openssl \
        --set PKG_CONFIG_PATH "${openssl.dev}/lib/pkgconfig"
    '';
  };

  # Create shell hook to set OpenSSL environment variables
  opensslHook = ''
    export OPENSSL_ROOT_DIR=${openssl.dev}
    export OPENSSL_LIBRARIES=${openssl.out}/lib
    export OPENSSL_INCLUDE_DIR=${openssl.dev}/include
    export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:${openssl.dev}/lib/pkgconfig
  '';

  packages = [
    binutils
    black
    cargo-nextest
    ccls
    clang-tools
    cmake
    curl
    fzf
    gcc
    gdb
    glibc
    gnumake
    isort
    lldb
    nixfmt-rfc-style
    opensslEnv
    pkg-config
    podman-compose
    prettierd
    pyright
    python313
    python313Packages.debugpy
    ripgrep
    rustup
    spdlog
    stow
    stylua
    tmux
    tmuxPlugins.sensible
    tmuxPlugins.catppuccin
    vscode-extensions.ms-vscode.cpptools
    cpptools # Add the extracted binaries to the PATH
    xclip
    xdotool
    xorg.xhost
    xsel
    zsh
    nodejs
    nodePackages.svelte-language-server
    nodePackages.typescript-language-server
    nodePackages.vscode-langservers-extracted # html, css, json, eslint
    nodePackages.typescript
  ];
in
{
  inherit packages;
  shellHook = opensslHook;
}
