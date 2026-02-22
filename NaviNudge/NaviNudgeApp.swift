import SwiftUI

@main
struct NaviNudgeApp: App {
    @StateObject private var destinationManager = DestinationManager()
    @StateObject private var locationProvider = LocationProvider()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(destinationManager)
                .environmentObject(locationProvider)
                .onAppear { locationProvider.start() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        locationProvider.start()
                    } else if phase == .background {
                        locationProvider.stop()
                    }
                }
        }
    }

}
