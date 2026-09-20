#!/usr/bin/env bash
# build.sh — package Drive Cards into a .plasmoid archive
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION=$(python3 -c "import json; print(json.load(open('${ROOT}/package/metadata.json'))['KPlugin']['Version'])")
OUT="${ROOT}/dist/cachyos-drive-card-${VERSION}.plasmoid"

mkdir -p "${ROOT}/dist"

# Remove old artefacts for this version
rm -f "${OUT}"

cd "${ROOT}/package"

# Exclude backup files, editor swap files, and macOS metadata
zip -r "${OUT}" . \
    --exclude '*.backup*' \
    --exclude '*.bak' \
    --exclude '*.orig' \
    --exclude '*~' \
    --exclude '*.swp' \
    --exclude '__MACOSX/*' \
    --exclude '.DS_Store'

echo "Built: ${OUT}"
