# Connnected (macOS Menu Bar App)

Connnected is a lightweight macOS menu bar app that makes hardware and device info
readable at a glance.

## Features
- Menu bar icon with a compact device overview window.
- Sections for Bluetooth, USB, audio input/output, cameras, and external displays.
- Active status indicators for audio devices and cameras.
- Quick deep links to relevant system settings and System Information.

## Requirements
- macOS 14+
- Swift 5.10 (for building from source)

## Install (DMG)
- Download `Connnected-v0.1.0-beta.1.dmg` from GitHub Releases.
- Open the DMG, drag `Connnected.app` to `/Applications`.
- Launch once via right-click ▶ Open if Gatekeeper blocks the unsigned build; this
  registers the app.

## Build and run from source
```bash
swift build
swift run ConnnectedMenu
```

## Release and packaging
- Push the beta branch/tag and publish binaries using GitHub Releases (DMG + checksums).
- Packaging commands and signing environment variables are documented in `AGENTS.md`.

## Notes
- Port mapping is best-effort and depends on what macOS exposes.
- Some settings deep links vary by macOS release; if a URL does not open, use the
  fallback System Information button.

## Developer and agent notes
See `AGENTS.md` for project structure, packaging details, and repo conventions.

## License
License is not yet specified.
