# Agent development tools

`nix run .#codex`, `nix run .#claude` and the development shells share the same
headless development packages and build environment. Existing `cx` / `cxd` and
`cl` / `cld` aliases pick these up on their next launch. Versions are pinned by
`flake.lock`.

Run a tool directly in that environment, including from an older session:

```sh
nix develop /home/dev/repos/dev -c clang++ --version
nix develop /home/dev/repos/dev -c python3 -m pytest
nix develop /home/dev/repos/dev -c cargo nextest run
```

| Area | Available tools |
| --- | --- |
| C/C++ | GCC, Clang, GNU binutils, LLVM, LLD, CMake/CTest, Ninja, Meson, Make, Autotools, Bison, Flex, Conan, Bear, ccache |
| C++ analysis and debugging | clangd, clang-format, clang-tidy, Cppcheck, CMake formatter, GDB, LLDB, CodeLLDB, Valgrind, gcovr, lcov, Doxygen, Graphviz |
| Native libraries | Boost, Eigen, fmt, spdlog, OpenSSL, zlib, Catch2, GoogleTest; CMake and pkg-config discovery paths; libclang for bindgen |
| Python | Python 3, pip, uv, venv/virtualenv, build, setuptools, wheel, Cython, pybind11, tox, nox |
| Python quality | Ruff, basedpyright, mypy, Black, isort, Pylint, Bandit, pip-audit, debugpy, py-spy, coverage |
| Python testing | pytest, pytest-asyncio, pytest-cov, pytest-mock, pytest-xdist, Hypothesis |
| Rust | Pinned nightly rustc/Cargo, rust-src, rust-analyzer, rustfmt, Clippy, Miri, matching LLVM tools, nextest |
| Rust analysis | cargo-audit, deny, semver-checks, public-api, machete, udeps, outdated, hack, expand, bloat, binutils |
| Rust testing and performance | cargo-llvm-cov, tarpaulin, fuzz, mutants, flamegraph, watch, edit, sccache |
| Shared utilities | Git/GitHub CLI, ripgrep, jq, pre-commit, ShellCheck, shfmt, hyperfine, strace, patchelf |
| Cloud deployment | AWS CLI, OpenTofu, Modal Python SDK and `modal` CLI |
| Provisioning | Ansible (`ansible`, `ansible-playbook`, `ansible-galaxy`, `ansible-vault`) |

Ansible is shared by every executable wrapper (including Neovim) and every
development shell, including `msrv`. Its version follows `flake.lock`.
From an existing session, use
`nix develop /home/dev/repos/dev -c ansible-playbook --version`.

Android (x86_64 Linux hosts), embedded/probe, WASM/web, document/PDF/OCR, and
Python data-processing packages are available to Codex, Claude and the
development shells. The OpenAI documentation and Context7 MCP servers are
configured by the Codex launcher. Language-server executables are on PATH;
Claude additionally gets them through its native LSP plugin.

Use project-specific virtual environments and dependency manifests for Python
application dependencies. On NixOS, select the packaged interpreter explicitly:
`uv venv --python "$(command -v python3)"`. The Nix-provided Python includes the
shared tools and data libraries; a new isolated venv needs its own dependencies.

Modal is included in that shared Python environment, so both `import modal`
and the `modal` command work in Claude, Codex, and the development shells.
Its version follows the existing nixpkgs lock. Authenticate once outside the
Nix store; credentials are not included in the flake:

```sh
nix develop -c modal --version
nix develop -c modal token new
nix develop -c python3 -c 'import modal; print(modal.__version__)'
```

Existing agent sessions keep their old environment; relaunch them or use
`nix develop -c …` to access the updated toolset immediately. Project virtual
environments and deployed worker images still declare their own Modal dependency.

The Rust toolchain already includes musl x86_64/aarch64, ARM Cortex-M, RISC-V,
and `wasm32-unknown-unknown` targets. Use `nix develop .#x86_64-musl` or
`nix develop .#aarch64-musl` for the matching cross-linker and static OpenSSL.
Use `nix develop .#msrv` for Rust 1.86.0. Miri's first actual run builds a cached
sysroot and can require registry access. Hardware probes and profiling tools
still depend on the host's device and kernel permissions.

Build and verify:

```sh
nix build .#codex .#codex-tools .#claude .#neovim --no-link
nix develop -c bash test/toolchain-smoke.sh
nix flake check --no-build
```

The smoke check resolves required commands, builds and tests against the native
libraries with GCC and Clang, runs Valgrind and clang-tidy, exercises Python
property/async/mock tests and coverage, and runs Rust Clippy, nextest, coverage,
and WASM/embedded compilation in temporary projects without registry downloads.

Runtime smoke tests were run on x86_64 Linux, with a separate successful
`cargo miri test`. Agent packages also evaluate for aarch64 Linux, but full
`nix flake check --all-systems` still encounters the pre-existing x86-only
OnlyOffice dependency in the desktop development shell.

The shared packages and hooks live in `packages/dependencies/default.nix`;
launchers and the Rust toolchain live in `flake.nix`. To add a native CLI tool
for Codex, Claude and the development shells, extend `developmentPackages` there.
