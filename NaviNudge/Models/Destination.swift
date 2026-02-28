import Foundation
import CoreLocation

struct Destination: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var icon: String // SF Symbol name
    var coordinate: CLLocationCoordinate2D
    var preferredSlotIndex: Int? // Optional button position (0-7), nil uses array order

    init(id: UUID = UUID(), name: String, icon: String, coordinate: CLLocationCoordinate2D, preferredSlotIndex: Int? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.coordinate = coordinate
        self.preferredSlotIndex = preferredSlotIndex
    }

    static func == (lhs: Destination, rhs: Destination) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.icon == rhs.icon &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.preferredSlotIndex == rhs.preferredSlotIndex
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(icon)
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
        hasher.combine(preferredSlotIndex)
    }

    enum CodingKeys: String, CodingKey { case id, name, icon, latitude, longitude, preferredSlotIndex }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        icon = try c.decode(String.self, forKey: .icon)
        let lat = try c.decode(CLLocationDegrees.self, forKey: .latitude)
        let lon = try c.decode(CLLocationDegrees.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        preferredSlotIndex = try c.decodeIfPresent(Int.self, forKey: .preferredSlotIndex)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(icon, forKey: .icon)
        try c.encode(coordinate.latitude, forKey: .latitude)
        try c.encode(coordinate.longitude, forKey: .longitude)
        try c.encodeIfPresent(preferredSlotIndex, forKey: .preferredSlotIndex)
    }
}
