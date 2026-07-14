{ pkgs }:
with pkgs;
let
  # Default python (3.13) — same interpreter the rest of nixpkgs' tools use,
  # so the closure carries exactly one CPython.
  pythonWithTools = python3.withPackages (
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

  runtimeLibraryPath = "${spdlog}/lib:${alsa-lib}/lib:${alsa-plugins}/lib:${pipewire}/lib";

  # Editor layer: every binary the neovim config resolves on PATH at runtime
  # (LSP servers, formatters, linters, debug adapters, build/test drivers).
  # This is what `nix run .#neovim` ships; keep it minimal.
  editorPackages = [
    # LSP servers
    bash-language-server
    basedpyright
    clang-tools # clangd, clang-format
    cmake-language-server
    dockerfile-language-server
    lemminx
    lua-language-server
    marksman
    nixd
    ruff # LSP + conform ruff_format/ruff_organize_imports
    svelte-language-server
    taplo # LSP + conform toml formatter
    typescript-language-server # bundles its own tsserver (nixpkgs patches it in)
    vscode-langservers-extracted
    yaml-language-server

    # Formatters / linters
    cppcheck
    nixfmt
    prettierd
    stylua
    xmlformat # conform's "xmlformatter" runs the xmlformat binary

    # Debug adapters
    gdb
    lldb
    vscode-extensions.vadimcn.vscode-lldb.adapter # codelldb

    # Build/test drivers used from inside the editor (cmake-tools, neotest, DAP)
    binutils
    cmake # also provides ctest (neotest-ctest)
    gcc
    gnumake
    pkg-config

    # Runtime helpers
    coreutils # clang-tools' bin wrappers call basename; don't rely on ambient PATH
    curl # crates.nvim crates.io requests
    git # gitsigns / fugitive / diffview / neo-tree
    ripgrep # telescope live_grep
    uv # neotest-python venv resolution for uv projects
    xclip # "+ clipboard provider (X11)

    # exepath("python3") for nvim-dap-python / neotest-python: debugpy and
    # pytest must be importable from this interpreter
    pythonWithTools
    # rust-analyzer / cargo / clippy / rustfmt come from the rust-overlay
    # toolchain (flake.nix), which keeps them in lockstep with nightly
  ];

  # Headless CLI tools an agent (or a build) can exec: dev shells + claude.
  cliPackages = [
    awscli2
    bun
    csvkit
    glibc # ldd / getent / iconv
    jq
    nodejs
    openssl
    podman-compose
    poppler-utils
    opentofu # terraform-compatible; terraform itself is BUSL/unfree → never cached
    tesseract
    typescript

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
  ];

  # Libraries with no (useful) executables: dev shells only. The wrappers
  # already retain these in their closures through the env hooks below.
  libPackages = [
    alsa-lib
    alsa-plugins
    fmt
    openssl.dev
    pipewire
    spdlog
  ];

  # Interactive / GUI / desktop-only: dev shells only. Useless in the claude
  # wrapper (an agent can't drive a GUI or an interactive TUI).
  desktopPackages = [
    fzf
    gnumeric
    onlyoffice-desktopeditors
    stow
    tmux
    tmuxPlugins.sensible
    tmuxPlugins.catppuccin
    xdotool
    xhost
    zsh
  ];

  # Build env for compiling from inside the editor (cmake-tools, cargo, :term).
  editorHook = ''
    export OPENSSL_DIR=${openssl.dev}
    export OPENSSL_ROOT_DIR=${openssl.dev}
    export OPENSSL_LIB_DIR=${openssl.out}/lib
    export OPENSSL_INCLUDE_DIR=${openssl.dev}/include
    export PKG_CONFIG_PATH=${openssl.dev}/lib/pkgconfig''${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}
    export spdlog_DIR=${spdlog.dev}/lib/cmake/spdlog
    export fmt_DIR=${fmt.dev}/lib/cmake/fmt
  '';

  # Full env for dev shells / claude: editor env plus audio runtime wiring.
  shellHook = ''
    ${editorHook}
    export PKG_CONFIG_PATH=${alsa-lib.dev}/lib/pkgconfig:$PKG_CONFIG_PATH
    export LD_LIBRARY_PATH=${runtimeLibraryPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
    export ALSA_CONFIG_DIR=${alsa-lib}/share/alsa
    export ALSA_CONFIG_PATH=${alsa-lib}/share/alsa/alsa.conf
    export ALSA_PLUGIN_DIR=${alsaPluginRuntime}/lib/alsa-lib
  '';
in
{
  inherit editorPackages editorHook shellHook;
  claudePackages = editorPackages ++ cliPackages;
  packages = editorPackages ++ cliPackages ++ libPackages ++ desktopPackages;
}
