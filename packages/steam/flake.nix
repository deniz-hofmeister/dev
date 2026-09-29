{
  description = "Steam client with the Nixpkgs runtime environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      packages.${system}.default = pkgs.steam;

      apps.${system}.default = {
        type = "app";
        program = "${pkgs.steam}/bin/steam";
        meta.description = "Launch Steam";
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.steam ];
      };
    };
}
