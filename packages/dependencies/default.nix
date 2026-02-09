{ pkgs }:
with pkgs;
let
  cpptools = pkgs.runCommand "vscode-cpptools-extracted" { } ''
    mkdir -p $out/bin
    cp -r ${vscode-extensions.ms-vscode.cpptools}/share/vscode/extensions/ms-vscode.cpptools/debugAdapters/bin/* $out/bin/
    chmod +x $out/bin/*
  '';

  pythonWithTools = python3.withPackages (
    ps: with ps; [
      beautifulsoup4
      debugpy
      lxml
      numpy
      opencv4
      pdfplumber
      pillow
      pypdf
      pytesseract
      pyyaml
      requests
    ]
  );

  alsaPluginRuntime = symlinkJoin {
    name = "alsa-plugin-runtime";
    paths = [
      alsa-plugins
      pipewire
    ];
  };

  alsaPluginDir = "${alsaPluginRuntime}/lib/alsa-lib";
  alsaConfigDir = "${alsa-lib}/share/alsa";
  alsaConfigPath = "${alsaConfigDir}/alsa.conf";
  runtimeLibraryPath = "${spdlog}/lib:${alsa-lib}/lib:${alsa-plugins}/lib:${pipewire}/lib";
  pkgConfigPath = "${openssl.dev}/lib/pkgconfig:${alsa-lib.dev}/lib/pkgconfig";

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
    pythonWithTools
    tesseract
    poppler-utils
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
    xhost
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

    # Web development (Leptos/WASM)
    cargo-leptos
    wasm-bindgen-cli
    trunk
    binaryen

    # Audio libraries
    alsa-lib
    alsa-plugins
    pipewire

    nodePackages.svelte-language-server
    nodePackages.typescript-language-server
    nodePackages.vscode-langservers-extracted
    nodePackages.typescript
  ];

  shellHook = ''
    export OPENSSL_DIR=${openssl.dev}
    export OPENSSL_LIB_DIR=${openssl.out}/lib
    export OPENSSL_INCLUDE_DIR=${openssl.dev}/include
    export PKG_CONFIG_PATH=${pkgConfigPath}:$PKG_CONFIG_PATH
    export LD_LIBRARY_PATH=${runtimeLibraryPath}:$LD_LIBRARY_PATH
    export ALSA_CONFIG_DIR=${alsaConfigDir}
    export ALSA_CONFIG_PATH=${alsaConfigPath}
    export ALSA_PLUGIN_DIR=${alsaPluginDir}
    export spdlog_DIR=${spdlog.dev}/lib/cmake/spdlog
    export fmt_DIR=${fmt.dev}/lib/cmake/fmt
  '';
in
{
  inherit
    alsaConfigDir
    alsaConfigPath
    alsaPluginDir
    packages
    pkgConfigPath
    runtimeLibraryPath
    shellHook
    ;
}
