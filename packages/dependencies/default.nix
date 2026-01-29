{ pkgs }:
with pkgs;
let
  cpptools = pkgs.runCommand "vscode-cpptools-extracted" { } ''
    mkdir -p $out/bin
    cp -r ${vscode-extensions.ms-vscode.cpptools}/share/vscode/extensions/ms-vscode.cpptools/debugAdapters/bin/* $out/bin/
    chmod +x $out/bin/*
  '';

  pythonWithDebugpy = python310.withPackages (ps: with ps; [ debugpy ]);

  packages = [
    binutils
    black
    clang-tools
    cmake
    cpptools
    curl
    fmt
    fzf
    gcc
    jq
    gdb
    glibc
    gnumake
    isort
    lldb
    nixfmt
    openssl
    openssl.dev
    pkg-config
    podman-compose
    prettierd
    pyright
    pythonWithDebugpy
    ripgrep
    rust-analyzer
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
    xmlformat
    zsh
    nodejs

    # Embedded development / probe-rs ecosystem
    probe-rs-tools
    elf2uf2-rs
    picotool
    flip-link
    usbutils
    stlink

    nodePackages.svelte-language-server
    nodePackages.typescript-language-server
    nodePackages.vscode-langservers-extracted
    nodePackages.typescript
  ];

  shellHook = ''
    export OPENSSL_DIR=${openssl.dev}
    export OPENSSL_LIB_DIR=${openssl.out}/lib
    export OPENSSL_INCLUDE_DIR=${openssl.dev}/include
    export PKG_CONFIG_PATH=${openssl.dev}/lib/pkgconfig:$PKG_CONFIG_PATH
    export LD_LIBRARY_PATH=${spdlog}/lib:$LD_LIBRARY_PATH
    export spdlog_DIR=${spdlog.dev}/lib/cmake/spdlog
    export fmt_DIR=${fmt.dev}/lib/cmake/fmt
  '';
in
{
  inherit packages shellHook;
}
