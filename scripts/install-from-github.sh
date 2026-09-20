#!/usr/bin/env bash
# install-from-github.sh — скачивает и устанавливает последний релиз Drive Cards
# Использование: bash install-from-github.sh
# Требования: curl, sha256sum, kpackagetool6
set -euo pipefail

REPO="aliksandrkarankevich-sudo/AI-PlasmaDriveCard"
API="https://api.github.com/repos/${REPO}/releases/latest"
PKG_ID="io.github.cachyos.drivecard"

echo "==> Drive Cards: получение информации о последнем релизе..."
if ! command -v curl &>/dev/null; then
  echo "Ошибка: curl не найден. Установите curl и повторите попытку."
  exit 1
fi
if ! command -v kpackagetool6 &>/dev/null; then
  echo "Ошибка: kpackagetool6 не найден. Убедитесь, что Plasma 6 установлена."
  exit 1
fi

# Получаем URL .plasmoid и SHA256SUMS из последнего релиза
RELEASE_JSON=$(curl -fsSL "${API}")
PLASMOID_URL=$(echo "${RELEASE_JSON}" | grep -o '"browser_download_url": "[^"]*\.plasmoid"' | head -1 | cut -d'"' -f4)
SHA256_URL=$(echo "${RELEASE_JSON}" | grep -o '"browser_download_url": "[^"]*SHA256SUMS"' | head -1 | cut -d'"' -f4)
VERSION=$(echo "${RELEASE_JSON}" | grep -o '"tag_name": "[^"]*"' | head -1 | cut -d'"' -f4)

if [[ -z "${PLASMOID_URL}" ]]; then
  echo "Ошибка: не удалось найти .plasmoid в последнем релизе."
  echo "Проверьте: https://github.com/${REPO}/releases"
  exit 1
fi

FILENAME=$(basename "${PLASMOID_URL}")
TMPDIR=$(mktemp -d)
trap 'rm -rf "${TMPDIR}"' EXIT

echo "==> Версия: ${VERSION}"
echo "==> Скачивание: ${FILENAME}..."
curl -fL --progress-bar -o "${TMPDIR}/${FILENAME}" "${PLASMOID_URL}"

# Проверяем SHA256 если файл доступен
if [[ -n "${SHA256_URL}" ]]; then
  echo "==> Проверка SHA256..."
  curl -fsSL -o "${TMPDIR}/SHA256SUMS" "${SHA256_URL}"
  cd "${TMPDIR}"
  if sha256sum --check --ignore-missing SHA256SUMS; then
    echo "==> SHA256: OK"
  else
    echo "Ошибка: контрольная сумма не совпадает. Файл повреждён."
    exit 1
  fi
  cd - >/dev/null
else
  echo "==> Предупреждение: файл SHA256SUMS не найден, пропускаем проверку."
fi

# Устанавливаем или обновляем
if kpackagetool6 --type Plasma/Applet --show "${PKG_ID}" &>/dev/null; then
  echo "==> Обновление существующей установки..."
  kpackagetool6 --type Plasma/Applet --upgrade "${TMPDIR}/${FILENAME}"
else
  echo "==> Установка виджета..."
  kpackagetool6 --type Plasma/Applet --install "${TMPDIR}/${FILENAME}"
fi

echo ""
echo "✓ Drive Cards ${VERSION} успешно установлен!"
echo "  Добавьте виджет 'Drive Cards' на рабочий стол Plasma."
echo "  Удаление: kpackagetool6 --type Plasma/Applet --remove ${PKG_ID}"
