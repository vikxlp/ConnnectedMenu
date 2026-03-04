# Connects (macOS Menu Bar App)

A lightweight menu bar app that makes macOS hardware/device info readable at a glance.

## Release
- Version: `0.1.0-beta.1`
- Scope: personal sideload beta focused on read-only visibility and settings shortcuts.

## v1 implemented
- Menu bar icon + dropdown window UI
- Polling refresh every 2 seconds
- Heavier USB/Bluetooth refresh every 10 seconds (cached between polls)
- Grouped sections:
  - Bluetooth devices
  - USB devices
  - Speakers / Output devices
  - Microphones / Input devices
  - Cameras
  - External displays
- Per-row details:
  - Device name
  - Connection state/type (best effort)
  - Port/identifier + left/right side inference (best effort)
- Bluetooth section shows connected devices only
- App-level active indicator:
  - Camera active when in use by another app
  - Audio devices marked active when running somewhere
- Per-section **Settings** button deep-links
- Quick action to open **System Information**

## Build and run
```bash
swift build
swift run
```

## Notes
- Port mapping is best-effort and depends on what macOS exposes.
- Some settings deep-links vary by macOS release; if a URL does not open, use the fallback System Information button.
