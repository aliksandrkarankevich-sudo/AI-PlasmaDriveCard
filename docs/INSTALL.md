# Installation

## Status

No installable release is published from this repository yet.

This document will describe installation of verified `.plasmoid` packages for KDE Plasma 6 after the first tested release is published.

## Planned installation command

```fish
kpackagetool6 --type Plasma/Applet --install path/to/cachyos-drive-card-VERSION.plasmoid
```

The package is installed for the current user. It does not require `sudo`.

## Removing the widget

```fish
kpackagetool6 --type Plasma/Applet --remove io.github.cachyos.drivecard
```
