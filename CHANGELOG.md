# Changelog

All notable changes to Connects are documented in this file.

## v0.1.0-beta.1 - 2026-03-04

### Added
- Initial Connects beta menubar app with grouped hardware visibility.
- Device discovery for Bluetooth, USB, camera, microphone, speaker/output, and external displays.
- Polling-based refresh model with heavy collector caching.
- External/Built-in grouped list with row click actions and settings deep-links.

### Changed
- Refined menu UI with centered tabs, hover polish, and aligned section/list lanes.
- Simplified left icon status colors:
  - Active -> green
  - Connected (non-active) -> blue

### Known Issues
- Bluetooth connected-device detection may miss some peripherals unless they are active in the audio path.

### Next
- Add Bluetooth fallback detection and deduplicate transport/audio representations.
- Add confidence levels for inferred mappings.
