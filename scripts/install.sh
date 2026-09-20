#!/usr/bin/env bash
# Install or upgrade Drive Cards from a local Git clone.
# Usage: ./scripts/install.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="${SCRIPT_DIR}/../package"
TOOL="kpackagetool6"
TYPE="Plasma/Applet"
ID="io.github.cachyos.drivecard"

if ! command -v "${TOOL}" &>/dev/null; then
    echo "Error: ${TOOL} not found. Install plasma-framework or plasma6-sdk."
    exit 1
fi

if "${TOOL}" --type "${TYPE}" --show "${ID}" &>/dev/null; then
    echo "Upgrading existing installation..."
    "${TOOL}" --type "${TYPE}" --upgrade "${PACKAGE_DIR}"
    echo "Done. Restart Plasma to apply changes:"
    echo "  kquitapp6 plasmashell && kstart plasmashell"
else
    echo "Installing Drive Cards..."
    "${TOOL}" --type "${TYPE}" --install "${PACKAGE_DIR}"
    echo "Done. Add the widget from the Plasma widget browser."
fi
