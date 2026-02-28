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
          // Sync destinations on first launch; LocationManager decides whether monitoring should run.
          locationManager.destinations = destinationManager.destinations
          locationManager.requestAuthorization()
        }
        .onChange(of: destinationManager.destinations) { _, destinations in
          // Keep LocationManager aware of the latest destination list
          locationManager.destinations = destinations
        }
        .onChange(of: scenePhase) { _, phase in
          // Resume monitoring when the app becomes active again.
          switch phase {
          case .active:
            locationManager.startUpdating()
          case .background, .inactive:
            break
          @unknown default:
            break
          }
        }
    }
  }
}
