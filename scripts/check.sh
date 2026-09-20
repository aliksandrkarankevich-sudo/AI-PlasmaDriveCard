#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
version="$(python3 -c "import json; print(json.load(open('package/metadata.json'))['KPlugin']['Version'])")"
archive="dist/cachyos-drive-card-${version}.plasmoid"
python3 - <<'PY'
from pathlib import Path
import json, re
import xml.etree.ElementTree as ET
required=[
    Path('package/metadata.json'),
    Path('package/contents/config/config.qml'),
    Path('package/contents/config/main.xml'),
    Path('package/contents/ui/ConfigGeneral.qml'),
    Path('package/contents/ui/main.qml'),
    Path('package/contents/ui/EdgeFadeBackground.qml')
]
missing=[str(p) for p in required if not p.is_file()]
assert not missing, f'Missing files: {missing}'
meta=json.loads(required[0].read_text())
assert meta['KPlugin']['Id']=='io.github.cachyos.drivecard'
assert meta['KPlugin']['Version']=='0.95.0-beta2'
assert meta['KPackageStructure']=='Plasma/Applet'
ET.parse(required[2])
cfg=required[3].read_text()
xml=required[2].read_text()
main=required[4].read_text()
fade=required[5].read_text()
props=set(re.findall(r'property\s+\w+\s+cfg_(\w+)',cfg))
entries=set(re.findall(r'<entry name="([^"]+)"',xml))
assert props==entries, f'Configuration mismatch: {sorted(props^entries)}'
assert 'openOnRowClick' not in cfg+xml+main, 'Obsolete row-click option remains'
assert 'QQC2.ToolButton' not in main, 'Separate open button remains'
assert 'QQC2.ItemDelegate' in main and 'onClicked: root.openTarget(target)' in main
assert 'createLinearGradient(0, 0, w, 0)' in fade, 'Horizontal fade is missing'
assert 'createLinearGradient(0, 0, 0, h)' in fade, 'Vertical fade is missing'
assert 'destination-in' in fade, 'Fade masks are not composed'
print('Package layout, metadata, XML, configuration and regressions: OK')
PY
bash -n scripts/*.sh
./scripts/build.sh
python3 - "$archive" <<'PY'
from pathlib import Path
from zipfile import ZipFile
import sys
p=Path(sys.argv[1])
assert p.is_file(), f'Archive not found: {p}'
with ZipFile(p) as z:
    assert z.testzip() is None
    names=set(z.namelist())
    required={'metadata.json','contents/ui/main.qml','contents/ui/EdgeFadeBackground.qml','contents/config/main.xml'}
    assert required <= names, f'Archive files missing: {sorted(required-names)}'
    forbidden=[name for name in names if name.lower().endswith(('.bak','.backup','.orig','.rej','.tmp','~')) or '.backup-' in name.lower()]
    assert not forbidden, f'Backup files included: {forbidden}'
print('Plasmoid archive: OK')
PY
if command -v qmllint >/dev/null 2>&1; then
  qmllint package/contents/ui/main.qml package/contents/ui/EdgeFadeBackground.qml package/contents/ui/ConfigGeneral.qml package/contents/config/config.qml
else
  echo "qmllint не найден: QML-проверка пропущена."
fi
