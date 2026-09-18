# Карточка дисков 0.6.2

Аварийное исправление 0.6.0: удалены проблемные attached properties, Screen и Canvas. Сохранены автоматическая высота, прокрутка списка, прозрачность фона и текста, скругление и плавный край.

Установка:
```fish
kpackagetool6 --type Plasma/Applet --upgrade ~/Загрузки/cachyos-drive-card-0.6.2.plasmoid
systemctl --user restart plasma-plasmashell.service
```
Если старый экземпляр остаётся сломанным, удалите его с рабочего стола и добавьте заново.
