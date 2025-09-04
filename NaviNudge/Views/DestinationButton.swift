import SwiftUI

struct DestinationButton: View {
    let destination: Destination

    var body: some View {
        VStack(spacing: 6) {
            Text(destination.icon)
                .font(.system(size: 28))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(.white.opacity(0.15)))
            Text(destination.name)
                .foregroundStyle(.white)
                .font(.caption)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(destination.name)
    }
}
