import Foundation
import MapKit
import Combine

final class LocalSearchViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var query: String = "" {
        didSet { completer.queryFragment = query }
    }
    @Published var results: [MKLocalSearchCompletion] = []

    private let completer: MKLocalSearchCompleter = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func updateRegion(_ region: MKCoordinateRegion) {
        completer.region = region
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.results = completer.results
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error.localizedDescription)")
    }

    func resolve(suggestion: MKLocalSearchCompletion, completion: @escaping (MKMapItem?) -> Void) {
        let request = MKLocalSearch.Request(completion: suggestion)
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let error = error {
                print("Local search error: \(error.localizedDescription)")
            }
            completion(response?.mapItems.first)
        }
    }
}

