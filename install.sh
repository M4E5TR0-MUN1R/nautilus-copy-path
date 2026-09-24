#!/usr/bin/env bash
# Install the "Copy Path" Nautilus extension and Ctrl+Shift+C shortcut for the current user.
set -euo pipefail

cd "$(dirname "$0")"

EXT_DIR="$HOME/.local/share/nautilus-python/extensions"
SCRIPT_DIR="$HOME/.local/share/nautilus/scripts"
ACCELS="$HOME/.config/nautilus/scripts-accels"
ACCEL_LINE="<Control><Shift>c Copy Path"

if ! dpkg -s python3-nautilus >/dev/null 2>&1; then
    echo "python3-nautilus is required. Install it with:"
    echo "    sudo apt install python3-nautilus"
    exit 1
fi

if ! command -v wl-copy >/dev/null && ! command -v xclip >/dev/null; then
    echo "Warning: neither wl-copy nor xclip found; the Ctrl+Shift+C shortcut needs one."
    echo "    sudo apt install wl-clipboard"
fi

mkdir -p "$EXT_DIR" "$SCRIPT_DIR" "$(dirname "$ACCELS")"
install -m 644 extension/copy_path.py "$EXT_DIR/copy_path.py"
install -m 755 "scripts/Copy Path" "$SCRIPT_DIR/Copy Path"

touch "$ACCELS"
sed -i '/ Copy Path$/d' "$ACCELS"
echo "$ACCEL_LINE" >> "$ACCELS"

nautilus -q 2>/dev/null || true

echo "Installed. Reopen Files: right-click → Copy Path, or select a file and press Ctrl+Shift+C."
