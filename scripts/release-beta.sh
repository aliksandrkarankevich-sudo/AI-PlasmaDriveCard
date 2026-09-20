#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
./scripts/check.sh
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Есть незакоммиченные изменения. Сначала проверьте и закоммитьте их." >&2
  exit 1
fi
if git rev-parse v0.95.0-beta1 >/dev/null 2>&1; then
  echo "Тег v0.95.0-beta1 уже существует."
else
  git tag -a v0.95.0-beta1 -m "Drive Cards 0.95.0-beta1"
fi
git push origin v0.95.0-beta1
echo "Workflow создаст GitHub prerelease и приложит .plasmoid с SHA256SUMS."
