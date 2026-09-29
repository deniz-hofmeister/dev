# Steam

Standalone user-profile installation, following `../wot`.
The initial lock uses the same Nixpkgs revision as that flake.

```sh
nix profile add path:/home/dev/repos/dev/packages/steam
steam
```

Run without installing into the profile:

```sh
nix run path:/home/dev/repos/dev/packages/steam
```

After editing the flake or updating its lock, update the installed package:

```sh
nix flake update --flake path:/home/dev/repos/dev/packages/steam
nix profile upgrade steam
```

The flake installs the client launcher and its Linux runtime dependencies.
Steam downloads its client updates and games into writable user storage;
these are not pinned by `flake.lock`.

On NixOS, the host must provide graphics support including
`hardware.graphics.enable32Bit = true` and appropriate audio support.
This machine already enables 32-bit graphics and PipeWire ALSA support.
For Steam controller/VR device permissions, enable
`hardware.steam-hardware.enable = true` in the host configuration if needed.
