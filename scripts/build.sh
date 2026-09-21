#!/usr/bin/env bash
# Build the .plasmoid archive and generate SHA256SUMS.
# Usage: bash scripts/build.sh
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

version="$(python3 -c "import json; print(json.load(open('package/metadata.json'))['KPlugin']['Version'])")"
out="dist/cachyos-drive-card-${version}.plasmoid"

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
