import MapKit

// MARK: - MKMapItem helpers (iOS 26 only)
func coordinate(of item: MKMapItem?) -> CLLocationCoordinate2D? {
    guard let item = item else { return nil }
    return item.location.coordinate
}

func displayAddress(for item: MKMapItem) -> String? {
    // TODO: Adopt iOS 26 address APIs when ready
    return nil
}
