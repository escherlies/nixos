# nautilus-copypath

Vendored copy of the `nautilus-copypath` Nautilus (GNOME Files) extension,
which adds "Copy Path" / "Copy Paths" / "Copy Directory Path" entries to the
right-click context menu.

- Upstream: https://git.sr.ht/~ronenk17/nautilus-copypath
- Revision: bbfa58c7b823605bc1fc352f61f6f8577b77200b
- License: GPL-3.0-or-later (see `LICENSE`)

The single `nautilus-copypath.py` file is vendored here (rather than fetched at
eval time) because upstream moved off GitHub to a sourcehut mirror. `default.nix`
packages it into `share/nautilus-python/extensions/`, where the GNOME NixOS
module's `environment.pathsToLink` picks it up. It requires `nautilus-python`
(the loader), which is added alongside it in `../gnome.nix`.
