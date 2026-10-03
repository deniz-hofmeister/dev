# `codex-review`: hands a diff to Codex for an independent, unsandboxed review
# and prints only the final report. Called by the nix-dev Claude plugin's
# codex-review skill (packages/claude-plugin) and runnable on its own via
# `nix run .#codex-review`.
#
# `codex` is the flake's wrapped Codex (same tools and build environment as
# Claude); model, effort and permissions are set per call in the script, so
# ~/.codex/config.toml only supplies auth and project trust.
{ pkgs, codex }:
pkgs.writeShellApplication {
  name = "codex-review";
  runtimeInputs = [
    codex
    pkgs.coreutils
    pkgs.diffutils
    pkgs.git
    pkgs.gnugrep
    pkgs.gnused
  ];
  text = builtins.readFile ./codex-review.sh;
}
