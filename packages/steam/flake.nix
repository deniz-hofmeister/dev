{
  description = "Steam client with the Nixpkgs runtime environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # Launches Steam with CEF remote debugging (127.0.0.1:8080) and keeps
      # hide-playtime.js injected so the library shows no hours played.
      launcher = pkgs.writeShellApplication {
        name = "steam";
        text = ''
          mkdir -p "$HOME/.local/share/Steam"
          touch "$HOME/.local/share/Steam/.cef-enable-remote-debugging"
          ${pkgs.nodejs-slim}/bin/node ${./hide-playtime.mjs} ${./hide-playtime.js} &
          injector=$!
          trap 'kill "$injector" 2>/dev/null' EXIT
          ${pkgs.steam}/bin/steam "$@"
        '';
      };

      # Steam launch option `span-screens %command%`: keeps the game's window
      # fullscreen across the identical monitors.
      span-screens = pkgs.writers.writePython3Bin "span-screens" {
        libraries = [ pkgs.python3Packages.python-xlib ];
        doCheck = false;
      } (builtins.readFile ./span-screens.py);

      steam = pkgs.symlinkJoin {
        name = "steam";
        paths = [
          launcher
          span-screens
          pkgs.steam
        ];
        meta.mainProgram = "steam";
      };
    in
    {
      packages.${system} = {
        default = steam;
        inherit span-screens;
        vanilla = pkgs.steam;
      };

      apps.${system}.default = {
        type = "app";
        program = "${steam}/bin/steam";
        meta.description = "Launch Steam with hours played hidden";
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [ steam ];
      };
    };
}
