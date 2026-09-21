#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
version="$(python3 -c "import json; print(json.load(open('package/metadata.json'))['KPlugin']['Version'])")"
out="dist/cachyos-drive-card-${version}.plasmoid"
mkdir -p dist
rm -f "$out" dist/SHA256SUMS
python3 - "$out" <<'PY'
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import sys
root = Path('package')
exclude_patterns = ('.backup', '.backup-before-fix', '~', '.swp', '.swo', '.DS_Store')
with ZipFile(sys.argv[1], 'w', ZIP_DEFLATED) as z:
    for p in sorted(root.rglob('*')):
        if not p.is_file():
            continue
        name = p.name
        if any(pat in name for pat in exclude_patterns):
            continue
        z.write(p, p.relative_to(root))
PY
(cd dist && sha256sum "$(basename "$out")" > SHA256SUMS)
echo "\u0421\u043e\u0437\u0434\u0430\u043d $out"
