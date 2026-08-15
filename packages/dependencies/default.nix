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

  # Android SDK. Versions are pinned rather than "latest": the aapt2 override
  # below needs a concrete build-tools path, and a floating compileSdk would
  # silently change what a project builds against on every nixpkgs bump.
  # `nix eval nixpkgs#androidenv.androidPkgs` won't list these — the available
  # versions live in nixpkgs' androidenv/repo.json.
  androidBuildToolsVersion = "36.0.0";
  # AGP resolves the NDK by exact revision and, finding it absent, tries to
  # sdkmanager-install it into the (read-only) store — a hard configure
  # failure. So ship both revisions projects actually ask for: AGP 8.x's
  # built-in default for anything that doesn't pin, and the one React
  # Native / Expo pin in their gradle plugin. 2.7 GiB each.
  androidNdkVersions = [
    "27.0.12077973" # AGP 8.x default
    "27.1.12297006" # React Native 0.76+ / Expo
  ];
  androidNdkVersion = lib.last androidNdkVersions; # what ANDROID_NDK_ROOT points at
  androidComposition = androidenv.composeAndroidPackages {
    cmdLineToolsVersion = "22.0";
    platformToolsVersion = "37.0.1"; # adb, fastboot
    buildToolsVersions = [
      "34.0.0"
      "35.0.0"
      androidBuildToolsVersion
    ];
    platformVersions = [
      "34"
      "35"
      "36"
    ];
    includeNDK = true;
    ndkVersions = androidNdkVersions;
    # AGP resolves the CMake it was pinned against by exact version and fails
    # the configure phase if it is absent. 3.22.1 is what every AGP 8.x asks
    # for by default; 4.1.2 is for projects that opt into a newer one.
    cmakeVersions = [
      "3.22.1"
      "4.1.2"
    ];
    # Emulator wants KVM plus a GUI, system images are ~1 GiB each, and the
    # java sources are only there for IDE navigation — none of it helps a
    # headless build/debug loop against a real device.
    includeEmulator = false;
    includeSystemImages = false;
    includeSources = false;
  };
  androidSdk = androidComposition.androidsdk;
  androidSdkRoot = "${androidSdk}/libexec/android-sdk";

  androidJdk = jdk21; # the default the daemon and everything else runs on

  gradleOpts = [
    # AGP downloads a prebuilt aapt2 from Maven; that binary is not patched for
    # NixOS and dies with "No such file or directory" on the loader. Point the
    # plugin at the SDK's own aapt2 instead. `org.gradle.project.` is Gradle's
    # documented system-property -> project-property bridge, so this one does
    # work from the environment (verified: AGP logs it, then uses it).
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdkRoot}/build-tools/${androidBuildToolsVersion}/aapt2"
  ];

  # Android build/debug env. Everything AGP resolves by absolute path.
  androidHook = ''
    export ANDROID_HOME=${androidSdkRoot}
    export ANDROID_SDK_ROOT=${androidSdkRoot}
    export ANDROID_NDK_ROOT=${androidSdkRoot}/ndk/${androidNdkVersion}
    export JAVA_HOME=${androidJdk.home}
    export GRADLE_OPTS="${lib.concatStringsSep " " gradleOpts}''${GRADLE_OPTS:+ $GRADLE_OPTS}"
    # Gradle toolchain resolution matches on *exact* language version, so a
    # project pinning jvmToolchain(17) (React Native's gradle plugin does) is
    # not satisfied by the 21 above, and Gradle's auto-detection never finds a
    # store JDK. `org.gradle.java.installations.*` cannot be delivered from
    # here: GRADLE_OPTS is ignored for it on both 8.14 and 9.3 (verified with
    # `gradle javaToolchains`). It is read from gradle.properties on both, and
    # from a command-line -D on 9.3 but not 8.14 — neither of which a wrapper
    # env can reach. So the flake cannot select the JDK for a project; what it
    # can do is publish the homes under stable names, and a project opts in
    # with one store-path-independent line in its gradle.properties that keeps
    # working across nixpkgs bumps:
    #   org.gradle.java.installations.fromEnv=JAVA17_HOME
    #   org.gradle.java.installations.auto-download=false
    # The second line matters here: an FHS JDK fetched from foojay cannot exec
    # on NixOS, so leaving it enabled only turns a clear error into a download
    # and a confusing one. `.home`, not the store root — that is where the
    # `release` file Gradle probes lives.
    export JAVA17_HOME=${jdk17.home}
    export JAVA21_HOME=${jdk21.home}
    # The sdk's own bin/ (adb, fastboot, apkanalyzer, sdkmanager, d8/r8) comes
    # from androidPackages; build-tools has no bin/ so apksigner, zipalign,
    # aapt2 and aidl need this. Appended, not prepended: this directory also
    # ships an `lld` that must not shadow the toolchain linker.
    export PATH="$PATH:${androidSdkRoot}/build-tools/${androidBuildToolsVersion}"
    # NDK binaries are deliberately kept off PATH — its clang/ld/llvm-* would
    # shadow the host toolchain. AGP and CMake find them via ANDROID_NDK_ROOT.
  '';

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
    cargo-semver-checks # transforms release gate: prove the API diff vs the published baseline
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

  # Android: compile an APK/AAB and debug it on a connected device.
  # adb/fastboot/apksigner/zipalign/aapt2/lldb-server all come from the SDK
  # itself, so no separate android-tools here — a second adb on PATH would
  # fight the SDK's over the adb server version.
  androidPackages = [
    androidSdk
    # Only the default JDK goes on PATH — a second `java`/`javac` there would
    # resolve by list order. jdk17 stays off PATH and reaches Gradle through
    # installations.paths above; the wrapper text retains it in the closure.
    androidJdk
    gradle
    ninja # AGP's externalNativeBuild generator for CMake projects

    # APK/AAB inspection: decompile, disassemble, split/build bundles
    apktool
    jadx
    bundletool
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

  # Full env for dev shells / claude: editor env plus android and audio
  # runtime wiring. The claude wrapper exports these before exec'ing claude,
  # so every tool it spawns (gradle, adb, cargo) inherits them.
  shellHook = ''
    ${editorHook}
    ${androidHook}
    export PKG_CONFIG_PATH=${alsa-lib.dev}/lib/pkgconfig:$PKG_CONFIG_PATH
    export LD_LIBRARY_PATH=${runtimeLibraryPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
    export ALSA_CONFIG_DIR=${alsa-lib}/share/alsa
    export ALSA_CONFIG_PATH=${alsa-lib}/share/alsa/alsa.conf
    export ALSA_PLUGIN_DIR=${alsaPluginRuntime}/lib/alsa-lib
  '';
in
{
  inherit
    editorPackages
    editorHook
    androidHook
    shellHook
    ;
  claudePackages = editorPackages ++ cliPackages ++ androidPackages;
  packages = editorPackages ++ cliPackages ++ androidPackages ++ libPackages ++ desktopPackages;
}
