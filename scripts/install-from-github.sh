#!/usr/bin/env bash
# Install or upgrade Drive Cards from the latest GitHub Release.
# Usage: bash install-from-github.sh [--version v0.95.0-beta2]
set -euo pipefail

REPO="aliksandrkarankevich-sudo/AI-PlasmaDriveCard"
ID="io.github.cachyos.drivecard"
API="https://api.github.com/repos/${REPO}"
VERSION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) VERSION="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

command -v kpackagetool6 >/dev/null 2>&1 || {
  echo "Ошибка: kpackagetool6 не найден." >&2
  echo "Установите пакет plasma-framework (Arch: extra/plasma-framework)." >&2
  exit 1
}
command -v curl >/dev/null 2>&1 || { echo "Ошибка: curl не найден." >&2; exit 1; }

if [[ -z "$VERSION" ]]; then
  echo "→ Поиск последней версии..."
  RELEASE_JSON=$(curl -fsSL "${API}/releases/latest")
else
  echo "→ Поиск версии ${VERSION}..."
  RELEASE_JSON=$(curl -fsSL "${API}/releases/tags/${VERSION}")
fi

TAG=$(echo "$RELEASE_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['tag_name'])")
PLASMOID_URL=$(echo "$RELEASE_JSON" | python3 -c "
import sys,json
d=json.load(sys.stdin)
assets=[a for a in d.get('assets',[]) if a['name'].endswith('.plasmoid')]
if not assets: raise SystemExit('Файл .plasmoid не найден в релизе')
print(assets[0]['browser_download_url'])
")
SHA_URL=$(echo "$RELEASE_JSON" | python3 -c "
import sys,json
d=json.load(sys.stdin)
assets=[a for a in d.get('assets',[]) if a['name']=='SHA256SUMS']
print(assets[0]['browser_download_url'] if assets else '')
")

FILE=$(basename "$PLASMOID_URL")
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "→ Скачиваем ${FILE} (${TAG})..."
curl -fSL --progress-bar -o "${TMPDIR}/${FILE}" "$PLASMOID_URL"

if [[ -n "$SHA_URL" ]]; then
  echo "→ Проверяем контрольную сумму..."
  curl -fsSL -o "${TMPDIR}/SHA256SUMS" "$SHA_URL"
  (cd "$TMPDIR" && sha256sum -c SHA256SUMS --ignore-missing) || {
    echo "Ошибка: контрольная сумма не совпадает. Файл повреждён." >&2
    exit 1
  }
fi

if kpackagetool6 --type Plasma/Applet --show "$ID" >/dev/null 2>&1; then
  echo "→ Обновляем установленную версию..."
  kpackagetool6 --type Plasma/Applet --upgrade "${TMPDIR}/${FILE}"
else
  echo "→ Устанавливаем..."
  kpackagetool6 --type Plasma/Applet --install "${TMPDIR}/${FILE}"
fi

echo ""
echo "✓ Drive Cards ${TAG} установлен."
echo "  Добавьте виджет 'Drive Cards' из интерфейса Plasma."
