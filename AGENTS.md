# Repository Guidelines

## Project Structure & Module Organization
- `NaviNudge/`: app sources
  - `NaviNudgeApp.swift`: app entry and environment setup
  - `Views/`: SwiftUI views (e.g., `ContentView.swift`, `CircularDestinationView.swift`)
  - `Models/`: data types (e.g., `Destination.swift`)
  - `Managers/`: services (e.g., `LocationManager.swift`, `DestinationManager.swift`, `Haptics.swift`)
  - `Assets.xcassets/`: colors and app icons
- `NaviNudge.xcodeproj/`: Xcode project files
- Required Info.plist key: `NSLocationWhenInUseUsageDescription`

## Build, Test, and Development Commands
- Open in Xcode: `xed .`
- Build & run (simulator): use Xcode ▶ or `xcodebuild -scheme NaviNudge -destination 'platform=iOS Simulator,name=iPhone 15' build`
- Clean build: Shift+⌘+K (Xcode)
- Tests (if a test target exists): run in Xcode or `xcodebuild -scheme NaviNudge test`

## Coding Style & Naming Conventions
- Indentation: 2 spaces; keep lines < 120 chars
- Follow Swift API Design Guidelines; prefer value types and immutability in models
- Naming: Types UpperCamelCase; vars/functions lowerCamelCase; views end with `View`; managers end with `Manager`
- File layout: one primary type per file; group with `// MARK:` sections
- SwiftUI: use `@StateObject` for long‑lived managers, `@EnvironmentObject` for app‑wide state

## Testing Guidelines
- Framework: XCTest; place tests under `NaviNudgeTests/`
- Names: files `ThingTests.swift`; methods `test_…()` describing behavior
- Scope: unit test managers (e.g., destination parsing/validation); keep UI logic testable via pure functions where possible
- Run: from Xcode Test navigator or `xcodebuild … test`

## Commit & Pull Request Guidelines
- Commits: small, focused, Conventional Commits preferred (e.g., `feat: add biking deeplink`, `fix: clamp angle calc`)
- PRs: include summary, linked issue, simulator/device used, screenshots or short video of UI, and test notes
- Keep diffs minimal; update docs (`README.md`, this file) when behavior or setup changes

## Security & Configuration Tips
- Do not commit secrets; this app uses no API keys by default
- Validate location permission flows; ensure the Info.plist reason matches UX
- Test routing on device and simulator; Apple Maps must be available
