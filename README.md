# Drive Cards

![Plasma 6](https://img.shields.io/badge/KDE%20Plasma-6-blue)
![Version](https://img.shields.io/badge/version-0.97.0--beta1-orange)
![License](https://img.shields.io/badge/license-GPL--3.0--or--later-green)

Небольшой полупрозрачный виджет дисков для KDE Plasma 6 и CachyOS. Показывает смонтированные локальные разделы, свободное место, файловую систему и краткое имя физического накопителя.

English: a compact configurable drive-card widget for KDE Plasma 6.

## Возможности

- Русский и английский интерфейс.
- Автоматическая высота при изменении числа разделов.
- Открытие раздела нажатием по всей строке.
- Значки диска, папки и открытой папки; отдельный значок и его размер для каждого тома.
- Масштаб текста и толщина индикатора заполнения.
- Цвета и прозрачность фона и текста, RGB ColorPicker с предварительным просмотром.
- Профили настроек: сохранение, загрузка и удаление пользовательских наборов.
- Группировка разделов под физическими дисками и RAID; единый раздел USB.
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

Для этой рабочей версии явно выберите ветку разработки. Установка из Releases выше не устанавливает неопубликованную 0.97-beta1.

```bash
git clone --branch dev/v0.97-beta1 https://github.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard.git
cd AI-PlasmaDriveCard
bash scripts/install.sh
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

Вручную:

```bash
kpackagetool6 --type Plasma/Applet --remove io.github.cachyos.drivecard
```

Из клонированного репозитория также можно выполнить `bash scripts/uninstall.sh`.

## Сборка и проверка

```bash
bash scripts/check.sh
bash scripts/build.sh
```

Готовый пакет появится в `dist/`.

## Сообщение об ошибке

Используйте форму **Bug report** в Issues. Приложите версию Plasma, способ установки, шаги воспроизведения, снимок экрана и вывод:

```bash
journalctl --user -b | grep -Ei "drivecard|qml"
```

## Статус

`dev/v0.97-beta1` — текущая ветка разработки; версия пакета `0.97.0-beta1`. Тег и GitHub Release для неё не создаются этим переходом.

Стабильная линия `0.96.0` подготавливается отдельно из неизменённой `dev/v0.96-beta5` в PR #13. До завершения публикации это кандидат, а не уже опубликованный стабильный выпуск. Более ранние версии считаются историческими, старые ветки и файлы Release сохраняются. Защита `main` не включается.

Незавершённые пункты в ROADMAP, аудите и документах beta4 остаются задачами разработки; старые названия в этих документах отражают историю. Номер 0.97-beta1 не означает, что эти проверки пройдены. Не выполнять слепое merge релизной metadata из main: в этой ветке сохранять `0.97.0-beta1`.

Перед обновлением сохраните настройки установленной версии.

## Авторы

- **Разработчик:** [aliksandrkarankevich-sudo](https://github.com/aliksandrkarankevich-sudo).
- **Соавтор:** Perplexity AI — ИИ-ассистент, помогавший с кодом, скриптами установки, релизами и документацией.

Проект разрабатывается с участием ИИ. Все изменения проверяет и публикует разработчик.

## Лицензия

GPL-3.0-or-later.
