import Foundation
import CoreLocation

struct Destination: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var icon: String // SF Symbol name
    var coordinate: CLLocationCoordinate2D

    init(id: UUID = UUID(), name: String, icon: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.name = name
        self.icon = icon
        self.coordinate = coordinate
    }

    static func == (lhs: Destination, rhs: Destination) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    enum CodingKeys: String, CodingKey { case id, name, icon, latitude, longitude }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        icon = try c.decode(String.self, forKey: .icon)
        let lat = try c.decode(CLLocationDegrees.self, forKey: .latitude)
        let lon = try c.decode(CLLocationDegrees.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(icon, forKey: .icon)
        try c.encode(coordinate.latitude, forKey: .latitude)
        try c.encode(coordinate.longitude, forKey: .longitude)
    }
}
