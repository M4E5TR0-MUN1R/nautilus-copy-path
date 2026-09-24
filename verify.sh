#!/usr/bin/env bash
# Check that Copy Path is installed correctly (no GUI needed).
set -uo pipefail

EXT="$HOME/.local/share/nautilus-python/extensions/copy_path.py"
SCRIPT="$HOME/.local/share/nautilus/scripts/Copy Path"
ACCELS="$HOME/.config/nautilus/scripts-accels"
TEST_PATH="/tmp/nautilus copy-path test/ünïcode file.txt"

fails=0
check() {
    if eval "$2"; then echo "PASS  $1"; else echo "FAIL  $1"; fails=$((fails + 1)); fi
}

if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wl-paste >/dev/null; then
    paste_cmd=(wl-paste --no-newline)
else
    paste_cmd=(xclip -selection clipboard -o)
fi

check "python3-nautilus package installed"   'dpkg -s python3-nautilus >/dev/null 2>&1'
check "extension installed ($EXT)"           '[[ -f "$EXT" ]]'
check "script installed and executable"      '[[ -x "$SCRIPT" ]]'
check "Ctrl+Shift+C bound in scripts-accels" 'grep -qx "<Control><Shift>c Copy Path" "$ACCELS" 2>/dev/null'
check "clipboard tool available"             'command -v wl-copy >/dev/null || command -v xclip >/dev/null'

# Functional test: run the script as Nautilus would, then read the clipboard back.
saved="$("${paste_cmd[@]}" 2>/dev/null || true)"
NAUTILUS_SCRIPT_SELECTED_FILE_PATHS="$TEST_PATH"$'\n' "$SCRIPT" 2>/dev/null
got="$("${paste_cmd[@]}" 2>/dev/null || true)"
check "script copies selected path to clipboard" '[[ "$got" == "$TEST_PATH" ]]'
if [[ -n "$saved" && -x "$SCRIPT" ]]; then
    NAUTILUS_SCRIPT_SELECTED_FILE_PATHS="$saved" "$SCRIPT" 2>/dev/null
fi

echo
if (( fails )); then
    echo "$fails check(s) failed."
    exit 1
fi
echo "All checks passed. In Files: right-click a file → Copy Path, or press Ctrl+Shift+C."
