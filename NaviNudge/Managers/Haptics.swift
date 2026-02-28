import Foundation
import UIKit

enum Haptics {
    static private let selectionGenerator = UISelectionFeedbackGenerator()
    static private let impactLightGenerator = UIImpactFeedbackGenerator(style: .light)
    static private let impactMediumGenerator = UIImpactFeedbackGenerator(style: .medium)

    static func prepareSelection() {
        selectionGenerator.prepare()
    }

    static func selectionChanged() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    static func impactLight() {
        impactLightGenerator.impactOccurred()
    }

    static func prepareImpactMedium() {
        impactMediumGenerator.prepare()
    }

    static func impactMedium() {
        // Wrap in do-catch to handle any unexpected initialization errors gracefully
        do {
            try impactMediumGenerator.prepare()
            impactMediumGenerator.impactOccurred()
        } catch {
            // Silently fail - haptic is a nice-to-have, not critical functionality
            print("Haptic feedback error: \(error.localizedDescription)")
        }
    }

    static func impactMediumSafely() {
        // Alternative method that doesn't require prepare() call first
        impactMediumGenerator.impactOccurred()
    }
}
