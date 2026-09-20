#!/usr/bin/env bash
# Скачивает и устанавливает последний Drive Cards из GitHub Releases
# Использование: bash scripts/install-from-github.sh
set -euo pipefail

REPO="aliksandrkarankevich-sudo/AI-PlasmaDriveCard"
API="https://api.github.com/repos/${REPO}/releases/latest"
ID="io.github.cachyos.drivecard"

# Проверка зависимостей
command -v kpackagetool6 >/dev/null 2>&1 || {
  echo "Ошибка: kpackagetool6 не найден." >&2
  echo "  Arch/CachyOS: sudo pacman -S kpackage" >&2
  exit 1
}
command -v curl >/dev/null 2>&1 || {
  echo "Ошибка: curl не найден. Установите curl." >&2
  exit 1
}

# sudo запрещён — виджет устанавливается для текущего пользователя
[ "$(id -u)" -eq 0 ] && {
  echo "Ошибка: не запускайте этот скрипт от root или через sudo." >&2
  exit 1
}

echo "Получаю информацию о последнем выпуске..."
RELEASE_JSON=$(curl -fsSL "$API")

ASSET_URL=$(printf '%s' "$RELEASE_JSON" \
  | grep -o '"browser_download_url": "[^"]*\.plasmoid"' \
  | head -1 \
  | cut -d'"' -f4)

[ -z "$ASSET_URL" ] && {
  echo "Ошибка: .plasmoid не найден в последнем выпуске." >&2
  echo "Проверьте: https://github.com/${REPO}/releases" >&2
  exit 1
}

VERSION=$(printf '%s' "$RELEASE_JSON" \
  | grep -o '"tag_name": "[^"]*"' \
  | head -1 \
  | cut -d'"' -f4)

FILENAME=$(basename "$ASSET_URL")
TMPDIR_WORK=$(mktemp -d)
trap 'rm -rf "$TMPDIR_WORK"' EXIT

echo "Скачиваю $FILENAME (версия $VERSION)..."
curl -fL -o "$TMPDIR_WORK/$FILENAME" "$ASSET_URL"

# Проверка контрольной суммы (если файл SHA256SUMS доступен)
SHA_URL="${ASSET_URL%.plasmoid}.SHA256SUMS"
if curl -fsSL -o "$TMPDIR_WORK/SHA256SUMS" "$SHA_URL" 2>/dev/null; then
  echo "Проверяю контрольную сумму..."
  (cd "$TMPDIR_WORK" && sha256sum -c SHA256SUMS --ignore-missing --quiet) || {
    echo "Ошибка: контрольная сумма не совпадает. Файл повреждён." >&2
    exit 1
  }
  echo "Контрольная сумма в порядке."
else
  echo "SHA256SUMS не найден в выпуске — пропускаю проверку."
fi

# Установка или обновление
if kpackagetool6 --type Plasma/Applet --show "$ID" >/dev/null 2>&1; then
  echo "Обновляю виджет..."
  kpackagetool6 --type Plasma/Applet --upgrade "$TMPDIR_WORK/$FILENAME"
  echo "Drive Cards успешно обновлён до $VERSION."
else
  echo "Устанавливаю виджет..."
  kpackagetool6 --type Plasma/Applet --install "$TMPDIR_WORK/$FILENAME"
  echo "Drive Cards $VERSION установлен."
  echo "Добавьте виджет через интерфейс Plasma (правая кнопка на рабочем столе → Добавить виджеты)."
fi
