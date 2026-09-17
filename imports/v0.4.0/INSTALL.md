# Установка, проверка и отладка

## Зависимости CachyOS / Plasma 6

Пакеты, которые уже почти наверняка установлены:

- `plasma-desktop`
- `plasma5support` — совместимый DataSource для запуска команды
- `coreutils` — команда `df`
- `util-linux` — команда `findmnt`
- `kpackage` / `kpackagetool6`

Проверка:

```bash
pacman -Q plasma-desktop plasma5support coreutils util-linux
command -v kpackagetool6 df findmnt
```

## Установка

Удалите предыдущую тестовую копию, если она есть:

```bash
kpackagetool6 --type Plasma/Applet --remove io.github.cachyos.drivecard
```

Установите пакет **без root**:

```bash
kpackagetool6 --type Plasma/Applet --install /путь/к/cachyos-drive-card-0.4.0.plasmoid
```

Если виджет уже установлен, обновляйте так:

```bash
kpackagetool6 --type Plasma/Applet --upgrade /путь/к/cachyos-drive-card-0.4.0.plasmoid
```

Либо из распакованного исходника:

```bash
chmod +x install.sh
./install.sh
```

Виджет попадает в `~/.local/share/plasma/plasmoids/io.github.cachyos.drivecard/`.

После установки:

1. Правый щелчок по рабочему столу → **Изменить / Настроить рабочий стол**.
2. **Добавить виджеты**.
3. Найти **Карточка диска**.
4. Перетащить на рабочий стол.
5. Открыть настройки карточки.
6. Указать реальную точку монтирования, например `/mnt/LinuxGames`.

Если список виджетов не обновился:

```bash
systemctl --user restart plasma-plasmashell.service
```

## Проверка до настройки виджета

Раздел должен быть **уже смонтирован**. Виджет сам его не подключает.

```bash
findmnt /mnt/LinuxGames
df -h /mnt/LinuxGames
```

Ожидается, что `findmnt` покажет устройство и точку монтирования, а `df` — размер и доступное место. Если `findmnt` ничего не выводит, сначала смонтируйте раздел, иначе карточка покажет «Диск не подключён».

Проверка открытия каталога тем же способом, что и виджет:

```bash
xdg-open file:///mnt/LinuxGames
```

## Проверка самого виджета

После добавления карточки на рабочий стол:

- Название совпадает с настройкой, по умолчанию `Games`.
- Текст показывает **свободно X из Y**, а не занятый объём как «свободно».
- Полоса заполнения растёт вместе с процентом **занятого** места.
- Пока раздел смонтирован, щелчок открывает Dolphin или другой файловый менеджер по умолчанию.
- Если путь существует как папка, но не является mount point, появляется «Диск не подключён», а не место корневого раздела.
- Правый щелчок по виджету даёт пункты **Обновить** и **Открыть диск**.
- В режиме редактирования рабочего стола можно сменить фон карточки: полупрозрачный фон включён по умолчанию.

Быстрая проверка команды, которую выполняет виджет (подставьте свой путь):

```bash
p='/mnt/LinuxGames'
if [ "$p" = / ] || findmnt -rn -M "$p" >/dev/null 2>&1; then
  LC_ALL=C df -B1 --output=size,avail,pcent -- "$p"
else
  printf '__DC_UNMOUNTED__
'
fi
```

## Отладка

### 1. Виджет не появляется в списке

```bash
kpackagetool6 --type Plasma/Applet --list | grep drivecard
ls ~/.local/share/plasma/plasmoids/io.github.cachyos.drivecard
```

Если каталога нет — установка не прошла. Если каталог есть, а в списке виджета нет, проверьте `metadata.json`: обязательны `KPackageStructure: Plasma/Applet` и `X-Plasma-API-Minimum-Version: 6.0`.

### 2. Карточка пустая или «виджет с ошибкой»

Смотрите журнал Plasmashell:

```bash
journalctl --user -u plasma-plasmashell.service -b --no-pager | tail -n 80
```

Живой просмотр во время добавления виджета:

```bash
journalctl --user -u plasma-plasmashell.service -f
```

Ищите `io.github.cachyos.drivecard`, `QML`, `Error`, `module "org.kde.plasma.plasma5support"`.

Если нет модуля `plasma5support`:

```bash
sudo pacman -S plasma5support
```

### 3. Просмотр без рабочего стола

Если установлен `plasma-sdk`:

```bash
plasmoidviewer -a io.github.cachyos.drivecard
```

### 4. Неверные цифры

Сравните вывод виджета с:

```bash
LC_ALL=C df -B1 --output=source,fstype,size,avail,pcent,target -- /mnt/LinuxGames
```

Виджет показывает столбец `avail` — место, доступное **текущему пользователю**, а не все физически свободные блоки.

### 5. Щелчок ничего не открывает

Проверьте, что на карточке есть цифры, а не ошибка, и что URL открывается системой:

```bash
xdg-open "file:///mnt/LinuxGames"
xdg-mime query default inode/directory
```

### 6. Удаление

```bash
kpackagetool6 --type Plasma/Applet --remove io.github.cachyos.drivecard
```

## Известное ограничение 0.4.0

Источник данных — совместимый `Plasma5Support.DataSource` с `findmnt` и `df`. Это намеренный минимальный вариант без C++. Он не монтирует диски и не отслеживает UUID. Следующий крупный шаг после визуальной проверки — заменить только backend на Solid + KIO, не переписывая карточку.
