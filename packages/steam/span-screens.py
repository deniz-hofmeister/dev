"""Run a game and keep its window fullscreen across the identical monitors.

Usage (Steam launch options): span-screens %command%

Finds the group of two or more monitors with the same resolution (e.g. two
2560x1440 screens next to an ultrawide), waits for the game's X11 window
(WM_CLASS $SPAN_SCREENS_CLASS, default bg3) and asks the window manager
(_NET_WM_FULLSCREEN_MONITORS) to make it fullscreen across them, re-applying
this within a second whenever the game resizes or moves its window (e.g. after
changing video settings). Run the game in windowed mode: it then renders at
the spanned size, while its own fullscreen mode only offers single-monitor
resolutions.

(A nested gamescope sized to the combined monitors would isolate the game from
this entirely, but on the NVIDIA driver here it only shows a black window.)
"""

import os
import subprocess
import sys
import time
from collections import defaultdict

from Xlib import X, display
from Xlib.error import DisplayError, XError
from Xlib.ext import xinerama
from Xlib.protocol import event


def target_heads(d):
    heads = list(enumerate(xinerama.query_screens(d).screens))
    groups = defaultdict(list)
    for i, s in heads:
        groups[(s.width, s.height)].append((i, s))
    group = max(groups.values(), key=len)
    if len(group) < 2:
        return None
    group.sort(key=lambda h: h[1].x)
    (left, ls), (right, rs) = group[0], group[-1]
    return left, right, (ls.x, ls.y, rs.x + rs.width - ls.x, ls.height)


def game_windows(root, wm_class):
    stack = [root]
    while stack:
        w = stack.pop()
        try:
            stack.extend(w.query_tree().children)
            cls = w.get_wm_class()
            viewable = w.get_attributes().map_state == X.IsViewable
        except XError:
            continue
        if viewable and cls and wm_class in cls:
            yield w


def send(d, root, w, atom, data):
    ev = event.ClientMessage(
        window=w,
        client_type=d.intern_atom(atom),
        data=(32, data + [0] * (5 - len(data))),
    )
    root.send_event(
        ev, event_mask=X.SubstructureRedirectMask | X.SubstructureNotifyMask
    )


def span(d, root, w, left, right):
    send(d, root, w, "_NET_WM_FULLSCREEN_MONITORS", [left, left, left, right, 1])
    send(
        d,
        root,
        w,
        "_NET_WM_STATE",
        [1, d.intern_atom("_NET_WM_STATE_FULLSCREEN"), 0, 1],
    )
    d.flush()


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: span-screens <command> [args...]")
    game = subprocess.Popen(sys.argv[1:])
    try:
        d = display.Display()
    except DisplayError as e:
        print(f"span-screens: no X display ({e}), not spanning", file=sys.stderr)
        sys.exit(game.wait())
    root = d.screen().root
    wm_class = os.environ.get("SPAN_SCREENS_CLASS", "bg3")

    while game.poll() is None:
        time.sleep(1)
        heads = target_heads(d)
        if not heads:
            continue
        left, right, (x, y, width, height) = heads
        for w in game_windows(root, wm_class):
            try:
                geo = w.get_geometry()
                pos = w.translate_coords(root, 0, 0)
            except XError:
                continue
            if (-pos.x, -pos.y, geo.width, geo.height) != (x, y, width, height):
                span(d, root, w, left, right)
    sys.exit(game.returncode)


if __name__ == "__main__":
    main()
