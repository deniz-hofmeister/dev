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

  opensslHook = ''
    export OPENSSL_ROOT_DIR=${openssl.dev}
    export OPENSSL_LIBRARIES=${openssl.out}/lib
    export OPENSSL_INCLUDE_DIR=${openssl.dev}/include
    export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:${openssl.dev}/lib/pkgconfig
  '';

  cpptools = pkgs.runCommand "vscode-cpptools-extracted" { } ''
    mkdir -p $out/bin
    cp -r ${vscode-extensions.ms-vscode.cpptools}/share/vscode/extensions/ms-vscode.cpptools/debugAdapters/bin/* $out/bin/
    chmod +x $out/bin/*
  '';

  pythonWithDebugpy = python310.withPackages (
    ps: with ps; [
      debugpy
    ]
  );

  # Hook to ensure spdlog shared libraries are available
  spdlogHook = ''
    export LD_LIBRARY_PATH=${spdlog}/lib:$LD_LIBRARY_PATH
  '';

  packages = [
    binutils
    black
    cargo-nextest
    ccls
    clang-tools
    cmake
    cpptools
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
    pythonWithDebugpy
    ripgrep
    rustup
    spdlog
    stow
    stylua
    tmux
    tmuxPlugins.sensible
    tmuxPlugins.catppuccin
    vscode-extensions.ms-vscode.cpptools
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
  shellHook = opensslHook + spdlogHook;
}
