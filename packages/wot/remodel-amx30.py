"""Make the AMX 30 1er prototype (F71) use the AMX 30 B (F72) 3D model.

Plants the donor's .model entry files at the target's paths under res_mods.
The .model files internally reference the donor's .visual/.primitives/textures,
which the engine keeps loading from the original res packages — so only these
small files are needed, and the swap survives as long as both tanks' assets
exist. Client-side visual only; armor/collision stay the real F71 hitbox.
"""

import os
import re
import sys
import zipfile
from pathlib import Path

TARGET = "vehicles/french/F71_AMX_30_prototype/"
DONOR = "vehicles/french/F72_AMX_30/"


def game_dir():
    if "WOT_GAME" in os.environ:
        return Path(os.environ["WOT_GAME"])
    prefix = Path(os.environ.get("WINEPREFIX", os.path.expanduser("~/Games/world-of-tanks")))
    for p in (prefix / "drive_c/Games").glob("World_of_Tanks*"):
        if (p / "res/packages").is_dir():
            return p
    sys.exit("game dir not found — set WOT_GAME")


def scan(pkg_glob, prefix, packages):
    """Map path-under-prefix -> (pkg, member) for entries of the tank dir."""
    out = {}
    for pkg in sorted(packages.glob(pkg_glob)):
        if "_hd" in pkg.name:
            continue
        with zipfile.ZipFile(pkg) as z:
            for name in z.namelist():
                if name.startswith(prefix) and not name.endswith("/"):
                    out[name[len(prefix):]] = (pkg, name)
    return out


def pick_donor(rel, donor):
    """Donor file for a target part, falling back to the lowest-numbered
    part of the same kind in the same state/lod dir (Gun_05 -> Gun_01)."""
    if rel in donor:
        return rel
    d, fname = os.path.split(rel)
    m = re.match(r"([A-Za-z]+)_\d+(\..*)", fname)
    if not m:
        return None
    kind, ext = m.groups()
    pat = re.compile(re.escape(d) + r"/" + re.escape(kind) + r"_\d+" + re.escape(ext) + r"$")
    candidates = sorted(r for r in donor if pat.match(r))
    return candidates[0] if candidates else None


def main():
    game = game_dir()
    packages = game / "res/packages"
    versions = sorted(
        (d for d in (game / "res_mods").iterdir() if re.match(r"[\d.]+$", d.name)),
        key=lambda d: [int(x) for x in d.name.split(".")],
    )
    if not versions:
        sys.exit("no version dir under res_mods")
    dest_root = versions[-1] / TARGET

    target = scan("vehicles_level_09*.pkg", TARGET, packages)
    donor = scan("vehicles_level_10*.pkg", DONOR, packages)
    if not target or not donor:
        sys.exit("could not find tank files in res/packages — game files changed?")

    planted, skipped = 0, []
    for rel in sorted(target):
        if not rel.endswith(".model"):
            continue
        state = rel.split("/", 1)[0]
        if state not in ("normal", "crash", "exploded"):
            continue
        src = pick_donor(rel, donor)
        if src is None:
            skipped.append(rel)
            continue
        pkg, member = donor[src]
        dest = dest_root / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(pkg) as z:
            dest.write_bytes(z.read(member))
        planted += 1

    print(f"planted {planted} .model files into {dest_root}")
    for rel in skipped:
        print(f"  no donor part for {rel} — left original", file=sys.stderr)
    print("remove the swap with: rm -r " + str(dest_root))


if __name__ == "__main__":
    main()
