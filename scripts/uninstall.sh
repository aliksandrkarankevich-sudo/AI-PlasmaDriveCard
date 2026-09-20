#!/usr/bin/env bash
# Remove the Drive Cards plasmoid.
# Usage: ./scripts/uninstall.sh
set -euo pipefail

TOOL="kpackagetool6"
TYPE="Plasma/Applet"
ID="io.github.cachyos.drivecard"

if ! command -v "${TOOL}" &>/dev/null; then
    echo "Error: ${TOOL} not found."
    exit 1
fi

if ! "${TOOL}" --type "${TYPE}" --show "${ID}" &>/dev/null; then
    echo "Drive Cards is not installed."
    exit 0
fi

echo "Removing Drive Cards..."
"${TOOL}" --type "${TYPE}" --remove "${ID}"
echo "Done."
