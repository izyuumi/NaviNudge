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
        }
    }
}
