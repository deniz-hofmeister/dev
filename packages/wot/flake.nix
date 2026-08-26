{
  description = "World of Tanks via umu-launcher + GE-Proton (Wargaming Game Center), Lutris included";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      proton = pkgs.proton-ge-bin.steamcompattool;

      # Shared env for every umu invocation. umu-run creates and maintains the
      # prefix itself; GE-Proton ships DXVK, VKD3D-Proton, fsync and font fixes,
      # so no winetricks bootstrap is needed.
      env = ''
        export WINEPREFIX="''${WOT_PREFIX:-$HOME/Games/world-of-tanks}"
        export GAMEID=umu-default
        export PROTONPATH=${proton}
        export STORE=none
        export WINEDLLOVERRIDES="winemenubuilder.exe=d"
        export __GL_SHADER_DISK_CACHE=1
        export __GL_SHADER_DISK_CACHE_PATH="$WINEPREFIX/nv-cache"
        mkdir -p "$WINEPREFIX" "$__GL_SHADER_DISK_CACHE_PATH"
      '';

      mkTool = name: text:
        pkgs.writeShellApplication {
          inherit name text;
          runtimeInputs = with pkgs; [ umu-launcher curl gamemode ];
        };

      wgcCandidates = ''
        wgc=""
        for c in \
          "$WINEPREFIX/drive_c/ProgramData/Wargaming.net/GameCenter/wgc.exe" \
          "$WINEPREFIX/drive_c/Program Files/Wargaming.net/GameCenter/wgc.exe"; do
          [ -f "$c" ] && { wgc="$c"; break; }
        done
        [ -n "$wgc" ] || wgc="$(find "$WINEPREFIX/drive_c" -name wgc.exe -print -quit 2>/dev/null || true)"
      '';

      # Keep mods in sync with the installed game version: fetch the latest
      # XVM nightly (markers, sixth-sense timer, hit/damage log, minimap
      # extras) if missing for the current version, and re-apply the AMX 30 B
      # remodel. Idempotent; wot-play runs this automatically before launch.
      wotSync = pkgs.writeShellApplication {
        name = "wot-sync";
        runtimeInputs = with pkgs; [ curl unzip python3 ];
        text = ''
          ${env}
          game=""
          for g in "$WINEPREFIX"/drive_c/Games/World_of_Tanks*; do
            [ -d "$g/res_mods" ] && { game="$g"; break; }
          done
          [ -n "$game" ] || { echo "game not installed yet — skipping mod sync" >&2; exit 0; }
          ver="$(find "$game/res_mods" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' \
            | grep -E '^[0-9.]+$' | sort -V | tail -n1)"

          if ! ls "$game/mods/$ver"/com.modxvm.* >/dev/null 2>&1; then
            url="$(curl -sL https://nightly.modxvm.com/ \
              | grep -oE 'https://nightly\.modxvm\.com/download/master/xvm_[^"]+\.zip' | head -n1)"
            [ -n "$url" ] || { echo "could not find XVM nightly download link" >&2; exit 1; }
            echo "installing XVM: $url"
            tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
            curl -sL --fail -o "$tmp/xvm.zip" "$url"
            unzip -qo "$tmp/xvm.zip" 'wg/*' -d "$tmp"
            chmod -R u+rwX "$tmp/wg"
            xvmver="$(find "$tmp/wg/mods" -mindepth 1 -maxdepth 1 -printf '%f\n' | head -n1)"
            [ "$xvmver" = "$ver" ] || echo "warning: XVM built for $xvmver, game is $ver" >&2
            cp -r --no-preserve=mode "$tmp/wg/mods/." "$game/mods/"
            cp -r --no-preserve=mode "$tmp/wg/res_mods/." "$game/res_mods/"
          fi

          python3 ${./remodel-amx30.py}
        '';
      };

      scripts = {
        wot-sync = wotSync;

        # Create the prefix without running anything (optional — install does it too).
        wot-setup = mkTool "wot-setup" ''
          ${env}
          umu-run createprefix
          echo "Prefix ready: $WINEPREFIX"
        '';

        # Install Wargaming Game Center. Downloads the official web installer
        # for $WOT_REGION (eu|na|asia, default eu) unless an .exe path is given.
        # /SP- /SILENT: unattended install, same flags Lutris' installer uses.
        wot-install = mkTool "wot-install" ''
          ${env}
          exe="''${1:-}"
          if [ -z "$exe" ]; then
            region="''${WOT_REGION:-eu}"
            exe="$WINEPREFIX/wgc_setup_$region.exe"
            [ -f "$exe" ] || curl -L --fail -o "$exe" \
              "https://redirect.wargaming.net/WGC/internal/Wargaming_Game_Center_Install_WoT_''${region^^}.exe"
          fi
          umu-run "$exe" /SP- /SILENT
        '';

        # Launch Wargaming Game Center (which updates/starts the game).
        wot-play = mkTool "wot-play" ''
          ${env}
          ${wotSync}/bin/wot-sync || echo "mod sync failed — launching anyway" >&2
          ${wgcCandidates}
          [ -n "$wgc" ] && [ -f "$wgc" ] || { echo "wgc.exe not found — run wot-install first" >&2; exit 1; }
          exec gamemoderun umu-run "$wgc"
        '';

        # Run Aslain's modpack installer inside the game's prefix.
        # First run is interactive: pick your mods (XVM markers/hitlog/minimap,
        # sixth-sense timer, damage log, ...) — the selection is saved via Inno
        # Setup's /SAVEINF into the prefix. From then on, `wot-mods -s` (or a
        # newer installer .exe) reapplies the same selection silently.
        # Installer: https://aslain.com/ — drop it in ~/Downloads or pass a path.
        wot-mods = mkTool "wot-mods" ''
          ${env}
          inf="$WINEPREFIX/aslains-selection.inf"
          silent=0
          [ "''${1:-}" = "-s" ] && { silent=1; shift; }
          exe="''${1:-}"
          if [ -z "$exe" ]; then
            exe="$(find "$HOME/Downloads" -maxdepth 1 -iname 'Aslains_WoT_Modpack*.exe' \
              -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -n1 | cut -d' ' -f2-)"
          fi
          [ -n "$exe" ] && [ -f "$exe" ] || {
            echo "No modpack installer found. Pass its path, or download Aslain's" >&2
            echo "installer to ~/Downloads: https://aslain.com/" >&2
            exit 1
          }
          winf="$(echo "$inf" | sed "s|^$WINEPREFIX|Z:$WINEPREFIX|; s|/|\\\\|g")"
          if [ "$silent" = 1 ]; then
            [ -f "$inf" ] || { echo "No saved selection yet — run wot-mods interactively first" >&2; exit 1; }
            exec umu-run "$exe" /SP- /SILENT /SUPPRESSMSGBOXES "/LOADINF=$winf"
          fi
          exec umu-run "$exe" "/SAVEINF=$winf"
        '';

        # Visual remodel: AMX 30 1er prototype uses the AMX 30 B's 3D model.
        # Re-run after every game patch (res_mods gets a fresh version dir).
        wot-remodel-amx30 = pkgs.writeShellApplication {
          name = "wot-remodel-amx30";
          runtimeInputs = [ pkgs.python3 ];
          text = ''
            ${env}
            exec python3 ${./remodel-amx30.py} "$@"
          '';
        };

        # Escape hatches into the same prefix.
        wot-winecfg = mkTool "wot-winecfg" "${env}\nexec umu-run winecfg";
        wot-tricks  = mkTool "wot-tricks"  "${env}\nexec umu-run winetricks \"$@\"";

        # Lutris with GE-Proton visible as a runner (STEAM_EXTRA_COMPAT_TOOLS_PATHS).
        wot-lutris = pkgs.writeShellApplication {
          name = "wot-lutris";
          runtimeInputs = [ pkgs.lutris ];
          text = ''
            export STEAM_EXTRA_COMPAT_TOOLS_PATHS=${proton}
            exec lutris "$@"
          '';
        };
      };

      allTools = pkgs.buildEnv {
        name = "wot-env";
        paths = builtins.attrValues scripts
          ++ (with pkgs; [ umu-launcher mangohud vulkan-tools ]);
      };

      mkApp = name: {
        type = "app";
        program = "${scripts.${name}}/bin/${name}";
      };
    in {
      packages.${system}.default = allTools;

      devShells.${system}.default = pkgs.mkShell {
        packages = [ allTools ];
        shellHook = ''
          ${env}
          echo "WoT env — prefix: $WINEPREFIX (override with WOT_PREFIX)"
          echo "  wot-install [installer.exe]   silent-install Wargaming Game Center (WOT_REGION=eu|na|asia)"
          echo "  wot-play                      launch WGC / the game"
          echo "  wot-mods [-s] [installer.exe] Aslain's modpack: interactive picks (saved), -s reapplies silently"
          echo "  wot-remodel-amx30             AMX 30 1er proto gets the AMX 30 B model (re-run each patch)"
          echo "  wot-setup | wot-winecfg | wot-tricks <verb> | wot-lutris"
        '';
      };

      apps.${system} = {
        setup   = mkApp "wot-setup";
        install = mkApp "wot-install";
        play    = mkApp "wot-play";
        mods    = mkApp "wot-mods";
        remodel = mkApp "wot-remodel-amx30";
        winecfg = mkApp "wot-winecfg";
        tricks  = mkApp "wot-tricks";
        lutris  = mkApp "wot-lutris";
        default = mkApp "wot-play";
      };
    };
}
