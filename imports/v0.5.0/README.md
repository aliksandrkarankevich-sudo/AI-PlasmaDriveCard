# Карточка дисков / Drive Card 0.5.0

Плазмоид KDE Plasma 6 показывает все реальные файловые системы, уже смонтированные и доступные в текущем сеансе. Каждая строка открывает свою точку монтирования. Язык интерфейса можно вручную переключить между русским и английским.

## Обновление с 0.4.0

```fish
kpackagetool6 --type Plasma/Applet --upgrade ~/Загрузки/cachyos-drive-card-0.5.0.plasmoid
systemctl --user restart plasma-plasmashell.service
```

Если `--upgrade` сообщает об ошибке, удалите и установите заново:

```fish
kpackagetool6 --type Plasma/Applet --remove io.github.cachyos.drivecard
kpackagetool6 --type Plasma/Applet --install ~/Загрузки/cachyos-drive-card-0.5.0.plasmoid
systemctl --user restart plasma-plasmashell.service
```

## Логика

- Один вызов `findmnt` возвращает JSON для всех реальных файловых систем.
- Показываются только уже смонтированные файловые системы; пароль не запрашивается.
- Повторные точки монтирования одной файловой системы удаляются по `SOURCE`.
- `/`, `/boot` и `/boot/efi` можно скрыть в настройках.
- По щелчку открывается `file://` URL в файловом менеджере по умолчанию.

## Зависимости

Plasma 6, `plasma5support`, `util-linux`.

Лицензия: GPL-3.0-or-later.
