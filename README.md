# Drive Cards — Plasma Widget

A configurable Plasma 6 widget that shows mounted local filesystems as cards with usage bars, activity indicators, and transparent backgrounds.

## Installation

### Option 1 — Download from GitHub Releases (recommended)

1. Go to [Releases](https://github.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard/releases).
2. Download the latest `cachyos-drive-card-*.plasmoid`.
3. Right-click the desktop → **Add Widgets** → **Install Widget from Local File** → select the file.

Or install from the terminal:

```bash
kpackagetool6 --type Plasma/Applet --install cachyos-drive-card-0.95.0-beta2.plasmoid
```

### Option 2 — One command (latest stable release)

```bash
curl -fsSL https://raw.githubusercontent.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard/main/scripts/install-from-github.sh -o install-drive-cards.sh
less install-drive-cards.sh   # inspect before running
bash install-drive-cards.sh
```

Install the latest beta instead:

```bash
bash install-drive-cards.sh --prerelease
```

### Option 3 — From a Git clone (for testing or development)

```bash
git clone --depth 1 https://github.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard.git
cd AI-PlasmaDriveCard
bash scripts/install.sh
```

To test a specific branch (e.g. beta2):

```bash
git clone --branch fix/v0.95.0-beta2-edge-fade --single-branch \
  https://github.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard.git
cd AI-PlasmaDriveCard
bash scripts/install.sh
```

## Updating

```bash
kpackagetool6 --type Plasma/Applet --upgrade cachyos-drive-card-<version>.plasmoid
```

Or re-run `install-from-github.sh` — it detects an existing installation automatically.

## Uninstalling

```bash
bash scripts/uninstall.sh
# or directly:
kpackagetool6 --type Plasma/Applet --remove io.github.cachyos.drivecard
```

## Features

- Mounted local filesystems displayed as compact cards
- Colour-coded usage bar (normal / warning / critical thresholds)
- Disk activity indicator per drive
- Four-sided configurable edge-fade background
- Light / dark theme colours or custom colour picker
- Configurable icon style: drive, folder, or open-folder
- Click anywhere on a drive row to open it in the file manager
- Russian and English interface

## Requirements

- KDE Plasma ≥ 6.0
- `findmnt`, `lsblk`, `udevadm` (standard on any Linux system)
- `kpackagetool6` for terminal installation

## Reporting Issues

Please include the widget version (visible in widget settings) when opening an issue.

## License

GPL-3.0-or-later — see [LICENSE](LICENSE).
