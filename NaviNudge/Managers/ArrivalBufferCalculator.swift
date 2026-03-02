import Foundation
import MapKit
import CoreLocation

// MARK: - Traffic Condition

/// Describes how heavy current traffic is for a given route.
enum TrafficCondition {
  case unknown
  case light    // travel time ≤ 110 % of baseline
  case moderate // travel time 111–150 % of baseline
  case heavy    // travel time > 150 % of baseline

  /// Additional buffer minutes applied on top of the event-type base buffer.
  var additionalBufferMinutes: Int {
    switch self {
    case .unknown:  return 5
    case .light:    return 0
    case .moderate: return 10
    case .heavy:    return 20
    }
  }

  var label: String {
    switch self {
    case .unknown:  return "Unknown"
    case .light:    return "Light"
    case .moderate: return "Moderate"
    case .heavy:    return "Heavy"
    }
  }

  var symbol: String {
    switch self {
    case .unknown:  return "questionmark.circle"
    case .light:    return "checkmark.circle.fill"
    case .moderate: return "exclamationmark.triangle.fill"
    case .heavy:    return "xmark.octagon.fill"
    }
  }
}

// MARK: - Buffer Result

/// All the data needed to show the smart departure advisory.
struct ArrivalBufferResult {
  /// Event-type base buffer in minutes.
  let baseBufferMinutes: Int
  /// Extra minutes added due to traffic conditions.
  let trafficBufferMinutes: Int
  /// Total recommended buffer (base + traffic).
  var totalBufferMinutes: Int { baseBufferMinutes + trafficBufferMinutes }
  /// MapKit's estimated travel time with traffic (seconds).
  let estimatedTravelSeconds: TimeInterval
  /// Summarised traffic condition.
  let trafficCondition: TrafficCondition
  /// The event type that determined the base buffer.
  let eventType: EventType

  /// Estimated travel time formatted as a human-readable string.
  var formattedTravelTime: String {
    let minutes = Int(estimatedTravelSeconds / 60)
    if minutes < 60 { return "\(minutes) min" }
    let hours = minutes / 60
    let remaining = minutes % 60
    return remaining == 0 ? "\(hours) hr" : "\(hours) hr \(remaining) min"
  }
}

// MARK: - Calculator

/// Calculates a smart arrival buffer using MapKit real-time travel estimates
/// combined with event-type-specific base buffer times.
@MainActor
final class ArrivalBufferCalculator {

  // MARK: Public API

  /// Calculates the arrival buffer for a trip from `origin` to `destination`.
  /// - Parameters:
  ///   - origin: Starting coordinate (use current user location or a saved place).
  ///   - destination: The `Destination` the user is navigating to.
  ///   - transportType: MapKit transport type (defaults to automobile).
  ///   - completion: Called on the main actor with the result, or `nil` if routing failed.
  func calculate(
    from origin: CLLocationCoordinate2D,
    to destination: Destination,
    transportType: MKDirectionsTransportType = .automobile,
    completion: @escaping @MainActor (ArrivalBufferResult?) -> Void
  ) {
    let request = buildDirectionsRequest(
      from: origin,
      to: destination.coordinate,
      transportType: transportType
    )
    let directions = MKDirections(request: request)
    directions.calculateETA { [weak self] response, error in
      Task { @MainActor in
        guard let self else { return }
        guard let etaResponse = response, error == nil else {
          // Fallback: return a result with unknown traffic using event-type base only.
          let fallback = self.buildResult(
            eventType: destination.eventType,
            trafficCondition: .unknown,
            travelSeconds: 0
          )
          completion(fallback)
          return
        }
        let travelSeconds = etaResponse.expectedTravelTime
        let trafficCondition = self.trafficCondition(
          from: etaResponse
        )
        let result = self.buildResult(
          eventType: destination.eventType,
          trafficCondition: trafficCondition,
          travelSeconds: travelSeconds
        )
        completion(result)
      }
    }
  }

  // MARK: Private Helpers

  private func buildDirectionsRequest(
    from origin: CLLocationCoordinate2D,
    to destination: CLLocationCoordinate2D,
    transportType: MKDirectionsTransportType
  ) -> MKDirections.Request {
    let request = MKDirections.Request()
    request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
    request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
    request.transportType = transportType
    request.requestsAlternateRoutes = false
    return request
  }

  /// Infers traffic condition from the ETA response.
  /// MapKit doesn't expose a "typical travel time" via ETA, so we use a
  /// heuristic: request a separate non-traffic estimate and compare.
  /// For simplicity we use distance / average speed as baseline.
  private func trafficCondition(from response: MKDirections.ETAResponse) -> TrafficCondition {
    let travelSeconds = response.expectedTravelTime
    let distanceMeters = response.distance

    guard distanceMeters > 0, travelSeconds > 0 else { return .unknown }

    // Compute implied average speed in km/h.
    let speedKmh = (distanceMeters / 1000) / (travelSeconds / 3600)

    // Reference: freeway ~100 km/h, city ~40 km/h, mixed ~60 km/h.
    // We use a conservative mixed-road baseline of 50 km/h.
    // A lower implied speed means heavier traffic.
    switch speedKmh {
    case 40...:   return .light
    case 20..<40: return .moderate
    default:      return .heavy
    }
  }

  private func buildResult(
    eventType: EventType,
    trafficCondition: TrafficCondition,
    travelSeconds: TimeInterval
  ) -> ArrivalBufferResult {
    ArrivalBufferResult(
      baseBufferMinutes: eventType.baseBufferMinutes,
      trafficBufferMinutes: trafficCondition.additionalBufferMinutes,
      estimatedTravelSeconds: travelSeconds,
      trafficCondition: trafficCondition,
      eventType: eventType
    )
  }
}
