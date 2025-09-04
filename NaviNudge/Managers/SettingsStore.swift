import SwiftUI
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    // MARK: - Persisted Settings
    @Published var isHapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(isHapticsEnabled, forKey: Keys.isHapticsEnabled) }
    }

    // Uses Apple Maps dirflg flags: d=drive, w=walk, r=transit, b=bike
    @Published var defaultTransportFlag: String {
        didSet { UserDefaults.standard.set(defaultTransportFlag, forKey: Keys.defaultTransportFlag) }
    }

    @Published var selectedTint: AppTint {
        didSet { UserDefaults.standard.set(selectedTint.rawValue, forKey: Keys.selectedTint) }
    }

    // MARK: - Init
    init() {
        if let stored = UserDefaults.standard.object(forKey: Keys.isHapticsEnabled) as? Bool {
            isHapticsEnabled = stored
        } else {
            isHapticsEnabled = true
        }

        defaultTransportFlag = UserDefaults.standard.string(forKey: Keys.defaultTransportFlag) ?? "d"

        if let name = UserDefaults.standard.string(forKey: Keys.selectedTint),
           let tint = AppTint(rawValue: name) {
            selectedTint = tint
        } else {
            selectedTint = .blue
        }
    }

    // MARK: - Keys
    private enum Keys {
        static let isHapticsEnabled = "settings.hapticsEnabled"
        static let defaultTransportFlag = "settings.defaultTransportFlag"
        static let selectedTint = "settings.selectedTint"
    }

    // MARK: - Tint
    enum AppTint: String, CaseIterable, Identifiable, Codable {
        case blue
        case green
        case orange
        case purple
        case pink
        case red
        case teal
        case indigo

        var id: String { rawValue }

        var color: Color {
            switch self {
            case .blue: return .blue
            case .green: return .green
            case .orange: return .orange
            case .purple: return .purple
            case .pink: return .pink
            case .red: return .red
            case .teal: return .teal
            case .indigo: return .indigo
            }
        }

        var displayName: String { rawValue.capitalized }
    }

    // MARK: - Transport Options
    var transportOptions: [(flag: String, label: String, symbol: String)] {
        [
            ("d", "Drive", "car.fill"),
            ("w", "Walk", "figure.walk"),
            ("r", "Transit", "tram.fill"),
            ("b", "Bike", "bicycle")
        ]
    }
}

