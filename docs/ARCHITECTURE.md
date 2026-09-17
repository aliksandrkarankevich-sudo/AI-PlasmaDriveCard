# Architecture

## Purpose

AI-PlasmaDriveCard is a KDE Plasma 6 desktop widget that presents local mounted filesystems as compact disk cards. A card may show available and total space, usage percentage, filesystem type, a short physical-drive identifier, and an action to open the mount point.

## Design principles

- Keep the widget local: no network access is required for normal operation.
- Prefer standard KDE Plasma, Qt, and Linux utilities over custom services.
- Keep shell interaction small, explicit, and read-only.
- Do not mount, format, repartition, or otherwise modify disks.
- Keep the user interface separate from data collection and configuration.
- Treat an unavailable disk as unavailable, never as zero free space.

## Planned package layout

```text
metadata.json
contents/
  config/
    config.qml
    main.xml
  ui/
    main.qml
    ConfigGeneral.qml
```

## Data flow

1. The widget reads the local mount table and block-device metadata.
2. It filters the result to mounted local filesystems that are accessible to the current user.
3. It updates the in-memory model only when the discovered mount list changes or a normal space-refresh interval expires.
4. QML renders the cards from that model.
5. A click opens the selected mounted location with the system default file manager.

## Current limitations

The project is experimental. The exact data-collection backend and visual background implementation will be revised only after source versions are imported and tested.
