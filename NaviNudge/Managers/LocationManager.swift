import Combine
import CoreLocation
import Foundation

/// Manages device location updates and triggers haptic feedback when
/// the user approaches a saved destination within `hapticThresholdMeters`.
@MainActor
final class LocationManager: NSObject, ObservableObject {
  @Published var currentLocation: CLLocation?
  @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

  /// Distance (in metres) at which haptic feedback is triggered. Configurable by the user.
  @Published var hapticThresholdMeters: Double {
    didSet { UserDefaults.standard.set(hapticThresholdMeters, forKey: Self.thresholdKey) }
  }

  /// The destinations to monitor proximity for. Updated by the app whenever
  /// `DestinationManager.destinations` changes.
  var destinations: [Destination] = [] {
    didSet {
      // Remove stale IDs for destinations that no longer exist
      let activeIDs = Set(destinations.map(\.id))
      triggeredIDs.formIntersection(activeIDs)
    }
  }

  private static let thresholdKey = "hapticThresholdMeters"
  private let manager = CLLocationManager()

  // One-shot flag: tracks which destination IDs have already fired haptics in the current
  // proximity session. Cleared again once the user moves sufficiently far away.
  private var triggeredIDs: Set<UUID> = []

  override init() {
    let saved = UserDefaults.standard.double(forKey: Self.thresholdKey)
    hapticThresholdMeters = saved > 0 ? saved : 50.0
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    manager.distanceFilter = 5 // receive updates roughly every 5 m
  }

  func requestAuthorization() {
    manager.requestWhenInUseAuthorization()
  }

  func startUpdating() {
    manager.startUpdatingLocation()
  }

  func stopUpdating() {
    manager.stopUpdatingLocation()
  }

  // MARK: - Proximity check

  /// Called after every location update to detect when the user enters the haptic zone.
  private func checkProximity() {
    guard let location = currentLocation else { return }
    for destination in destinations {
      let target = CLLocation(
        latitude: destination.coordinate.latitude,
        longitude: destination.coordinate.longitude
      )
      let distance = location.distance(from: target)

      if distance <= hapticThresholdMeters {
        // Trigger once per proximity session (one-shot flag)
        guard !triggeredIDs.contains(destination.id) else { continue }
        triggeredIDs.insert(destination.id)
        Haptics.impactMedium()
      } else if distance > hapticThresholdMeters * 2 {
        // Reset the flag once the user has moved clearly out of range
        triggeredIDs.remove(destination.id)
        // Warm up the generator so the next trigger fires without latency
        Haptics.prepareImpactMedium()
      }
    }
  }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
  nonisolated func locationManager(
    _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
  ) {
    guard let location = locations.last else { return }
    Task { @MainActor in
      self.currentLocation = location
      self.checkProximity()
    }
  }

  nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    Task { @MainActor in
      self.authorizationStatus = manager.authorizationStatus
      if manager.authorizationStatus == .authorizedWhenInUse
        || manager.authorizationStatus == .authorizedAlways
      {
        manager.startUpdatingLocation()
      }
    }
  }
}
