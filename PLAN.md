# Connnected Plan

## Current Status
- v1 menubar app is implemented with grouped `External` and `Built-in` lists.
- Polling model is in place (fast UI refresh + slower heavy scan).
- Device coverage includes camera, microphone, speaker, Bluetooth, USB, and external displays.

## Future TODOs
- Improve Bluetooth connected-device detection reliability:
  - Problem: some Bluetooth audio devices (for example AirPods) may not appear in `All` from the Bluetooth pipeline unless they are selected as active mic/speaker.
  - Current behavior: device can still appear through CoreAudio input/output pipeline.
  - TODO:
    - Add fallback detection path (CoreBluetooth and/or IOKit/IORegistry) for connected Bluetooth devices.
    - Merge/deduplicate Bluetooth and audio representations of the same physical device.
    - Keep current behavior as fallback when extra metadata is unavailable.

- Add explicit confidence levels for inferred mappings:
  - Replace binary inferred/exact with `high`, `medium`, `low` confidence where possible.

- Improve deep-link precision:
  - Use device-type-specific settings subsections when reliable.
  - Fallback to category-level settings when deep links are not stable.

- Optional UX improvements:
  - Inline transport detail text fallback if tooltip behavior is inconsistent on some macOS versions.
  - Add compact device history/timeline for connect/disconnect events.
  - Add Settings/Preferences UI for configuring refresh interval, filters, and display options.
