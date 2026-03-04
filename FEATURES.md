# Connects Feature List

## Core Value
- Menubar-first hardware visibility for ports, connections, and I/O devices.
- Faster, friendlier view than System Information for day-to-day checks.

## Layout
- Menu bar app with icon and dropdown window UI.
- Header row:
  - App title (`Connects`)
  - Centered segmented tabs (`All` / `Active`) with no visible `Filter` label
  - Refresh icon button
- Main content:
  - Plain sectioned list (no card backgrounds)
  - Section divider between top-level sections only
  - No per-row divider
- Footer actions:
  - `Open System Information`
  - `Quit`

## Tabs / Filters
- `All`: shows all discovered rows.
- `Active`: shows only rows with active state.

## Sections
- `External`
- `Built-in`

## List Item Structure
- Entire row is clickable and opens relevant settings target.
- Left area:
  - Circular status background
  - Device type icon centered in the circle
- Middle area:
  - Primary text: device name
  - Secondary text: device subtype/status (includes `Active` when active)
- Right area (external rows only):
  - Connection transport icon
  - Optional inferred badge (`?`) when mapping is inferred

## I/O Left Icon List (Device Type)
- Camera: `camera`
- Microphone: `mic`
- Speaker/Output: `speaker.wave.2`
- Display: `display`
- USB device: `cable.connector`
- Bluetooth device: `dot.radiowaves.left.and.right`

## Right Icon List (Transport)
- USB transport: `usb`
- Bluetooth transport: `dot.radiowaves.left.and.right`
- HDMI/Display cable transport: `tv`
- Wireless transport: `wifi`
- Built-in transport: hidden on right side (built-in rows)
- Other/unknown transport: `link`

## Inferred Mapping Badge
- Badge icon: `questionmark.circle.fill`
- Meaning: detail is inferred (best effort), not guaranteed exact.
- Example inferred detail: left/right side or display path mapping.

## Left Icon Color Semantics
- Green: active device (`isActive == true`).
- Blue: connected, non-active device (`isActive == false`).
- Left icon color does not encode transport type (wired/wireless/built-in).

## ASCII Layout Reference
```text
+------------------------------------------------------+
| Connects              [ All | Active ]            ⟳ |
|                                                      |
| [ext-icon] External                                  |
|   (◯kind) Device name                    (transport) |
|          subtitle                          (?) opt.  |
|   (◯kind) Device name                    (transport) |
|          subtitle                                   |
|                                                      |
| ---------------------------------------------------- |
|                                                      |
| [builtin-icon] Built-in                              |
|   (◯kind) Device name                                |
|          subtitle                                     |
|   (◯kind) Device name                                |
|          subtitle                                     |
|                                                      |
| Open System Information                        [Quit] |
+------------------------------------------------------+
```

## Data Refresh Model
- Polling refresh every 2 seconds for UI updates.
- Heavier USB/Bluetooth scan every 10 seconds (cached between heavy scans).

## Device Coverage
- Bluetooth devices (connected only).
- USB devices.
- Speakers / output devices.
- Microphones / input devices.
- Cameras.
- External displays.

## Per-Device Info
- Device name.
- Device subtype/category.
- Connection type (wired / wireless / internal / unknown; best effort).
- Port/address/detail text (best effort).
- Left/right side inference for USB/display where possible.

## Activity Signals
- Camera active status (in use by another app).
- Audio device active status (running somewhere).
- Active rows include `Active` in subtitle and active color treatment.

## Handy User Checks Enabled
- Is any external camera connected?
- Is camera currently active?
- Which microphones/speakers are available?
- Is an audio device currently active?
- Which Bluetooth devices are currently connected?
- Which USB devices are connected and on which side (left/right best effort)?
- Are external monitors connected?

## Known Limitations
- Port mapping is best-effort and can be ambiguous on some hardware/docks.
- Left/right mapping can be inferred rather than explicit.
- Tooltip behavior for transport detail may vary by macOS/SwiftUI interaction model.
- Deep-link settings URLs may vary across macOS versions.
- No per-app attribution for camera/mic activity yet.

## Next Feature Candidates
- Direct deep-link to more specific settings subsections where reliable.
- Confidence levels for inferred mappings (e.g., high/medium/low).
- Dock and hub hierarchy view (upstream/downstream chain).
- Power delivery details (charging wattage, source, dock power).
- External display transport details (HDMI/DP/USB-C if exposed).
- Device change timeline (connected/disconnected history).
- Alerts/notifications for attach/detach events.
