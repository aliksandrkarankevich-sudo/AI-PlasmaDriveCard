# Drive Cards

![Plasma 6](https://img.shields.io/badge/KDE%20Plasma-6-blue)
![Version](https://img.shields.io/badge/version-0.95.0--beta1-orange)
![License](https://img.shields.io/badge/license-GPL--3.0--or--later-green)

Небольшой полупрозрачный виджет дисков для KDE Plasma 6 и CachyOS. Показывает смонтированные локальные разделы, свободное место, файловую систему и краткое имя физического накопителя.

English: a compact configurable drive-card widget for KDE Plasma 6.

## Возможности

- Русский и английский интерфейс.
- Автоматическая высота при изменении числа разделов.
- Открытие раздела нажатием по всей строке.
- Значки диска, папки и открытой папки.
- Масштаб текста и толщина индикатора заполнения.
- Цвета и прозрачность фона и текста.
- Настраиваемые скругления и прозрачные края.
- Индикатор операций чтения/записи.
- Автообновление после подключения и отключения накопителя.

## Установка

### Способ 1 — Автоматически из GitHub Releases (рекомендуется)

Скачивает последний выпуск, проверяет контрольную сумму и устанавливает:

```bash
curl -fsSL https://raw.githubusercontent.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard/main/scripts/install-from-github.sh -o install-from-github.sh
bash install-from-github.sh
```

> Рекомендуется сначала просмотреть скрипт: `less install-from-github.sh`

### Способ 2 — Вручную из Releases

1. Перейдите на страницу [Releases](https://github.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard/releases).
2. Скачайте файл `*.plasmoid`.
3. Установите командой:

```bash
kpackagetool6 --type Plasma/Applet --install cachyos-drive-card-*.plasmoid
```

При обновлении замените `--install` на `--upgrade`.

Либо откройте файл через Plasma: правая кнопка на рабочем столе → **Добавить виджеты** → **Установить виджет из локального файла**.

### Способ 3 — Через Git (стабильная ветка main)

Клонирует репозиторий и запускает скрипт установки:

```bash
git clone https://github.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard.git
cd AI-PlasmaDriveCard
bash scripts/install.sh
```

### Способ 4 — Через Git (бета-ветка)

Для тестирования последних изменений до официального релиза:

```bash
git clone --branch fix/v0.95.0-beta2-edge-fade --single-branch \
  https://github.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard.git
cd AI-PlasmaDriveCard
bash scripts/install.sh
```

> ⚠️ Бета-ветка может содержать нестабильный код. Перед установкой сохраните текущую версию.

#### Обновление через Git

Если виджет уже установлен из Git, для обновления до последнего коммита:

```bash
cd AI-PlasmaDriveCard
git pull
bash scripts/install.sh
```

## Удаление

```bash
bash scripts/uninstall.sh
```

Либо вручную:

```bash
kpackagetool6 --type Plasma/Applet --remove io.github.cachyos.drivecard
```

## Сборка и проверка

```bash
bash scripts/check.sh
bash scripts/build.sh
```

Готовый пакет появится в `dist/`.

## Сообщение об ошибке

Используйте форму **Bug report** в Issues. Приложите версию Plasma, способ установки, шаги воспроизведения, снимок экрана и вывод:

```bash
journalctl --user -b | grep -Ei "drivecard|qml|plasmoid"
```

## 💡 Предложения и идеи

Есть идея по улучшению? Откройте [Issue с шаблоном Feature Request](https://github.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard/issues/new?template=feature_request.yml) — опишите что хотите и зачем.

## Статус

0.95.0-beta1 — тестовая версия. Перед обновлением сохраните установленную 0.8.1.

## Лицензия

GPL-3.0-or-later.
