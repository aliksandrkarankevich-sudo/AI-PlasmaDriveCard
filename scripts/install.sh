#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
id=io.github.cachyos.drivecard
command -v kpackagetool6 >/dev/null || { echo "Нет kpackagetool6. Установите пакет kpackage." >&2; exit 1; }
if kpackagetool6 --type Plasma/Applet --show "$id" >/dev/null 2>&1; then
  kpackagetool6 --type Plasma/Applet --upgrade package
else
  kpackagetool6 --type Plasma/Applet --install package
fi
echo "Drive Cards установлен. Добавьте виджет через интерфейс Plasma."
