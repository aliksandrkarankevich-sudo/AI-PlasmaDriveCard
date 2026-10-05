#!/usr/bin/env bash
# Validate package structure, metadata, and build artefact.
# Usage: bash scripts/check.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
PACKAGE_DIR="${ROOT_DIR}/package"
PASS=0
FAIL=0

# Use PASS=$((PASS+1)) instead of ((PASS++)): the latter returns exit code 1
# when the result is 0, which kills the script under set -e.
ok()   { echo "  [OK]  $*"; PASS=$((PASS+1)); }
fail() { echo "  [FAIL] $*"; FAIL=$((FAIL+1)); }

echo "=== Drive Cards package check ==="

# 1. Required files
for f in metadata.json \
         contents/ui/main.qml \
         contents/config/main.xml \
         contents/ui/ConfigGeneral.qml \
         contents/ui/ColorPicker.qml \
         contents/ui/EdgeFadeBackground.qml; do
    if [[ -f "${PACKAGE_DIR}/${f}" ]]; then
        ok "${f} exists"
    else
        fail "${f} missing"
    fi
done

# 2. No backup files inside package/
BACKUPS="$(find "${PACKAGE_DIR}" \( -name '*.backup' -o -name '*.backup-*' -o -name '*.bak' \) 2>/dev/null || true)"
if [[ -z "${BACKUPS}" ]]; then
    ok "No backup files in package/"
else
    fail "Backup files found: ${BACKUPS}"
fi

# 3. metadata.json has required fields
META="${PACKAGE_DIR}/metadata.json"
for field in Id Version Name KPackageStructure; do
    if grep -q "${field}" "${META}"; then
        ok "metadata.json has ${field}"
    else
        fail "metadata.json missing ${field}"
    fi
done

# 4. metadata.json is valid JSON
if python3 -c "import json; json.load(open('${META}'))" 2>/dev/null; then
    ok "metadata.json is valid JSON"
else
    fail "metadata.json is not valid JSON"
fi

# 5. main.xml is well-formed XML
MAIN_XML="${PACKAGE_DIR}/contents/config/main.xml"
if python3 -c "import xml.dom.minidom as m; m.parse('${MAIN_XML}')" 2>/dev/null; then
    ok "main.xml is well-formed"
else
    fail "main.xml is not well-formed XML"
fi

# 6. openOnRowClick was removed in beta2
if grep -q 'openOnRowClick' "${MAIN_XML}" "${PACKAGE_DIR}/contents/ui/ConfigGeneral.qml"; then
    fail "openOnRowClick still present in config"
else
    ok "No openOnRowClick in config"
fi

# 7. main.qml has no standalone folder-open ToolButton
MAIN_QML="${PACKAGE_DIR}/contents/ui/main.qml"
if grep -qE 'folder-open.*ToolButton|ToolButton.*folder-open' "${MAIN_QML}"; then
    fail "main.qml still contains standalone folder-open ToolButton"
else
    ok "main.qml: no standalone folder-open ToolButton"
fi

# 8. Build
echo ""
echo "--- Running build ---"
bash "${SCRIPT_DIR}/build.sh"

# 9. Verify .plasmoid artefact exists
VERSION="$(python3 -c "import json,sys; print(json.load(open('${META}'))['KPlugin']['Version'])")"
PLASMOID="${ROOT_DIR}/dist/cachyos-drive-card-${VERSION}.plasmoid"
if [[ -f "${PLASMOID}" ]]; then
    ok "${PLASMOID##*/} created"
else
    fail "${PLASMOID##*/} not found"
fi

# 10. No backup files inside the .plasmoid archive
if [[ -f "${PLASMOID}" ]]; then
    BAD="$(unzip -l "${PLASMOID}" | grep -E '\.backup|\.bak' || true)"
    if [[ -z "${BAD}" ]]; then
        ok "No backup files inside .plasmoid"
    else
        fail "Backup files inside .plasmoid: ${BAD}"
    fi
fi

echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="
if [[ "${FAIL}" -eq 0 ]]; then
    exit 0
else
    exit 1
fi
