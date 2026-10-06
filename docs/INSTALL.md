# Установка

Текущая версия: **0.96.0-beta3** (pre-release).

## Из GitHub Releases (рекомендуется)

```bash
curl -fsSL https://raw.githubusercontent.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard/main/scripts/install-from-github.sh -o install-from-github.sh
bash install-from-github.sh
```

Скрипт скачивает последний релиз, проверяет контрольную сумму и устанавливает пакет. Если стабильных релизов нет, берётся последний pre-release (флаг `--prerelease` не обязателен).

## Готовый пакет вручную

Скачайте `.plasmoid` со страницы [Releases](https://github.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard/releases), затем:

```bash
kpackagetool6 --type Plasma/Applet --upgrade cachyos-drive-card-0.96.0-beta3.plasmoid
```

Первая установка: замените `--upgrade` на `--install`.

## Из исходников

```bash
git clone https://github.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard.git
cd AI-PlasmaDriveCard
./scripts/install.sh
```

Только сборка пакета: `./scripts/build.sh` (результат в `dist/`).

## Перезапуск Plasma

После установки или обновления перезапустите оболочку:

```bash
systemctl --user restart plasma-plasmashell.service
```

Если служба недоступна: `kquitapp6 plasmashell && kstart plasmashell` (в fish: `kquitapp6 plasmashell; and kstart plasmashell`).

## Удаление

```bash
./scripts/uninstall.sh
```

Или: `kpackagetool6 --type Plasma/Applet --remove io.github.cachyos.drivecard`.

## Откат

Удалите текущую версию и установите сохранённый пакет предыдущей версии (например, 0.95.0-beta2 или 0.8.1) либо восстановите каталог `~/.local/share/plasma/plasmoids/io.github.cachyos.drivecard` из резервной копии.
