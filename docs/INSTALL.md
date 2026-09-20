# Установка

## Готовый пакет

```bash
kpackagetool6 --type Plasma/Applet --upgrade cachyos-drive-card-0.95.0-beta1.plasmoid
```

Первая установка: замените `--upgrade` на `--install`.

## Исходники

```bash
./scripts/install.sh
```

## Удаление

```bash
./scripts/uninstall.sh
```

## Откат

Удалите beta1 и установите сохранённый пакет 0.8.1 либо восстановите каталог `~/.local/share/plasma/plasmoids/io.github.cachyos.drivecard` из резервной копии.
