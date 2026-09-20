# Changelog

## 0.95.0-beta2 (2026-09-20)

### Fixed
- Edge fade now applies to all four sides of the widget (previously only left/right).
- Background centre opacity no longer drifts above the configured value due to double-layer compositing.
- Edge width set to 0 now correctly disables the fade entirely.
- Fade curve is applied symmetrically to all four edges.

### Changed
- Entire drive row is now clickable and opens the mount point in the file manager.
  Row highlights on hover with a subtle Plasma theme colour.
- Removed the separate folder-open button from each drive row.
- Removed `openOnRowClick` config key (opening via row click is now always active).
- `openTarget` now normalises the path with a trailing `/` for correct Dolphin behaviour.
- Added `Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation`.

### Added
- `EdgeFadeBackground.qml` component — four-sided gradient mask via two layered gradients.
- `install-from-github.sh` — downloads and installs the latest release from GitHub Releases;
  supports `--prerelease` flag, checksum verification, auto-upgrade detection.
- `build.sh` now excludes backup files (`*.backup*`, `*.bak`, `*.orig`, `~`, `*.swp`) from the `.plasmoid` archive.
- `README.md` installation section: three installation methods documented.

---

## 0.95.0-beta1 (2026-09-19)

### Added
- Initial release of Drive Cards Plasma widget.
- Configurable cards for mounted local filesystems.
- Disk activity indicator, usage bar with warning/critical colours.
- Edge-fade transparent background (horizontal only in this version).
- Russian and English language support.
