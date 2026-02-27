import SwiftUI

@main
struct NaviNudgeApp: App {
  @StateObject private var destinationManager = DestinationManager()
  @StateObject private var locationManager = LocationManager()
  @Environment(\.scenePhase) private var scenePhase

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(destinationManager)
        .environmentObject(locationManager)
        .onAppear {
          // Sync destinations and kick off location updates on first launch
          locationManager.destinations = destinationManager.destinations
          locationManager.requestAuthorization()
          locationManager.startUpdating()
        }
        .onChange(of: destinationManager.destinations) { _, destinations in
          // Keep LocationManager aware of the latest destination list
          locationManager.destinations = destinations
        }
        .onChange(of: scenePhase) { _, phase in
          // Pause location updates while the app is in the background to save battery
          switch phase {
          case .active:
            locationManager.startUpdating()
          case .background, .inactive:
            locationManager.stopUpdating()
          @unknown default:
            break
          }
        }
    }
  }
}
