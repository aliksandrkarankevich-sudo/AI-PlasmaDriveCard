# Настройка репозитория

Владелец: `aliksandrkarankevich-sudo`  
Репозиторий: `AI-PlasmaDriveCard`  
Основная ветка: `main`  
Текущая версия: `0.96.0-beta3`

## Рекомендуемые параметры

В `Settings → Branches` добавьте правило для `main`:

- Require a pull request before merging (по желанию, для одного разработчика можно оставить прямые коммиты).
- Require status checks to pass; выберите проверку `package` (workflow `Check`).
- Block force pushes.
- Block deletions.

В `Settings → General → Features` включите Issues и Discussions (на них ссылаются `SUPPORT.md` и шаблоны Issues). В `Issues → Labels` создайте метку `feedback`.

## Ветки

- `main` — текущая рабочая ветка и источник релизов.
- `fix/...` — исправления ошибок.
- `feature/...` — новые функции.
- `dev/...` и `archive/...` — исторические ветки версий (см. `VERSION_HISTORY.md`).

## Публикация релиза

1. Обновите `KPlugin.Version` в `package/metadata.json`, `CHANGELOG.md` и `ROADMAP.md`.
2. Выполните `bash scripts/check.sh` и проверьте виджет в Plasma 6.
3. Поставьте тег и отправьте его:

```bash
git tag v0.96.0-beta4
git push origin v0.96.0-beta4
```

4. Workflow `Release` соберёт пакет, опубликует `.plasmoid` и `SHA256SUMS`. Версии с `alpha`, `beta` или `rc` помечаются как pre-release.
5. При необходимости отредактируйте описание релиза и добавьте блок «Авторы» из `CHANGELOG.md`.

Ручной запуск: `Actions → Release → Run workflow` с указанием тега.
