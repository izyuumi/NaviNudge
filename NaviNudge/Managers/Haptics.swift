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
        impactMediumGenerator.impactOccurred()
    }
}
