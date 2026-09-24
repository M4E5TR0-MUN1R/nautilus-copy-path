#!/usr/bin/env bash
# Check that Copy Path is installed correctly (no GUI needed).
set -uo pipefail

EXT_DIR="$HOME/.local/share/nautilus-python/extensions"
OLD_SCRIPT="$HOME/.local/share/nautilus/scripts/Copy Path"
ACCELS="$HOME/.config/nautilus/scripts-accels"
TEST_PATH="/tmp/nautilus copy-path test/ünïcode file.txt"

fails=0
check() {
    if eval "$2"; then echo "PASS  $1"; else echo "FAIL  $1"; fails=$((fails + 1)); fi
}

check "python3-nautilus package installed"      'dpkg -s python3-nautilus >/dev/null 2>&1'
check "extension installed ($EXT_DIR/copy_path.py)" '[[ -f "$EXT_DIR/copy_path.py" ]]'
check "no leftover v1.0 script shortcut"        '[[ ! -e "$OLD_SCRIPT" ]] && ! grep -qs " Copy Path$" "$ACCELS"'

# Load the extension with the system Python, the same one Nautilus embeds,
# build its menu item and copy a test path through its clipboard code.
if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wl-paste >/dev/null; then
    paste_cmd=(wl-paste --no-newline)
elif command -v xclip >/dev/null; then
    paste_cmd=(xclip -selection clipboard -o)
else
    paste_cmd=()
fi
saved=""
(( ${#paste_cmd[@]} )) && saved="$("${paste_cmd[@]}" 2>/dev/null || true)"

result="$(EXT_DIR="$EXT_DIR" TEST_PATH="$TEST_PATH" SAVED="$saved" /usr/bin/python3 - 2>&1 <<'EOF'
import os, sys
import gi
for v in ("4.1", "4.0"):
    try:
        gi.require_version("Nautilus", v)
        break
    except ValueError:
        pass
gi.require_version("Gtk", "4.0")
from gi.repository import Gtk, GLib
Gtk.init()
sys.path.insert(0, os.environ["EXT_DIR"])
import copy_path

labels = [i.props.label for i in copy_path.CopyPathExtension().get_background_items(None)]
print("menu:" + ",".join(labels))

def read_back(clipboard, res, loop):
    print("clip:" + (clipboard.read_text_finish(res) or ""))
    loop.quit()

loop = GLib.MainLoop()
copy_path._copy_to_clipboard(os.environ["TEST_PATH"])
clipboard = Gtk.Widget.get_display(Gtk.Label()).get_clipboard()
clipboard.read_text_async(None, read_back, loop)
GLib.timeout_add(2000, loop.quit)
loop.run()
if os.environ["SAVED"]:
    copy_path._copy_to_clipboard(os.environ["SAVED"])
EOF
)"

check "extension loads and builds its menu item" '[[ "$result" == *"menu:Copy Path"* ]]'
check "extension copies a path to the clipboard" '[[ "$result" == *"clip:$TEST_PATH"* ]]'

echo
if (( fails )); then
    echo "$fails check(s) failed."
    echo "$result"
    exit 1
fi
echo "All checks passed. In Files: right-click a file → Copy Path, or press Ctrl+Shift+C."
