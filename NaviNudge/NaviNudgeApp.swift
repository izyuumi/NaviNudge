import SwiftUI

@main
struct NaviNudgeApp: App {
  @StateObject private var destinationManager = DestinationManager()
  @StateObject private var locationManager = LocationManager()

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
        .onChange(of: destinationManager.destinations) { destinations in
          // Keep LocationManager aware of the latest destination list
          locationManager.destinations = destinations
        }
    }
  }
}
