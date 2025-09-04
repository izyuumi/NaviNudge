import Foundation
import UIKit

enum Haptics {
    static private let selectionGenerator = UISelectionFeedbackGenerator()
    static private let impactLightGenerator = UIImpactFeedbackGenerator(style: .light)

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
}
