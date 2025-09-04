import Combine
import CoreLocation
import Foundation
import SwiftUI

@MainActor
final class DestinationManager: ObservableObject {
    @Published var destinations: [Destination] = [] // start empty: only center node visible

    private var cancellables = Set<AnyCancellable>()
    private let storageKey = "destinations"

    init() {
        load()
        $destinations
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.save() }
            .store(in: &cancellables)
    }

    func add(name: String, icon: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees, at index: Int? = nil) {
        let dest = Destination(name: name, icon: icon, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        if let index = index, index >= 0 && index <= destinations.count {
            destinations.insert(dest, at: index)
        } else {
            destinations.append(dest)
        }
    }

    func remove(at offsets: IndexSet) {
        destinations.remove(atOffsets: offsets)
    }

    func move(from source: IndexSet, to destination: Int) {
        destinations.move(fromOffsets: source, toOffset: destination)
    }

    func update(_ destination: Destination) {
        if let idx = destinations.firstIndex(where: { $0.id == destination.id }) {
            destinations[idx] = destination
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        if let decoded = try? JSONDecoder().decode([Destination].self, from: data) {
            destinations = decoded
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(destinations) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
