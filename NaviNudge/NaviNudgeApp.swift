import SwiftUI

@main
struct NaviNudgeApp: App {
    @StateObject private var destinationManager = DestinationManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var settings = SettingsStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(destinationManager)
                .environmentObject(locationManager)
                .environmentObject(settings)
        }
    }

}
