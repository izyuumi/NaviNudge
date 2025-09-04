import SwiftUI
import CoreLocation
import MapKit
import Combine

struct ManageDestinationsView: View {
    @EnvironmentObject private var destinationManager: DestinationManager
    @EnvironmentObject private var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var icon: String = "📍"
    @StateObject private var search = LocalSearchViewModel()
    @State private var selectedItem: MKMapItem? = nil
    @State private var showingEmojiPicker: Bool = false
    @State private var editingDestination: Destination? = nil

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Saved Destinations")) {
                    if destinationManager.destinations.isEmpty {
                        Text("No destinations yet. Add one below.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(destinationManager.destinations) { dest in
                            HStack(spacing: 12) {
                                Text(dest.icon)
                                    .font(.system(size: 20))
                                    .frame(width: 28)
                                VStack(alignment: .leading) {
                                    Text(dest.name)
                                    Text(String(format: "%.5f, %.5f", dest.coordinate.latitude, dest.coordinate.longitude))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onLongPressGesture {
                                editingDestination = dest
                            }
                        }
                        .onDelete(perform: destinationManager.remove)
                        .onMove(perform: destinationManager.move)
                    }
                }

                Section(header: Text("Add Destination")) {
                    TextField("Name", text: $name)
                    HStack {
                        Text("Emoji")
                        Spacer()
                        Text(icon)
                            .font(.title)
                        Button("Change") { showingEmojiPicker = true }
                            .buttonStyle(.borderless)
                    }
                    .sheet(isPresented: $showingEmojiPicker) {
                        EmojiPickerView(selection: $icon)
                    }
                    // Search input
                    TextField("Search place or address", text: $search.query)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)

                    // Show selected place summary
                    if let item = selectedItem {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name ?? "Selected place")
                                    .font(.subheadline)
                                if let subtitle = displayAddress(for: item) {
                                    Text(subtitle)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Button("Change") { selectedItem = nil }
                                .buttonStyle(.borderless)
                        }
                    }

                    // Suggestions list (limited)
                    if selectedItem == nil {
                        let suggestions = Array(search.results.prefix(8))
                        if !suggestions.isEmpty {
                            ForEach(Array(suggestions.enumerated()), id: \.offset) { _, suggestion in
                                Button {
                                    selectSuggestion(suggestion)
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(suggestion.title)
                                        if !suggestion.subtitle.isEmpty {
                                            Text(suggestion.subtitle)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Button("Add") { add() }
                        .buttonStyle(.borderedProminent)
                        .disabled(!isValid)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                        .disabled(destinationManager.destinations.isEmpty)
                }
            }
            .onAppear {
                if let center = locationManager.currentCoordinate {
                    search.updateRegion(MKCoordinateRegion(center: center, latitudinalMeters: 2500, longitudinalMeters: 2500))
                }
            }
            .sheet(item: $editingDestination) { dest in
                EditDestinationView(destination: dest) { updated in
                    destinationManager.update(updated)
                }
            }
        }
    }

    private var isValid: Bool {
        selectedItem != nil && !name.trimmingCharacters(in: .whitespaces).isEmpty && !icon.isEmpty
    }

    private func add() {
        guard let coord = coordinate(of: selectedItem) else { return }
        destinationManager.add(
            name: name.trimmingCharacters(in: .whitespaces),
            icon: icon,
            latitude: coord.latitude,
            longitude: coord.longitude
        )
        name = ""
        icon = "📍"
        selectedItem = nil
        search.query = ""
    }

    private func selectSuggestion(_ suggestion: MKLocalSearchCompletion) {
        search.resolve(suggestion: suggestion) { item in
            DispatchQueue.main.async {
                self.selectedItem = item
                if let n = item?.name, self.name.trimmingCharacters(in: .whitespaces).isEmpty {
                    self.name = n
                }
            }
        }
    }
}

// MARK: - Local Search View Model (inline)
private final class LocalSearchViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
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

// MARK: - Emoji Picker
private struct EmojiPickerView: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss

    private let emojis: [String] = [
        "📍","🏠","🏢","🏫","🏛️","🏖️","🏝️","🏔️","⛺️","🏕️","🗽","🗼","🕌","⛩️","⛲️",
        "🎢","🎡","🎠","🏟️","⚽️","🏀","🎾","🏊‍♂️","🏋️‍♀️",
        "🚗","🚲","🛴","🚌","🚆","🚇","✈️","🚢","⛴️","⛵️","🛥️","🚁",
        "🍽️","☕️","🍺","🍣","🍜","🍕","🥐","🥗","🛒","🏥","🏬","🏪","🏨"
    ]

    private var columns: [GridItem] { Array(repeating: GridItem(.flexible(), spacing: 12), count: 6) }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(emojis, id: \.self) { e in
                        Button {
                            selection = e
                            dismiss()
                        } label: {
                            Text(e)
                                .font(.system(size: 28))
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.secondary.opacity(0.12))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Emoji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Close") { dismiss() } }
            }
        }
    }
}

// MARK: - Edit Destination View
private struct EditDestinationView: View {
    let destination: Destination
    let onSave: (Destination) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var locationManager: LocationManager

    @State private var name: String
    @State private var icon: String
    @StateObject private var search = LocalSearchViewModel()
    @State private var selectedItem: MKMapItem? = nil
    @State private var showingEmojiPicker: Bool = false

    init(destination: Destination, onSave: @escaping (Destination) -> Void) {
        self.destination = destination
        self.onSave = onSave
        _name = State(initialValue: destination.name)
        _icon = State(initialValue: destination.icon)
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !icon.isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Edit Destination")) {
                    TextField("Name", text: $name)
                    HStack {
                        Text("Emoji")
                        Spacer()
                        Text(icon)
                            .font(.title)
                        Button("Change") { showingEmojiPicker = true }
                            .buttonStyle(.borderless)
                    }
                    .sheet(isPresented: $showingEmojiPicker) {
                        EmojiPickerView(selection: $icon)
                    }
                }

                Section(header: Text("Location")) {
                    // Current selection summary
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current: \(destination.coordinate.latitude), \(destination.coordinate.longitude)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    TextField("Search place or address", text: $search.query)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)

                    if let item = selectedItem {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name ?? "Selected place")
                                    .font(.subheadline)
                                if let subtitle = displayAddress(for: item) {
                                    Text(subtitle)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Button("Change") { selectedItem = nil }
                                .buttonStyle(.borderless)
                        }
                    }

                    let suggestions = Array(search.results.prefix(8))
                    if selectedItem == nil && !suggestions.isEmpty {
                        ForEach(Array(suggestions.enumerated()), id: \.offset) { _, suggestion in
                            Button {
                                selectSuggestion(suggestion)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestion.title)
                                    if !suggestion.subtitle.isEmpty {
                                        Text(suggestion.subtitle)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear {
                if let center = locationManager.currentCoordinate {
                    search.updateRegion(MKCoordinateRegion(center: center, latitudinalMeters: 2500, longitudinalMeters: 2500))
                }
            }
        }
    }

    private func selectSuggestion(_ suggestion: MKLocalSearchCompletion) {
        search.resolve(suggestion: suggestion) { item in
            DispatchQueue.main.async {
                self.selectedItem = item
            }
        }
    }

    private func save() {
        let newCoord = coordinate(of: selectedItem) ?? destination.coordinate
        let updated = Destination(
            id: destination.id,
            name: name.trimmingCharacters(in: .whitespaces),
            icon: icon,
            coordinate: CLLocationCoordinate2D(latitude: newCoord.latitude, longitude: newCoord.longitude)
        )
        onSave(updated)
        dismiss()
    }
}

// MARK: - Helpers (deprecation-safe)
private func coordinate(of item: MKMapItem?) -> CLLocationCoordinate2D? {
    guard let item = item else { return nil }
    if #available(iOS 26.0, *) {
        return item.location.coordinate
    } else {
        return item.placemark.coordinate
    }
}

private func displayAddress(for item: MKMapItem) -> String? {
    if #available(iOS 26.0, *) {
        // Future: use item.address / addressRepresentations when formatting is desired.
        return nil
    } else {
        return item.placemark.title
    }
}
