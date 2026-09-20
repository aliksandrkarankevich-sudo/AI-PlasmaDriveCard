#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
owner="aliksandrkarankevich-sudo"
repo="cachyos-drive-card"
command -v gh >/dev/null || { echo "Установите GitHub CLI: sudo pacman -S github-cli" >&2; exit 1; }
if [ ! -d .git ]; then
  git init -b main
  git config user.name "${GIT_AUTHOR_NAME:-$owner}"
  git config user.email "${GIT_AUTHOR_EMAIL:-$owner@users.noreply.github.com}"
  git add .
  git commit -m "Initial Drive Cards 0.95.0-beta1 repository"
fi
if ! git show-ref --verify --quiet refs/heads/develop; then git branch develop; fi
if ! gh auth status >/dev/null 2>&1; then
  echo "Сначала откроется безопасная авторизация GitHub."
  gh auth login --hostname github.com --git-protocol https --web
fi
if gh repo view "$owner/$repo" >/dev/null 2>&1; then
  echo "Репозиторий уже существует; подключаю origin."
  git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$owner/$repo.git"
  git push -u origin main
  git push -u origin develop
else
  gh repo create "$owner/$repo" --public --source=. --remote=origin --push \
    --description "Drive Cards — configurable disk-space widget for KDE Plasma 6 and CachyOS"
  git push -u origin develop
fi
gh repo edit "$owner/$repo" --enable-issues --enable-discussions --enable-wiki=false \
  --add-topic kde --add-topic plasma --add-topic plasma-6 --add-topic plasmoid \
  --add-topic cachyos --add-topic qml --add-topic disk-space
for spec in "bug:d73a4a:Ошибка" "enhancement:a2eeef:Улучшение" "documentation:0075ca:Документация" "beta:fbca04:Beta-версия" "dependencies:0366d6:Зависимости"; do
  IFS=: read -r name color description <<< "$spec"
  gh label create "$name" --repo "$owner/$repo" --color "$color" --description "$description" --force
 done
printf '\nГотово: https://github.com/%s/%s\n' "$owner" "$repo"
printf 'После успешной проверки beta1 выполните: ./scripts/release-beta.sh\n'
