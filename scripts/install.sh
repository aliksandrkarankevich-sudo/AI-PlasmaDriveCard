#!/usr/bin/env bash
# Install Drive Cards from a local Git clone.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

PKG_ID="io.github.cachyos.drivecard"
PKG_DIR="package"

if ! command -v kpackagetool6 &>/dev/null; then
    echo "Error: kpackagetool6 not found. Please install plasma-framework or kde-cli-tools." >&2
    exit 1
fi

if kpackagetool6 --type Plasma/Applet --show "$PKG_ID" &>/dev/null 2>&1; then
    echo "Updating existing installation…"
    kpackagetool6 --type Plasma/Applet --upgrade "$PKG_DIR"
else
    echo "Installing Drive Cards…"
    kpackagetool6 --type Plasma/Applet --install "$PKG_DIR"
fi

echo ""
echo "Done. Restart Plasma or log out/in to use the widget."
echo "  plasmashell --replace &"
