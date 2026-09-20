# Changelog

## [0.95.0-beta2] \u2014 2026-09-20

### Fixed

- **Background edge fade**: transition now applies to all four sides (left,
  right, top, bottom). Previously only horizontal edges faded.
- **Correct centre opacity**: background is drawn as a single solid rectangle
  at `backgroundOpacity`; separate gradient masks handle only the edge
  transition. This eliminates the double-compositing artefact that made the
  centre more opaque than intended.
- **Fade with `edgeWidth = 0`**: setting fade width to 0 now fully disables
  both gradient masks instead of leaving a 1\u2009px artefact.
- **Symmetric curve**: the `edgeCurve` parameter now applies equally to all
  four sides instead of producing an asymmetric left/right effect.
- **URL normalisation in `openTarget`**: trailing slashes are stripped before
  opening (except for the filesystem root `/`), ensuring Dolphin opens mount
  points correctly.
- **`Plasmoid.preferredRepresentation`**: restored the
  `Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation` declaration
  that was missing from the beta1 build.

### Changed

- **Row interaction**: the entire drive row is now an interactive
  `QQC2.ItemDelegate`. Clicking anywhere on the row (icon, name, details,
  progress bar, percentage) opens the drive in the file manager.
- **Hover highlight**: the active row shows a subtle theme-coloured highlight
  on hover and a slightly stronger one on press, with a 120\u2009ms colour
  animation.
- **Keyboard accessible**: drive rows can be activated with Enter or Space.
- **Tooltip updated**: includes a \u201cClick to open\u201d hint alongside the source and
  target path.
- **Removed standalone open button**: the `folder-open` `ToolButton` at the
  end of each row has been removed. Opening is now handled by the whole row.
- **Removed `openOnRowClick` setting**: since the row is always clickable,
  this configuration option is no longer needed and has been removed from
  `main.xml` and `ConfigGeneral.qml`.

### Added

- `scripts/install.sh` \u2014 install or upgrade from a local Git clone.
- `scripts/install-from-github.sh` \u2014 download and install the latest
  GitHub release automatically, with SHA-256 checksum verification.
- `scripts/uninstall.sh` \u2014 remove the installed plasmoid.
- Updated `scripts/build.sh` to exclude backup and editor artefact files
  from the `.plasmoid` archive.
- Updated `scripts/check.sh` with regression checks for all beta2 fixes.
- `README.md` with three installation methods, requirements, and
  issue-reporting instructions.

## [0.95.0-beta1] \u2014 2026-09-20

### Added

- Initial release of Drive Cards for Plasma 6.
- Mounted filesystem cards with usage bar, activity indicator, and
  configurable appearance.
- Per-row folder-open button (replaced by full-row click in beta2).
- Horizontal background edge fade.
- Configurable icon styles: drive, folder, open folder.
- Russian and English localisation.

---

Repository: <https://github.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard>
