# Drive Cards

![Plasma 6](https://img.shields.io/badge/KDE%20Plasma-6-blue)
![Version](https://img.shields.io/badge/version-0.95.0--beta2-orange)
![License](https://img.shields.io/badge/license-GPL--3.0--or--later-green)

Небольшой полупрозрачный виджет дисков для KDE Plasma 6 и CachyOS. Показывает смонтированные локальные разделы, свободное место, файловую систему и краткое имя физического накопителя.

English: a compact configurable drive-card widget for KDE Plasma 6.

## Возможности

- Русский и английский интерфейс.
- Автоматическая высота при изменении числа разделов.
- Открытие раздела нажатием по любому месту строки.
- Значки диска, папки и открытой папки.
- Масштаб текста и толщина индикатора заполнения.
- Цвета и прозрачность фона и текста.
- Четырёхсторонний переход фона в прозрачность с настраиваемой шириной и кривой.
- Настраиваемые скругления углов.
- Индикатор операций чтения/записи.
- Автообновление после подключения и отключения накопителя.

## Установка — способы

### 1. Скачать готовый файл из Releases (рекомендуется)

Перейдите на страницу [Releases](https://github.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard/releases), скачайте файл `cachyos-drive-card-*.plasmoid` и выполните:

```bash
kpackagetool6 --type Plasma/Applet --install cachyos-drive-card-0.95.0-beta2.plasmoid
```

Для обновления существующей установки:

```bash
kpackagetool6 --type Plasma/Applet --upgrade cachyos-drive-card-0.95.0-beta2.plasmoid
```

Либо откройте режим редактирования рабочего стола Plasma → **Добавить виджеты** → **Установить из локального файла** и укажите скачанный `.plasmoid`.

---

### 2. Установить последнюю версию одной командой

Просмотрите сценарий перед запуском:

```bash
curl -LO https://raw.githubusercontent.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard/main/scripts/install-from-github.sh
less install-from-github.sh
bash install-from-github.sh
```

Сценарий автоматически:
- находит последний Release,
- скачивает `.plasmoid` и `SHA256SUMS`,
- проверяет контрольную сумму,
- устанавливает или обновляет виджет.

Для установки конкретной версии:

```bash
bash install-from-github.sh --version v0.95.0-beta2
```

---

### 3. Установить из Git (для разработчиков и тестировщиков)

Последняя стабильная версия:

```bash
git clone --depth 1 https://github.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard.git
cd AI-PlasmaDriveCard
./scripts/install.sh
```

Конкретная версия по тегу:

```bash
git clone --branch v0.95.0-beta2 --depth 1 \
  https://github.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard.git
cd AI-PlasmaDriveCard
./scripts/install.sh
```

Тестовая ветка:

```bash
git clone --branch fix/v0.95.0-beta2-edge-fade --single-branch \
  https://github.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard.git
cd AI-PlasmaDriveCard
./scripts/check.sh
./scripts/install.sh
```

---

## Удаление

```bash
bash scripts/uninstall.sh
```

Или вручную:

```bash
kpackagetool6 --type Plasma/Applet --remove io.github.cachyos.drivecard
```

---

## Сборка и проверка

```bash
./scripts/check.sh   # проверка структуры и сборка
./scripts/build.sh   # только сборка
```

Готовый пакет появится в `dist/`.

---

## Сообщение об ошибке

Используйте форму **Bug report** в [Issues](https://github.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard/issues). Приложите:
- версию Plasma и дистрибутив;
- способ установки и версию виджета;
- шаги воспроизведения;
- снимок экрана;
- вывод журнала:

```bash
journalctl --user -b | grep -Ei "drivecard|qml|plasmoid"
```

---

## Статус

0.95.0-beta2 — тестовая версия. Исправлены четырёхсторонний переход прозрачности и открытие раздела по строке.

## Лицензия

GPL-3.0-or-later.
