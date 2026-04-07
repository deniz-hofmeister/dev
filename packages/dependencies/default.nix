{ pkgs }:
with pkgs;
let
  cpptools = pkgs.runCommand "vscode-cpptools-extracted" { } ''
    mkdir -p $out/bin
    cp -r ${vscode-extensions.ms-vscode.cpptools}/share/vscode/extensions/ms-vscode.cpptools/debugAdapters/bin/* $out/bin/
    chmod +x $out/bin/*
  '';

  pythonWithTools = python312.withPackages (
    ps: with ps; [
      beautifulsoup4
      debugpy
      httpx
      lxml
      matplotlib
      numpy
      odfpy
      opencv4
      openpyxl
      pandas
      pdfplumber
      pillow
      pip
      pydantic
      pytest
      pyxlsb
      pypdf
      pytesseract
      pyyaml
      requests
      scipy
      xlrd
      xlsxwriter
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
    bash-language-server
    binutils
    black
    bun
    clang-tools
    cmake
    cmake-language-server
    cpptools
    curl
    dockerfile-language-server
    fmt
    fzf
    gcc
    jq
    gdb
    glibc
    gnumake
    isort
    lemminx
    lldb
    marksman
    nixfmt
    openssl
    openssl.dev
    pkg-config
    podman-compose
    prettierd
    pyright
    ruff
    pythonWithTools
    uv
    csvkit
    tesseract
    poppler-utils
    gnumeric
    onlyoffice-desktopeditors
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
    yaml-language-server
    awscli2
    terraform
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

    svelte-language-server
    typescript-language-server
    vscode-langservers-extracted
    typescript
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
