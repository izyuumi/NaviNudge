import SwiftUI

@main
struct NaviNudgeApp: App {
    @StateObject private var destinationManager = DestinationManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(destinationManager)
        }
    }

}
