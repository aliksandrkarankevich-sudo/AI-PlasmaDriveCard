# Drive Cards

![Plasma 6](https://img.shields.io/badge/KDE%20Plasma-6-blue)
![Version](https://img.shields.io/badge/version-0.95.0--beta1-orange)
![License](https://img.shields.io/badge/license-GPL--3.0--or--later-green)

Небольшой полупрозрачный виджет дисков для KDE Plasma 6 и CachyOS. Показывает смонтированные локальные разделы, свободное место, файловую систему и краткое имя физического накопителя.

English: a compact configurable drive-card widget for KDE Plasma 6.

## Возможности

- Русский и английский интерфейс.
- Автоматическая высота при изменении числа разделов.
- Открытие раздела кнопкой папки или нажатием по строке.
- Значки диска, папки и открытой папки.
- Масштаб текста и толщина индикатора заполнения.
- Цвета и прозрачность фона и текста.
- Настраиваемые скругления и прозрачные края.
- Индикатор операций чтения/записи.
- Автообновление после подключения и отключения накопителя.

## Установка beta1

Скачайте `.plasmoid` из Releases и выполните:

```bash
kpackagetool6 --type Plasma/Applet --upgrade cachyos-drive-card-0.95.0-beta1.plasmoid
```

При первой установке используйте `--install`. Затем добавьте «Карточка дисков» из списка виджетов Plasma.

## Из исходников

```bash
git clone https://github.com/aliksandrkarankevich-sudo/cachyos-drive-card.git
cd cachyos-drive-card
./scripts/install.sh
```

## Сборка и проверка

```bash
./scripts/check.sh
./scripts/build.sh
```

Готовый пакет появится в `dist/`.

## Сообщение об ошибке

Используйте форму **Bug report** в Issues. Приложите версию Plasma, способ установки, шаги воспроизведения, снимок экрана и вывод:

```bash
journalctl --user -b | grep -Ei "drivecard|qml|plasmoid"
```

## Статус

0.95.0-beta1 — тестовая версия. Перед обновлением сохраните установленную 0.8.1.

## Лицензия

GPL-3.0-or-later.
