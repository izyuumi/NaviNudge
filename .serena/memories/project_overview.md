# NaviNudge — Project Overview

- Purpose: iOS SwiftUI app focused on managing destinations and providing lightweight navigation nudges. Integrates with Apple Maps and device location services. A Share Extension lets users add content from the share sheet. (Purpose inferred from code structure and names; please confirm if different.)
- Platforms: iOS
- Entry points:
  - App: `NaviNudge/NaviNudgeApp.swift`
  - Share Extension: `NaviNudgeShareExtension/ShareViewController.swift`
- Key capabilities (from code): destination management, haptic feedback, location usage, Apple Maps URL parsing.
- Permissions: `NSLocationWhenInUseUsageDescription` configured in Xcode project settings (confirmed in `NaviNudge.xcodeproj/project.pbxproj`).
- Notable targets: `NaviNudge` (app), `NaviNudgeShareExtension` (extension).