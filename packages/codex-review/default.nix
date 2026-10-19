# `codex-review`: hands a diff to Codex for an independent, unsandboxed review
# and prints only the final report. Called by the nix-dev Claude plugin's
# codex-review skill (packages/claude-plugin) and runnable on its own via
# `nix run .#codex-review`.
#
# `codex` is the flake's wrapped Codex (same tools and build environment as
# Claude), run via `nix run` on first use rather than referenced by store path,
# so building Claude never builds or downloads Codex. Model, effort and
# permissions are set per call in the script, so ~/.codex/config.toml only
# supplies auth and project trust.
{ pkgs, flake }:
pkgs.writeShellApplication {
  name = "codex-review";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.diffutils
    pkgs.git
    pkgs.gnugrep
    pkgs.gnused
  ];
  text = ''
    codex() { nix run ${flake}#codex -- "$@"; }
  ''
  + builtins.readFile ./codex-review.sh;
}
