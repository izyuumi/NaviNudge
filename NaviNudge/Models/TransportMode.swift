import Foundation

/// Transport mode used when building Apple Maps navigation URLs.
/// Shared between `CircularDestinationView` and `FavoritesView`.
enum TransportMode: CaseIterable, Identifiable, Hashable {
    case driving, walking, transit, biking
    var id: Self { self }
    var dirflg: String {
        switch self {
        case .driving: return "d"
        case .walking: return "w"
        case .transit: return "r"
        case .biking: return "b"
        }
    }
}
