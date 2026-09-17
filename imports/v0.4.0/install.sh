#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
id="io.github.cachyos.drivecard"
if kpackagetool6 --type Plasma/Applet --show "$id" >/dev/null 2>&1; then
  kpackagetool6 --type Plasma/Applet --upgrade package
else
  kpackagetool6 --type Plasma/Applet --install package
fi
printf '\nInstalled %s. Add “Карточка диска” from desktop edit mode.\n' "$id"
