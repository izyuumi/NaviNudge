import SwiftUI
import CoreLocation

/// A list-based view of saved favorite destinations with quick one-tap navigation.
struct FavoritesView: View {
    @EnvironmentObject private var destinationManager: DestinationManager
    @Environment(\.openURL) private var openURL

    @State private var transport: TransportMode = .driving
    @State private var showingAdd = false
    @State private var editingDestination: Destination? = nil
    @State private var showingNavigationConfirm: Destination? = nil
    @AppStorage("favoritesRequireConfirm") private var requireConfirm = false

    var body: some View {
        NavigationStack {
            Group {
                if destinationManager.destinations.isEmpty {
                    emptyState
                } else {
                    favoritesList
                }
            }
            .navigationTitle("Favorites")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                ManageDestinationsView()
            }
            .sheet(item: $editingDestination) { dest in
                EditDestinationView(destination: dest) { updated in
                    destinationManager.update(updated)
                }
            }
            .confirmationDialog(
                "Navigate to \(showingNavigationConfirm?.name ?? "")?",
                isPresented: Binding(
                    get: { showingNavigationConfirm != nil },
                    set: { if !$0 { showingNavigationConfirm = nil } }
                ),
                titleVisibility: .visible
            ) {
                if let dest = showingNavigationConfirm {
                    Button("Open in Maps") {
                        navigate(to: dest)
                        showingNavigationConfirm = nil
                    }
                    Button("Cancel", role: .cancel) { showingNavigationConfirm = nil }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.slash")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No Favorites Yet")
                .font(.title2.bold())
            Text("Save frequently visited places for one-tap navigation.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Add Favorite") { showingAdd = true }
                .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Favorites List

    private var favoritesList: some View {
        VStack(spacing: 0) {
            // Transport mode picker
            Picker("Mode", selection: $transport) {
                Image(systemName: "car.fill").tag(TransportMode.driving)
                Image(systemName: "figure.walk").tag(TransportMode.walking)
                Image(systemName: "bus.fill").tag(TransportMode.transit)
                Image(systemName: "bicycle").tag(TransportMode.biking)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            List {
                ForEach(destinationManager.destinations) { dest in
                    FavoriteRow(destination: dest) {
                        // Quick-launch: confirm if preference set, otherwise go directly
                        if requireConfirm {
                            showingNavigationConfirm = dest
                        } else {
                            navigate(to: dest)
                        }
                    } onEdit: {
                        editingDestination = dest
                    }
                }
                .onDelete { offsets in
                    destinationManager.remove(at: offsets)
                }
                .onMove { source, destination in
                    destinationManager.move(from: source, to: destination)
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    // MARK: - Navigation

    private func navigate(to destination: Destination) {
        var comps = URLComponents()
        comps.scheme = "https"
        comps.host = "maps.apple.com"
        comps.queryItems = [
            URLQueryItem(name: "saddr", value: "Current Location"),
            URLQueryItem(name: "daddr", value: "\(destination.coordinate.latitude),\(destination.coordinate.longitude)"),
            URLQueryItem(name: "dirflg", value: transport.dirflg),
        ]
        if let url = comps.url { openURL(url) }
    }
}

// MARK: - Favorite Row

private struct FavoriteRow: View {
    let destination: Destination
    let onNavigate: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Icon bubble
            Text(destination.icon)
                .font(.system(size: 26))
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.secondary.opacity(0.15)))

            // Name
            Text(destination.name)
                .font(.body)
                .lineLimit(1)

            Spacer()

            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 4)

            // Navigation button (primary action)
            Button(action: onNavigate) {
                Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onNavigate)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(destination.name)")
        .accessibilityHint("Tap to navigate, swipe left to delete")
    }
}

// MARK: - Transport Mode (mirrors the one in CircularDestinationView)

private enum TransportMode: CaseIterable, Identifiable, Hashable {
    case driving, walking, transit, biking
    var id: Self { self }
    var dirflg: String {
        switch self {
        case .driving: return "d"
        case .walking: return "w"
        case .transit: return "r"
        case .biking: return "b"
        }
    }
}
