#!/usr/bin/env bash
# Remove the "Copy Path" Nautilus extension and shortcut.
set -euo pipefail

rm -f "$HOME/.local/share/nautilus-python/extensions/copy_path.py"
rm -f "$HOME/.local/share/nautilus/scripts/Copy Path"

ACCELS="$HOME/.config/nautilus/scripts-accels"
[[ -f "$ACCELS" ]] && sed -i '/ Copy Path$/d' "$ACCELS"

nautilus -q 2>/dev/null || true

echo "Uninstalled."
