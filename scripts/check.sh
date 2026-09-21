#!/usr/bin/env bash
# Validate the package structure, metadata, and build artefact.
# Usage: ./scripts/check.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
PACKAGE_DIR="${ROOT_DIR}/package"
PASS=0
FAIL=0

ok()   { echo "  [OK]  $*"; ((PASS++)) || true; }
fail() { echo "  [FAIL] $*"; ((FAIL++)) || true; }

echo "=== Drive Cards package check ==="

# 1. Required files
for f in metadata.json contents/ui/main.qml contents/config/main.xml \
         contents/ui/ConfigGeneral.qml contents/ui/EdgeFadeBackground.qml; do
    [[ -f "${PACKAGE_DIR}/${f}" ]] && ok "${f} exists" || fail "${f} missing"
done

# 2. No backup files inside package/
BACKUPS="$(find "${PACKAGE_DIR}" -name '*.backup' -o -name '*.backup-*' -o -name '*.bak' 2>/dev/null)"
[[ -z "${BACKUPS}" ]] && ok "No backup files in package/" || fail "Backup files found:\n${BACKUPS}"

# 3. metadata.json has required fields
META="${PACKAGE_DIR}/metadata.json"
for field in Id Version Name KPackageStructure; do
    grep -q "${field}" "${META}" && ok "metadata.json has ${field}" || fail "metadata.json missing ${field}"
done

# 4. main.xml consistency: no openOnRowClick
MAIN_XML="${PACKAGE_DIR}/contents/config/main.xml"
if grep -q 'openOnRowClick' "${MAIN_XML}"; then
    fail "main.xml still contains openOnRowClick (should be removed in beta2)"
else
    ok "main.xml does not contain openOnRowClick"
fi

# 5. ConfigGeneral.qml consistency: no openOnRowClick
CFG="${PACKAGE_DIR}/contents/ui/ConfigGeneral.qml"
if grep -q 'openOnRowClick' "${CFG}"; then
    fail "ConfigGeneral.qml still contains openOnRowClick"
else
    ok "ConfigGeneral.qml does not contain openOnRowClick"
fi

# 6. main.qml uses ItemDelegate (not plain Item) for list delegate
MAIN_QML="${PACKAGE_DIR}/contents/ui/main.qml"
if grep -q 'QQC2.ItemDelegate' "${MAIN_QML}"; then
    ok "main.qml uses ItemDelegate for list rows"
else
    fail "main.qml does not use ItemDelegate for list rows"
fi

# 7. main.qml has no standalone folder-open ToolButton
if grep -q 'folder-open.*ToolButton\|ToolButton.*folder-open' "${MAIN_QML}"; then
    fail "main.qml still contains standalone folder-open ToolButton"
else
    ok "No standalone folder-open ToolButton in main.qml"
fi

# 8. EdgeFadeBackground.qml has four-sided fade (both Horizontal and Vertical gradients)
#    Since beta2 the gradients live in EdgeFadeBackground.qml, not main.qml.
EDGE_QML="${PACKAGE_DIR}/contents/ui/EdgeFadeBackground.qml"
if [[ -f "${EDGE_QML}" ]]; then
    H="$(grep -c 'Gradient.Horizontal' "${EDGE_QML}" || true)"
    V="$(grep -c 'Gradient.Vertical' "${EDGE_QML}" || true)"
    [[ "${H}" -ge 1 ]] && ok "EdgeFadeBackground.qml has Horizontal gradient mask" || fail "EdgeFadeBackground.qml missing Horizontal gradient mask"
    [[ "${V}" -ge 1 ]] && ok "EdgeFadeBackground.qml has Vertical gradient mask" || fail "EdgeFadeBackground.qml missing Vertical gradient mask"
else
    fail "EdgeFadeBackground.qml not found"
fi

# 9. Build test
echo ""
echo "--- Running build ---"
bash "${SCRIPT_DIR}/build.sh"

# 10. Verify .plasmoid artefact
VERSION="$(python3 -c "import json; print(json.load(open('${META}'))['KPlugin']['Version'])")"
PLASMOID="${ROOT_DIR}/dist/cachyos-drive-card-${VERSION}.plasmoid"
[[ -f "${PLASMOID}" ]] && ok "${PLASMOID##*/} created" || fail "${PLASMOID##*/} not found"

# 11. No backup files inside the .plasmoid archive
if [[ -f "${PLASMOID}" ]]; then
    BAD="$(unzip -l "${PLASMOID}" | grep -E '\.backup|\.bak' || true)"
    [[ -z "${BAD}" ]] && ok "No backup files inside .plasmoid" || fail "Backup files inside .plasmoid:\n${BAD}"
fi

echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="
[[ "${FAIL}" -eq 0 ]] && exit 0 || exit 1
