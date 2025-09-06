import Foundation
import SwiftUI

enum TransportMode: String, CaseIterable, Identifiable, Codable {
	case driving
	case walking
	case transit
	case biking

	var id: Self { self }

	// Apple Maps dirflg parameter
	var appleDirflg: String {
		switch self {
		case .driving: return "d"
		case .walking: return "w"
		case .transit: return "r"
		case .biking: return "b"
		}
	}

	// Google Maps travelmode parameter
	var googleTravelMode: String {
		switch self {
		case .driving: return "driving"
		case .walking: return "walking"
		case .transit: return "transit"
		case .biking: return "bicycling"
		}
	}
}

