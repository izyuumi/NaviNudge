import SwiftUI
import MapKit

struct EditDestinationView: View {
    let destination: Destination
    let onSave: (Destination) -> Void
    @Environment(\.dismiss) private var dismiss

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

