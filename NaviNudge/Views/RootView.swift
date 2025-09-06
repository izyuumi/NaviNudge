import SwiftUI

struct RootView: View {
	@EnvironmentObject private var settings: AppSettings

	var body: some View {
		ContentView()
			.tint(accentColor)
			.preferredColorScheme(preferredScheme)
	}

	private var preferredScheme: ColorScheme? {
		switch settings.preferredColorScheme {
		case .system: return nil
		case .light: return .light
		case .dark: return .dark
		}
	}

	private var accentColor: Color {
		Color(hex: settings.accentColorHex) ?? .accentColor
	}
}

