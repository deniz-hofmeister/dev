# Steam

Standalone user-profile installation.

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

## Hidden playtime

The `steam` launcher hides your hours played in the library: the game page's
play time (and the last-played date Steam shows next to it), the "You've played
for N hours" review prompt, the hover card's "Time played" block, and the
playtime text on shelves. Sorting/grouping by hours played sees every game as
unplayed. It only changes what the client UI displays; Steam still tracks
playtime, and your profile and the store website still show it.

How it works: the launcher creates `~/.local/share/Steam/.cef-enable-remote-debugging`,
so Steam serves the Chrome DevTools protocol on `127.0.0.1:8080`, and runs
`hide-playtime.mjs` alongside Steam to inject `hide-playtime.js` into the
`SharedJSContext` page (re-injecting if Steam reloads its UI). Any local process
can drive the signed-in client through that port while Steam runs.

For the unmodified client, run `nix run path:/home/dev/repos/dev/packages/steam#vanilla`
and delete `~/.local/share/Steam/.cef-enable-remote-debugging` to close the port.

## Spanning two identical monitors

`span-screens` (also installed by the profile package) runs a game and keeps
its window fullscreen across the group of identical monitors, here the two
2560x1440 screens next to the ultrawide, via `_NET_WM_FULLSCREEN_MONITORS`.
It re-applies this within a second whenever the game resizes or moves its
window, e.g. after changing video settings. Baldur's Gate 3 uses it for local
split-screen with one player per screen:

- Steam launch options: `/home/dev/.nix-profile/bin/span-screens %command%`
- In-game Video settings: Display Mode `Windowed`. BG3's own fullscreen only
  offers single-monitor resolutions (it resets anything else at launch), while
  in windowed mode it renders at the window size, so the spanned window gives
  a native 5120x1440 picture instead of a stretched 3440x1440 one.

Set `SPAN_SCREENS_CLASS` to the game's X11 `WM_CLASS` for other games
(default `bg3`). A nested gamescope sized to both monitors would isolate the
game from its own window handling, but on this NVIDIA driver it only renders a
black window.

The flake installs the client launcher and its Linux runtime dependencies.
Steam downloads its client updates and games into writable user storage;
these are not pinned by `flake.lock`.

On NixOS, the host must provide graphics support including
`hardware.graphics.enable32Bit = true` and appropriate audio support.
This machine already enables 32-bit graphics and PipeWire ALSA support.
For Steam controller/VR device permissions, enable
`hardware.steam-hardware.enable = true` in the host configuration if needed.
