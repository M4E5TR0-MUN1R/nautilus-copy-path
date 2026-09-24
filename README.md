# nautilus-copy-path

Adds **Copy Path** to the GNOME Files (Nautilus) right-click menu, plus a **Ctrl+Shift+C** shortcut that copies the selected file's full path as plain text:

```
/home/you/Downloads/OctaviaImageAndLogo/oc_favicon_io.zip
```

- Right-click a file → **Copy Path** (or **Copy Paths** for multiple files, one per line)
- Right-click empty space in a folder → **Copy Path** copies the folder's path
- **Ctrl+Shift+C** copies the selected file(s); with nothing selected it copies the current folder

Tested on Ubuntu 25.10, GNOME 49 / Nautilus 49, Wayland. Works on X11 too.

## How it works

This is not a GNOME Shell extension, since GNOME Shell extensions can't change Nautilus menus. It is two small per-user Nautilus add-ons:

| Piece | Installed to | Purpose |
| --- | --- | --- |
| `extension/copy_path.py` | `~/.local/share/nautilus-python/extensions/` | [nautilus-python](https://gitlab.gnome.org/GNOME/nautilus-python) menu provider that adds the top-level menu item |
| `scripts/Copy Path` | `~/.local/share/nautilus/scripts/` | Nautilus script used for the keyboard shortcut. Nautilus extensions can't register shortcuts, but scripts can. |
| `<Control><Shift>c Copy Path` | `~/.config/nautilus/scripts-accels` | Binds the script to Ctrl+Shift+C |

The script copies with `wl-copy` on Wayland or `xclip` on X11.

## Install

```bash
sudo apt install python3-nautilus wl-clipboard   # xclip instead of wl-clipboard on X11
git clone https://github.com/M4E5TR0-MUN1R/nautilus-copy-path.git
cd nautilus-copy-path
./install.sh
```

`install.sh` restarts Nautilus (`nautilus -q`). Reopen Files afterwards.

## Uninstall

```bash
./uninstall.sh
```

## Notes

- Because of the script shortcut, **Copy Path** also appears under the **Scripts** submenu. This is harmless.
- To use a different shortcut, edit `~/.config/nautilus/scripts-accels`, e.g. `<Control><Alt>c Copy Path`, then run `nautilus -q`.

## License

MIT
