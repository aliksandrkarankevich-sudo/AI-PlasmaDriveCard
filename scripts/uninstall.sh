#!/usr/bin/env bash
# Remove Drive Cards.
set -euo pipefail

PKG_ID="io.github.cachyos.drivecard"

if ! command -v kpackagetool6 &>/dev/null; then
    echo "Error: kpackagetool6 not found." >&2
    exit 1
fi

if ! kpackagetool6 --type Plasma/Applet --show "$PKG_ID" &>/dev/null 2>&1; then
    echo "Drive Cards is not installed."
    exit 0
fi

kpackagetool6 --type Plasma/Applet --remove "$PKG_ID"
echo "Drive Cards removed."
