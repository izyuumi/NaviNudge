import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var destinationManager: DestinationManager
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var showingManage = false
    @State private var confirmClear = false
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var exportData: Data? = nil
    @State private var importError: String? = nil

    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    Picker("Theme", selection: $settings.preferredColorScheme) {
                        ForEach(ColorSchemeOption.allCases) { option in
                            Text(label(for: option)).tag(option)
                        }
                    }
                    ColorPicker("Accent Color", selection: Binding(
                        get: { Color(hex: settings.accentColorHex) ?? .accentColor },
                        set: { color in settings.accentColorHex = color.toHex() ?? settings.accentColorHex }
                    ))
                }

                Section("Navigation") {
                    Picker("Default Mode", selection: $settings.defaultTransportMode) {
                        ForEach(TransportMode.allCases) { mode in
                            Text(modeLabel(mode)).tag(mode)
                        }
                    }
                    Picker("Maps App", selection: $settings.preferredMapsApp) {
                        ForEach(MapsApp.allCases) { app in
                            Text(appLabel(app)).tag(app)
                        }
                    }
                }

                Section("Interaction") {
                    Toggle("Haptics", isOn: $settings.hapticsEnabled)
                    Button("System Settings…") { openAppSettings() }
                }

                Section("Destinations") {
                    Button("Manage Destinations") { showingManage = true }
                    Button(role: .destructive) {
                        confirmClear = true
                    } label: {
                        Text("Clear All Destinations")
                    }
                }

                Section("Backup") {
                    Button("Export Settings & Destinations") { exportAll() }
                    Button("Import from JSON…") { showingImporter = true }
                    if let error = importError {
                        Text(error).font(.footnote).foregroundStyle(.red)
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
            .fileExporter(
                isPresented: $showingExporter,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "NaviNudge-Backup.json"
            ) { _ in
                exportData = nil
            }
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    do {
                        let data = try Data(contentsOf: url)
                        try importAll(from: data)
                        importError = nil
                    } catch {
                        importError = "Failed to import: \(error.localizedDescription)"
                    }
                case .failure(let error):
                    importError = "Import canceled: \(error.localizedDescription)"
                }
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

    private func label(for option: ColorSchemeOption) -> String {
        switch option {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    private func modeLabel(_ mode: TransportMode) -> String {
        switch mode {
        case .driving: return "Drive"
        case .walking: return "Walk"
        case .transit: return "Transit"
        case .biking: return "Bike"
        }
    }

    private func appLabel(_ app: MapsApp) -> String {
        switch app {
        case .apple: return "Apple Maps"
        case .google: return "Google Maps"
        }
    }

    // MARK: - Export / Import
    private var exportDocument: JSONDocument? {
        guard let data = exportData else { return nil }
        return JSONDocument(data: data)
    }

    private func exportAll() {
        var payload: [String: Any] = [:]
        if let settingsData = settings.exportJSON() {
            payload["settings"] = try? JSONSerialization.jsonObject(with: settingsData)
        }
        if let dests = try? JSONEncoder().encode(destinationManager.destinations) {
            payload["destinations"] = try? JSONSerialization.jsonObject(with: dests)
        }
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted]) {
            exportData = data
            showingExporter = true
        }
    }

    private func importAll(from data: Data) throws {
        let obj = try JSONSerialization.jsonObject(with: data, options: [])
        guard let dict = obj as? [String: Any] else { throw NSError(domain: "Import", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON root"]) }
        if let settingsObj = dict["settings"], JSONSerialization.isValidJSONObject(settingsObj),
           let settingsData = try? JSONSerialization.data(withJSONObject: settingsObj) {
            try settings.importJSON(settingsData)
        }
        if let destsObj = dict["destinations"], JSONSerialization.isValidJSONObject(destsObj),
           let destsData = try? JSONSerialization.data(withJSONObject: destsObj) {
            let decoded = try JSONDecoder().decode([Destination].self, from: destsData)
            destinationManager.destinations = decoded
        }
    }
}

// MARK: - Helpers
extension Color {
    func toHex() -> String? {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        let value = (Int(r * 255) << 24) | (Int(g * 255) << 16) | (Int(b * 255) << 8) | Int(a * 255)
        return String(format: "#%08X", value)
    }
}

struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) { self.data = data }

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

