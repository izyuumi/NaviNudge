import SwiftUI
import MapKit
import Combine

struct QuickAddDestinationPopover: View {
    let slotIndex: Int
    let onClose: () -> Void

    @EnvironmentObject private var destinationManager: DestinationManager

    @State private var name: String = ""
    @State private var icon: String = "📍"
    @StateObject private var search = QuickLocalSearchViewModel()
    @State private var selectedItem: MKMapItem? = nil

    private var isValid: Bool {
        selectedItem != nil && !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private let quickEmojis: [String] = ["📍","🏠","🏢","🏫","🏖️","🍽️","☕️","🚗"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Add Destination")
                .font(.headline)

            // Name
            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)

            // Emoji quick picker (wraps to fit width)
            VStack(alignment: .leading, spacing: 6) {
                Text("Emoji")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                let cols = Array(repeating: GridItem(.fixed(32), spacing: 8), count: 6)
                LazyVGrid(columns: cols, alignment: .leading, spacing: 8) {
                    ForEach(quickEmojis, id: \.self) { e in
                        Button {
                            icon = e
                        } label: {
                            Text(e)
                                .font(.system(size: 20))
                                .frame(width: 32, height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(icon == e ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.12))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Search
            VStack(alignment: .leading, spacing: 8) {
                TextField("Search place or address", text: $search.query)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .textFieldStyle(.roundedBorder)

                if let item = selectedItem {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name ?? "Selected place")
                                .font(.subheadline)
                            if let subtitle = quickDisplayAddress(for: item) {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button("Change") { selectedItem = nil }
                            .buttonStyle(.borderless)
                    }
                } else {
                    let suggestions = Array(search.results.prefix(6))
                    if !suggestions.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(Array(suggestions.enumerated()), id: \.offset) { _, suggestion in
                                    Button {
                                        search.resolve(suggestion: suggestion) { item in
                                            DispatchQueue.main.async { self.selectedItem = item }
                                        }
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(suggestion.title)
                                                .font(.subheadline)
                                                .lineLimit(1)
                                                .foregroundStyle(.primary)
                                            if !suggestion.subtitle.isEmpty {
                                                Text(suggestion.subtitle)
                                                    .font(.caption2)
                                                    .lineLimit(1)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(maxHeight: 150)
                    }
                }
            }

            HStack {
                Button("Cancel") { onClose() }
                Spacer()
                Button("Add") { add() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValid)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func add() {
        guard let coord = quickCoordinate(of: selectedItem) else { return }
        destinationManager.add(
            name: name.trimmingCharacters(in: .whitespaces),
            icon: icon,
            latitude: coord.latitude,
            longitude: coord.longitude,
            at: slotIndex
        )
        onClose()
    }
}

// MARK: - Lightweight Search VM
final class QuickLocalSearchViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
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
        DispatchQueue.main.async { self.results = completer.results }
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

// MARK: - Helpers
private func quickCoordinate(of item: MKMapItem?) -> CLLocationCoordinate2D? {
    guard let item = item else { return nil }
    return item.location.coordinate
}

private func quickDisplayAddress(for item: MKMapItem) -> String? {
    return nil
}
