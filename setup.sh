#!/usr/bin/env bash
# One-command setup: install dependencies, install Copy Path, verify.
#   git clone https://github.com/M4E5TR0-MUN1R/nautilus-copy-path.git
#   cd nautilus-copy-path && ./setup.sh
set -euo pipefail

cd "$(dirname "$0")"

pkgs=(python3-nautilus)

missing=()
for p in "${pkgs[@]}"; do
    dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
done

if (( ${#missing[@]} )); then
    echo "==> Installing: ${missing[*]} (sudo required)"
    sudo apt-get update -qq
    sudo apt-get install -y "${missing[@]}"
else
    echo "==> Dependencies already installed: ${pkgs[*]}"
fi

echo "==> Installing Copy Path"
./install.sh

echo "==> Verifying"
./verify.sh
