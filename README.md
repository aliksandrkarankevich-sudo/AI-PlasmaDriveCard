# Drive Cards

A Plasma 6 widget that shows mounted local filesystems as configurable cards.
Click any row to open the drive in your file manager.

## Quick Install

### Option 1 — Download ready-made file

1. Open the [**Releases**](https://github.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard/releases) page.
2. Download `cachyos-drive-card-<version>.plasmoid`.
3. Right-click the desktop → **Add Widgets → Install Widget from Local File**.
4. Select the downloaded file.

Or install via terminal:

```bash
kpackagetool6 --type Plasma/Applet --install cachyos-drive-card-0.95.0-beta2.plasmoid
```

Upgrade an existing installation:

```bash
kpackagetool6 --type Plasma/Applet --upgrade cachyos-drive-card-0.95.0-beta2.plasmoid
```

### Option 2 \u2014 Install latest release automatically

Download, inspect, then run:

```bash
curl -LO https://raw.githubusercontent.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard/main/scripts/install-from-github.sh
less install-from-github.sh
bash install-from-github.sh
```

The script fetches the latest release, verifies the SHA-256 checksum, and
installs or upgrades the widget automatically.

### Option 3 \u2014 Install from Git (for testing or development)

```bash
git clone --depth 1 https://github.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard.git
cd AI-PlasmaDriveCard
bash scripts/install.sh
```

To install a specific version:

```bash
git clone --branch v0.95.0-beta2 --depth 1 \
  https://github.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard.git
cd AI-PlasmaDriveCard
bash scripts/install.sh
```

## Uninstall

```bash
bash scripts/uninstall.sh
# or
kpackagetool6 --type Plasma/Applet --remove io.github.cachyos.drivecard
```

## Requirements

- KDE Plasma 6
- `findmnt` and `lsblk` (included in `util-linux`)
- `kpackagetool6` (from `plasma-framework` or `plasma6-sdk`)

## Features

- Shows all mounted local filesystems as cards
- Click any row to open the drive in your file manager
- Configurable four-sided background fade
- Per-row read/write activity indicator
- Filesystem type and physical drive info
- Colour-coded progress bar (normal / warning / critical)
- Light and dark theme support
- Configurable icon style: drive, folder, open folder
- Auto-fit height
- Separate language setting (Russian / English)

## Configuration

Right-click the widget and select **Configure Drive Cards**.

## Reporting Issues

Please open an issue at
[github.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard/issues](https://github.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard/issues)
and include:

- Widget version (visible in the config dialog title)
- Plasma version: `plasmashell --version`
- Output of: `findmnt --real --output SOURCE,TARGET,FSTYPE`

## License

GPL-3.0-or-later
