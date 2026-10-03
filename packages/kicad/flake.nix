{
  description = "KiCad (with 3D models), run against the host NVIDIA driver";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Runs Nix-built GL programs against the host (non-NixOS) NVIDIA driver:
    # copies the host driver libs into a cache at runtime, so no driver
    # version is pinned at eval time (unlike nixGL).
    nix-gl-host = {
      url = "github:numtide/nix-gl-host";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-gl-host,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      outputsFor =
        system:
        let
          pkgs = import nixpkgs { inherit system; };

          # Same nix-gl-host patch as ../blender: moves libnvoptix into the
          # CUDA set and skips the unversioned libcuda.so copy. KiCad only
          # needs OpenGL, but keeping one patched launcher means both apps
          # see the host driver the same way.
          nixglhost = nix-gl-host.packages.${system}.default.overrideAttrs (o: {
            postPatch = (o.postPatch or "") + ''
              substituteInPlace src/nixglhost.py \
                --replace-fail '    "libnvoptix\\.so.*$",' "" \
                --replace-fail '"libcuda\\.so.*$",' '"libcuda\\.so\\..*$", "libnvoptix\\.so.*$",'
              # upstream's checkPhase runs `black --check`
              black -q src/nixglhost.py
            '';
          });

          # The PCB editor's accelerated canvas and the 3D viewer need OpenGL.
          kicad = pkgs.writeShellApplication {
            name = "kicad";
            text = ''
              # A sourced ROS/other env would otherwise shadow Nix RUNPATHs.
              unset LD_LIBRARY_PATH
              exec ${nixglhost}/bin/nixglhost ${pkgs.kicad}/bin/kicad "$@"
            '';
          };
        in
        {
          packages.default = kicad;

          apps.default = {
            type = "app";
            program = "${kicad}/bin/kicad";
            meta.description = "Launch KiCad";
          };
        };

      perSystem = nixpkgs.lib.genAttrs systems outputsFor;
      transpose = attr: nixpkgs.lib.mapAttrs (_: v: v.${attr}) perSystem;
    in
    {
      packages = transpose "packages";
      apps = transpose "apps";
    };
}
