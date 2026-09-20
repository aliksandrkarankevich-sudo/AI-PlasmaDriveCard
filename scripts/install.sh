#!/usr/bin/env bash
# Install or upgrade Drive Cards from a local Git clone.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
ID="io.github.cachyos.drivecard"

command -v kpackagetool6 >/dev/null 2>&1 || {
  echo "Ошибка: kpackagetool6 не найден." >&2
  echo "Установите пакет plasma-framework (Arch: extra/plasma-framework)." >&2
  exit 1
}

VERSION=$(python3 -c "import json; print(json.load(open('package/metadata.json'))['KPlugin']['Version'])")

if kpackagetool6 --type Plasma/Applet --show "$ID" >/dev/null 2>&1; then
  echo "→ Обновляем Drive Cards ${VERSION}..."
  kpackagetool6 --type Plasma/Applet --upgrade package
else
  echo "→ Устанавливаем Drive Cards ${VERSION}..."
  kpackagetool6 --type Plasma/Applet --install package
fi

echo ""
echo "✓ Drive Cards ${VERSION} установлен."
echo "  Добавьте виджет 'Drive Cards' из интерфейса Plasma."
