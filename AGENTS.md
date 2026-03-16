# AGENTS.md

## Project overview
Connnected is a macOS menu bar app that surfaces hardware/device status at a glance
using Swift/SwiftUI and Swift Package Manager.

## Setup commands
- Build: `swift build`
- Run: `swift run ConnnectedMenu`

## Packaging
- Build .app bundle into `dist/`: `scripts/package_app.sh`
  - Optional env vars:
    - `APP_VERSION` (defaults from `Sources/ConnnectedMenu/Version.swift`)
    - `SIGN_MODE=adhoc|developer-id|none` (default `adhoc`)
    - `CODESIGN_IDENTITY` (required when `SIGN_MODE=developer-id`)
    - `BUNDLE_IDENTIFIER` (default `me.vikalp.connnected`)
- Create DMG + checksum: `scripts/create_dmg.sh`
  - Requires `dist/Connnected.app` to exist.

## Testing
- No automated tests are configured in this repository.

## Project structure
- App entry and UI: `Sources/ConnnectedMenu/ConnnectedMenuApp.swift`
- Version metadata: `Sources/ConnnectedMenu/Version.swift`
- Device discovery/state: `Sources/ConnnectedMenu/DeviceCore.swift`

## Code style and conventions
- Swift 5.10, macOS 14 target (see `Package.swift`).
- Keep layout constants in metric enums (see `LayoutMetrics`, `ListMetrics`).
- Prefer small, focused changes over repo-wide refactors unless asked.

## Safety and permissions
- Ask before adding new dependencies, changing signing behavior, or modifying release artifacts.
