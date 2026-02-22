import SwiftUI
import CoreLocation
import MapKit
import Combine

struct ManageDestinationsView: View {
    @EnvironmentObject private var destinationManager: DestinationManager
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var icon: String = "📍"
    @StateObject private var search = LocalSearchViewModel()
    @State private var selectedItem: MKMapItem? = nil
    @State private var showingEmojiPicker: Bool = false

    var body: some View {
        NavigationStack {
            List {
                if !destinationManager.destinations.isEmpty {
                    Section(header: Text("Your Destinations")) {
                        ForEach(destinationManager.destinations) { dest in
                            HStack(spacing: 12) {
                                Text(dest.icon)
                                    .font(.title2)
                                Text(dest.name)
                                    .font(.body)
                                Spacer()
                            }
                        }
                        .onDelete { offsets in
                            destinationManager.remove(at: offsets)
                        }
                        .onMove { source, destination in
                            destinationManager.move(from: source, to: destination)
                        }
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
                    if !destinationManager.destinations.isEmpty {
                        EditButton()
                    }
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
