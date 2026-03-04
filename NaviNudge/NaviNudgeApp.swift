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
                    locationManager.requestWhenInUseAuthorization()
                    locationManager.startUpdatingLocation()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .active:
                        locationManager.startUpdatingLocation()
                    case .background:
                        locationManager.stopUpdatingLocation()
                    default:
                        break
                    }
                }
        }
    }

}
