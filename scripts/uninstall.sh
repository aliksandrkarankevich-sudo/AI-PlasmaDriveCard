#!/usr/bin/env bash
# Remove Drive Cards Plasma widget.
set -euo pipefail
ID="io.github.cachyos.drivecard"

command -v kpackagetool6 >/dev/null 2>&1 || {
  echo "Ошибка: kpackagetool6 не найден." >&2; exit 1
}

if kpackagetool6 --type Plasma/Applet --show "$ID" >/dev/null 2>&1; then
  kpackagetool6 --type Plasma/Applet --remove "$ID"
  echo "✓ Drive Cards удалён."
else
  echo "Drive Cards не установлен." >&2
  exit 1
fi
