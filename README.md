# NaviNudge (SwiftUI + MapKit)

NaviNudge is a minimalist navigation app with a circular interface for quickly launching directions to frequent destinations. Built with SwiftUI and MapKit.

## Features
- Minimal UI: no title bar, no gradients
- Circular destination selector (SF Symbols + labels)
- Drag from source → destination to launch Apple Maps
- Dynamic path indicator follows your swipe
- Center "Current Location" node for fast from-here routing
- Transport modes: driving, walking, transit, biking (deeplink)
- Open selected route in Apple Maps
- Location permission + live user location

## Project Layout
- `NaviNudge/`
  - `NaviNudgeApp.swift`: App entry and environment objects
  - `Views/`
    - `ContentView.swift`: Host navigation + permissions state
    - `CircularDestinationView.swift`: Radial UI of destinations + Apple Maps deeplink
    - `DestinationButton.swift`: Destination button component
  - `Models/`
    - `Destination.swift`: Destination model
  - `Managers/`
    - `DestinationManager.swift`: Predefined destinations store
    - `LocationManager.swift`: CoreLocation wrapper

## Setup
1. Create an iOS App project in Xcode with SwiftUI.
2. Add the `NaviNudge/` folder and its subfolders (`Views`, `Models`, `Managers`) into the project.
3. In the target’s `Info.plist`, add:
   - `NSLocationWhenInUseUsageDescription` = "Your location is used to provide directions."
4. Ensure target platform iOS 16+ (Map SwiftUI component assumed).
5. Build and run on a device/simulator with Maps available.

## Notes
- Cycling directions are not exposed as a distinct `MKDirectionsTransportType`. The UI includes driving, walking, and transit. You can still open Apple Maps with cycling via URL, but MapKit’s in-app route calculation does not return cycling.
- For route overlays, consider a `UIViewRepresentable` wrapping `MKMapView` to draw polylines.

## Quick Start in Xcode
- Create project: iOS App, SwiftUI lifecycle, name "NaviNudge".
- Add the `Models`, `Managers`, and `Views` folders plus `NaviNudgeApp.swift`.
- Ensure the app’s entry file (`@main`) is `NaviNudgeApp.swift`.
- Add the Info.plist key listed above and run.

## Make Xcode Recognize The Files
- In Xcode, right-click the app target group (likely named "NaviNudge") > "Add Files to \"NaviNudge\"…"
- Choose the `NaviNudge/` folder from this workspace path, enable "Copy items if needed", and select "Create groups". Check your app target under "Add to targets".
- Verify in File Inspector (⌥⌘1) that each file’s Target Membership includes your app target.
- If files appear grey or builds fail, clean build folder (Shift+⌘+K) and rebuild.

## Apple Maps Deeplink Routing
- Gesture: press a node to start (center = Current Location or any saved place), drag to another node, then release to open Apple Maps prefilled from → to.
- Transport picker maps to Apple Maps `dirflg`: `d` (driving), `w` (walking), `r` (transit), `b` (biking).
- Deeplink format used: `https://maps.apple.com/?saddr=<lat,lon|Current%20Location>&daddr=<lat,lon>&dirflg=<flag>`.
