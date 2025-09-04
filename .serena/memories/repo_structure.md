# Repository Structure

- `NaviNudge/` — App sources
  - `NaviNudgeApp.swift` — App entry / environment setup
  - `Managers/` — Services
    - `DestinationManager.swift` — Manage saved destinations
    - `LocationManager.swift` — CoreLocation integration
    - `Haptics.swift` — Haptic feedback helpers
    - `MapsURLParser.swift` — Apple Maps URL parsing
    - `SharedStore.swift` — Shared state/utilities
  - `Models/`
    - `Destination.swift` — Core value type for destinations
  - `Views/` — SwiftUI views
    - `ContentView.swift` — Main screen
    - `CircularDestinationView.swift`, `DestinationButton.swift`
    - `ManageDestinationsView.swift`, `QuickAddDestinationPopover.swift`, `SettingsView.swift`
  - `Assets.xcassets/` — Colors, app icons
- `NaviNudgeShareExtension/`
  - `ShareViewController.swift`, `SharedStore.swift`, `Info.plist`
- `NaviNudge.xcodeproj/` — Xcode project files
- Root files: `README.md`, `AGENTS.md`

Note: Top-level `Managers/`, `Models/`, `Views/` directories exist but are currently empty; active sources live under `NaviNudge/`. 