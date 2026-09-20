# Настройка репозитория

Владелец: `aliksandrkarankevich-sudo`  
Репозиторий: `cachyos-drive-card`  
Основная ветка: `main`  
Ветка разработки: `develop`

## Автоматическая публикация

После распаковки архива:

```bash
chmod +x scripts/*.sh
./scripts/publish-github.sh
```

Скрипт:

- инициализирует Git при необходимости;
- открывает безопасную авторизацию GitHub в браузере;
- создаёт публичный репозиторий;
- отправляет `main` и `develop`;
- включает Issues и Discussions;
- отключает Wiki;
- добавляет темы и основные метки.

## Рекомендуемые параметры

После публикации откройте `Settings → Branches` и добавьте правило для `main`:

- Require a pull request before merging.
- Require status checks to pass; выберите проверку `package`.
- Block force pushes.
- Block deletions.

До завершения личной проверки 0.95b1 не отправляйте тег релиза. После успешной проверки:

```bash
./scripts/release-beta.sh
```

## Структура веток

- `main` — проверенные версии и релизы.
- `develop` — объединение изменений следующей версии.
- `fix/...` — исправления ошибок.
- `feature/...` — новые функции.
