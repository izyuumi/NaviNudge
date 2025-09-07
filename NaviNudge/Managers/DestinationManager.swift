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

    func add(name: String, icon: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees, at index: Int? = nil, preferredSlotIndex: Int? = nil) {
        let dest = Destination(name: name, icon: icon, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), preferredSlotIndex: preferredSlotIndex)
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

    /// Returns destinations organized by their preferred button positions (0-7)
    /// Destinations without preferred positions fill remaining slots in array order
    var destinationsBySlot: [Int: Destination] {
        var slotMap: [Int: Destination] = [:]
        var unassigned: [Destination] = []
        
        // First pass: assign destinations with preferred slots
        for dest in destinations {
            if let slot = dest.preferredSlotIndex, slot >= 0 && slot < 8 {
                if slotMap[slot] == nil {
                    slotMap[slot] = dest
                } else {
                    // Slot conflict - add to unassigned
                    unassigned.append(dest)
                }
            } else {
                unassigned.append(dest)
            }
        }
        
        // Second pass: assign remaining destinations to free slots
        let usedSlots = Set(slotMap.keys)
        let availableSlots = (0..<8).filter { !usedSlots.contains($0) }
        
        for (index, dest) in unassigned.enumerated() {
            if index < availableSlots.count {
                slotMap[availableSlots[index]] = dest
            }
        }
        
        return slotMap
    }
    
    /// Updates a destination's preferred slot position
    func setPreferredSlot(_ slotIndex: Int?, for destinationId: UUID) {
        if let idx = destinations.firstIndex(where: { $0.id == destinationId }) {
            destinations[idx].preferredSlotIndex = slotIndex
        }
    }
    
    /// Returns the next available slot index (0-7), or nil if all are taken
    var nextAvailableSlot: Int? {
        let usedSlots = Set(destinations.compactMap { $0.preferredSlotIndex })
        return (0..<8).first { !usedSlots.contains($0) }
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
