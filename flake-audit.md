# Flake audit — verified & implemented (2026-07-13)

Original audit written at b8c7857 (2026-07-10). Each claim was re-verified
against cache.nixos.org, the lock file, and current Claude Code docs before
implementation. Outcome per item:

| # | Original claim | Verdict | Action taken |
|---|----------------|---------|--------------|
| 1 | `nixpkgs-claude` master pin older than `nixpkgs`; deps (nodejs) resolve uncached | Version inversion confirmed (2.1.193 vs 2.1.201 at verification time). The nodejs hazard was obsolete twice over: nodejs from the master pin was cached, and current claude-code is a prebuilt binary with no nodejs dependency at all. | Kept the master pin (day-zero freshness wanted) but grafted only the package definition: `pkgs.callPackage "${nixpkgs-claude}/pkgs/by-name/cl/claude-code/package.nix" { }`. Deps now resolve from cached unstable; second nixpkgs eval gone. |
| 2 | `nixpkgs-neovim` identical rev to `nixpkgs`, pure eval overhead | Confirmed (identical rev + lastModified in lock). | Input deleted; neovim builds from `pkgs`. Flake is down to a single nixpkgs evaluation. Re-add the input if neovim ever needs to be held back. |
| 3 | Cross toolchains "never Hydra-cached"; first `nix develop .#*-musl` after a bump rebuilds cross-GCC | **Wrong.** Both cross-GCC wrappers, both unwrapped compilers, and static openssl all return 200 from cache.nixos.org at the current pin (musl64 cross stdenv is a dependency of Nix's own sandbox shell, so it is effectively always cached). | None. NixOS-side OOM hardening remains optional general robustness, not a flake concern. |
| 4 | 14 LSP servers dead weight in claude closure; "Claude Code cannot drive LSP servers" | Closure facts confirmed (lemminx → headless JRE 21, marksman → dotnet-runtime 9), but the premise is outdated: Claude Code has native LSP support (~v2.0.74+) via plugins. | Inverted the fix: LSP servers stay in `claudePackages`, and `packages/claude-plugin` now generates a plugin (`.lsp.json` + `.mcp.json` + manifest) mapping 16 servers to file extensions. The wrapper loads it via `--plugin-dir` and sets `ENABLE_LSP_TOOL=1`. Verified loaded: `claude plugin list` → `nix-dev@inline ✔`. |
| 5 | terraform BUSL/unfree → never cached, built on every pin bump | Confirmed (404 from cache.nixos.org). | Swapped to `opentofu` (fetched straight from cache). |
| 6 | `rust-bin.nightly.latest` re-downloads ~GB toolchain on every lock update | Confirmed mechanically. | Deliberately kept: latest-always preferred over download cost. |
| 7 | `xclip` + `xsel` both shipped, one suffices | Confirmed (nothing references either by name; X11 session). | Dropped `xsel`, kept `xclip`. `wl-clipboard` not added (X11). |

## Notes

- The `--plugin-dir` plugin is session-only by design; it never touches
  `~/.claude` state. All former user-scope marketplace plugins (`clangd-lsp`,
  `pyright-lsp`, `rust-analyzer-lsp`, `context7`) were uninstalled and
  migrated into the flake plugin: LSP via `.lsp.json`, context7 via
  `.mcp.json` pointing at the nixpkgs `context7-mcp` binary (pinned + cached,
  replaces the upstream plugin's `npx -y @upstash/context7-mcp` runtime
  fetch).
- `nix flake update nixpkgs-claude` remains the only way claude-code should
  move (see input comment); the graft keeps that update cheap.
- Dockerfile/CMakeLists routing is extension-based only; bare `Dockerfile` /
  `CMakeLists.txt` files don't attach to their servers.

## Deliberate non-issues (unchanged from original audit)

- **tesseract overlay**: language selection happens in nixpkgs' wrapper layer, so the engine stays cached; only the wrapper + pytesseract chain rebuild. Sound trade against >1 GB of tessdata.
- **`glibc` in `cliPackages`**: PATH-only exposure in `writeShellApplication` (`ldd`/`getent`/`iconv`), justified by comment.
- **`LD_LIBRARY_PATH` in `shellHook`**: leaks spdlog/alsa/pipewire into everything Claude spawns; accepted risk given the audio use case.
- **`binutils` beside `gcc`**: low risk in PATH-only wrappers.

## Verification

```
nix build --dry-run .#claude .#neovim
```

Should build only: claude-code (uncached leaf, cheap binary repack), the
claude-lsp-plugin, the tesseract wrapper + pytesseract chain, treesitter
grammars, and the two shell wrappers. Anything toolchain-sized appearing
here means the callPackage graft regressed.
