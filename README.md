# NaviNudge (SwiftUI + MapKit)

NaviNudge is a minimalist navigation app with a circular interface for quickly launching directions to frequent destinations. Built with SwiftUI and MapKit.

## Features
- Minimal UI: no title bar, no gradients
- Circular destination selector (SF Symbols + labels)
- Drag from source → destination to launch Apple Maps
- Dynamic path indicator follows your swipe
- Center "Current Location" node for fast from-here routing
- Manage destinations via sheet; starts with none (only center)
- Transport modes: driving, walking, transit, biking (deeplink)
- Open selected route in Apple Maps
- Location permission + live user location

## Development

For development setup, build commands, architecture details, and coding guidelines, see [`CLAUDE.md`](CLAUDE.md).

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
- Create project: iOS App, SwiftUI lifecycle, name "NaviNudge"
- Add the `NaviNudge/` folder to your project (see [`CLAUDE.md`](CLAUDE.md) for detailed build commands)
- Add the Info.plist key listed above and run

## Apple Maps Deeplink Routing
- Gesture: press a node to start (center = Current Location or any saved place), drag to another node, then release to open Apple Maps prefilled from → to.
- Transport picker maps to Apple Maps `dirflg`: `d` (driving), `w` (walking), `r` (transit), `b` (biking).
- Deeplink format used: `https://maps.apple.com/?saddr=<lat,lon|Current%20Location>&daddr=<lat,lon>&dirflg=<flag>`.

