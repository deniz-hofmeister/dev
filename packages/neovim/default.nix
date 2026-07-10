{ pkgs }:
# Bare wrapped neovim: config + plugins only. PATH (LSPs, formatters,
# debuggers) and build env vars are layered on top in flake.nix, so editing
# the tool set never rebuilds this and vice versa.
pkgs.wrapNeovim pkgs.neovim-unwrapped {
  configure = {
    customRC = import ./config;
    packages.all.start = import ./plugins { inherit pkgs; };
  };
}
