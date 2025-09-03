import Foundation
import CoreLocation
import Combine

final class DestinationManager: ObservableObject {
    @Published var destinations: [Destination] = [
        Destination(
            name: "Home",
            icon: "house.fill",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        ),
        Destination(
            name: "Work",
            icon: "briefcase.fill",
            coordinate: CLLocationCoordinate2D(latitude: 37.7879, longitude: -122.4075)
        ),
        Destination(
            name: "School",
            icon: "graduationcap.fill",
            coordinate: CLLocationCoordinate2D(latitude: 37.7833, longitude: -122.4089)
        ),
        Destination(
            name: "Gym",
            icon: "dumbbell.fill",
            coordinate: CLLocationCoordinate2D(latitude: 37.7800, longitude: -122.4200)
        )
    ]
}
