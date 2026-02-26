import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var destinationManager: DestinationManager
    @EnvironmentObject private var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss

    @State private var showingManage = false
    @State private var confirmClear = false

    var body: some View {
        NavigationStack {
            List {
                Section("Destinations") {
                    Button("Manage Destinations") { showingManage = true }
                    Button(role: .destructive) {
                        confirmClear = true
                    } label: {
                        Text("Clear All Destinations")
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Haptic alert distance")
                            Spacer()
                            Text("\(Int(locationManager.hapticThresholdMeters)) m")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(
                            value: $locationManager.hapticThresholdMeters,
                            in: 10...200,
                            step: 10
                        )
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Haptic Feedback")
                } footer: {
                    Text("Vibrates when you come within this distance of a saved destination.")
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

