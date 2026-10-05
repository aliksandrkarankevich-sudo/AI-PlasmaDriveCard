# Drive Cards

![Plasma 6](https://img.shields.io/badge/KDE%20Plasma-6-blue)
![Version](https://img.shields.io/badge/version-0.96.0--beta3-orange)
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
- Настраиваемые скругления и **четырёхсторонний переход в прозрачность** по краям.
- Индикатор операций чтения/записи.
- Автообновление после подключения и отключения накопителя.

## Установка

### Способ 1 — Автоматически из GitHub Releases (рекомендуется)

Скачивает последний выпуск, проверяет контрольную сумму и устанавливает. Если стабильных релизов нет, скрипт автоматически берёт последний pre-release:

```bash
curl -fsSL https://raw.githubusercontent.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard/main/scripts/install-from-github.sh -o install-from-github.sh
bash install-from-github.sh
```

Чтобы явно выбрать последний выпуск, включая beta-версии, запустите с флагом:

```bash
bash install-from-github.sh --prerelease
```

> Рекомендуется сначала просмотреть скрипт: `less install-from-github.sh`

После установки или обновления [перезапустите Plasma](#перезапуск-plasma).

### Способ 2 — Вручную из Releases

1. Перейдите на страницу [Releases](https://github.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard/releases).
2. Скачайте файл `*.plasmoid`.
3. Установите командой:

```bash
kpackagetool6 --type Plasma/Applet --install cachyos-drive-card-*.plasmoid
```

При обновлении замените `--install` на `--upgrade`.

Либо откройте через Plasma: правая кнопка на рабочем столе → **Добавить виджеты** → **Установить виджет из локального файла**.

### Способ 3 — Из исходников (для разработки и тестирования)

```bash
git clone https://github.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard.git
cd AI-PlasmaDriveCard
./scripts/install.sh
```

## Перезапуск Plasma

Чтобы новая версия виджета подхватилась, перезапустите plasmashell:

```bash
systemctl --user restart plasma-plasmashell.service
```

Если служба недоступна (plasmashell запущен не через systemd), используйте:

```bash
kquitapp6 plasmashell && kstart plasmashell
```

В fish вместо `&&` можно использовать `; and`. Команда `plasmashell --replace &` тоже работает, но запускает plasmashell в текущем терминале и выводит в него журнал всех виджетов и обоев.

## Удаление

```bash
./scripts/uninstall.sh
```

Либо вручную:

```bash
kpackagetool6 --type Plasma/Applet --remove io.github.cachyos.drivecard
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

0.96.0-beta3 — тестовая версия (pre-release). Стабильных выпусков пока нет. Перед обновлением сохраните настройки установленной версии.

## Авторы

- **Разработчик:** [aliksandrkarankevich-sudo](https://github.com/aliksandrkarankevich-sudo).
- **Соавтор:** Perplexity AI — ИИ-ассистент, помогавший с кодом, скриптами установки, релизами и документации.

Проект разрабатывается с участием ИИ. Все изменения проверяет и публикует разработчик.

## Лицензия

GPL-3.0-or-later.
