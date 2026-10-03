# KiCad

Standalone user-profile installation, following `../steam`. KiCad (with 3D
models) is launched through `nixglhost`, so the PCB editor's accelerated canvas
and the 3D viewer get OpenGL from the host (non-NixOS) NVIDIA driver. The lock
uses the same Nixpkgs and nix-gl-host revisions as the root flake.

```sh
nix profile add path:/home/dev/repos/dev/packages/kicad
kicad
```

Run without installing into the profile:

```sh
nix run path:/home/dev/repos/dev/packages/kicad
```

After editing the flake or updating its lock, update the installed package:

```sh
nix flake update --flake path:/home/dev/repos/dev/packages/kicad
nix profile upgrade kicad
```
