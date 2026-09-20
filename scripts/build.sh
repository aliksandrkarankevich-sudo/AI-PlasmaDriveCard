#!/usr/bin/env bash
# Build the .plasmoid package from the package/ directory.
# Usage: ./scripts/build.sh
# Output: dist/cachyos-drive-card-<version>.plasmoid
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
PACKAGE_DIR="${ROOT_DIR}/package"
DIST_DIR="${ROOT_DIR}/dist"

# Read version from metadata.json
VERSION="$(grep '"Version"' "${PACKAGE_DIR}/metadata.json" | sed 's/.*"Version": *"\([^"]*\)".*/\1/')"
if [[ -z "${VERSION}" ]]; then
    echo "Error: could not read Version from metadata.json"
    exit 1
fi

OUTPUT="${DIST_DIR}/cachyos-drive-card-${VERSION}.plasmoid"
mkdir -p "${DIST_DIR}"

# Build zip, excluding backups, test files, and editor artefacts
cd "${PACKAGE_DIR}"
zip -r "${OUTPUT}" . \
    --exclude '*.backup' \
    --exclude '*.bak' \
    --exclude '*~' \
    --exclude '*.swp' \
    --exclude 'design-test.html' \
    --exclude '__pycache__/*' \
    --exclude '.DS_Store'

echo "Built: ${OUTPUT}"

# Generate SHA256 checksum
cd "${DIST_DIR}"
sha256sum "cachyos-drive-card-${VERSION}.plasmoid" > SHA256SUMS
echo "Checksum: ${DIST_DIR}/SHA256SUMS"
