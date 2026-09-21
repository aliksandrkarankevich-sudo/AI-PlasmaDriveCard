#!/usr/bin/env bash
# Build the .plasmoid archive, generate SHA256SUMS, then install or upgrade.
# Usage: bash scripts/build.sh
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

version="$(python3 -c "import json; print(json.load(open('package/metadata.json'))['KPlugin']['Version'])")"
out="dist/cachyos-drive-card-${version}.plasmoid"
plugin_id="$(python3 -c "import json; print(json.load(open('package/metadata.json'))['KPlugin']['Id'])")"

mkdir -p dist
rm -f "${out}" dist/SHA256SUMS

python3 - "${out}" <<'PY'
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import sys

root = Path('package')
exclude = ('.backup', '.backup-before-fix', '~', '.swp', '.swo', '.DS_Store')

with ZipFile(sys.argv[1], 'w', ZIP_DEFLATED) as z:
    for p in sorted(root.rglob('*')):
        if not p.is_file():
            continue
        if any(pat in p.name for pat in exclude):
            continue
        z.write(p, p.relative_to(root))
PY

( cd dist && sha256sum "$(basename "${out}")" > SHA256SUMS )

echo "Built: ${out}"

# Install or upgrade
if kpackagetool6 --type=Plasma/Applet --list 2>/dev/null | grep -qF "${plugin_id}"; then
    kpackagetool6 --type=Plasma/Applet --upgrade "${out}"
else
    kpackagetool6 --type=Plasma/Applet --install "${out}"
fi
