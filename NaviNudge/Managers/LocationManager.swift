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
      if destinations.isEmpty {
        // Clear all triggered IDs when no destinations remain to prevent memory leaks
        clearTriggeredIDs()
        stopUpdating()
      } else {
        triggeredIDs.formIntersection(activeIDs)
        // Clear triggered flag for any destination whose coordinate changed
        // (same UUID but edited location) so the haptic fires at the new location.
        let previousCoords = Dictionary(uniqueKeysWithValues: oldValue.map { ($0.id, $0.coordinate) })
        for dest in destinations {
          if let prev = previousCoords[dest.id],
             prev.latitude != dest.coordinate.latitude || prev.longitude != dest.coordinate.longitude {
            triggeredIDs.remove(dest.id)
          }
        }
        startUpdating()
      }
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
    authorizationStatus = manager.authorizationStatus
    manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    manager.distanceFilter = 10 // receive updates roughly every 10 m
  }

  func requestAuthorization() {
    manager.requestAlwaysAuthorization()
  }

  func startUpdating() {
    guard !destinations.isEmpty else { return }
    guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
      return
    }
    manager.allowsBackgroundLocationUpdates = true
    manager.startUpdatingLocation()
  }

  func stopUpdating() {
    manager.stopUpdatingLocation()
  }

  // MARK: - Proximity check

  /// Called after every location update to detect when the user enters the haptic zone.
  private func checkProximity() {
    guard let location = currentLocation, !destinations.isEmpty else { return }

    for destination in destinations {
      // Validate coordinate before creating CLLocation
      guard isValidCoordinate(destination.coordinate) else {
        print("Invalid coordinates for destination: \(destination.name)")
        continue
      }

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
      } else if distance > hapticThresholdMeters * 3 {
        // Reset the flag once the user has moved clearly out of range (3x threshold)
        triggeredIDs.remove(destination.id)
      }
    }

    // Warm up the generator for all active destinations to reduce latency on next trigger
    Haptics.prepareImpactMedium()
  }

  /// Validates that a coordinate is within acceptable ranges.
  private func isValidCoordinate(_ coord: CLLocationCoordinate2D) -> Bool {
    return abs(coord.latitude) <= 90.0 && abs(coord.longitude) <= 180.0
  }

  /// Clears triggeredIDs to prevent memory leaks when all destinations are removed.
  private func clearTriggeredIDs() {
    triggeredIDs.removeAll()
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
      switch manager.authorizationStatus {
      case .authorizedAlways:
        self.startUpdating()
      case .authorizedWhenInUse:
        // Upgrade to Always authorization so haptics work when the app is backgrounded.
        // On iOS this is a no-op if the user already chose "Allow Once" or "While Using".
        self.startUpdating()
        manager.requestAlwaysAuthorization()
      case .denied, .restricted:
        // User denied permission - no action needed, UI can show appropriate message
        self.stopUpdating()
        break
      case .notDetermined:
        // Will be handled by requestAuthorization() call from app
        break
      @unknown default:
        break
      }
    }
  }

  nonisolated func locationManager(
    _ manager: CLLocationManager, didFailWithError error: Error
  ) {
    Task { @MainActor in
      // Log the error but don't crash - location services may recover
      print("LocationManager error: \(error.localizedDescription)")
    }
  }
}
