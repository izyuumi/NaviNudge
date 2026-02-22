import Foundation
import CoreLocation

struct Destination: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var icon: String // SF Symbol name
    var coordinate: CLLocationCoordinate2D
    var preferredSlotIndex: Int? // Optional button position (0-7), nil uses array order
    var colorHex: String? // Custom color hex (e.g. "#FF6B6B"), nil uses default

    init(id: UUID = UUID(), name: String, icon: String, coordinate: CLLocationCoordinate2D, preferredSlotIndex: Int? = nil, colorHex: String? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.coordinate = coordinate
        self.preferredSlotIndex = preferredSlotIndex
        self.colorHex = colorHex
    }

    static func == (lhs: Destination, rhs: Destination) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    enum CodingKeys: String, CodingKey { case id, name, icon, latitude, longitude, preferredSlotIndex, colorHex }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        icon = try c.decode(String.self, forKey: .icon)
        let lat = try c.decode(CLLocationDegrees.self, forKey: .latitude)
        let lon = try c.decode(CLLocationDegrees.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        preferredSlotIndex = try c.decodeIfPresent(Int.self, forKey: .preferredSlotIndex)
        colorHex = try c.decodeIfPresent(String.self, forKey: .colorHex)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(icon, forKey: .icon)
        try c.encode(coordinate.latitude, forKey: .latitude)
        try c.encode(coordinate.longitude, forKey: .longitude)
        try c.encodeIfPresent(preferredSlotIndex, forKey: .preferredSlotIndex)
        try c.encodeIfPresent(colorHex, forKey: .colorHex)
    }

    /// Returns a SwiftUI Color from the hex string, or default if not set
    var color: Color {
        guard let hex = colorHex, !hex.isEmpty else { return .blue }
        let clean = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard clean.count == 6, let rgb = UInt(clean, radix: 16) else { return .blue }
        return Color(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
