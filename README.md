# nautilus-copy-path

This adds **Copy Path** to the right-click menu of GNOME Files (Nautilus) on Ubuntu, and binds it to **Ctrl+Shift+C**. It copies the full path of a file or folder as plain text, e.g.:

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

1. Installs the dependencies with `apt`, asking for your sudo password only if something is missing.
2. Installs the extension, the script and the keyboard shortcut for your user.
3. Checks that everything works.

> **Note:** setup restarts Nautilus (`nautilus -q`), which closes any open Files windows.

Afterwards, open Files and do either of these:

- **Right-click** a file → **Copy Path**. With several files selected it says **Copy Paths** and copies one path per line. Right-clicking empty space copies the current folder's path.
- **Select** a file and press **Ctrl+Shift+C**. With nothing selected, it copies the current folder's path.

To remove everything, run `./uninstall.sh`.

| Script | What it does |
| --- | --- |
| `setup.sh` | One command: installs dependencies, then runs `install.sh` and `verify.sh` |
| `install.sh` | Copies the extension and script into your home folder, binds Ctrl+Shift+C and restarts Nautilus |
| `verify.sh` | Checks the install without the GUI and prints a PASS or FAIL line for each check |
| `uninstall.sh` | Removes everything `install.sh` added |

---

## Environment where this was fixed

| | |
| --- | --- |
| **Date & time fixed** | **2026-09-24, 13:45 EAT (UTC+03:00)** |
| OS | **Ubuntu 25.10 "Questing Quokka"** |
| Kernel | 6.17.0-41-generic |
| Desktop | GNOME Shell 49.0 |
| Session | Wayland |
| File manager | GNOME Files (Nautilus) 49.0 |
| `python3-nautilus` | 4.0.1-3 (exposes the `Nautilus` GObject namespace **4.1**) |
| `wl-clipboard` / `xclip` | 2.2.1-2 / 0.13-4 |

It should also work on other Ubuntu or Debian releases with Nautilus 43 or newer, on Wayland or X11.

---

## 1. The problem

In Ubuntu's Files app, right-clicking a file such as `oc_favicon_io.zip` shows *Open With…, Cut, Copy, Move to…, Copy to…, Rename…, Compress…, Email…, Move to Trash, Properties*. None of these copies the file's path as text.

- **Copy (Ctrl+C)** copies the *file itself*, to paste into another folder. It doesn't reliably copy the path as text.
- The only built-in way to get the path is **Properties** → select the "Parent folder" text and add the file name by hand, or open a terminal and drag the file in.

The goal was a one-click **Copy Path** menu item plus a **Ctrl+Shift+C** shortcut.

## 2. Choosing the approach: GNOME extension, distro change, or something else?

| Option | Verdict |
| --- | --- |
| **GNOME Shell extension** (extensions.gnome.org) | ❌ Shell extensions run inside the desktop shell, not inside Nautilus, so they can't add items to its menus. |
| **Patching or rebuilding Nautilus / the distro** | ❌ Overkill. It's fragile, and every `apt upgrade` would overwrite it. |
| **Nautilus's own plugin systems** | ✅ Per-user, no root needed except to install one package, and survives upgrades. |

Nautilus has two plugin mechanisms, and we need both:

1. **nautilus-python extensions** (`~/.local/share/nautilus-python/extensions/*.py`). These are Python classes that Nautilus loads at startup. They can add **top-level** right-click menu items, but **they can't register keyboard shortcuts**.
2. **Nautilus scripts** (`~/.local/share/nautilus/scripts/`). These are executables that appear under right-click → *Scripts*, and receive the selection in environment variables. They **can** have keyboard shortcuts, through `~/.config/nautilus/scripts-accels`. We checked that Nautilus 49 still supports this by searching its binary for `scripts-accels` and `NAUTILUS_SCRIPT_SELECTED_FILE_PATHS`.

So the **extension gives the menu item**, and the **script gives the Ctrl+Shift+C shortcut**.

## 3. Step-by-step solution (manual)

This is exactly what `setup.sh` and `install.sh` do. Run these from the cloned repo if you'd rather do it by hand.

### Step 1: Install the dependencies

```bash
sudo apt install python3-nautilus   # lets Nautilus load Python extensions
sudo apt install wl-clipboard       # wl-copy, for the shortcut on Wayland (use xclip on X11)
```

Check what you're running with `echo $XDG_SESSION_TYPE`, which prints `wayland` or `x11`.

### Step 2: Install the menu extension

```bash
mkdir -p ~/.local/share/nautilus-python/extensions
cp extension/copy_path.py ~/.local/share/nautilus-python/extensions/
```

### Step 3: Install the shortcut script

```bash
mkdir -p ~/.local/share/nautilus/scripts
cp "scripts/Copy Path" ~/.local/share/nautilus/scripts/
chmod +x ~/.local/share/nautilus/scripts/"Copy Path"
```

The file name `Copy Path` is what the shortcut refers to in the next step.

### Step 4: Bind Ctrl+Shift+C to the script

```bash
mkdir -p ~/.config/nautilus
echo '<Control><Shift>c Copy Path' >> ~/.config/nautilus/scripts-accels
```

Each line has the format `<accelerator> <script file name>`.

### Step 5: Restart Nautilus

```bash
nautilus -q
```

Then open Files again. Right-click a file and **Copy Path** is there. Ctrl+Shift+C also works.

### Step 6: Verify

```bash
./verify.sh
```

Expected output:

```
PASS  python3-nautilus package installed
PASS  extension installed (/home/you/.local/share/nautilus-python/extensions/copy_path.py)
PASS  script installed and executable
PASS  Ctrl+Shift+C bound in scripts-accels
PASS  clipboard tool available
PASS  script copies selected path to clipboard

All checks passed. In Files: right-click a file → Copy Path, or press Ctrl+Shift+C.
```

Then check in the GUI: right-click `oc_favicon_io.zip` → **Copy Path**, and paste into a terminal or text editor. Next, select it, press **Ctrl+Shift+C** and paste again.

## 4. How it works

### `extension/copy_path.py` (the right-click menu item)

- A `Nautilus.MenuProvider` class. Nautilus calls `get_file_items(files)` when you right-click files, and `get_background_items(folder)` when you right-click empty space.
- It returns one `Nautilus.MenuItem`, labelled "Copy Path" or "Copy Paths".
- When clicked, it turns each file into a local path with `file.get_location().get_path()`. That gives a real path with no `file://` prefix and no `%20` encoding. For virtual locations without a local path, such as `trash://`, it falls back to the URI.
- It puts the text on the clipboard with GTK's own clipboard, `Gdk.Display.get_default().get_clipboard().set(text)`. The extension runs inside Nautilus, so it needs no external tool and works on both Wayland and X11.

### `scripts/Copy Path` (the Ctrl+Shift+C shortcut)

- Nautilus runs the script with `NAUTILUS_SCRIPT_SELECTED_FILE_PATHS` set to the selected paths, one per line.
- If nothing is selected, it decodes `NAUTILUS_SCRIPT_CURRENT_URI` to get the current folder's path.
- It pipes the result to `wl-copy` on Wayland or `xclip -selection clipboard` on X11.

## 5. Troubleshooting

| Symptom | Fix |
| --- | --- |
| No **Copy Path** item in the menu | Make sure `python3-nautilus` is installed, then run `nautilus -q` and reopen Files. Nautilus has loaded the extension if `~/.local/share/nautilus-python/extensions/__pycache__/copy_path.*.pyc` exists after reopening. |
| Menu item is there but Ctrl+Shift+C does nothing | Check that `~/.config/nautilus/scripts-accels` contains `<Control><Shift>c Copy Path`, that the script is executable, and that `wl-copy` or `xclip` is installed. Then run `nautilus -q`. |
| `python3 -c "import gi"` fails in your terminal | Your `python3` is probably a pyenv or conda one. This is fine, because Nautilus uses the system Python (`/usr/bin/python3`). Test with `/usr/bin/python3`. |
| `Namespace Nautilus not available for version 4.0` | Nautilus 49 ships `Nautilus-4.1.typelib`. The extension doesn't pin a version, so it isn't affected. Only standalone tests need `gi.require_version('Nautilus', '4.1')`. |
| Scripts lose their executable bit | This happens when the repo sits on an NTFS or exFAT drive. `install.sh` sets permissions when it copies the files into your home folder, and git stores the `+x` bit, so a fresh clone on ext4 is fine. |
| "Copy Path" also appears under **Scripts** | This is expected, because the shortcut needs the script to exist. It does the same thing. |

## 6. Customize

- **A different shortcut:** edit `~/.config/nautilus/scripts-accels`, e.g. `<Control><Alt>c Copy Path`, then run `nautilus -q`.
- **Paths separated by spaces instead of newlines:** change `"\n".join` in `copy_path.py` and adjust the script.

## 7. Uninstall

```bash
./uninstall.sh
```

This removes the extension, the script and the shortcut line, then restarts Nautilus. It leaves `python3-nautilus` installed; remove it with `sudo apt remove python3-nautilus` if you like.

## Repo layout

```
nautilus-copy-path/
├── extension/copy_path.py   # nautilus-python MenuProvider → "Copy Path" menu item
├── scripts/Copy Path        # Nautilus script → used by Ctrl+Shift+C
├── setup.sh                 # one command: dependencies + install + verify
├── install.sh               # installs for the current user
├── verify.sh                # checks the install without the GUI
├── uninstall.sh             # removes everything
├── README.md
└── LICENSE                  # MIT
```

## License

MIT, see [LICENSE](LICENSE).
