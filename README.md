# Drive Cards — виджет Plasma 6

Настраиваемые карточки смонтированных разделов для рабочего стола KDE Plasma 6.
Отображает свободное место, файловую систему, физический диск и активность ввода-вывода.
Нажатие на строку диска открывает его в файловом менеджере.

![Drive Cards](https://raw.githubusercontent.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard/main/preview.png)

---

## Быстрая установка

### Вариант 1 — Скачать готовый файл

1. Перейдите на страницу [Releases](https://github.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard/releases).
2. Скачайте файл `cachyos-drive-card-*.plasmoid`.
3. Откройте режим редактирования рабочего стола Plasma.
4. Нажмите **«Добавить виджеты»** → **«Установить виджет из файла»**.
5. Укажите скачанный `.plasmoid`.

Или через терминал:

```bash
kpackagetool6 --type Plasma/Applet --install cachyos-drive-card-*.plasmoid
```

### Вариант 2 — Автоматическая установка из GitHub

Скачивает и устанавливает последний релиз автоматически:

```bash
curl -fsSL https://raw.githubusercontent.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard/main/scripts/install-from-github.sh -o install-drive-cards.sh
bash install-drive-cards.sh
```

> Рекомендуется просмотреть скрипт перед запуском: `less install-drive-cards.sh`

### Вариант 3 — Установка через Git (для разработчиков и тестировщиков)

```bash
git clone --depth 1 https://github.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard.git
cd AI-PlasmaDriveCard
bash scripts/install.sh
```

Для установки конкретной версии:

```bash
git clone --branch v0.95.0-beta2 --depth 1 https://github.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard.git
cd AI-PlasmaDriveCard
bash scripts/install.sh
```

---

## Обновление

```bash
kpackagetool6 --type Plasma/Applet --upgrade cachyos-drive-card-*.plasmoid
```

## Удаление

```bash
kpackagetool6 --type Plasma/Applet --remove io.github.cachyos.drivecard
```

---

## Требования

- KDE Plasma 6.0+
- `findmnt`, `lsblk` (входят в состав `util-linux`)
- `udevadm` (входит в состав `udev` / `systemd`)

---

## Возможности

- Отображение смонтированных разделов с именем, свободным местом и процентом заполнения
- Цветовая индикация полосы заполнения: обычный / предупреждение / критический уровень
- Индикатор активности ввода-вывода для каждого диска
- Настраиваемый полупрозрачный фон с плавным переходом по всем четырём сторонам
- Открытие раздела в файловом менеджере нажатием на строку
- Варианты значка: диск, папка, открытая папка
- Поддержка светлой и тёмной темы, пользовательские цвета
- Автоопределение USB, NVMe, SATA
- Автоматическое обновление при монтировании и размонтировании
- Языки: русский, английский

---

## Настройка

Правой кнопкой мыши на виджете → **«Настроить Drive Cards»**.

---

## Сборка `.plasmoid` вручную

```bash
bash scripts/build.sh
```

Файл появится в `dist/`.

---

## Лицензия

GPL-3.0-or-later
