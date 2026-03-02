import CoreLocation
import Foundation

/// Lightweight wrapper around `CLLocationManager` that publishes the user's
/// last known location. Used by `ArrivalBufferCalculator` as the route origin
/// when the user navigates from "Current Location".
@MainActor
final class LocationManager: NSObject, ObservableObject {
  @Published var lastLocation: CLLocation? = nil
  @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

  private let manager = CLLocationManager()

  override init() {
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    manager.distanceFilter = 100
  }

  func requestWhenInUseAuthorization() {
    manager.requestWhenInUseAuthorization()
  }

  func startUpdatingLocation() {
    manager.startUpdatingLocation()
  }

  func stopUpdatingLocation() {
    manager.stopUpdatingLocation()
  }

  /// Current coordinate, or `nil` if unavailable.
  var coordinate: CLLocationCoordinate2D? {
    lastLocation?.coordinate
  }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
  nonisolated func locationManager(
    _ manager: CLLocationManager,
    didUpdateLocations locations: [CLLocation]
  ) {
    guard let latest = locations.last else { return }
    Task { @MainActor in self.lastLocation = latest }
  }

  nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    Task { @MainActor in self.authorizationStatus = manager.authorizationStatus }
  }
}
