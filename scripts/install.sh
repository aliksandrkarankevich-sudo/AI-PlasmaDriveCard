#!/usr/bin/env bash
# install.sh — build and install Drive Cards from a local Git clone
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v kpackagetool6 &>/dev/null; then
    echo "ERROR: kpackagetool6 not found."
    exit 1
fi

bash "${ROOT}/scripts/build.sh"

VERSION=$(python3 -c "import json; print(json.load(open('${ROOT}/package/metadata.json'))['KPlugin']['Version'])")
FILE="${ROOT}/dist/cachyos-drive-card-${VERSION}.plasmoid"

if kpackagetool6 --type Plasma/Applet --list 2>/dev/null | grep -q "io.github.cachyos.drivecard"; then
    echo "Upgrading existing installation..."
    kpackagetool6 --type Plasma/Applet --upgrade "${FILE}"
else
    echo "Installing Drive Cards..."
    kpackagetool6 --type Plasma/Applet --install "${FILE}"
fi

echo "Done! Drive Cards ${VERSION} installed."
