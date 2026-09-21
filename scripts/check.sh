#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
python3 - <<'PY'
from pathlib import Path
import json, re
import xml.etree.ElementTree as ET
required=[Path('package/metadata.json'),Path('package/contents/config/config.qml'),Path('package/contents/config/main.xml'),Path('package/contents/ui/ConfigGeneral.qml'),Path('package/contents/ui/main.qml')]
missing=[str(p) for p in required if not p.is_file()]
assert not missing, f'Missing files: {missing}'
meta=json.loads(required[0].read_text())
assert meta['KPlugin']['Id']=='io.github.cachyos.drivecard'
assert meta['KPackageStructure']=='Plasma/Applet'
version=meta['KPlugin']['Version']
print(f'Version from metadata: {version}')
ET.parse(required[2])
cfg=required[3].read_text(); xml=required[2].read_text()
props=set(re.findall(r'property\s+\w+\s+cfg_(\w+)',cfg))
entries=set(re.findall(r'<entry name="([^"]+)"',xml))
assert props==entries, f'Configuration mismatch: {sorted(props^entries)}'
print('Package layout, metadata, XML and configuration: OK')
PY
bash -n scripts/*.sh
./scripts/build.sh
python3 - <<'PY'
from zipfile import ZipFile
import json
from pathlib import Path
version=json.loads(Path('package/metadata.json').read_text())['KPlugin']['Version']
p=f'dist/cachyos-drive-card-{version}.plasmoid'
with ZipFile(p) as z:
    assert z.testzip() is None
    names=set(z.namelist())
    assert {'metadata.json','contents/ui/main.qml','contents/config/main.xml'} <= names
print(f'Plasmoid archive {p}: OK')
PY
if command -v qmllint >/dev/null 2>&1; then
  qmllint package/contents/ui/main.qml package/contents/ui/ConfigGeneral.qml package/contents/config/config.qml
else
  echo "qmllint не найден: QML-проверка пропущена."
fi
