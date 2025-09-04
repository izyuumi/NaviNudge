# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

**Build & Run:**
- Open in Xcode: `xed .`
- Build for simulator: `xcodebuild -scheme NaviNudge -destination 'platform=iOS Simulator,name=iPhone 15' build`
- Run tests: `xcodebuild -scheme NaviNudge test`
- Clean build: Shift+⌘+K in Xcode

**Utilities:**
- List simulators: `xcrun simctl list devices`
- Boot simulator: `xcrun simctl boot "iPhone 15"`
- Check location permission config: `grep -n "INFOPLIST_KEY_NSLocationWhenInUseUsageDescription" NaviNudge.xcodeproj/project.pbxproj`

## Architecture Overview

NaviNudge is a SwiftUI iOS app with dual-target architecture:

**Main App (`NaviNudge` target):**
- Entry point: `NaviNudgeApp.swift` - sets up environment objects
- Core interaction: Circular gesture interface for launching Apple Maps deeplinks
- Manager pattern: Separated concerns for destinations, location, haptics, and URL parsing
- State management: Uses `@StateObject` for managers, `@EnvironmentObject` for app-wide state

**Share Extension (`NaviNudgeShareExtension` target):**
- Entry point: `ShareViewController.swift`
- Shares state with main app via `SharedStore.swift`
- Allows adding destinations from system share sheet

## Key Managers & Their Roles

- **DestinationManager:** Persistent destination storage and management
- **LocationManager:** CoreLocation integration and permission handling
- **MapsURLParser:** Apple Maps URL parsing and deeplink construction
- **Haptics:** Tactile feedback coordination
- **SharedStore:** State sharing between app and extension

## Critical Configuration

- **Location Permission:** `NSLocationWhenInUseUsageDescription` must be configured in project settings
- **iOS Version:** Requires iOS 16+ for MapKit SwiftUI components
- **Apple Maps Integration:** Uses deeplink format `https://maps.apple.com/?saddr=<>&daddr=<>&dirflg=<flag>`
- **Transport Modes:** Maps to Apple Maps `dirflg` parameters (d=driving, w=walking, r=transit, b=biking)

## Code Style Requirements

- **Indentation:** 2 spaces, lines < 120 characters
- **Naming:** Types UpperCamelCase, vars/functions lowerCamelCase
- **File Organization:** Views end with `View`, managers with `Manager`
- **SwiftUI Patterns:** Value types preferred in models, immutability where possible
- **File Layout:** One primary type per file, group with `// MARK:` sections

## Testing Approach

- **Framework:** XCTest under `NaviNudgeTests/`
- **Focus:** Unit test managers (destination parsing, validation)
- **UI Testing:** Keep UI logic testable via pure functions where possible
- **File Naming:** `ThingTests.swift`, methods `test_...()`