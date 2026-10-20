# Version history

Format: newest first. Details are reconstructed from the commit history of each branch.

## Текущие линии после перехода

- Стабильная линия: `0.96.0`, подготовлена из `dev/v0.96-beta5` (`a952715acf5f3dd78c519ddcd136c486d6ba542d`). До публикации Release — только подготовленный кандидат.
- Разработка: `dev/v0.97-beta1`, номер пакета `0.97.0-beta1`, без тега и публичного pre-release.
- Beta5 сохраняется под прежним именем ветки как точный источник стабильной линии; остальные старые версии — исторические, без удаления веток и старых Release assets.
- План снимков `archive/...`, проверок и публикации: [RELEASE_TRANSITION.md](RELEASE_TRANSITION.md).

## v0.96.0-beta4 (историческая разработка)

- Ветка: `dev/v0.96-beta4`, состояние перед переходом `56f0d7189edcae71cc110c0a8bc306c7b9d5dba1`.
- Отдельного GitHub Release до перехода нет; изменения включены в beta5 и подготовку `0.96.0`.
- Исторические подробности: [аудит](AUDIT_BETA4.md), [подготовка](BETA4_PREPARATION.md).

## v0.96.0-beta3 (release tag `v0.96.0-beta3`, pre-release; development branch `dev/v0.96-beta3`)

UI and settings
- Settings page rebuilt on `KCM.SimpleKCM`; RGB `ColorPicker` with preview and visible slider handles.
- User profiles: save / load / delete named snapshots, built-in "Default" profile, `volumeOverrides` inside profiles.
- Per-volume icon and icon size (by mount point); more icon styles and custom icon file.
- Removed the "Drives" header row; USB devices grouped under a single USB header; optical drives treated as disks.
- Partitions grouped under physical disks and RAID arrays; factory profile hides /boot; new defaults.

Fixes
- Auto-fit height now uses measured row and header heights; shrink regression fixed.
- `ColorPicker` signals renamed (`modeSelected`, `colorPicked`) to avoid clash with property change signals.
- `org.kde.solid` dependency removed (polling instead of DeviceNotifier).
- Audit fixes: scan watchdog and error state, mountinfo hotplug, loop devices skipped, `makeGroup` null crash.

Repository and tooling
- `install-from-github.sh` finds the latest release or pre-release without the `--prerelease` flag.
- Authors recorded: developer aliksandrkarankevich-sudo, co-author Perplexity AI.
- Documentation refreshed (TESTING, INSTALL, ROADMAP, CONTRIBUTING); generic `feedback.yml` issue template.

## v0.96-beta2 (branch `dev/v0.96-beta2`, tip b749d96)

- Auto-fit via runtime-measured row/header heights; fit diagnostics.

## v0.96-beta (branch `dev/v0.96-beta`, tip 34b6ff5)

- C++ backend (hotplug, debounce, watchdog, deferred init), HiDPI via Kirigami.Units, many auto-fit height iterations, disk separator with thickness setting.

## v0.95.0-beta2 (branch `fix/v0.95.0-beta2-edge-fade`, tip dce4363)

- Edge fade fixes.

## v0.95.0-beta1 (`main` at d5c164f, archived as `archive/v0.95.0-beta1-main`)

- Last state of `main` before the v0.96 line.

> TODO: expand the v0.95 entries from their own commits.
