import Foundation
import CoreLocation

struct Destination: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String // SF Symbol name
    let coordinate: CLLocationCoordinate2D

    static func == (lhs: Destination, rhs: Destination) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
