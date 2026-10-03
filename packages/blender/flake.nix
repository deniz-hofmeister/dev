{
  description = "Blender with Cycles CUDA/OptiX, run against the host NVIDIA driver";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Runs Nix-built GL/CUDA programs against the host (non-NixOS) NVIDIA
    # driver: copies the host driver libs into a cache at runtime, so no
    # driver version is pinned at eval time (unlike nixGL).
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

          # CUDA-enabled package set. Must match what the nixos-cuda Hydra
          # builds, or Blender (and its CUDA deps) compile locally.
          pkgsCuda = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              cudaSupport = true;
            };
          };

          # nix-gl-host only puts its glx/cuda/egl dirs on LD_LIBRARY_PATH; the
          # rest of the host driver lands in a lib/ dir reachable solely via
          # those DSOs' RPATH. OptiX is dlopen'ed directly by Cycles, so move
          # libnvoptix into the CUDA set (its own RPATH still finds rtcore).
          # It also copies (not symlinks) libcuda.so and libcuda.so.1, and
          # Cycles and OptiX dlopen different names: two driver instances,
          # OptiX then sees an uninitialised CUDA. Skip the unversioned one.
          nixglhost = nix-gl-host.packages.${system}.default.overrideAttrs (o: {
            postPatch = (o.postPatch or "") + ''
              substituteInPlace src/nixglhost.py \
                --replace-fail '    "libnvoptix\\.so.*$",' "" \
                --replace-fail '"libcuda\\.so.*$",' '"libcuda\\.so\\..*$", "libnvoptix\\.so.*$",'
              # upstream's checkPhase runs `black --check`
              black -q src/nixglhost.py
            '';
          });

          # Needs the nixos-cuda substituter (cache.nixos-cuda.org) in
          # nix.conf; without it this is a multi-hour local build.
          blender = pkgs.writeShellApplication {
            name = "blender";
            text = ''
              # A sourced ROS/other env would otherwise shadow Nix RUNPATHs.
              unset LD_LIBRARY_PATH
              exec ${nixglhost}/bin/nixglhost ${pkgsCuda.blender}/bin/blender "$@"
            '';
          };
        in
        {
          packages.default = blender;

          apps.default = {
            type = "app";
            program = "${blender}/bin/blender";
            meta.description = "Launch Blender";
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
