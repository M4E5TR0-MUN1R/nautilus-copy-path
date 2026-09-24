#!/usr/bin/env bash
# Install the "Copy Path" Nautilus extension (right-click item + Ctrl+Shift+C) for the current user.
set -euo pipefail

cd "$(dirname "$0")"

EXT_DIR="$HOME/.local/share/nautilus-python/extensions"

if ! dpkg -s python3-nautilus >/dev/null 2>&1; then
    echo "python3-nautilus is required. Install it with:"
    echo "    sudo apt install python3-nautilus"
    exit 1
fi

mkdir -p "$EXT_DIR"
install -m 644 extension/copy_path.py "$EXT_DIR/copy_path.py"

# Clean up v1.0, which bound the shortcut through a Nautilus script.
rm -f "$HOME/.local/share/nautilus/scripts/Copy Path"
ACCELS="$HOME/.config/nautilus/scripts-accels"
[[ -f "$ACCELS" ]] && sed -i '/ Copy Path$/d' "$ACCELS"

nautilus -q 2>/dev/null || true

echo "Installed. Reopen Files: right-click → Copy Path, or select a file and press Ctrl+Shift+C."
