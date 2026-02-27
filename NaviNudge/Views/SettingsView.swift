import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var destinationManager: DestinationManager
    @Environment(\.dismiss) private var dismiss

    @State private var showingManage = false
    @State private var confirmClear = false
    @AppStorage("favoritesRequireConfirm") private var favoritesRequireConfirm = false

    var body: some View {
        NavigationStack {
            List {
                Section("Favorites") {
                    Toggle("Confirm before navigating", isOn: $favoritesRequireConfirm)
                }

                Section("Destinations") {
                    Button("Manage Destinations") { showingManage = true }
                    Button(role: .destructive) {
                        confirmClear = true
                    } label: {
                        Text("Clear All Destinations")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showingManage) {
                ManageDestinationsView()
            }
            .alert("Clear all saved destinations?", isPresented: $confirmClear) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    destinationManager.destinations.removeAll()
                }
            } message: {
                Text("This cannot be undone.")
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return build.isEmpty ? version : "\(version) (\(build))"
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

