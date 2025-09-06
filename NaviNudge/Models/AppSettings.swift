import Foundation
import SwiftUI

@MainActor
final class AppSettings: ObservableObject {
	// Appearance
	@Published var preferredColorScheme: ColorSchemeOption = .system { didSet { persist() } }
	@Published var accentColorHex: String = "#0A84FF" { didSet { persist() } } // default iOS accent

	// Interaction
	@Published var hapticsEnabled: Bool = true { didSet { persist() } }
	@Published var defaultTransportMode: TransportMode = .driving { didSet { persist() } }
	@Published var preferredMapsApp: MapsApp = .apple { didSet { persist() } }

	// Storage keys
	private let storageKey = "app_settings_v1"

	init() {
		load()
	}

	func persist() {
		let snapshot = Snapshot(
			preferredColorScheme: preferredColorScheme,
			accentColorHex: accentColorHex,
			hapticsEnabled: hapticsEnabled,
			defaultTransportMode: defaultTransportMode,
			preferredMapsApp: preferredMapsApp
		)
		if let data = try? JSONEncoder().encode(snapshot) {
			UserDefaults.standard.set(data, forKey: storageKey)
		}
	}

	private func load() {
		guard let data = UserDefaults.standard.data(forKey: storageKey),
				let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
		preferredColorScheme = decoded.preferredColorScheme
		accentColorHex = decoded.accentColorHex
		hapticsEnabled = decoded.hapticsEnabled
		defaultTransportMode = decoded.defaultTransportMode
		preferredMapsApp = decoded.preferredMapsApp
	}

	// MARK: - Export / Import
	func exportJSON() -> Data? {
		let snapshot = Snapshot(
			preferredColorScheme: preferredColorScheme,
			accentColorHex: accentColorHex,
			hapticsEnabled: hapticsEnabled,
			defaultTransportMode: defaultTransportMode,
			preferredMapsApp: preferredMapsApp
		)
		return try? JSONEncoder().encode(snapshot)
	}

	func importJSON(_ data: Data) throws {
		let decoded = try JSONDecoder().decode(Snapshot.self, from: data)
		preferredColorScheme = decoded.preferredColorScheme
		accentColorHex = decoded.accentColorHex
		hapticsEnabled = decoded.hapticsEnabled
		defaultTransportMode = decoded.defaultTransportMode
		preferredMapsApp = decoded.preferredMapsApp
		persist()
	}
}

// MARK: - Types
enum ColorSchemeOption: String, CaseIterable, Identifiable, Codable {
	case system
	case light
	case dark
	var id: Self { self }
}

enum MapsApp: String, CaseIterable, Identifiable, Codable {
	case apple
	case google
	var id: Self { self }
}

private struct Snapshot: Codable {
	let preferredColorScheme: ColorSchemeOption
	let accentColorHex: String
	let hapticsEnabled: Bool
	let defaultTransportMode: TransportMode
	let preferredMapsApp: MapsApp
}

// MARK: - Helpers
extension Color {
	init?(hex: String) {
		let r, g, b, a: Double
		var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
		if cleaned.hasPrefix("#") { cleaned.removeFirst() }
		if cleaned.count == 6 { cleaned.append("FF") }
		guard cleaned.count == 8, let value = UInt64(cleaned, radix: 16) else { return nil }
		r = Double((value & 0xFF000000) >> 24) / 255.0
		g = Double((value & 0x00FF0000) >> 16) / 255.0
		b = Double((value & 0x0000FF00) >> 8) / 255.0
		a = Double(value & 0x000000FF) / 255.0
		self = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
	}
}

