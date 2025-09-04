import SwiftUI
import CoreLocation

struct ContentView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        NavigationStack {
            Group {
                switch locationManager.authorizationStatus {
                case .notDetermined:
                    RequestLocationView()
                case .restricted, .denied:
                    LocationDeniedView()
                default:
                    CircularDestinationView()
                }
            }
        }
        .tint(settings.selectedTint.color)
        .onAppear {
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestWhenInUse()
            }
        }
    }
}

private struct RequestLocationView: View {
    @EnvironmentObject private var locationManager: LocationManager

    var body: some View {
        VStack(spacing: 16) {
            Text("Allow Location Access")
                .font(.title2)
                .bold()
            Text("We use your location to start directions from where you are.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button("Enable Location") {
                locationManager.requestWhenInUse()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

private struct LocationDeniedView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Location Disabled")
                .font(.title2)
                .bold()
            Text("Enable location in Settings > Privacy to use directions.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
