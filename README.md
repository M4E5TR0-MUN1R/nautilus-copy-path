# nautilus-copy-path

This adds **Copy Path  Ctrl+Shift+C** to the right-click menu of GNOME Files (Nautilus) on Ubuntu. It copies the full path of a file or folder as plain text, e.g.:

```
/home/khamis/Downloads/OctaviaImageAndLogo/oc_favicon_io.zip
```

---

## Quick fix (clone and run)

```bash
git clone https://github.com/M4E5TR0-MUN1R/nautilus-copy-path.git
cd nautilus-copy-path
./setup.sh
```

`setup.sh` does three things:

1. Installs the one dependency, `python3-nautilus`, with `apt`. It asks for your sudo password only if the package is missing.
2. Installs the extension for your user.
3. Checks that everything works.

> **Note:** setup restarts Nautilus (`nautilus -q`), which closes any open Files windows.

Afterwards, open Files and do either of these:

- **Right-click** a file → **Copy Path**, with the **Ctrl+Shift+C** label shown next to it, just like *Copy Ctrl+C*. With several files selected it says **Copy Paths** and copies one path per line. Right-clicking empty space copies the current folder's path.
- **Select** a file and press **Ctrl+Shift+C**. With nothing selected, it copies the current folder's path.

To remove everything, run `./uninstall.sh`.

| Script | What it does |
| --- | --- |
| `setup.sh` | One command: installs the dependency, then runs `install.sh` and `verify.sh` |
| `install.sh` | Copies the extension into your home folder, removes any v1.0 leftovers and restarts Nautilus |
| `verify.sh` | Checks the install without the GUI and prints a PASS or FAIL line for each check |
| `uninstall.sh` | Removes everything `install.sh` added |

---

## Environment where this was fixed

| | |
| --- | --- |
| **Date & time fixed** | **2026-09-24, 13:45 EAT (UTC+03:00)**. The menu label was added in v1.1 at 14:12 EAT. |
| OS | **Ubuntu 25.10 "Questing Quokka"** |
| Kernel | 6.17.0-41-generic |
| Desktop | GNOME Shell 49.0 |
| Session | Wayland |
| File manager | GNOME Files (Nautilus) 49.0 |
| `python3-nautilus` | 4.0.1-3 (exposes the `Nautilus` GObject namespace **4.1**) |

It should also work on other Ubuntu or Debian releases with Nautilus 43 or newer, on Wayland or X11.

---

## 1. The problem

In Ubuntu's Files app, right-clicking a file such as `oc_favicon_io.zip` shows *Open With…, Cut, Copy, Move to…, Copy to…, Rename…, Compress…, Email…, Move to Trash, Properties*. None of these copies the file's path as text.

- **Copy (Ctrl+C)** copies the *file itself*, to paste into another folder. It doesn't reliably copy the path as text.
- The only built-in way to get the path is **Properties** → select the "Parent folder" text and add the file name by hand, or open a terminal and drag the file in.

The goal was a one-click **Copy Path** menu item with a **Ctrl+Shift+C** shortcut, shown in the menu like the built-in items.

## 2. Choosing the approach: GNOME extension, distro change, or something else?

| Option | Verdict |
| --- | --- |
| **GNOME Shell extension** (extensions.gnome.org) | ❌ Shell extensions run inside the desktop shell, not inside Nautilus, so they can't add items to its menus. |
| **Patching or rebuilding Nautilus / the distro** | ❌ Overkill. It's fragile, and every `apt upgrade` would overwrite it. |
| **A Nautilus Python extension** | ✅ Per-user, no root needed except to install one package, and survives upgrades. |

**nautilus-python extensions** (`~/.local/share/nautilus-python/extensions/*.py`) are Python classes that Nautilus loads at startup, and they run *inside* the Nautilus process. The extension API can add top-level right-click menu items. It has no API for keyboard shortcuts. However, because the code runs in-process, it can register a shortcut on its own menu item's action through GTK. GTK then does two things, exactly as it does for the built-in *Copy Ctrl+C* item:

1. shows **Ctrl+Shift+C** next to **Copy Path** in the menu
2. runs the action when you press the keys

> **History:** v1.0 used a second mechanism for the shortcut: a Nautilus script in `~/.local/share/nautilus/scripts/` bound through `~/.config/nautilus/scripts-accels`. The shortcut worked, but Nautilus binds script shortcuts in a way GTK can't show in menus, so the menu said just "Copy Path". It also added an extra *Scripts ›* submenu. v1.1 replaced this with the approach above, and `install.sh` removes the old script automatically.

## 3. Step-by-step solution (manual)

This is exactly what `setup.sh` and `install.sh` do. Run these from the cloned repo if you'd rather do it by hand.

### Step 1: Install the dependency

```bash
sudo apt install python3-nautilus   # lets Nautilus load Python extensions
```

### Step 2: Install the extension

```bash
mkdir -p ~/.local/share/nautilus-python/extensions
cp extension/copy_path.py ~/.local/share/nautilus-python/extensions/
```

### Step 3 (only if you installed v1.0): Remove the old script shortcut

```bash
rm -f ~/.local/share/nautilus/scripts/"Copy Path"
sed -i '/ Copy Path$/d' ~/.config/nautilus/scripts-accels
```

### Step 4: Restart Nautilus

```bash
nautilus -q
```

Then open Files again. Right-click a file and you'll see **Copy Path    Ctrl+Shift+C**.

### Step 5: Verify

```bash
./verify.sh
```

Expected output:

```
PASS  python3-nautilus package installed
PASS  extension installed (/home/you/.local/share/nautilus-python/extensions/copy_path.py)
PASS  no leftover v1.0 script shortcut
PASS  extension loads and builds its menu item
PASS  extension copies a path to the clipboard

All checks passed. In Files: right-click a file → Copy Path, or press Ctrl+Shift+C.
```

Then check in the GUI:

1. Right-click `oc_favicon_io.zip`. The menu should show **Copy Path  Ctrl+Shift+C**. Click it and paste into a terminal or text editor.
2. Select a file and press **Ctrl+Shift+C**, then paste.
3. Click empty space so nothing is selected, press **Ctrl+Shift+C**, and paste. You should get the folder's path.

## 4. How it works (`extension/copy_path.py`)

- **The menu items.** A `Nautilus.MenuProvider` class. Nautilus calls `get_file_items(files)` for the selection menu and `get_background_items(folder)` for the empty-space menu. Each returns one `Nautilus.MenuItem`, labelled "Copy Path" or "Copy Paths".
- **The shortcut and its label.**
  - Nautilus turns each extension menu item into a GTK action named `view.extension_extensions_<idx>_<item name>`. See `build_menu_for_extension_menu_items()` in Nautilus's `src/nautilus-files-view.c`.
  - The extension calls `Gtk.Application.get_default().set_accels_for_action(<that name>, ["<Control><Shift>c"])`. That's the same mechanism GTK menus use to display shortcut labels.
  - `idx` is the item's position among *all* installed extensions' items, so the extension registers the shortcut for a small range of positions. Registering a shortcut for an action that doesn't exist does nothing.
- **Always the current selection.**
  - Nautilus rebuilds its context menus, calling both `get_*_items` methods, every time the selection changes. It never removes old actions, though.
  - So the extension remembers the latest selection and folder it was given. Both the menu click and the shortcut copy the current selection, or the current folder when nothing is selected.
- **The paths.**
  - `file.get_location().get_path()` gives a real local path, with no `file://` prefix and no `%20` encoding.
  - For virtual locations without a local path, such as `trash://`, it falls back to the URI.
- **The clipboard.** `Gdk.Display.get_default().get_clipboard().set(text)` is GTK's own clipboard. Because the code runs inside Nautilus, it needs no `wl-copy` or `xclip` and works on both Wayland and X11.

## 5. Troubleshooting

| Symptom | Fix |
| --- | --- |
| No **Copy Path** item in the menu | Make sure `python3-nautilus` is installed, then run `nautilus -q` and reopen Files. Nautilus has loaded the extension if `~/.local/share/nautilus-python/extensions/__pycache__/copy_path.*.pyc` exists after reopening. |
| Menu item is there but has no shortcut label, and Ctrl+Shift+C does nothing | You probably have many other extension menu items, pushing ours past position 15. Raise `MAX_IDX` in `copy_path.py`, reinstall and run `nautilus -q`. |
| Menu shows **Shift+Ctrl+C** rather than Ctrl+Shift+C | This is expected. GTK always writes modifiers in the order Shift, Ctrl, Alt, whatever order they were registered in, so Nautilus's own *New Folder* shows **Shift+Ctrl+N**. It's the same key combination, and apps can't change the order. |
| Ctrl+Shift+C copies twice or does something else | Remove any v1.0 leftovers (Step 3), then run `nautilus -q`. |
| `python3 -c "import gi"` fails in your terminal | Your `python3` is probably a pyenv or conda one. This is fine, because Nautilus uses the system Python (`/usr/bin/python3`). Test with `/usr/bin/python3`. `verify.sh` already does. |
| `Namespace Nautilus not available for version 4.0` | Nautilus 49 ships `Nautilus-4.1.typelib`. The extension doesn't pin a version, so it isn't affected. Only standalone tests need `gi.require_version('Nautilus', '4.1')`. |
| Scripts lose their executable bit | This happens when the repo sits on an NTFS or exFAT drive. Git stores the `+x` bit, so a fresh clone on ext4 is fine. You can also run the scripts with `bash setup.sh`. |

## 6. Customize

- **A different shortcut:** change `ACCEL` at the top of `copy_path.py`, e.g. `"<Control><Alt>c"`. Then run `./install.sh`.
- **Paths separated by spaces instead of newlines:** change `"\n".join` in `_on_activate`.

## 7. Uninstall

```bash
./uninstall.sh
```

This removes the extension and any v1.0 script or shortcut line, then restarts Nautilus. It leaves `python3-nautilus` installed; remove it with `sudo apt remove python3-nautilus` if you like.

## Changelog

| Version | Date (EAT, UTC+03:00) | Change |
| --- | --- | --- |
| v1.1 | 2026-09-24 14:12 | **Ctrl+Shift+C is now shown next to Copy Path** in the menu. The shortcut moved into the extension, and the Nautilus script, the `scripts-accels` entry, the *Scripts ›* submenu and the `wl-clipboard`/`xclip` dependency are gone. |
| v1.0 | 2026-09-24 13:45 | First working version: a "Copy Path" menu item from the extension, and Ctrl+Shift+C through a Nautilus script. |

## Repo layout

```
nautilus-copy-path/
├── extension/copy_path.py   # nautilus-python extension: "Copy Path" menu item + Ctrl+Shift+C
├── setup.sh                 # one command: dependency + install + verify
├── install.sh               # installs for the current user
├── verify.sh                # checks the install without the GUI
├── uninstall.sh             # removes everything
├── README.md
└── LICENSE                  # MIT
```

## License

MIT, see [LICENSE](LICENSE).
