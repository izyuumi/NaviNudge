import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var destinationManager: DestinationManager
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var showingManage = false
    @State private var confirmClear = false
    @State private var exporting = false
    @State private var exportDocument: DestinationsDocument? = nil
    @State private var importing = false
    @State private var importError: String? = nil
    @State private var confirmImportReplace = false
    @State private var pendingImported: [Destination] = []

    var body: some View {
        NavigationStack {
            List {
                Section("General") {
                    Toggle(isOn: $settings.isHapticsEnabled) {
                        HStack {
                            Image(systemName: "hand.tap")
                            Text("Haptics")
                        }
                    }

                    Picker("Default Transport", selection: $settings.defaultTransportFlag) {
                        ForEach(settings.transportOptions, id: \.flag) { opt in
                            HStack {
                                Image(systemName: opt.symbol)
                                Text(opt.label)
                            }.tag(opt.flag)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Appearance") {
                    Picker("Accent Color", selection: $settings.selectedTint) {
                        ForEach(SettingsStore.AppTint.allCases) { tint in
                            HStack {
                                Circle()
                                    .fill(tint.color)
                                    .frame(width: 16, height: 16)
                                Text(tint.displayName)
                            }
                            .tag(tint)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Destinations") {
                    Button("Manage Destinations") { showingManage = true }
                    Button("Export Destinations") { exportDestinations() }
                    Button("Import Destinations") { importing = true }
                    Button(role: .destructive) {
                        confirmClear = true
                    } label: {
                        Text("Clear All Destinations")
                    }
                }

                Section("Privacy") {
                    HStack {
                        Text("Location Access")
                        Spacer()
                        Text(locationAuthorizationLabel)
                            .foregroundStyle(.secondary)
                    }
                    Button {
                        openAppSettings()
                    } label: {
                        HStack {
                            Image(systemName: "location")
                            Text("Open iOS Settings")
                        }
                    }
                    if locationManager.authorizationStatus == .notDetermined {
                        Button("Request When In Use") { locationManager.requestWhenInUse() }
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
            .alert("Import Error", isPresented: .constant(importError != nil), actions: {
                Button("OK", role: .cancel) { importError = nil }
            }, message: {
                Text(importError ?? "")
            })
            .alert("Replace all destinations with the imported list?", isPresented: $confirmImportReplace) {
                Button("Cancel", role: .cancel) { pendingImported = [] }
                Button("Replace", role: .destructive) {
                    destinationManager.destinations = pendingImported
                    pendingImported = []
                }
            } message: {
                Text("Your current destinations will be lost.")
            }
            .fileExporter(isPresented: $exporting, item: exportDocument, defaultFilename: "NaviNudge-Destinations") { result in
                switch result {
                case .success: break
                case .failure(let error): importError = error.localizedDescription
                }
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    do {
                        let data = try Data(contentsOf: url)
                        let decoded = try JSONDecoder().decode([Destination].self, from: data)
                        pendingImported = decoded
                        confirmImportReplace = true
                    } catch {
                        importError = "Failed to import: \(error.localizedDescription)"
                    }
                case .failure(let error):
                    importError = error.localizedDescription
                }
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

    private var locationAuthorizationLabel: String {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return "Authorized"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        default:
            return "Not Determined"
        }
    }
}

// MARK: - Export/Import Document
struct DestinationsDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Helpers
private extension SettingsView {
    func exportDestinations() {
        do {
            let data = try JSONEncoder().encode(destinationManager.destinations)
            exportDocument = DestinationsDocument(data: data)
            exporting = true
        } catch {
            importError = "Failed to export: \(error.localizedDescription)"
        }
    }
}

