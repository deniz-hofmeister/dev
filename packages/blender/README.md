# Blender

Standalone user-profile installation, following `../steam`. Blender is built
with Cycles CUDA/OptiX kernels and launched through `nixglhost`, so it uses the
host (non-NixOS) NVIDIA driver. The lock uses the same Nixpkgs and nix-gl-host
revisions as the root flake.

Add the nixos-cuda substituter (`cache.nixos-cuda.org`) to `nix.conf` first;
without it the CUDA build takes hours.

```sh
nix profile add path:/home/dev/repos/dev/packages/blender
blender
```

Run without installing into the profile:

```sh
nix run path:/home/dev/repos/dev/packages/blender
```

After editing the flake or updating its lock, update the installed package:

```sh
nix flake update --flake path:/home/dev/repos/dev/packages/blender
nix profile upgrade blender
```
